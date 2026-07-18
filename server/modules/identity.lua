--[[
    server/modules/identity.lua
    ---------------------------
    The authoritative identity / known-people system.

    Core guarantees:
      * Privacy-preserving: a client is only ever told a name it has *earned*.
        Citizenids and names of strangers never leave the server.
      * One-directional: owner learning `known` does NOT reveal owner to known.
      * Persistent: relationships survive reconnect / restart (DB backed).

    Data model:
      knownMap[ownerCid] = { [knownCid] = true }     -- loaded lazily per player
      online[cid]        = { source, name }          -- currently connected chars
      cidBySource[src]   = cid

    Reveal protocol (server -> client):
      'bitirim:client:reveal'  payload = { [serverId] = "Full Name", ... }
      'bitirim:client:conceal' payload = serverId          (cache cleanup only)

    Exposed via Bitirim.Identity (server-only).
]]

local Utils = Bitirim.Utils
local Players = Bitirim.Players
local Cfg = Bitirim.Config.identity

local Identity = {}

local knownMap = {}      -- ownerCid -> { knownCid = true }
local online = {}        -- cid -> { source, name }
local cidBySource = {}   -- source -> cid

---------------------------------------------------------------------------
-- DATABASE
---------------------------------------------------------------------------

local function ensureTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bitirim_known_identities` (
            `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `owner_citizenid`  VARCHAR(64) NOT NULL,
            `known_citizenid`  VARCHAR(64) NOT NULL,
            `created_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uniq_owner_known` (`owner_citizenid`, `known_citizenid`),
            KEY `idx_owner` (`owner_citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

--- Load an owner's known set into memory (once per session).
local function loadKnown(ownerCid)
    if knownMap[ownerCid] then return knownMap[ownerCid] end
    local set = {}
    if Cfg.persist then
        local rows = MySQL.query.await(
            'SELECT known_citizenid FROM bitirim_known_identities WHERE owner_citizenid = ?',
            { ownerCid }
        ) or {}
        for _, row in ipairs(rows) do
            set[row.known_citizenid] = true
        end
    end
    knownMap[ownerCid] = set
    return set
end

--- Persist a new relationship (idempotent).
local function persist(ownerCid, knownCid)
    if not Cfg.persist then return end
    MySQL.insert(
        'INSERT IGNORE INTO bitirim_known_identities (owner_citizenid, known_citizenid) VALUES (?, ?)',
        { ownerCid, knownCid }
    )
end

---------------------------------------------------------------------------
-- QUERIES
---------------------------------------------------------------------------

--- Is this source registered as a ready/online character? (diagnostics)
function Identity.isRegistered(source)
    return cidBySource[source] ~= nil
end

--- Does ownerCid know knownCid?
function Identity.knows(ownerCid, knownCid)
    if ownerCid == knownCid then return true end
    local set = loadKnown(ownerCid)
    return set[knownCid] == true
end

---------------------------------------------------------------------------
-- REVEAL SYNC
---------------------------------------------------------------------------

--- Push a single reveal (serverId -> name) to one client.
local function pushReveal(toSource, aboutSource, name)
    TriggerClientEvent('bitirim:client:reveal', toSource, { [aboutSource] = name })
end

--- When a character comes online, reconcile reveals with everyone already on.
--- @param source number  the joining player's source
local function reconcile(source)
    local cid = cidBySource[source]
    if not cid then return end
    local myName = online[cid].name

    -- Build the batch of players *I* already know (so my client can label them).
    local batchForMe = {}
    for otherCid, info in pairs(online) do
        if otherCid ~= cid then
            -- Do I know them?
            if Identity.knows(cid, otherCid) then
                batchForMe[info.source] = info.name
            end
            -- Do they know me? Then reveal me to their client.
            if Identity.knows(otherCid, cid) then
                pushReveal(info.source, source, myName)
            end
        end
    end

    if Utils.count(batchForMe) > 0 then
        TriggerClientEvent('bitirim:client:reveal', source, batchForMe)
    end
end

---------------------------------------------------------------------------
-- LIFECYCLE
---------------------------------------------------------------------------

--- Register a fully-loaded character as online and sync reveals.
function Identity.onReady(source)
    local player = Players.get(source)
    if not player then return end
    local cid = player.PlayerData.citizenid
    local name = Players.getFullName(source) or 'Unknown'

    online[cid] = { source = source, name = name }
    cidBySource[source] = cid
    loadKnown(cid)

    -- Issue / restore this character's permanent public number.
    if Bitirim.PlayerId then
        Bitirim.PlayerId.attach(source, cid)
    end

    reconcile(source)
    Utils.log('identity', ('ready cid=%s src=%s name=%s'):format(cid, source, name))
end

--- Remove a character from the online registry.
function Identity.onDrop(source)
    local cid = cidBySource[source]
    if not cid then return end
    cidBySource[source] = nil
    if online[cid] and online[cid].source == source then
        online[cid] = nil
    end
    -- Tell everyone who knew this player to drop the local cache entry.
    TriggerClientEvent('bitirim:client:conceal', -1, source)
    Utils.log('identity', ('drop cid=%s src=%s'):format(cid, source))
end

---------------------------------------------------------------------------
-- LEARNING (called by passport accept)
---------------------------------------------------------------------------

--- ownerSource permanently learns the identity of knownSource.
--- Pushes an immediate reveal to owner's client. One-directional by design.
function Identity.learn(ownerSource, knownSource)
    local ownerCid = cidBySource[ownerSource]
    local knownCid = cidBySource[knownSource]
    if not ownerCid or not knownCid or ownerCid == knownCid then return false end

    local set = loadKnown(ownerCid)
    if not set[knownCid] then
        set[knownCid] = true
        persist(ownerCid, knownCid)
    end

    local knownName = online[knownCid] and online[knownCid].name or Players.getFullName(knownSource)
    pushReveal(ownerSource, knownSource, knownName or 'Unknown')
    Utils.log('identity', ('learn owner=%s known=%s (%s)'):format(ownerCid, knownCid, knownName))
    return true
end

--- Remove a relationship (forget). Optional / future.
function Identity.forget(ownerSource, knownCid)
    local ownerCid = cidBySource[ownerSource]
    if not ownerCid then return false end
    local set = loadKnown(ownerCid)
    if set then set[knownCid] = nil end
    if Cfg.persist then
        MySQL.query('DELETE FROM bitirim_known_identities WHERE owner_citizenid = ? AND known_citizenid = ?',
            { ownerCid, knownCid })
    end
    return true
end

---------------------------------------------------------------------------
-- WIRING
---------------------------------------------------------------------------

CreateThread(function()
    if Cfg.persist then ensureTable() end
end)

AddEventHandler('playerDropped', function()
    Identity.onDrop(source)
end)

Bitirim.Identity = Identity
