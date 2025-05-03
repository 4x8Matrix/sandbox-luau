--[[
    Pretty Print; I did not write this file, this file was initially sourced from
        Roact: https://github.com/Roblox/rodux/blob/master/src/prettyPrint.lua, and then put through a round of
        GPT to add some flare to the functionality.

    This iteration of PP doesn't include ANSI colors because the Roblox output does not support ANSI.
]]

return [[
local defaultIndent = "    "

local ANSI = {
    reset   = "\27[0m",
    black   = "\27[30m",
    red     = "\27[31m",
    green   = "\27[32m",
    yellow  = "\27[33m",
    blue    = "\27[34m",
    magenta = "\27[35m",
    cyan    = "\27[36m",
    white   = "\27[37m",
}

local function isArray(t)
    local count = 0
    for k in pairs(t) do
        if type(k) ~= "number" then
            return false
        end
        count = count + 1
    end
    return count > 0
end

local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys, function(a, b)
        local ta, tb = type(a), type(b)
        if ta == tb then
            return a < b
        end
        return ta < tb
    end)
    return keys
end

local function colourize(str, colour)
    return str
end

local function formatValue(value, indentLevel, visited)
    indentLevel = indentLevel or 0
    visited = visited or {}

    local t = type(value)
    if t == "string" then
        return colourize(string.format("%q", value), ANSI.green)
    elseif t == "number" then
        return colourize(tostring(value), ANSI.yellow)
    elseif t == "boolean" then
        return colourize(tostring(value), ANSI.magenta)
    elseif t == "nil" then
        return colourize("nil", ANSI.red)
    elseif t == "table" then
        if visited[value] then
            return colourize("<recursive table>", ANSI.red)
        end
        visited[value] = true

        local parts = {}
        local indent = string.rep(defaultIndent, indentLevel)
        local innerIndent = string.rep(defaultIndent, indentLevel + 1)
        local isArr = isArray(value)

        table.insert(parts, colourize("{\n", ANSI.blue))
        if isArr then
            for i = 1, #value do
                table.insert(parts, innerIndent)
                table.insert(parts, formatValue(value[i], indentLevel + 1, visited))
                table.insert(parts, colourize(",\n", ANSI.blue))
            end
        else
            for _, key in ipairs(sortedKeys(value)) do
                local v = value[key]
                table.insert(parts, innerIndent)
                table.insert(parts, colourize(tostring(key), ANSI.cyan))
                table.insert(parts, colourize(" = ", ANSI.blue))
                table.insert(parts, formatValue(v, indentLevel + 1, visited))
                table.insert(parts, colourize(",\n", ANSI.blue))
            end
        end
        table.insert(parts, indent)
        table.insert(parts, colourize("}", ANSI.blue))
        visited[value] = nil
        return table.concat(parts)
    else
        return colourize(tostring(value), ANSI.white)
    end
end

local function prettyPrint(...)
    local outputs = {}
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        table.insert(outputs, formatValue(v, 0, {}))
    end
    return table.concat(outputs, "\t")
end

local oldPrint = print
print = function(...)
    oldPrint(prettyPrint(...))
end
]]
