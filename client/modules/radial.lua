--[[
    client/modules/radial.lua
    -------------------------
    Bridges the Lua interaction layer to the NUI radial menu.

    Responsibilities:
        - open/close the menu (NUI focus management)
        - remember which player is being interacted with (currentTarget)
        - dispatch the selected action (string) to the right behaviour

    Actions are strings defined in config/menu.lua. Adding a new menu action =
    add a case in Dispatch(). Everything else stays untouched.
]]

local Utils = Bitirim.Utils

local Radial = {}
local isOpen = false
local currentTarget = nil

function Radial.isOpen() return isOpen end

--- Open the radial menu targeting a specific player.
function Radial.open(targetServerId)
    if isOpen then return end
    currentTarget = targetServerId
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'radialOpen',
        centerLabel = Bitirim.Menu.centerLabel,
        targetId = targetServerId,
    })
end

--- Close the radial menu and release focus.
function Radial.close()
    if not isOpen then return end
    isOpen = false
    currentTarget = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'radialClose' })
end

--- Route a selected action to its behaviour.
local function dispatch(actionName)
    if not actionName then return end

    if actionName == 'showPassport' then
        if currentTarget then
            TriggerServerEvent('bitirim:server:requestPassport', currentTarget)
        end
        Radial.close()
        return
    end

    -- Everything else is a future feature — acknowledge gracefully.
    Radial.close()
    TriggerEvent('bitirim:client:notify', {
        type = 'inform',
        title = 'Coming soon',
        description = 'This feature is not available yet.',
        duration = 2500,
    })
    Utils.log('radial', 'unhandled action: ' .. tostring(actionName))
end

---------------------------------------------------------------------------
-- NUI CALLBACKS
---------------------------------------------------------------------------

RegisterNUICallback('bitirim:radialSelect', function(data, cb)
    dispatch(data and data.action)
    cb('ok')
end)

RegisterNUICallback('bitirim:radialClose', function(_, cb)
    Radial.close()
    cb('ok')
end)

Bitirim.Radial = Radial
