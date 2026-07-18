--[[
    server/modules/playerid.lua
    ---------------------------
    Permanent, never-reused player numbers.

    Guarantees:
      * Issued ONCE per character (citizenid), on first login.
      * Stable across reconnects, character reloads and server restarts.
      * NEVER reused. Two mechanisms back this:
          1. Registry rows are never deleted — a removed character is
             soft-deleted (deleted_at), so its number stays claimed forever.
          2. MySQL AUTO_INCREMENT never reissues a value.
        So deleting character #3 leaves 3 retired and the next one gets 4.
      * Race-safe: two simultaneous logins can't take the same number, because
        INSERT IGNORE collapses onto the UNIQUE(citizenid) key and both then
        read back the same row.

    The number is PUBLIC (it renders above every player), so it is replicated
    to all clients via a player statebag. Names are NOT — those stay
    server-side and are only revealed to players who earned them
    (see identity.lua).

    Exposed via Bitirim.PlayerId (server-only).
]]

local Utils = Bitirim.Utils
local Cfg = Bitirim.Config.playerId

local PlayerId = {}

local byCitizenId = {}   -- citizenid -> number
local bySource = {}      -- source    -> number

---------------------------------------------------------------------------
-- DATABASE
---------------------------------------------------------------------------

local function ensureTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bitirim_player_ids` (
            `number`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `citizenid`  VARCHAR(64) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `deleted_at` TIMESTAMP NULL DEFAULT NULL,
            PRIMARY KEY (`number`),
            UNIQUE KEY `uniq_citizenid` (`citizenid`)
        ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;
    ]])
end

---------------------------------------------------------------------------
-- ASSIGNMENT
---------------------------------------------------------------------------

--- Fetch (or issue) the permanent number for a citizenid.
function PlayerId.ensure(citizenid)
    if not citizenid then return nil end

    local cached = byCitizenId[citizenid]
    if cached then return cached end

    -- Race-safe: whichever insert loses is simply ignored, and both callers
    -- read back the identical row.
    MySQL.insert.await('INSERT IGNORE INTO bitirim_player_ids (citizenid) VALUES (?)', { citizenid })
    local row = MySQL.single.await('SELECT number FROM bitirim_player_ids WHERE citizenid = ?', { citizenid })
    if not row or not row.number then
        Utils.warn('playerid', 'could not issue a number for ' .. tostring(citizenid))
        return nil
    end

    local number = row.number
    if Cfg.max and number > Cfg.max then
        Utils.warn('playerid', ('issued number %d is past the configured max of %d'):format(number, Cfg.max))
    end

    byCitizenId[citizenid] = number
    return number
end

--- Called once a character is ready: issue, cache and replicate the number.
function PlayerId.attach(source, citizenid)
    if not Cfg.enabled then return nil end
    local number = PlayerId.ensure(citizenid)
    if not number then return nil end

    bySource[source] = number
    -- Replicated statebag (third arg = true) so every client can label this
    -- player without the server broadcasting anything sensitive.
    Player(source).state:set('bitirimId', number, true)

    Utils.log('playerid', ('attached #%d to %s (src %s)'):format(number, citizenid, source))
    return number
end

function PlayerId.detach(source)
    bySource[source] = nil
end

---------------------------------------------------------------------------
-- LOOKUPS
---------------------------------------------------------------------------

function PlayerId.get(source)
    return bySource[source]
end

function PlayerId.getByCitizenId(citizenid)
    return byCitizenId[citizenid]
end

--- Which online source currently holds this number (if any)?
function PlayerId.getSourceByNumber(number)
    for src, num in pairs(bySource) do
        if num == number then return src end
    end
    return nil
end

--- Registry row for a number — used by the admin lookup.
function PlayerId.lookup(number)
    return MySQL.single.await(
        'SELECT number, citizenid, created_at, deleted_at FROM bitirim_player_ids WHERE number = ?',
        { number }
    )
end

--- Retire a number when its character is deleted. The row is KEPT (only
--- flagged), so the number can never come back into circulation.
function PlayerId.retire(citizenid)
    if not citizenid then return false end
    MySQL.query('UPDATE bitirim_player_ids SET deleted_at = CURRENT_TIMESTAMP WHERE citizenid = ? AND deleted_at IS NULL',
        { citizenid })
    byCitizenId[citizenid] = nil
    Utils.log('playerid', 'retired number for ' .. citizenid)
    return true
end

---------------------------------------------------------------------------
-- WIRING
---------------------------------------------------------------------------

CreateThread(function()
    if Cfg.enabled then ensureTable() end
end)

AddEventHandler('playerDropped', function()
    PlayerId.detach(source)
end)

Bitirim.PlayerId = PlayerId
