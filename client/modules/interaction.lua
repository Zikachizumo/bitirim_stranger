--[[
    client/modules/interaction.lua
    ------------------------------
    Owns the interaction key (default G). Pressing it NEVER executes an action
    directly — it opens the radial menu for the currently targeted player.

    The valid target is whatever proximity.lua last resolved (nearest, in range,
    line-of-sight, on foot). If there is no target, the key does nothing.
]]

local Utils = Bitirim.Utils
local Cfg = Bitirim.Config

local COMMAND = 'bitirim_interact'

--- Triggered by the G key mapping.
RegisterCommand(COMMAND, function()
    -- Ignore while typing in chat / NUI focus / radial already open.
    if IsPauseMenuActive() then return end
    if Bitirim.Radial and Bitirim.Radial.isOpen() then return end

    local target = Bitirim.Proximity and Bitirim.Proximity.target or nil
    if not target then return end

    if Bitirim.Radial then
        Bitirim.Radial.open(target)
    end
end, false)

RegisterKeyMapping(COMMAND, Cfg.interaction.keyMapDescription, 'keyboard', Cfg.interaction.key)

Utils.log('interaction', 'key mapping registered: ' .. Cfg.interaction.key)
