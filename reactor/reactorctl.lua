local cfg = require("peripheral_config")
local control = require("control_common")

local args = { ... }

local function usage()
    print("Reactor control commands:")
    print("  reactorctl status [reactor|all]")
    print("  reactorctl fuel <reactor|all> <on|off>")
    print("  reactorctl chute <reactor|all> <1|2|3|all> <on|off>")
    print("  reactorctl clutch <reactor|all> <primary|backup|generator|all> <on|off>")
    print("  reactorctl coil <reactor|all> <on|off>")
    print("  reactorctl safeoff <reactor|all>")
    print("")
    print("Examples:")
    print("  reactorctl fuel 1 off")
    print("  reactorctl chute 2 3 on")
    print("  reactorctl clutch all backup off")
    print("  reactorctl coil 1 off")
end

local function parseOnOff(value)
    value = tostring(value or ""):lower()
    if value == "on" or value == "enable" or value == "enabled" then return true end
    if value == "off" or value == "disable" or value == "disabled" then return false end
    return nil
end

local function selected(selector)
    local reactors = control.selectedReactors(cfg, selector)
    if #reactors == 0 then error("Unknown reactor selector: " .. tostring(selector)) end
    return reactors
end

local function writeResult(prefix, ok, state)
    if ok then print(prefix .. " -> " .. state) else print(prefix .. " -> FAILED: " .. tostring(state)) end
end

local function setFuel(reactor, enabled, chuteSelector)
    local matched = 0
    for index, chute in ipairs(reactor.fuelChutes or {}) do
        if chuteSelector == "all" or tonumber(chuteSelector) == index then
            matched = matched + 1
            local ok, state = control.setRelayState(chute.relay, enabled)
            writeResult(reactor.label .. " " .. (chute.label or ("Rod " .. index)), ok, state)
        end
    end
    if matched == 0 then print(reactor.label .. " -> no matching chute") end
end

local function setClutch(reactor, enabled, network)
    local clutch = reactor.clutches and reactor.clutches[network]
    if not clutch then
        print(reactor.label .. " " .. network .. " -> no clutch configured")
        return
    end
    local ok, state = control.setRelayState(clutch.relay, enabled)
    writeResult(reactor.label .. " " .. (clutch.label or network), ok, state)
end

local function setGeneratorCoil(reactor, enabled)
    local ok, state = control.setGeneratorClutchState(reactor, enabled)
    writeResult(reactor.label .. " Generator Coil Clutch", ok, state)
end

local function status(reactors)
    for _, reactor in ipairs(reactors) do
        local feed = control.getFuelFeedState(reactor)
        local primaryOn, primaryState = control.getClutchState(reactor, "primary")
        local backupOn, backupState = control.getClutchState(reactor, "backup")
        local coilOn, coilState = control.getGeneratorClutchState(reactor)
        local bank = control.readAccumulatorBank(reactor)
        print(reactor.label)
        print("  Fuel feed: " .. feed.state .. " (" .. feed.enabledCount .. "/" .. feed.total .. " rods on)")
        for _, chute in ipairs(feed.details) do
            print("    " .. chute.label .. ": " .. chute.state)
        end
        print("  Primary clutch: " .. tostring(primaryState))
        print("  Backup clutch:  " .. tostring(backupState))
        print("  Generator coil: " .. tostring(coilState))
        print("  Accumulators:   " .. bank.online .. "/" .. bank.total .. " online, " .. bank.readable .. " readable")
        if bank.capacity > 0 then print("  Energy:         " .. math.floor(bank.energy) .. " / " .. math.floor(bank.capacity) .. " (" .. string.format("%.1f", bank.percent) .. "%)") end
        print("")
    end
end

local command = tostring(args[1] or "status"):lower()

if command == "help" or command == "--help" or command == "-h" then
    usage()
elseif command == "status" then
    status(selected(args[2] or "all"))
elseif command == "fuel" then
    local enabled = parseOnOff(args[3])
    if enabled == nil then usage(); return end
    for _, reactor in ipairs(selected(args[2])) do setFuel(reactor, enabled, "all") end
elseif command == "chute" then
    local enabled = parseOnOff(args[4])
    if enabled == nil then usage(); return end
    local chuteSelector = tostring(args[3] or "all"):lower()
    for _, reactor in ipairs(selected(args[2])) do setFuel(reactor, enabled, chuteSelector) end
elseif command == "clutch" then
    local enabled = parseOnOff(args[4])
    if enabled == nil then usage(); return end
    local network = tostring(args[3] or "all"):lower()
    for _, reactor in ipairs(selected(args[2])) do
        if network == "all" then
            setClutch(reactor, enabled, "primary")
            setClutch(reactor, enabled, "backup")
            setGeneratorCoil(reactor, enabled)
        elseif network == "primary" or network == "backup" then
            setClutch(reactor, enabled, network)
        elseif network == "generator" or network == "coil" then
            setGeneratorCoil(reactor, enabled)
        else
            error("Unknown clutch selector: " .. network)
        end
    end
elseif command == "coil" then
    local enabled = parseOnOff(args[3])
    if enabled == nil then usage(); return end
    for _, reactor in ipairs(selected(args[2])) do setGeneratorCoil(reactor, enabled) end
elseif command == "safeoff" then
    for _, reactor in ipairs(selected(args[2])) do
        setFuel(reactor, false, "all")
        setClutch(reactor, false, "primary")
        setClutch(reactor, false, "backup")
        setGeneratorCoil(reactor, false)
    end
else
    usage()
end
