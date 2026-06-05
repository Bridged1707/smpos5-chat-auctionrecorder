local cfg = require("peripheral_config")
local monitorConfig = require("monitor_config")
local control = require("control_common")

local refreshRate = monitorConfig.refreshRate or 1

local THEME = {
    bg = colors.black,
    text = colors.white,
    headerBg = colors.brown,
    sectionBg = colors.gray,
    ok = colors.lime,
    warn = colors.yellow,
    crit = colors.red,
    standby = colors.lightGray,
    unknown = colors.orange,
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
local function compact(value)
    value = tonumber(value) or 0
    local a = math.abs(value)
    if a >= 1000000000 then return string.format("%.1fB", value / 1000000000) end
    if a >= 1000000 then return string.format("%.1fM", value / 1000000) end
    if a >= 1000 then return string.format("%.1fk", value / 1000) end
    return tostring(math.floor(value + 0.5))
end
local function statusColor(s)
    if s == "OK" or s == "ON" then return THEME.ok end
    if s == "LOW" or s == "WARN" or s == "PARTIAL" then return THEME.warn end
    if s == "CRIT" or s == "MISSING" or s == "READ ERR" or s == "BAD TYPE" then return THEME.crit end
    if s == "OFF" or s == "STANDBY" or s == "DISABLED" or s == "UNCONFIGURED" then return THEME.standby end
    return THEME.unknown
end
local function bar(t, x, y, width, pct, status)
    if width < 4 then return end
    pct = math.max(0, math.min(100, pct or 0))
    local fill = math.floor(width * pct / 100 + 0.5)
    if isColor(t) then
        at(t, x, y, string.rep(" ", width), THEME.text, THEME.empty)
        if fill > 0 then at(t, x, y, string.rep(" ", fill), THEME.text, statusColor(status)) end
    else
        local inner = math.max(1, width - 2)
        local innerFill = math.floor(inner * pct / 100 + 0.5)
        at(t, x, y, "[" .. string.rep("#", innerFill) .. string.rep("-", inner - innerFill) .. "]")
    end
end

local function render(t)
    clear(t)
    local y = 1
    local totalEnergy, totalCapacity, activeCoils = 0, 0, 0

    line(t, y, " GENERATOR COIL ACCUMULATORS ", THEME.text, THEME.headerBg); y = y + 2

    for _, reactor in ipairs(cfg.reactors or {}) do
        if reactor.enabled ~= false then
            local coilOn, coilState = control.getGeneratorClutchState(reactor)
            local bank = control.readAccumulatorBank(reactor)
            local state = coilState or "UNKNOWN"

            if coilOn == true then activeCoils = activeCoils + 1 end
            if bank.capacity > 0 then
                totalEnergy = totalEnergy + bank.energy
                totalCapacity = totalCapacity + bank.capacity
            end

            line(t, y, string.format(" %s  Coil:%s", reactor.label, state), statusColor(state), THEME.sectionBg); y = y + 1
            line(t, y, string.format(" Accumulators: %d/%d online  %d readable", bank.online, bank.total, bank.readable), THEME.text, THEME.bg); y = y + 1

            if bank.capacity > 0 then
                local status = bank.percent <= 10 and "CRIT" or bank.percent <= 25 and "LOW" or "OK"
                local w = t.getSize()
                line(t, y, " Energy: " .. compact(bank.energy) .. " / " .. compact(bank.capacity), statusColor(status), THEME.bg)
                bar(t, 28, y, math.max(8, w - 40), bank.percent, status)
                at(t, math.max(1, w - 8), y, string.format("%5.1f%%", bank.percent), statusColor(status)); y = y + 1
            elseif bank.noEnergyApi > 0 then
                line(t, y, " Energy API: not exposed on visible accumulators", THEME.warn, THEME.bg); y = y + 1
            else
                line(t, y, " Energy: no readable accumulator data", THEME.warn, THEME.bg); y = y + 1
            end

            y = y + 1
        end
    end

    local pct = totalCapacity > 0 and totalEnergy / totalCapacity * 100 or 0
    line(t, y, " ACTIVE COIL TOTALS ", THEME.text, THEME.sectionBg); y = y + 1
    line(t, y, " Active Coils: " .. activeCoils, THEME.text, THEME.bg); y = y + 1
    if totalCapacity > 0 then
        line(t, y, string.format(" Stored: %s / %s  %.1f%%", compact(totalEnergy), compact(totalCapacity), pct), statusColor("OK"), THEME.bg)
    else
        line(t, y, " Stored: no readable energy data", THEME.warn, THEME.bg)
    end
end

local function getMonitor()
    local out = monitorConfig.outputs and monitorConfig.outputs.accumulators
    if not out or out.enabled == false then return nil end
    local m = peripheral.wrap(out.monitor)
    if m and m.setTextScale then m.setTextScale(out.textScale or 0.5) end
    return m
end

while true do
    local ok, err = pcall(function()
        render(term)
        local m = getMonitor()
        if m then render(m) end
    end)

    if not ok then clear(term); print("accumulators.lua error:"); print(err) end
    sleep(refreshRate)
end
