local user = "Bridged1707"
local repo = "create-pastebinscripts"
local branch = "main"
local folder = "reactor"

local files = {
    "startup.lua",
    "monitor_config.lua",
    "peripheral_config.lua",
    "peripheral_resolver.lua",
    "control_common.lua",
    "reactorctl.lua",
    "graph_common.lua",
    "stress.lua",
    "reactor_fuel.lua",
    "accumulators.lua",
    "reactor_fuel_graph.lua",
    "stress_graph.lua",
    "speed_graph.lua",
    "scan_peripherals.lua",
    "check_vault_items.lua",
    "check_rotation.lua",
    "check_accumulators.lua",
    "probe_stress.lua"
}

local baseUrl = "https://raw.githubusercontent.com/" .. user .. "/" .. repo .. "/" .. branch .. "/" .. folder .. "/"
local cacheBust = tostring(os.epoch("utc"))

local function downloadFile(file)
    local url = baseUrl .. file .. "?v=" .. cacheBust
    print("Downloading " .. file .. "...")
    local response = http.get(url)
    if not response then print("FAILED: " .. url); return false end
    local content = response.readAll(); response.close()
    local tmp = file .. ".tmp"
    local handle = fs.open(tmp, "w"); handle.write(content); handle.close()
    if fs.exists(file) then fs.delete(file) end
    fs.move(tmp, file)
    print("Saved " .. file)
    return true
end

if not http then error("HTTP API is disabled. Enable it in ComputerCraft config.") end
print("Installing reactor monitor and control scripts...")
print("-----------------------------------------------")
local failed = 0
for _, file in ipairs(files) do if not downloadFile(file) then failed = failed + 1 end end
print("-----------------------------------------------")
if failed > 0 then print("Install finished with " .. failed .. " failed downloads.") else print("Install complete. Run: reboot") end
