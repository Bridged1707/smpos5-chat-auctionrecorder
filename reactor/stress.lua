local cfg = require("peripheral_config")
local monitorConfig = require("monitor_config")
local control = require("control_common")
local resolver = require("peripheral_resolver")

local refreshRate = monitorConfig.refreshRate or 1
local warningPercent = monitorConfig.warningPercent or 85
local criticalPercent = monitorConfig.criticalPercent or 95

local THEME = {
    bg = colors.black,
    text = colors.white,
    headerBg = colors.blue,
    sectionBg = colors.gray,
    ok = colors.lime,
    warn = colors.yellow,
    crit = colors.orange,
    over = colors.red,
    standby = colors.lightGray,
    unknown = colors.orange,
    empty = colors.gray
}

local function isColor(target)
    return target and target.isColor and target.isColor()
end

local function setColors(target, foreground, background)
    if isColor(target) then
        target.setTextColor(foreground or THEME.text)
        target.setBackgroundColor(background or THEME.bg)
    end
end

local function clear(target)
    setColors(target, THEME.text, THEME.bg)
    target.clear()
    target.setCursorPos(1, 1)
end

local function writeLine(target, y, text, foreground, background)
    local width, height = target.getSize()
    if y < 1 or y > height then
        return
    end

    setColors(target, foreground, background)
    target.setCursorPos(1, y)
    target.clearLine()
    target.write(tostring(text or ""):sub(1, width))
    setColors(target, THEME.text, THEME.bg)
end

local function writeAt(target, x, y, text, foreground, background)
    local width, height = target.getSize()
    if y < 1 or y > height or x > width then
        return
    end

    setColors(target, foreground, background)
    target.setCursorPos(x, y)
    target.write(tostring(text or ""):sub(1, width - x + 1))
    setColors(target, THEME.text, THEME.bg)
end

local function percentOf(used, capacity)
    if not capacity or capacity <= 0 then
        return 0
    end

    return used / capacity * 100
end

local function statusColor(status)
    if status == "OK" or status == "ON" then
        return THEME.ok
    elseif status == "WARN" then
        return THEME.warn
    elseif status == "CRIT" then
        return THEME.crit
    elseif status == "OVER" then
        return THEME.over
    elseif status == "OFF" or status == "STANDBY" or status == "DISABLED" then
        return THEME.standby
    end

    return THEME.unknown
end

local function compactNumber(value)
    value = tonumber(value) or 0
    local absolute = math.abs(value)

    if absolute >= 1000000000 then
        return string.format("%.1fB", value / 1000000000)
    elseif absolute >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif absolute >= 1000 then
        return string.format("%.1fk", value / 1000)
    end

    return tostring(math.floor(value + 0.5))
end

local function drawBar(target, x, y, width, percent, status)
    if width < 4 then
        return
    end

    percent = math.max(0, math.min(100, percent or 0))
    local filled = math.floor(width * percent / 100 + 0.5)

    if isColor(target) then
        writeAt(target, x, y, string.rep(" ", width), THEME.text, THEME.empty)
        if filled > 0 then
            writeAt(target, x, y, string.rep(" ", filled), THEME.text, statusColor(status))
        end
    else
        local innerWidth = math.max(1, width - 2)
        local innerFilled = math.floor(innerWidth * percent / 100 + 0.5)
        writeAt(
            target,
            x,
            y,
            "[" .. string.rep("#", innerFilled) .. string.rep("-", innerWidth - innerFilled) .. "]"
        )
    end
end

local function readStressometer(name)
    if type(name) ~= "string" or name == "" or name:find("CHANGE_ME", 1, true) then
        return {
            online = false,
            used = nil,
            capacity = nil,
            percent = 0,
            status = "UNCONFIGURED"
        }
    end

    local meter, actualName, resolveStatus = resolver.wrap(name, { "getStress", "getStressCapacity" })
    if not meter then
        return {
            online = false,
            used = nil,
            capacity = nil,
            percent = 0,
            status = resolveStatus or "MISSING",
            configuredName = name,
            actualName = actualName
        }
    end

    local okUsed, used = pcall(meter.getStress)
    local okCapacity, capacity = pcall(meter.getStressCapacity)

    if not okUsed or not okCapacity then
        return {
            online = false,
            used = nil,
            capacity = nil,
            percent = 0,
            status = "READ ERR"
        }
    end

    used = tonumber(used) or 0
    capacity = tonumber(capacity) or 0

    local loadPercent = percentOf(used, capacity)
    local status = "OK"

    if used > capacity then
        status = "OVER"
    elseif loadPercent >= criticalPercent then
        status = "CRIT"
    elseif loadPercent >= warningPercent then
        status = "WARN"
    end

    return {
        online = true,
        used = used,
        capacity = capacity,
        percent = loadPercent,
        status = status,
        configuredName = name,
        actualName = actualName
    }
end

local function formatStress(meter)
    if not meter.online then
        return meter.status
    end

    return compactNumber(meter.used) .. "/" .. compactNumber(meter.capacity) .. " SU"
end

