local cfg = require("peripheral_config")
local monitorConfig = require("monitor_config")
local graph = require("graph_common")

local output = (monitorConfig.outputs and monitorConfig.outputs.reactor_fuel_graph) or {}
local sampleSeconds = output.sampleSeconds or (monitorConfig.graphDefaults and monitorConfig.graphDefaults.sampleSeconds) or 30
local historyPoints = output.historyPoints or (monitorConfig.graphDefaults and monitorConfig.graphDefaults.historyPoints) or 120
local historyPath = ".reactor_data/reactor_fuel_history"
local history = graph.loadHistory(historyPath)
local lastSample = 0

local function isFuelItem(name)
    local items = cfg.fuelItems or {}
    if next(items) == nil then return true end
    if items[name] == true then return true end
    for _, value in pairs(items) do
        if value == name then return true end
    end
    return false
end

local function readVault(name)
    local vault = peripheral.wrap(name)
    if not vault or type(vault.list) ~= "function" then return nil end

    local ok, items = pcall(vault.list)
    if not ok then return nil end

    local total = 0
    for _, item in pairs(items or {}) do
        if item and item.name and isFuelItem(item.name) then
            total = total + (item.count or 0)
        end
    end

    return total
end

local function buildSeries()
    local series = {}
    for index, reactor in ipairs(cfg.reactors or {}) do
        table.insert(series, {
            key = reactor.id,
            label = reactor.label,
            color = graph.seriesColor(index),
            symbol = graph.seriesSymbol(index)
        })
    end
    return series
end

local function collectSample()
    local values = {}
    for _, reactor in ipairs(cfg.reactors or {}) do
        values[reactor.id] = readVault(reactor.fuelVault)
    end

    local now = os.epoch("utc")
    graph.appendHistory(history, {
        timestamp = now,
        timeLabel = textutils.formatTime(os.time("local"), true),
        values = values
    }, historyPoints)
    graph.saveHistory(historyPath, history)
    lastSample = now
end

local function maxExpectedFuel()
    local maximum = cfg.expectedFuelPerVault or 1024
    for _, reactor in ipairs(cfg.reactors or {}) do
        maximum = math.max(maximum, reactor.expectedFuel or 0)
    end
    return maximum
end

local function getMonitor()
    if output.enabled == false or not output.monitor then return nil end
    local monitor = peripheral.wrap(output.monitor)
    if monitor and monitor.setTextScale then monitor.setTextScale(output.textScale or 0.5) end
    return monitor
end

local function render(target)
    graph.renderGraph(target, {
        title = "REACTOR FUEL HISTORY",
        subtitle = "Each line is one item vault | sample " .. sampleSeconds .. "s | points " .. historyPoints,
        headerColor = colors.purple,
        series = buildSeries(),
        history = history,
        yMin = 0,
        yMax = maxExpectedFuel(),
        valueSuffix = " items"
    })
end

while true do
    local ok, err = pcall(function()
        local now = os.epoch("utc")
        if lastSample == 0 or now - lastSample >= sampleSeconds * 1000 then
            collectSample()
        end

        render(term)
        local monitor = getMonitor()
        if monitor then render(monitor) end
    end)

    if not ok then
        term.clear()
        term.setCursorPos(1, 1)
        print("reactor_fuel_graph.lua error:")
        print(err)
    end

    sleep(1)
end
