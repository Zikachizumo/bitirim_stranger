--[[
    server/modules/debug.lua
    ------------------------
    Server-side developer test commands. Loaded only when Bitirim.Config.debug
    is true. Useful for testing identity reveals with two players without
    performing the whole passport handshake.

        /bx_reveal <serverId>   you instantly LEARN that player's identity
                                (their label flips Stranger -> real name)
        /bx_ping                prints your resolved citizenid + name to console
]]

if not Bitirim.Config.debug then return end

local Utils = Bitirim.Utils
local Players = Bitirim.Players
local Identity = Bitirim.Identity

RegisterCommand('bx_reveal', function(source, args)
    local target = tonumber(args[1])
    if not target then
        Utils.warn('debug', 'usage: /bx_reveal <serverId>')
        return
    end
    local ok = Identity.learn(source, target)
    TriggerClientEvent('bitirim:client:notify', source, {
        type = ok and 'success' or 'error',
        title = 'Debug',
        description = ok and ('Learned ID ' .. target) or 'Could not learn that player',
    })
end, false)

RegisterCommand('bx_ping', function(source)
    local cid = Players.getCitizenId(source)
    local name = Players.getFullName(source)
    Utils.warn('debug', ('src=%s cid=%s name=%s'):format(source, tostring(cid), tostring(name)))
end, false)

Utils.warn('debug', 'DEBUG server commands active: /bx_reveal <id>  /bx_ping')
