local cfg = require("peripheral_config")
local monitorConfig = require("monitor_config")
local graph = require("graph_common")
local resolver = require("peripheral_resolver")

local output = (monitorConfig.outputs and monitorConfig.outputs.stress_graph) or {}
local sampleSeconds = output.sampleSeconds or (monitorConfig.graphDefaults and monitorConfig.graphDefaults.sampleSeconds) or 30
local historyPoints = output.historyPoints or (monitorConfig.graphDefaults and monitorConfig.graphDefaults.historyPoints) or 120
local historyPath = ".reactor_data/stress_history"
local history = graph.loadHistory(historyPath)
local lastSample = 0
local lastCapacityMax = 1

local function readMeter(name)
    local meter = peripheral.wrap(name)
    if not meter or type(meter.getStress) ~= "function" or type(meter.getStressCapacity) ~= "function" then return nil, nil end
    local okUsed, used = pcall(meter.getStress); local okCapacity, capacity = pcall(meter.getStressCapacity)
    if not okUsed or not okCapacity then return nil, nil end
    return tonumber(used), tonumber(capacity)
end

local function primaryKey(reactor) return reactor.id .. "_primary" end
local function backupKey(reactor) return reactor.id .. "_backup" end

local function buildSeries()
    local series, index = {}, 1
    for _, reactor in ipairs(cfg.reactors or {}) do
        table.insert(series, { key = primaryKey(reactor), label = reactor.label .. " Primary", color = graph.seriesColor(index), symbol = graph.seriesSymbol(index) }); index = index + 1
        table.insert(series, { key = backupKey(reactor), label = reactor.label .. " Backup", color = graph.seriesColor(index), symbol = graph.seriesSymbol(index) }); index = index + 1
    end
    return series
end

local function collectSample()
    local values, capacityMax = {}, 1
    for _, reactor in ipairs(cfg.reactors or {}) do
        local primaryUsed, primaryCapacity = readMeter(reactor.primaryStressometer)
        local backupUsed, backupCapacity = readMeter(reactor.backupStressometer)
        values[primaryKey(reactor)] = primaryUsed
        values[backupKey(reactor)] = backupUsed
        capacityMax = math.max(capacityMax, primaryCapacity or 0, backupCapacity or 0)
    end
    lastCapacityMax = capacityMax
    local now = os.epoch("utc")
    graph.appendHistory(history, { timestamp = now, timeLabel = textutils.formatTime(os.time("local"), true), values = values }, historyPoints)
    graph.saveHistory(historyPath, history); lastSample = now
end

local function getMonitor()
    if output.enabled == false or not output.monitor then return nil end
    local monitor = peripheral.wrap(output.monitor); if monitor and monitor.setTextScale then monitor.setTextScale(output.textScale or 0.5) end
    return monitor
end

local function render(target)
    graph.renderGraph(target, {
        title = "STRESS UNIT HISTORY",
        subtitle = "Primary and backup used SU | sample " .. sampleSeconds .. "s | points " .. historyPoints,
        headerColor = colors.blue, series = buildSeries(), history = history, yMin = 0, yMax = lastCapacityMax, valueSuffix = " SU"
    })
end

while true do
    local ok, err = pcall(function()
        local now = os.epoch("utc")
        if lastSample == 0 or now - lastSample >= sampleSeconds * 1000 then collectSample() end
        render(term); local monitor = getMonitor(); if monitor then render(monitor) end
    end)
    if not ok then term.clear(); term.setCursorPos(1, 1); print("stress_graph.lua error:"); print(err) end
    sleep(1)
end
