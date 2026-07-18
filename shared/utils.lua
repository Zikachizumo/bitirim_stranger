--[[
    shared/utils.lua
    ----------------
    Small, dependency-free helpers used on both client & server.
    Attached to the shared `Bitirim` namespace as `Bitirim.Utils`.
]]

Bitirim = Bitirim or {}

local Utils = {}

--- Debug logger. No-op unless Bitirim.Config.debug is true.
--- @param tag string  short subsystem tag, e.g. 'identity'
function Utils.log(tag, ...)
    if not (Bitirim.Config and Bitirim.Config.debug) then return end
    print(('[bitirim:%s]'):format(tag or '?'), ...)
end

--- Always-on warning log (even when debug is off).
function Utils.warn(tag, ...)
    print(('[bitirim:%s][WARN]'):format(tag or '?'), ...)
end

--- Clamp a number between min and max.
function Utils.clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

--- Linear interpolation.
function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

--- Map a value from one range to another, clamped.
function Utils.remap(v, inMin, inMax, outMin, outMax)
    if inMax == inMin then return outMin end
    local t = Utils.clamp((v - inMin) / (inMax - inMin), 0.0, 1.0)
    return outMin + (outMax - outMin) * t
end

--- Shallow count of a (possibly sparse) table.
function Utils.count(t)
    local n = 0
    if not t then return 0 end
    for _ in pairs(t) do n = n + 1 end
    return n
end

--- Safe deep-ish read of a dotted path from a table, e.g. path(obj, 'a.b.c').
function Utils.path(root, dotted)
    local node = root
    for key in string.gmatch(dotted, '[^%.]+') do
        if type(node) ~= 'table' then return nil end
        node = node[key]
    end
    return node
end

--- Trim whitespace.
function Utils.trim(s)
    if type(s) ~= 'string' then return s end
    return (s:gsub('^%s*(.-)%s*$', '%1'))
end

Bitirim.Utils = Utils
