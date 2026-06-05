local config = require("peripheral_config")

local reactor = config.reactors[1]

local function probe(label, configuredName)
    local lines = {}

    table.insert(lines, label)
    table.insert(lines, "Configured: " .. tostring(configuredName))

    local wrapped = peripheral.wrap(configuredName)

    if not wrapped then
        table.insert(lines, "Result: MISSING")
        table.insert(lines, "")
        return lines
    end

    table.insert(lines, "Type: " .. tostring(peripheral.getType(configuredName)))

    if type(wrapped.getStress) ~= "function" then
        table.insert(lines, "getStress: MISSING METHOD")
    else
        local ok, value = pcall(wrapped.getStress)

        if ok then
            table.insert(lines, "getStress: " .. tostring(value))
        else
            table.insert(lines, "getStress ERROR: " .. tostring(value))
        end
    end

    if type(wrapped.getStressCapacity) ~= "function" then
        table.insert(lines, "getStressCapacity: MISSING METHOD")
    else
        local ok, value = pcall(wrapped.getStressCapacity)

        if ok then
            table.insert(lines, "getStressCapacity: " .. tostring(value))
        else
            table.insert(lines, "getStressCapacity ERROR: " .. tostring(value))
        end
    end

    table.insert(lines, "")

    return lines
end

local output = {}

for _, line in ipairs(probe("PRIMARY STRESSOMETER", reactor.primaryStressometer)) do
    table.insert(output, line)
end

for _, line in ipairs(probe("BACKUP STRESSOMETER", reactor.backupStressometer)) do
    table.insert(output, line)
end

local file = fs.open("stress_probe.txt", "w")
file.write(table.concat(output, "\n"))
file.close()

print("Saved results to stress_probe.txt")
print("Run: edit stress_probe.txt")
