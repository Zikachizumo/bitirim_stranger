--[[
    client/modules/passport.lua
    ---------------------------
    Two responsibilities:

    1) Incoming request PROMPT (non-focus, premium notification with countdown).
       The player keeps full movement control while deciding. Y accepts,
       N declines, or they can click the NUI buttons.

    2) Passport DISPLAY (focus modal) shown to the receiver after they accept.

    Only one active prompt can exist at a time on the client, matching the
    server's one-request guarantee.
]]

local Utils = Bitirim.Utils

local Passport = {}
local activePrompt = nil     -- { requestId = number }

---------------------------------------------------------------------------
-- REQUEST PROMPT
---------------------------------------------------------------------------

--- Give the focus-less prompt keyboard focus while keeping game input
--- (movement) alive via SetNuiFocusKeepInput. This lets the NUI reliably
--- capture Y/N (and button clicks) WITHOUT depending on RegisterKeyMapping
--- default bindings, which don't always activate on first load.
local function grabPromptFocus()
    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true)
end
local function releasePromptFocus()
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
end

--- Server asks us to accept/decline someone's passport.
RegisterNetEvent('bitirim:client:passportPrompt', function(data)
    if type(data) ~= 'table' or not data.requestId then return end
    activePrompt = { requestId = data.requestId }
    grabPromptFocus()
    SendNUIMessage({
        action = 'passportPrompt',
        requestId = data.requestId,
        senderName = data.senderName or 'Someone',
        senderId = data.senderServerId,
        timeout = data.timeout or 10,
    })
end)

--- Server tells us the prompt is gone (timeout / other player cancelled).
RegisterNetEvent('bitirim:client:passportDismiss', function(requestId)
    if activePrompt and activePrompt.requestId == requestId then
        activePrompt = nil
        releasePromptFocus()
        SendNUIMessage({ action = 'passportPromptClose' })
    end
end)

--- Local respond helper (from NUI key/button or the fallback key mapping).
local function respond(accepted)
    if not activePrompt then return end
    local requestId = activePrompt.requestId
    activePrompt = nil
    releasePromptFocus()
    SendNUIMessage({ action = 'passportPromptClose' })
    if accepted then
        TriggerServerEvent('bitirim:server:passportAccept', requestId)
    else
        TriggerServerEvent('bitirim:server:passportDecline', requestId)
    end
end

-- Y / N key mappings (only act while a prompt is active).
RegisterCommand('bitirim_passport_accept', function()
    if activePrompt then respond(true) end
end, false)
RegisterCommand('bitirim_passport_decline', function()
    if activePrompt then respond(false) end
end, false)

RegisterKeyMapping('bitirim_passport_accept', 'Bitirim — Accept passport request', 'keyboard', Bitirim.Config.passport.acceptKey)
RegisterKeyMapping('bitirim_passport_decline', 'Bitirim — Decline passport request', 'keyboard', Bitirim.Config.passport.declineKey)

-- NUI button fallbacks (mouse users). The prompt is focus-less, so these fire
-- via a lightweight focus-less callback path.
RegisterNUICallback('bitirim:passportRespond', function(data, cb)
    respond(data and data.accepted == true)
    cb('ok')
end)

---------------------------------------------------------------------------
-- PASSPORT DISPLAY (receiver, after acceptance)
---------------------------------------------------------------------------

RegisterNetEvent('bitirim:client:passportShow', function(payload)
    if type(payload) ~= 'table' then return end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'passportShow', passport = payload })
end)

RegisterNUICallback('bitirim:passportClose', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'passportHide' })
    cb('ok')
end)

Bitirim.Passport = Passport
Utils.log('passport', 'client passport module ready')
