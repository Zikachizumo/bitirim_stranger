--[[
    client/main.lua
    ---------------
    Client bootstrap:
        - Ready handshake to the server (character loaded).
        - Premium notification bridge (ox_lib).
        - NUI initialisation (push theme + menu config once the UI is ready).
]]

local Utils = Bitirim.Utils

---------------------------------------------------------------------------
-- READY HANDSHAKE
-- Robust across qbx versions: we notify the server whenever our character is
-- confirmed loaded, from any of the known signals.
---------------------------------------------------------------------------
local hasSignalled = false
local function sendReady()
    if hasSignalled then return end
    hasSignalled = true
    TriggerServerEvent('bitirim:server:onReady')
    Utils.log('client', 'sent ready handshake')
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', sendReady)
RegisterNetEvent('qbx_core:client:playerLoaded', sendReady)

-- If the resource (re)starts while already in-game, catch up.
CreateThread(function()
    for _ = 1, 20 do
        if LocalPlayer.state.isLoggedIn then
            sendReady()
            return
        end
        Wait(1000)
    end
end)

-- Allow re-signalling on a fresh spawn (e.g. after logout -> new char).
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    hasSignalled = false
end)

---------------------------------------------------------------------------
-- PREMIUM NOTIFICATIONS (ox_lib)
-- Handles both server pushes (RegisterNetEvent) and local triggers.
---------------------------------------------------------------------------
local function handleNotify(data)
    if type(data) ~= 'table' then return end
    lib.notify({
        title = data.title,
        description = data.description,
        type = data.type or 'inform',
        duration = data.duration or 4000,
        position = 'top',
    })
end
RegisterNetEvent('bitirim:client:notify', handleNotify)

---------------------------------------------------------------------------
-- NUI INITIALISATION
-- Push the full theme + menu tree so the UI can render itself with zero
-- hardcoded values. Sent once the NUI signals it is ready, and again on start.
---------------------------------------------------------------------------
local function pushInit()
    SendNUIMessage({
        action = 'init',
        theme = Bitirim.Theme,
        menu = Bitirim.Menu,
        config = {
            strangerLabel = Bitirim.Config.identity.strangerLabel,
            interactionKey = Bitirim.Config.interaction.key,
            acceptKey = Bitirim.Config.passport.acceptKey,
            declineKey = Bitirim.Config.passport.declineKey,
        },
    })
end

RegisterNUICallback('bitirim:uiReady', function(_, cb)
    pushInit()
    cb('ok')
end)

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    -- Give the NUI a moment to mount, then seed it (covers live-restart case).
    CreateThread(function()
        Wait(500)
        pushInit()
    end)
end)

Utils.log('client', 'bitirim_stranger client initialised')
