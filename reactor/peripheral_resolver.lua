local M = {}

local function isPlaceholder(value)
    return type(value) ~= "string" or value == "" or value:find("CHANGE_ME", 1, true) ~= nil
end

local function normalize(value)
    return tostring(value or ""):lower():gsub("[^%w]", "")
end

local function hasMethods(wrapped, requiredMethods)
    for _, methodName in ipairs(requiredMethods or {}) do
        if type(wrapped[methodName]) ~= "function" then
            return false
        end
    end
    return true
end

function M.normalize(value)
    return normalize(value)
end

function M.resolveName(configuredName, requiredMethods)
    if isPlaceholder(configuredName) then
        return nil, "UNCONFIGURED"
    end

    local exact = peripheral.wrap(configuredName)
    if exact and hasMethods(exact, requiredMethods) then
        return configuredName, "EXACT"
    end

    local wanted = normalize(configuredName)
    local matches = {}

    for _, actualName in ipairs(peripheral.getNames()) do
        if normalize(actualName) == wanted then
            local wrapped = peripheral.wrap(actualName)
            if wrapped and hasMethods(wrapped, requiredMethods) then
                table.insert(matches, actualName)
            end
        end
    end

    if #matches == 1 then
        return matches[1], "NORMALIZED"
    elseif #matches > 1 then
        return nil, "AMBIGUOUS"
    end

    if exact then
        return configuredName, "BAD TYPE"
    end

    return nil, "MISSING"
end

function M.wrap(configuredName, requiredMethods)
    local actualName, status = M.resolveName(configuredName, requiredMethods)
    if not actualName then
        return nil, nil, status
    end

    local wrapped = peripheral.wrap(actualName)
    if not wrapped then
        return nil, nil, "MISSING"
    end

    if not hasMethods(wrapped, requiredMethods) then
        return nil, actualName, "BAD TYPE"
    end

    return wrapped, actualName, status
end

function M.findByMethods(requiredMethods)
    local results = {}

    for _, actualName in ipairs(peripheral.getNames()) do
        local wrapped = peripheral.wrap(actualName)
        if wrapped and hasMethods(wrapped, requiredMethods) then
            table.insert(results, actualName)
        end
    end

    table.sort(results)
    return results
end

return M
