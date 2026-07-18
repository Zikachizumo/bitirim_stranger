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
-- FORGET COMMAND (optional / config-gated)
---------------------------------------------------------------------------
if Bitirim.Config.identity.allowForget and Bitirim.Config.identity.forgetCommand then
    -- Minimal stub: full "select from known people" menu is future UI work.
    -- Usage: /forget <citizenid>
    RegisterCommand(Bitirim.Config.identity.forgetCommand, function(source, args)
        local knownCid = args[1]
        if not knownCid then
            TriggerClientEvent('bitirim:client:notify', source, {
                type = 'inform', title = 'Forget',
                description = 'Usage: /' .. Bitirim.Config.identity.forgetCommand .. ' <citizenid>',
            })
            return
        end
        Identity.forget(source, knownCid)
        TriggerClientEvent('bitirim:client:notify', source, {
            type = 'success', title = 'Forget', description = 'Identity forgotten.',
        })
    end, false)
end

Utils.log('server', 'bitirim_stranger server modules initialised')
