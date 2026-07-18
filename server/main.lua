--[[
    server/main.lua
    ---------------
    Bootstrap + network event surface for the server side.
    All heavy lifting lives in the modules; this file only wires events to them
    and performs source-level validation.
]]

local Utils = Bitirim.Utils
local Identity = Bitirim.Identity
local Passport = Bitirim.PassportService

---------------------------------------------------------------------------
-- READY HANDSHAKE
-- The client tells us when its Qbox character is fully loaded. This avoids
-- depending on any specific qbx_core internal event name across versions.
---------------------------------------------------------------------------
RegisterNetEvent('bitirim:server:onReady', function()
    local src = source
    Identity.onReady(src)
end)

---------------------------------------------------------------------------
-- PASSPORT FLOW
---------------------------------------------------------------------------
RegisterNetEvent('bitirim:server:requestPassport', function(targetServerId)
    local src = source
    targetServerId = tonumber(targetServerId)
    if not targetServerId then return end
    Passport.request(src, targetServerId)
end)

RegisterNetEvent('bitirim:server:passportAccept', function(requestId)
    local src = source
    requestId = tonumber(requestId)
    if not requestId then return end
    Passport.accept(src, requestId)
end)

RegisterNetEvent('bitirim:server:passportDecline', function(requestId)
    local src = source
    requestId = tonumber(requestId)
    if not requestId then return end
    Passport.decline(src, requestId)
end)

---------------------------------------------------------------------------
-- ADMIN: /whois <number>
-- Resolves a permanent player number back to its character. ACE-gated, so it
-- works with any admin setup:  add_ace group.admin bitirim.admin allow
---------------------------------------------------------------------------
local idCfg = Bitirim.Config.playerId
if idCfg.enabled and idCfg.allowAdminCommands and idCfg.adminCommand then
    RegisterCommand(idCfg.adminCommand, function(source, args)
        local src = source
        local function reply(msg)
            if src > 0 then
                TriggerClientEvent('bitirim:client:notify', src,
                    { type = 'inform', title = 'Whois', description = msg, duration = 6000 })
            else
                print('[bitirim:whois] ' .. msg)
            end
        end

        -- src 0 is the server console, which is always allowed.
        if src > 0 and not IsPlayerAceAllowed(src, idCfg.adminAce) then
            reply('You do not have permission to use this.')
            return
        end

        local number = tonumber(args[1])
        if not number then
            reply(('Usage: /%s <number>'):format(idCfg.adminCommand))
            return
        end

        local row = Bitirim.PlayerId.lookup(number)
        if not row then
            reply(('No character has ever held ID %d.'):format(number))
            return
        end

        local onlineSrc = Bitirim.PlayerId.getSourceByNumber(number)
        local status
        if row.deleted_at then
            status = 'character deleted (number retired)'
        elseif onlineSrc then
            status = ('online as server id %d — %s'):format(onlineSrc, Bitirim.Players.getFullName(onlineSrc) or '?')
        else
            status = 'offline'
        end

        reply(('ID %d -> citizenid %s (%s)'):format(row.number, row.citizenid, status))
    end, false)
end

---------------------------------------------------------------------------
-- FORGET COMMAND (optional / config-gated)
---------------------------------------------------------------------------
if Bitirim.Config.identity.allowForget and Bitirim.Config.identity.forgetCommand then
    local cmd = Bitirim.Config.identity.forgetCommand

    -- Usage:  /forget <playerId>   (the number shown above their head)
    --         /forget <citizenid>  (still accepted)
    --         /forget all          (wipe everyone you know)
    RegisterCommand(cmd, function(source, args)
        local src = source
        local function reply(msgType, description)
            TriggerClientEvent('bitirim:client:notify', src,
                { type = msgType, title = 'Forget', description = description })
        end

        local arg = args[1]
        if not arg then
            reply('inform', ('Usage: /%s <playerId | citizenid | all>'):format(cmd))
            return
        end

        if arg:lower() == 'all' then
            local removed = Identity.forgetAll(src)
            reply('success', ('Forgot %d %s.'):format(removed, removed == 1 and 'person' or 'people'))
            return
        end

        -- Prefer the permanent player id — it's the number players actually see.
        local knownCid
        local number = tonumber(arg)
        if number and Bitirim.PlayerId then
            local targetSrc = Bitirim.PlayerId.getSourceByNumber(number)
            if targetSrc then
                knownCid = Identity.getCitizenId(targetSrc)
            end
        end
        knownCid = knownCid or arg   -- fall back to treating it as a citizenid

        if Identity.forget(src, knownCid) then
            reply('success', ('Forgot %s. They are a stranger again.'):format(arg))
        else
            reply('error', 'Could not forget that player.')
        end
    end, false)
end

Utils.log('server', 'bitirim_stranger server modules initialised')
