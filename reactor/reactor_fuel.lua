local cfg = require("peripheral_config")
local monitorConfig = require("monitor_config")
local control = require("control_common")
local refreshRate = monitorConfig.refreshRate or 1

local THEME = {
    bg = colors.black, text = colors.white, headerBg = colors.purple,
    sectionBg = colors.gray, ok = colors.lime, low = colors.yellow,
    crit = colors.red, standby = colors.lightGray, unknown = colors.orange,
    empty = colors.gray
}

local function isColor(t) return t and t.isColor and t.isColor() end
local function setColors(t, fg, bg) if isColor(t) then t.setTextColor(fg or THEME.text); t.setBackgroundColor(bg or THEME.bg) end end
local function clear(t) setColors(t, THEME.text, THEME.bg); t.clear(); t.setCursorPos(1, 1) end
local function line(t, y, text, fg, bg)
    local w, h = t.getSize(); if y < 1 or y > h then return end
    setColors(t, fg, bg); t.setCursorPos(1, y); t.clearLine(); t.write(tostring(text or ""):sub(1, w)); setColors(t, THEME.text, THEME.bg)
end
local function at(t, x, y, text, fg, bg)
    local w, h = t.getSize(); if y < 1 or y > h or x > w then return end
    setColors(t, fg, bg); t.setCursorPos(x, y); t.write(tostring(text or ""):sub(1, w - x + 1)); setColors(t, THEME.text, THEME.bg)
end
local function statusColor(s)
    if s == "OK" or s == "ON" then return THEME.ok end
    if s == "LOW" or s == "PARTIAL" then return THEME.low end
    if s == "CRIT" or s == "MISSING" or s == "READ ERR" or s == "BAD TYPE" then return THEME.crit end
    if s == "OFF" or s == "STANDBY" then return THEME.standby end
    return THEME.unknown
end
local function bar(t, x, y, width, pct, status)
    if width < 4 then return end
    pct = math.max(0, math.min(100, pct or 0)); local fill = math.floor(width * pct / 100 + 0.5)
    if isColor(t) then
        at(t, x, y, string.rep(" ", width), THEME.text, THEME.empty)
        if fill > 0 then at(t, x, y, string.rep(" ", fill), THEME.text, statusColor(status)) end
    else
        at(t, x, y, "[" .. string.rep("#", math.max(0, fill - 2)) .. string.rep("-", math.max(0, width - fill - 2)) .. "]")
    end
end
local function isFuel(name)
    local items = cfg.fuelItems or {}; if next(items) == nil then return true end
    if items[name] == true then return true end
    for _, value in pairs(items) do if value == name then return true end end
    return false
end
local function readVault(name)
    local vault = peripheral.wrap(name)
    if not vault then return { online = false, fuel = 0, status = "MISSING" } end
    if type(vault.list) ~= "function" then return { online = false, fuel = 0, status = "BAD TYPE" } end
    local ok, items = pcall(vault.list); if not ok then return { online = false, fuel = 0, status = "READ ERR" } end
    local total = 0
    for _, item in pairs(items or {}) do if item and item.name and isFuel(item.name) then total = total + (item.count or 0) end end
    return { online = true, fuel = total, status = "OK" }
end
local function fuelStatus(pct, feed, online)
    if not online then return "MISSING" end
    if not feed.active then return "STANDBY" end
    if pct <= (cfg.criticalFuelPercent or 10) then return "CRIT" end
    if pct <= (cfg.lowFuelPercent or 25) then return "LOW" end
    return "OK"
end

local function render(t)
    clear(t)
    local y = 1; local totalFuel, totalTarget, active = 0, 0, 0
    line(t, y, " CREATE NEW AGE REACTOR FUEL ", THEME.text, THEME.headerBg); y = y + 2

    for _, reactor in ipairs(cfg.reactors or {}) do
        local feed = control.getFuelFeedState(reactor)
        local data = readVault(reactor.fuelVault)
        local expected = reactor.expectedFuel or cfg.expectedFuelPerVault or 1024
        local pct = expected > 0 and data.fuel / expected * 100 or 0
        local status = fuelStatus(pct, feed, data.online)

        line(t, y, string.format(" %s  Feed:%s  Rods:%d/%d", reactor.label, feed.state, feed.enabledCount, feed.total), statusColor(feed.state), THEME.sectionBg); y = y + 1
        line(t, y, " Fuel Items: " .. data.fuel .. " / " .. expected)
        bar(t, 28, y, 18, pct, status)
        at(t, math.max(1, select(1, t.getSize()) - 8), y, string.format("%5.1f%%", pct), statusColor(status)); y = y + 2

        if feed.active and data.online then active = active + 1; totalFuel = totalFuel + data.fuel; totalTarget = totalTarget + expected end
    end

    local totalPct = totalTarget > 0 and totalFuel / totalTarget * 100 or 0
    local totalStatus = totalPct <= (cfg.criticalFuelPercent or 10) and "CRIT" or totalPct <= (cfg.lowFuelPercent or 25) and "LOW" or "OK"
    line(t, y, " ACTIVE FUEL TOTALS ", THEME.text, THEME.sectionBg); y = y + 1
    line(t, y, " Active Reactors: " .. active .. "   Fuel: " .. totalFuel .. " / " .. totalTarget); y = y + 1
    line(t, y, string.format(" Fill: %.1f%%  %s", totalPct, totalStatus), statusColor(totalStatus))
end

local function getMonitor()
    local out = monitorConfig.outputs and monitorConfig.outputs.reactor_fuel
    if not out or out.enabled == false then return nil end
    local m = peripheral.wrap(out.monitor); if m and m.setTextScale then m.setTextScale(out.textScale or 0.5) end
    return m
end

while true do
    local ok, err = pcall(function() render(term); local m = getMonitor(); if m then render(m) end end)
    if not ok then clear(term); print("reactor_fuel.lua error:"); print(err) end
    sleep(refreshRate)
end