local function formatSpeed(speedometer)
    if not speedometer.online then
        return speedometer.status
    end

    return string.format("%.1f RPM", math.abs(speedometer.rpm or 0))
end

local function renderNetwork(target, y, label, clutchState, meter, speedometer)
    local width = target.getSize()
    local active = clutchState == "ON"
    local meterStatus = active and meter.status or "STANDBY"
    local speedStatus = active and speedometer.status or "STANDBY"

    writeLine(
        target,
        y,
        string.format(" %s Network  |  Clutch: %s", label, clutchState),
        statusColor(clutchState),
        THEME.bg
    )
    y = y + 1

    if meter.online then
        local stressText = " Stress: " .. formatStress(meter)
        local percentText = string.format("%.1f%%", meter.percent)
        writeLine(target, y, stressText, statusColor(meterStatus), THEME.bg)

        local barStart = math.min(#stressText + 3, math.max(1, width - 18))
        local barWidth = math.max(4, width - barStart - 8)
        drawBar(target, barStart, y, barWidth, meter.percent, meterStatus)
        writeAt(target, math.max(1, width - #percentText + 1), y, percentText, statusColor(meterStatus), THEME.bg)
    else
        writeLine(target, y, " Stress: " .. meter.status, statusColor(meter.status), THEME.bg)
    end
    y = y + 1

    writeLine(
        target,
        y,
        " Speed:  " .. formatSpeed(speedometer),
        statusColor(speedStatus),
        THEME.bg
    )

    return active and meter.online, y
end

local function render(target)
    clear(target)

    local y = 1
    writeLine(target, y, " CREATE / NEW AGE ROTATION DASHBOARD ", THEME.text, THEME.headerBg)
    y = y + 2

    local totalUsed = 0
    local totalCapacity = 0
    local activeNetworks = 0
    local enabledReactors = 0

    for _, reactor in ipairs(cfg.reactors or {}) do
        if reactor.enabled ~= false then
            enabledReactors = enabledReactors + 1

            local _, primaryState = control.getClutchState(reactor, "primary")
            local _, backupState = control.getClutchState(reactor, "backup")
            local _, coilState = control.getGeneratorClutchState(reactor)
            local primaryMeter = readStressometer(reactor.primaryStressometer)
            local backupMeter = readStressometer(reactor.backupStressometer)
            local primarySpeed = control.readSpeedometer(reactor.primarySpeedometer)
            local backupSpeed = control.readSpeedometer(reactor.backupSpeedometer)

            writeLine(target, y, " " .. reactor.label, THEME.text, THEME.sectionBg)
            y = y + 1

            local primaryCounts
            primaryCounts, y = renderNetwork(target, y, "Primary", primaryState, primaryMeter, primarySpeed)
            if primaryCounts then
                activeNetworks = activeNetworks + 1
                totalUsed = totalUsed + primaryMeter.used
                totalCapacity = totalCapacity + primaryMeter.capacity
            end
            y = y + 2

            local backupCounts
            backupCounts, y = renderNetwork(target, y, "Backup", backupState, backupMeter, backupSpeed)
            if backupCounts then
                activeNetworks = activeNetworks + 1
                totalUsed = totalUsed + backupMeter.used
                totalCapacity = totalCapacity + backupMeter.capacity
            end
            y = y + 2

            writeLine(target, y, " Generator Coil Clutch: " .. tostring(coilState), statusColor(coilState), THEME.bg)
            y = y + 2
        end
    end

    if enabledReactors == 0 then
        writeLine(target, y, " No reactors are enabled in peripheral_config.lua", THEME.warn, THEME.bg)
        return
    end

    local totalPercent = percentOf(totalUsed, totalCapacity)
    local totalStatus = "OK"

    if totalPercent >= criticalPercent then
        totalStatus = "CRIT"
    elseif totalPercent >= warningPercent then
        totalStatus = "WARN"
    end

    writeLine(target, y, " ACTIVE NETWORK TOTALS ", THEME.text, THEME.sectionBg)
    y = y + 1
    writeLine(target, y, " Active Networks: " .. activeNetworks, THEME.text, THEME.bg)
    y = y + 1
    writeLine(
        target,
        y,
        " Stress: " .. compactNumber(totalUsed) .. "/" .. compactNumber(totalCapacity) .. " SU",
        statusColor(totalStatus),
        THEME.bg
    )
    y = y + 1
    writeLine(target, y, string.format(" Load: %.1f%%  %s", totalPercent, totalStatus), statusColor(totalStatus), THEME.bg)
end

local function getMonitor()
    local output = monitorConfig.outputs and monitorConfig.outputs.stress_full
    if not output or output.enabled == false then
        return nil
    end

    local monitor = peripheral.wrap(output.monitor)
    if monitor and monitor.setTextScale then
        monitor.setTextScale(output.textScale or 0.5)
    end

    return monitor
end

while true do
    local ok, err = pcall(function()
        render(term)

        local monitor = getMonitor()
        if monitor then
            render(monitor)
        end
    end)

    if not ok then
        clear(term)
        print("stress.lua error:")
        print(err)
    end

    sleep(refreshRate)
end
