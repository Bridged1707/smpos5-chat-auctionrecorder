local cfg = require("peripheral_config")
local control = require("control_common")

local function dumpMethods(name)
    local methods = peripheral.getMethods(name) or {}
    table.sort(methods)
    local out = {}
    for _, method in ipairs(methods) do table.insert(out, method) end
    return table.concat(out, ", ")
end

for _, reactor in ipairs(cfg.reactors or {}) do
    if reactor.enabled ~= false then
        print("==============================")
        print(reactor.label)

        local coilOn, coilState = control.getGeneratorClutchState(reactor)
        print("Generator clutch: " .. tostring(coilState))

        local bank = control.readAccumulatorBank(reactor)
        print("Accumulators: " .. bank.online .. "/" .. bank.total .. " online, " .. bank.readable .. " readable")
        print("Missing: " .. bank.missing .. "  Unconfigured: " .. bank.unconfigured .. "  No API: " .. bank.noEnergyApi)
        if bank.capacity > 0 then
            print("Energy: " .. math.floor(bank.energy) .. " / " .. math.floor(bank.capacity) .. " (" .. string.format("%.1f", bank.percent) .. "%)")
        end
        print("")

        for _, acc in ipairs(bank.details) do
            print((acc.label or ("Accumulator " .. tostring(acc.index))) .. ": " .. tostring(acc.status))
            print("  Configured: " .. tostring(acc.configuredName))
            print("  Actual:     " .. tostring(acc.actualName))
            if acc.energy ~= nil then print("  Energy:     " .. tostring(acc.energy) .. " via " .. tostring(acc.energyMethod)) end
            if acc.capacity ~= nil then print("  Capacity:   " .. tostring(acc.capacity) .. " via " .. tostring(acc.capacityMethod)) end
            if acc.status == "NO ENERGY API" and acc.actualName then
                print("  Methods:    " .. dumpMethods(acc.actualName))
            end
            print("")
        end
    end
end
