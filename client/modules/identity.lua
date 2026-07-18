--[[
    client/modules/identity.lua
    ---------------------------
    Client-side cache of *earned* identities.

    The server only ever sends us names we are entitled to see
    (bitirim:client:reveal). Everyone else is a "Stranger" by default.
    We never receive citizenids or stranger names — nothing to leak.

    Exposed via Bitirim.Identity (client).
]]

local Utils = Bitirim.Utils
local Cfg = Bitirim.Config.identity

local Identity = {}

-- serverId -> "Full Name"
local revealed = {}

--- Merge a batch of reveals from the server.
RegisterNetEvent('bitirim:client:reveal', function(batch)
    if type(batch) ~= 'table' then return end
    for serverId, name in pairs(batch) do
        revealed[tonumber(serverId)] = name
    end
    Utils.log('identity', 'revealed batch of ' .. Utils.count(batch))
end)

--- Drop a cache entry when a known player disconnects (memory hygiene only —
--- the persistent relationship still lives in the DB).
RegisterNetEvent('bitirim:client:conceal', function(serverId)
    revealed[tonumber(serverId)] = nil
end)

--- Resolve the label for a given server id.
--- @return table { name = string, known = boolean }
function Identity.label(serverId)
    serverId = tonumber(serverId)
    local name = revealed[serverId]
    if name then
        return { name = name, known = true }
    end
    return { name = Cfg.strangerLabel, known = false }
end

--- Is this server id a known character?
function Identity.isKnown(serverId)
    return revealed[tonumber(serverId)] ~= nil
end

Bitirim.Identity = Identity
