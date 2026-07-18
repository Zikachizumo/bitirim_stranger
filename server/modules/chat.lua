--[[
    server/modules/chat.lua
    -----------------------
    Identity-aware chat.

    A normal chat resource broadcasts one message to everybody. We cancel that
    and send the message to each player individually, labelling the sender by
    what THAT receiver has earned:

        stranger        ->  "Stranger (12): hello"
        learned via
        passport        ->  "Yasin Demir (12): hello"

    The number in brackets is the PERMANENT player id (playerid.lua), not the
    volatile session id, so it stays the same across reconnects.

    Nothing is revealed that the receiver has not earned — the same guarantee
    the floating name label gives, applied to chat.

    Commands (messages starting with '/') are left alone so their own handlers
    still run.
]]

local Cfg = Bitirim.Config.chat
if not Cfg or not Cfg.enabled then return end

local Utils = Bitirim.Utils
local Players = Bitirim.Players
local Identity = Bitirim.Identity
local strangerLabel = Bitirim.Config.identity.strangerLabel

--- How should `viewer` see `senderCid`?
local function labelFor(viewerSource, senderCid, senderName)
    local viewerCid = Players.getCitizenId(viewerSource)
    if not viewerCid or not senderCid then return strangerLabel end
    -- You always know yourself.
    if viewerCid == senderCid then return senderName end
    if Identity.knows(viewerCid, senderCid) then return senderName end
    return strangerLabel
end

AddEventHandler('chatMessage', function(source, _, message)
    local src = source
    if type(message) ~= 'string' or message == '' then return end

    -- Commands keep their normal path.
    if message:sub(1, 1) == '/' then return end

    -- Take over the broadcast.
    CancelEvent()

    local senderCid = Players.getCitizenId(src)
    local senderName = Players.getFullName(src) or 'Unknown'
    local senderId = Bitirim.PlayerId and Bitirim.PlayerId.get(src)
    local idText = senderId and tostring(senderId) or '?'

    for _, target in ipairs(GetPlayers()) do
        target = tonumber(target)
        if target then
            local label = labelFor(target, senderCid, senderName)
            TriggerClientEvent('chat:addMessage', target, {
                args = { (Cfg.format):format(label, idText, message) },
            })
        end
    end

    Utils.log('chat', ('relayed message from %s (#%s)'):format(senderName, idText))
end)
