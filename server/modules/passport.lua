--[[
    server/modules/passport.lua
    ---------------------------
    Server-authoritative passport request lifecycle.

    Guarantees (from spec):
      * Only ONE active request per sender and per target (no spam / stacking).
      * Timeout auto-cancels after Config.passport.requestTimeout seconds.
      * Accept / Decline / Timeout all funnel through one cleanup path.
      * On accept, the RECEIVER permanently learns the SENDER (Identity.learn).
      * Distance re-validated server-side (anti-cheat; never trust the client).

    Request record:
      requests[id] = { id, sender, target, senderName, expires, timer }
    Indices (fast lock checks):
      bySender[src] = id ; byTarget[src] = id
]]

local Utils = Bitirim.Utils
local Players = Bitirim.Players
local Identity = Bitirim.Identity
local Cfg = Bitirim.Config

local Passport = {}

local requests = {}     -- id -> record
local bySender = {}     -- source -> id
local byTarget = {}     -- source -> id
local cooldowns = {}    -- "senderSrc:targetSrc" -> os.clock ms until allowed
local nextId = 0

---------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------

local function now() return GetGameTimer() end

local function cooldownKey(s, t) return ('%d:%d'):format(s, t) end

local function withinRange(a, b)
    local pa = GetEntityCoords(GetPlayerPed(a))
    local pb = GetEntityCoords(GetPlayerPed(b))
    if not pa or not pb then return false end
    return #(pa - pb) <= (Cfg.interaction.targetDistance + 1.5) -- small tolerance
end

--- Tear down a request and clear all indices / timers.
local function cleanup(id)
    local rec = requests[id]
    if not rec then return end
    if rec.timer then
        -- ox_lib SetTimeout returns a cancel handle
        pcall(function() rec.timer:cancel() end)
    end
    if bySender[rec.sender] == id then bySender[rec.sender] = nil end
    if byTarget[rec.target] == id then byTarget[rec.target] = nil end
    requests[id] = nil
end

local function notify(source, msgType, description, title)
    TriggerClientEvent('bitirim:client:notify', source, {
        type = msgType,           -- 'inform' | 'success' | 'error' | 'warning'
        title = title or 'Passport',
        description = description,
        duration = 4000,
    })
end

---------------------------------------------------------------------------
-- REQUEST
---------------------------------------------------------------------------

--- A sender asks to show their passport to a target.
function Passport.request(senderSrc, targetSrc)
    -- Basic validity.
    if not targetSrc or senderSrc == targetSrc then return end
    if not Players.get(senderSrc) or not Players.get(targetSrc) then return end

    -- Distance (anti-cheat).
    if not withinRange(senderSrc, targetSrc) then
        notify(senderSrc, 'error', 'That person is too far away.')
        return
    end

    -- One-request rule: sender may have no outgoing, target no incoming.
    if bySender[senderSrc] then
        notify(senderSrc, 'warning', 'You already have a pending passport request.')
        return
    end
    if byTarget[targetSrc] then
        notify(senderSrc, 'warning', 'That person is busy with another request.')
        return
    end

    -- Anti-spam cooldown after a prior decline/timeout with the same target.
    local ck = cooldownKey(senderSrc, targetSrc)
    if cooldowns[ck] and now() < cooldowns[ck] then
        notify(senderSrc, 'warning', 'Please wait before requesting again.')
        return
    end

    -- Create the request.
    nextId = nextId + 1
    local id = nextId
    local senderName = Players.getFullName(senderSrc) or 'Someone'
    local timeoutMs = Cfg.passport.requestTimeout * 1000

    local rec = {
        id = id,
        sender = senderSrc,
        target = targetSrc,
        senderName = senderName,
        expires = now() + timeoutMs,
    }
    requests[id] = rec
    bySender[senderSrc] = id
    byTarget[targetSrc] = id

    -- Timeout handler.
    rec.timer = SetTimeout(timeoutMs, function()
        if not requests[id] then return end
        cleanup(id)
        TriggerClientEvent('bitirim:client:passportDismiss', targetSrc, id)
        notify(senderSrc, 'inform', 'Passport request expired.')
        notify(targetSrc, 'inform', 'Passport request expired.')
    end)

    -- Prompt the receiver (sender voluntarily identifies themselves here).
    TriggerClientEvent('bitirim:client:passportPrompt', targetSrc, {
        requestId = id,
        senderName = senderName,
        senderServerId = (Bitirim.PlayerId and Bitirim.PlayerId.get(senderSrc)) or senderSrc,
        timeout = Cfg.passport.requestTimeout,
    })

    notify(senderSrc, 'inform', ('Passport request sent to ID %d.'):format((Bitirim.PlayerId and Bitirim.PlayerId.get(targetSrc)) or targetSrc))
    Utils.log('passport', ('request #%d %s -> %s'):format(id, senderSrc, targetSrc))
end

--- Receiver accepts: open passport, learn the sender.
function Passport.accept(targetSrc, requestId)
    local rec = requests[requestId]
    if not rec or rec.target ~= targetSrc then return end

    local senderSrc = rec.sender
    cleanup(requestId)

    -- Build & deliver the sender's passport to the receiver.
    local payload = Players.buildPassport(senderSrc)
    if not payload then
        notify(targetSrc, 'error', 'Could not load that passport.')
        return
    end
    TriggerClientEvent('bitirim:client:passportShow', targetSrc, payload)

    -- Receiver permanently learns the sender (one-directional).
    local learned = Identity.learn(targetSrc, senderSrc)
    if not learned then
        -- Always-on warning: almost always means one side never sent the ready
        -- handshake, so the server has no citizenid mapping for them.
        Utils.warn('passport', ('learn FAILED target=%s(reg=%s) sender=%s(reg=%s) — ready handshake missing?')
            :format(targetSrc, tostring(Identity.isRegistered(targetSrc)),
                    senderSrc, tostring(Identity.isRegistered(senderSrc))))
    end

    notify(senderSrc, 'success', ('ID %d accepted your passport.'):format((Bitirim.PlayerId and Bitirim.PlayerId.get(targetSrc)) or targetSrc))
    Utils.log('passport', ('accept #%d learned=%s'):format(requestId, tostring(learned)))
end

--- Receiver declines: nothing changes, sets a short cooldown.
function Passport.decline(targetSrc, requestId)
    local rec = requests[requestId]
    if not rec or rec.target ~= targetSrc then return end

    local senderSrc = rec.sender
    cleanup(requestId)
    cooldowns[cooldownKey(senderSrc, targetSrc)] = now() + Cfg.passport.resendCooldown

    notify(senderSrc, 'error', ('ID %d declined your passport.'):format((Bitirim.PlayerId and Bitirim.PlayerId.get(targetSrc)) or targetSrc))
    Utils.log('passport', ('decline #%d'):format(requestId))
end

--- Clean up any request tied to a dropping player.
local function onDrop(source)
    local id = bySender[source] or byTarget[source]
    if id then cleanup(id) end
end

AddEventHandler('playerDropped', function()
    onDrop(source)
end)

-- NOTE: exported as PassportService, NOT Bitirim.Passport, because
-- config/passport.lua already owns Bitirim.Passport (the document config).
Bitirim.PassportService = Passport
