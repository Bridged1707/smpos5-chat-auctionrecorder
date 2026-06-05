local cfg = require("peripheral_config")
local monitorConfig = require("monitor_config")
local graph = require("graph_common")
local control = require("control_common")

local output = (monitorConfig.outputs and monitorConfig.outputs.speed_graph) or {}
local sampleSeconds = output.sampleSeconds or (monitorConfig.graphDefaults and monitorConfig.graphDefaults.sampleSeconds) or 30
local historyPoints = output.historyPoints or (monitorConfig.graphDefaults and monitorConfig.graphDefaults.historyPoints) or 120
local historyPath = ".reactor_data/speed_history"
local history = graph.loadHistory(historyPath)
local lastSample = 0
local maxRpm = 1

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
    local values, currentMax = {}, 1
    for _, reactor in ipairs(cfg.reactors or {}) do
        local primary = control.readSpeedometer(reactor.primarySpeedometer)
        local backup = control.readSpeedometer(reactor.backupSpeedometer)
        values[primaryKey(reactor)] = primary.online and math.abs(primary.rpm) or nil
        values[backupKey(reactor)] = backup.online and math.abs(backup.rpm) or nil
        currentMax = math.max(currentMax, math.abs(primary.rpm or 0), math.abs(backup.rpm or 0))
    end
    maxRpm = math.max(maxRpm, currentMax)
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
        title = "ROTATIONAL SPEED HISTORY",
        subtitle = "Primary and backup RPM | sample " .. sampleSeconds .. "s | points " .. historyPoints,
        headerColor = colors.cyan, series = buildSeries(), history = history, yMin = 0, yMax = maxRpm, valueSuffix = " RPM"
    })
end

while true do
    local ok, err = pcall(function()
        local now = os.epoch("utc")
        if lastSample == 0 or now - lastSample >= sampleSeconds * 1000 then collectSample() end
        render(term); local monitor = getMonitor(); if monitor then render(monitor) end
    end)
    if not ok then term.clear(); term.setCursorPos(1, 1); print("speed_graph.lua error:"); print(err) end
    sleep(1)
end
