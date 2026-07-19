--[[
    server/modules/chat.lua
    -----------------------
    Identity-aware proximity chat.

    A normal chat resource broadcasts one message to everybody. We cancel that
    and deliver the message individually, so each receiver sees the sender
    labelled by what THEY have earned:

        stranger              ->  "Stranger (12): hello"
        learned via passport  ->  "Yasin Demir (12): hello"

    The number is the PERMANENT player id (playerid.lua), not the session id.

    Messages only reach players within Config.chat.range metres, and are cut
    off at Config.chat.maxLength characters.

    Colours are baked into our own registered chat template instead of relying
    on the theme's CSS — the theme does not wrap the author in a styleable
    element, so CSS alone could not colour the name separately.

    Commands (messages starting with '/') are left alone.
]]

local Cfg = Bitirim.Config.chat
if not Cfg or not Cfg.enabled then return end

local Utils = Bitirim.Utils
local Players = Bitirim.Players
local Identity = Bitirim.Identity
local strangerLabel = Bitirim.Config.identity.strangerLabel

local TEMPLATE_ID = 'bitirimChat'

---------------------------------------------------------------------------
-- TEMPLATE
---------------------------------------------------------------------------

local function templateHtml()
    return ('<span style="color:%s">{0}</span> <span style="color:%s">{1}</span>')
        :format(Cfg.authorColor or '#FF8C00', Cfg.messageColor or '#FFFFFF')
end

local function registerTemplate(target)
    TriggerClientEvent('chat:addTemplate', target, TEMPLATE_ID, templateHtml())
end

-- Templates live on the client, so (re)register on join and on resource start
-- for anyone already connected.
AddEventHandler('playerJoining', function()
    registerTemplate(source)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, p in ipairs(GetPlayers()) do
        registerTemplate(tonumber(p))
    end
end)

---------------------------------------------------------------------------
-- DELIVERY
---------------------------------------------------------------------------

--- How should `viewer` see `senderCid`?
local function labelFor(viewerSource, senderCid, senderName)
    local viewerCid = Players.getCitizenId(viewerSource)
    if not viewerCid or not senderCid then return strangerLabel end
    if viewerCid == senderCid then return senderName end   -- you know yourself
    if Identity.knows(viewerCid, senderCid) then return senderName end
    return strangerLabel
end

--- Is `target` close enough to hear `senderCoords`?
local function inRange(senderCoords, target)
    local range = Cfg.range or 0
    if range <= 0 then return true end          -- 0 = server-wide
    local ped = GetPlayerPed(target)
    if not ped or ped == 0 then return false end
    return #(senderCoords - GetEntityCoords(ped)) <= range
end

AddEventHandler('chatMessage', function(source, _, message)
    local src = source
    if type(message) ~= 'string' or message == '' then return end

    -- Commands keep their normal path.
    if message:sub(1, 1) == '/' then return end

    -- Take over the broadcast.
    CancelEvent()

    -- Trim overly long messages.
    local maxLength = Cfg.maxLength or 0
    if maxLength > 0 and #message > maxLength then
        message = message:sub(1, maxLength)
    end

    local senderCid = Players.getCitizenId(src)
    local senderName = Players.getFullName(src) or 'Unknown'
    local senderId = Bitirim.PlayerId and Bitirim.PlayerId.get(src)
    local idText = senderId and tostring(senderId) or '?'
    local senderCoords = GetEntityCoords(GetPlayerPed(src))

    local heard = 0
    for _, p in ipairs(GetPlayers()) do
        local target = tonumber(p)
        if target and inRange(senderCoords, target) then
            heard = heard + 1
            TriggerClientEvent('chat:addMessage', target, {
                templateId = TEMPLATE_ID,
                args = { (Cfg.authorFormat):format(labelFor(target, senderCid, senderName), idText), message },
            })
        end
    end

    Utils.log('chat', ('%s (#%s) heard by %d'):format(senderName, idText, heard))
end)
