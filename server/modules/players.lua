--[[
    server/modules/players.lua
    ---------------------------
    Bridges Qbox player data into the shapes this resource needs.

    Responsibilities:
        - Resolve a source -> Qbox player object (never caches stale data).
        - Build a display name ("Firstname Lastname").
        - Build the passport payload strictly from config/passport.lua mappings.

    This is the ONLY module that reads Qbox charinfo/metadata, so if Qbox ever
    changes its data shape, this is the single place to adapt.

    Exposed via Bitirim.Players (server-only).
]]

local Utils = Bitirim.Utils
local Players = {}

--- Get the Qbox player object for a source, or nil.
function Players.get(source)
    local ok, player = pcall(function()
        return exports.qbx_core:GetPlayer(source)
    end)
    if not ok or not player then return nil end
    return player
end

--- Get a player's citizenid, or nil if not loaded.
function Players.getCitizenId(source)
    local player = Players.get(source)
    if not player then return nil end
    return player.PlayerData and player.PlayerData.citizenid or nil
end

--- Build the public display name for a loaded character.
function Players.getFullName(source)
    local player = Players.get(source)
    if not player then return nil end
    local ci = player.PlayerData and player.PlayerData.charinfo
    if not ci then return nil end
    local first = Utils.trim(ci.firstname or '')
    local last = Utils.trim(ci.lastname or '')
    local full = Utils.trim((first .. ' ' .. last))
    if full == '' then return 'Unknown' end
    return full
end

--- Resolve a single passport field value from its config `source` string.
--- @param srcId number  the player's server id (for the 'playerid' source)
local function resolveSource(playerData, source, static, srcId)
    if source == 'playerid' then
        return srcId
    end
    if source == 'citizenid' then
        return playerData.citizenid
    end
    if source == 'charinfo.__fullname' then
        local ci = playerData.charinfo or {}
        return Utils.trim(((ci.firstname or '') .. ' ' .. (ci.lastname or '')))
    end
    local scope, key = source:match('^(%w+)%.(.+)$')
    if scope == 'charinfo' then
        return Utils.path(playerData.charinfo or {}, key)
    elseif scope == 'meta' then
        return Utils.path(playerData.metadata or {}, key)
    elseif scope == 'static' then
        return static
    end
    return nil
end

--- Apply a named transform (e.g. gender code -> "Male").
local function applyTransform(value, transformName)
    if not transformName then return value end
    local map = Bitirim.Passport.transforms[transformName]
    if not map then return value end
    local mapped = map[value]
    if mapped ~= nil then return mapped end
    return map.default or value
end

--- Build the full passport payload for a character.
--- @return table|nil  { title, subtitle, showPhoto, fields = { {label, value}... }, signature }
function Players.buildPassport(source)
    local player = Players.get(source)
    if not player then return nil end
    local pd = player.PlayerData
    if not pd then return nil end

    local cfg = Bitirim.Passport
    local out = {
        title = cfg.title,
        subtitle = cfg.subtitle,
        showPhoto = cfg.showPhoto,
        photo = cfg.photoPlaceholder,
        fields = {},
        signature = nil,
    }

    for _, field in ipairs(cfg.fields) do
        local raw = resolveSource(pd, field.source, field.static, source)
        local value = applyTransform(raw, field.transform)
        if value == nil or value == '' then value = 'N/A' end
        out.fields[#out.fields + 1] = { key = field.key, label = field.label, value = tostring(value) }
    end

    if cfg.signature and cfg.signature.enabled then
        out.signature = resolveSource(pd, cfg.signature.source, cfg.signature.static, source)
    end

    return out
end

Bitirim.Players = Players
