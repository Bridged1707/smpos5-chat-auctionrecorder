local M = {}
local resolver = require("peripheral_resolver")

local function isPlaceholder(value)
    return type(value) ~= "string" or value == "" or value:find("CHANGE_ME", 1, true) ~= nil
end

function M.findReactor(cfg, selector)
    selector = tostring(selector or ""):lower()
    local number = tonumber(selector)

    for index, reactor in ipairs(cfg.reactors or {}) do
        if number == index or selector == tostring(reactor.id or ""):lower() or selector == tostring(reactor.label or ""):lower() then
            return reactor, index
        end
    end

    return nil, nil
end

function M.selectedReactors(cfg, selector)
    if tostring(selector or ""):lower() == "all" then
        return cfg.reactors or {}
    end

    local reactor = M.findReactor(cfg, selector)
    if reactor then return { reactor } end
    return {}
end

function M.getRelayState(relayConfig)
    if not relayConfig or isPlaceholder(relayConfig.peripheral) then
        return nil, "UNCONFIGURED"
    end

    local relay, _, resolveStatus = resolver.wrap(relayConfig.peripheral, {})
    if not relay then return nil, resolveStatus or "MISSING" end

    local side = relayConfig.outputSide or "back"
    local ok, powered

    if type(relay.getOutput) == "function" then
        ok, powered = pcall(relay.getOutput, side)
    elseif type(relay.getAnalogOutput) == "function" then
        local value
        ok, value = pcall(relay.getAnalogOutput, side)
        powered = ok and value > 0 or false
    else
        return nil, "BAD TYPE"
    end

    if not ok then return nil, "READ ERR" end

    local enabled
    if relayConfig.poweredMeansEnabled == true then
        enabled = powered == true
    else
        enabled = powered ~= true
    end

    return enabled, enabled and "ON" or "OFF"
end

function M.setRelayState(relayConfig, enabled)
    if not relayConfig or isPlaceholder(relayConfig.peripheral) then
        return false, "UNCONFIGURED"
    end

    local relay, _, resolveStatus = resolver.wrap(relayConfig.peripheral, {})
    if not relay then return false, resolveStatus or "MISSING" end

    local powered
    if relayConfig.poweredMeansEnabled == true then
        powered = enabled == true
    else
        powered = enabled ~= true
    end

    local side = relayConfig.outputSide or "back"
    local ok, err

    if type(relay.setOutput) == "function" then
        ok, err = pcall(relay.setOutput, side, powered)
    elseif type(relay.setAnalogOutput) == "function" then
        ok, err = pcall(relay.setAnalogOutput, side, powered and 15 or 0)
    else
        return false, "BAD TYPE"
    end

    if not ok then return false, tostring(err or "WRITE ERR") end
    return true, enabled and "ON" or "OFF"
end

function M.getFuelFeedState(reactor)
    local total, enabledCount, unknownCount = 0, 0, 0
    local details = {}

    for index, chute in ipairs(reactor.fuelChutes or {}) do
        total = total + 1
        local enabled, state = M.getRelayState(chute.relay)
        if enabled == true then enabledCount = enabledCount + 1 end
        if enabled == nil then unknownCount = unknownCount + 1 end
        table.insert(details, {
            index = index,
            label = chute.label or ("Rod " .. index),
            enabled = enabled,
            state = state
        })
    end

    local state
    if total == 0 then state = "NO CHUTES"
    elseif unknownCount > 0 then state = "UNKNOWN"
    elseif enabledCount == 0 then state = "OFF"
    elseif enabledCount == total then state = "ON"
    else state = "PARTIAL" end

    return {
        total = total,
        enabledCount = enabledCount,
        unknownCount = unknownCount,
        state = state,
        active = enabledCount > 0,
        details = details
    }
end

function M.getClutchState(reactor, network)
    local clutch = reactor.clutches and reactor.clutches[network]
    if not clutch then return nil, "NO CLUTCH" end
    return M.getRelayState(clutch.relay)
end

