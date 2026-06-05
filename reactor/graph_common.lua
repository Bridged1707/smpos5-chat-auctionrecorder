local M = {}

local DEFAULT_COLORS = {
    colors.lime,
    colors.yellow,
    colors.cyan,
    colors.pink,
    colors.orange,
    colors.lightBlue,
    colors.red,
    colors.green,
    colors.purple,
    colors.white
}

local DEFAULT_SYMBOLS = { "*", "+", "x", "o", "#", "%", "@", "=" }

local function isColor(target)
    return target and target.isColor and target.isColor()
end

local function setColors(target, fg, bg)
    if isColor(target) then
        target.setTextColor(fg or colors.white)
        target.setBackgroundColor(bg or colors.black)
    end
end

local function writeAt(target, x, y, text, fg, bg)
    local width, height = target.getSize()
    if x < 1 or y < 1 or x > width or y > height then return end

    setColors(target, fg, bg)
    target.setCursorPos(x, y)
    target.write(tostring(text or ""):sub(1, width - x + 1))
    setColors(target, colors.white, colors.black)
end

local function clear(target)
    setColors(target, colors.white, colors.black)
    target.clear()
    target.setCursorPos(1, 1)
end

local function ensureParent(path)
    local directory = fs.getDir(path)
    if directory ~= "" and not fs.exists(directory) then
        fs.makeDir(directory)
    end
end

function M.loadHistory(path)
    if not fs.exists(path) then return {} end

    local handle = fs.open(path, "r")
    if not handle then return {} end

    local content = handle.readAll()
    handle.close()

    local ok, data = pcall(textutils.unserialize, content)
    if not ok or type(data) ~= "table" then return {} end

    return data
end

function M.saveHistory(path, history)
    ensureParent(path)

    local handle = fs.open(path .. ".tmp", "w")
    if not handle then return false end

    handle.write(textutils.serialize(history))
    handle.close()

    if fs.exists(path) then fs.delete(path) end
    fs.move(path .. ".tmp", path)
    return true
end

function M.appendHistory(history, point, maxPoints)
    table.insert(history, point)

    maxPoints = math.max(2, tonumber(maxPoints) or 120)
    while #history > maxPoints do
        table.remove(history, 1)
    end
end

