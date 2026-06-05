local cfg = require("peripheral_config")
local resolver = require("peripheral_resolver")

local function printCandidates(label, methods)
    local candidates = resolver.findByMethods(methods)
    print(label .. " visible on this computer:")
    if #candidates == 0 then
        print("  NONE")
    else
        for _, name in ipairs(candidates) do
            print("  " .. name)
        end
    end
    print()
end

local function inspect(label, configuredName, expectedMethods)
    print(label)
    print("  Configured: " .. tostring(configuredName))

    local wrapped, actualName, resolveStatus = resolver.wrap(configuredName, expectedMethods)
    if not wrapped then
        print("  Status: " .. tostring(resolveStatus))
        return
    end

    print("  Resolved:   " .. tostring(actualName))
    print("  Match:      " .. tostring(resolveStatus))
    print("  Type:       " .. tostring(peripheral.getType(actualName)))

    for _, methodName in ipairs(expectedMethods) do
        local ok, value = pcall(wrapped[methodName])
        if ok then
            print("  " .. methodName .. ": " .. tostring(value))
        else
            print("  " .. methodName .. ": ERROR " .. tostring(value))
        end
    end
end

printCandidates("Stressometers", { "getStress", "getStressCapacity" })
printCandidates("Speedometers", { "getSpeed" })

for _, reactor in ipairs(cfg.reactors or {}) do
    if reactor.enabled ~= false then
        print("============================")
        print(reactor.label)
        print("============================")

        inspect("Primary Stressometer", reactor.primaryStressometer, { "getStress", "getStressCapacity" })
        print()
        inspect("Backup Stressometer", reactor.backupStressometer, { "getStress", "getStressCapacity" })
        print()
        inspect("Primary Speedometer", reactor.primarySpeedometer, { "getSpeed" })
        print()
        inspect("Backup Speedometer", reactor.backupSpeedometer, { "getSpeed" })
        print()
    end
end