function M.readSpeedometer(name)
    if isPlaceholder(name) then return { online = false, rpm = 0, status = "UNCONFIGURED", configuredName = name } end
    local meter, actualName, resolveStatus = resolver.wrap(name, { "getSpeed" })
    if not meter then return { online = false, rpm = 0, status = resolveStatus or "MISSING", configuredName = name, actualName = actualName } end
    local ok, speed = pcall(meter.getSpeed)
    if not ok then return { online = false, rpm = 0, status = "READ ERR", configuredName = name, actualName = actualName } end
    return { online = true, rpm = tonumber(speed) or 0, status = "OK", configuredName = name, actualName = actualName }
end


function M.getGeneratorClutchState(reactor)
    local coil = reactor.generatorCoil
    local clutch = coil and coil.clutch
    if not clutch then return nil, "NO COIL CLUTCH" end
    return M.getRelayState(clutch.relay)
end

function M.setGeneratorClutchState(reactor, enabled)
    local coil = reactor.generatorCoil
    local clutch = coil and coil.clutch
    if not clutch then return false, "NO COIL CLUTCH" end
    return M.setRelayState(clutch.relay, enabled)
end

local function tryNumberMethod(peripheralObject, methodNames)
    for _, methodName in ipairs(methodNames) do
        if type(peripheralObject[methodName]) == "function" then
            local ok, value = pcall(peripheralObject[methodName])
            if ok and tonumber(value) ~= nil then
                return tonumber(value), methodName
            end
        end
    end

    return nil, nil
end

function M.readAccumulator(name)
    if isPlaceholder(name) then
        return { online = false, status = "UNCONFIGURED", energy = nil, capacity = nil, percent = 0, configuredName = name }
    end

    local acc, actualName, resolveStatus = resolver.wrap(name, {})
    if not acc then
        return { online = false, status = resolveStatus or "MISSING", energy = nil, capacity = nil, percent = 0, configuredName = name, actualName = actualName }
    end

    -- Different electricity/energy mods expose different method names. Try the common ones.
    local energy, energyMethod = tryNumberMethod(acc, {
        "getEnergy", "getEnergyStored", "getStoredEnergy", "getFE", "getFEStored",
        "getPower", "getPowerStored", "getCharge", "getStored", "getAmount"
    })

    local capacity, capacityMethod = tryNumberMethod(acc, {
        "getEnergyCapacity", "getMaxEnergyStored", "getCapacity", "getMaxEnergy",
        "getMaxFE", "getMaxPower", "getMaxCharge", "getLimit"
    })

    if energy == nil and capacity == nil then
        return {
            online = true,
            status = "NO ENERGY API",
            energy = nil,
            capacity = nil,
            percent = 0,
            configuredName = name,
            actualName = actualName,
            methods = peripheral.getMethods(actualName or name) or {}
        }
    end

    local percent = 0
    if capacity and capacity > 0 and energy then
        percent = energy / capacity * 100
    end

    return {
        online = true,
        status = "OK",
        energy = energy,
        capacity = capacity,
        percent = percent,
        configuredName = name,
        actualName = actualName,
        energyMethod = energyMethod,
        capacityMethod = capacityMethod
    }
end

function M.readAccumulatorBank(reactor)
    local coil = reactor.generatorCoil or {}
    local totalEnergy = 0
    local totalCapacity = 0
    local online = 0
    local readable = 0
    local missing = 0
    local unconfigured = 0
    local noEnergyApi = 0
    local details = {}

    for index, accumulator in ipairs(coil.accumulators or {}) do
        local data = M.readAccumulator(accumulator.peripheral)
        data.index = index
        data.label = accumulator.label or ("Accumulator " .. index)
        table.insert(details, data)

        if data.status == "UNCONFIGURED" then
            unconfigured = unconfigured + 1
        elseif data.online then
            online = online + 1
            if data.energy ~= nil or data.capacity ~= nil then
                readable = readable + 1
                totalEnergy = totalEnergy + (data.energy or 0)
                totalCapacity = totalCapacity + (data.capacity or 0)
            elseif data.status == "NO ENERGY API" then
                noEnergyApi = noEnergyApi + 1
            end
        else
            missing = missing + 1
        end
    end

    local percent = 0
    if totalCapacity > 0 then
        percent = totalEnergy / totalCapacity * 100
    end

    return {
        total = #(coil.accumulators or {}),
        online = online,
        readable = readable,
        missing = missing,
        unconfigured = unconfigured,
        noEnergyApi = noEnergyApi,
        energy = totalEnergy,
        capacity = totalCapacity,
        percent = percent,
        details = details
    }
end

return M