function M.seriesColor(index)
    return DEFAULT_COLORS[((index - 1) % #DEFAULT_COLORS) + 1]
end

function M.seriesSymbol(index)
    return DEFAULT_SYMBOLS[((index - 1) % #DEFAULT_SYMBOLS) + 1]
end

function M.formatNumber(value)
    value = tonumber(value) or 0
    local absValue = math.abs(value)

    if absValue >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif absValue >= 1000 then
        return string.format("%.1fk", value / 1000)
    elseif math.floor(value) == value then
        return tostring(math.floor(value))
    end

    return string.format("%.1f", value)
end

local function valueAt(point, key)
    if not point or type(point.values) ~= "table" then return nil end
    return tonumber(point.values[key])
end

local function drawLine(target, x1, y1, x2, y2, symbol, color)
    local dx = x2 - x1
    local steps = math.max(1, math.abs(dx))

    for step = 0, steps do
        local ratio = step / steps
        local x = math.floor(x1 + dx * ratio + 0.5)
        local y = math.floor(y1 + (y2 - y1) * ratio + 0.5)
        writeAt(target, x, y, symbol, color, colors.black)
    end
end

function M.renderGraph(target, options)
    options = options or {}
    local width, height = target.getSize()
    clear(target)

    local series = options.series or {}
    local history = options.history or {}
    local title = options.title or "HISTORY GRAPH"
    local subtitle = options.subtitle or ""
    local suffix = options.valueSuffix or ""

    writeAt(target, 1, 1, (" " .. title .. " "):sub(1, width), colors.white, options.headerColor or colors.blue)
    if subtitle ~= "" then
        writeAt(target, 1, 2, subtitle:sub(1, width), colors.lightGray, colors.black)
    end

    local legendColumns = width >= 60 and 2 or 1
    local legendRows = math.ceil(#series / legendColumns)
    local legendStart = 3
    local legendWidth = math.floor(width / legendColumns)
    local latest = history[#history]

    for index, entry in ipairs(series) do
        local column = (index - 1) % legendColumns
        local row = math.floor((index - 1) / legendColumns)
        local x = column * legendWidth + 1
        local y = legendStart + row
        local color = entry.color or M.seriesColor(index)
        local symbol = entry.symbol or M.seriesSymbol(index)
        local current = valueAt(latest, entry.key)
        local valueText = current and (M.formatNumber(current) .. suffix) or "--"
        local label = symbol .. " " .. tostring(entry.label or entry.key) .. ": " .. valueText
        writeAt(target, x, y, label:sub(1, legendWidth - 1), color, colors.black)
    end

    local chartTop = legendStart + legendRows + 1
    local chartBottom = height - 2
    local chartLeft = 8
    local chartRight = width
    local chartWidth = chartRight - chartLeft + 1
    local chartHeight = chartBottom - chartTop + 1

    if chartWidth < 8 or chartHeight < 5 then
        writeAt(target, 1, math.min(height, chartTop), "Monitor is too small for graph output.", colors.red, colors.black)
        return
    end

    local yMin = tonumber(options.yMin) or 0
    local yMax = tonumber(options.yMax) or yMin + 1

    for _, point in ipairs(history) do
        for _, entry in ipairs(series) do
            local value = valueAt(point, entry.key)
            if value and value > yMax then yMax = value end
            if value and value < yMin then yMin = value end
        end
    end

    if yMax <= yMin then yMax = yMin + 1 end

    local function mapY(value)
        local normalized = (value - yMin) / (yMax - yMin)
        normalized = math.max(0, math.min(1, normalized))
        return chartBottom - math.floor(normalized * (chartHeight - 1) + 0.5)
    end

    local mid = (yMin + yMax) / 2
    writeAt(target, 1, chartTop, string.format("%6s", M.formatNumber(yMax)), colors.lightGray, colors.black)
    writeAt(target, 1, math.floor((chartTop + chartBottom) / 2), string.format("%6s", M.formatNumber(mid)), colors.lightGray, colors.black)
    writeAt(target, 1, chartBottom, string.format("%6s", M.formatNumber(yMin)), colors.lightGray, colors.black)

    for y = chartTop, chartBottom do
        writeAt(target, chartLeft - 1, y, "|", colors.gray, colors.black)
    end
    for x = chartLeft, chartRight do
        writeAt(target, x, chartBottom, "-", colors.gray, colors.black)
    end

    local startIndex = math.max(1, #history - chartWidth + 1)
    local visibleCount = #history - startIndex + 1

    if visibleCount <= 0 then
        writeAt(target, chartLeft + 1, chartTop + 1, "Collecting first sample...", colors.lightGray, colors.black)
    else
        for seriesIndex, entry in ipairs(series) do
            local previousX, previousY = nil, nil
            local color = entry.color or M.seriesColor(seriesIndex)
            local symbol = entry.symbol or M.seriesSymbol(seriesIndex)

            for historyIndex = startIndex, #history do
                local point = history[historyIndex]
                local value = valueAt(point, entry.key)

                if value then
                    local x = chartLeft + (historyIndex - startIndex)
                    local y = mapY(value)

                    if previousX and previousY then
                        drawLine(target, previousX, previousY, x, y, symbol, color)
                    else
                        writeAt(target, x, y, symbol, color, colors.black)
                    end

                    previousX, previousY = x, y
                else
                    previousX, previousY = nil, nil
                end
            end
        end
    end

    local oldest = history[startIndex]
    local newest = history[#history]
    local oldestText = oldest and oldest.timeLabel or "--"
    local newestText = newest and newest.timeLabel or "--"
    writeAt(target, chartLeft, height, tostring(oldestText), colors.lightGray, colors.black)
    writeAt(target, math.max(chartLeft, width - #tostring(newestText) + 1), height, tostring(newestText), colors.lightGray, colors.black)
end

return M
