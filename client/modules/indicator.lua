--[[
    client/modules/indicator.lua
    ----------------------------
    Projects each tracked player's waist bone to screen space and feeds the NUI
    a compact per-frame batch. The NUI owns all the visual work (billboarding,
    fade in/out, scaling, glassmorphism) — Lua only supplies coordinates + state.

    One SendNUIMessage per frame carries ALL indicators (not one per player),
    keeping the NUI bridge cheap.
]]

local Utils = Bitirim.Utils
local Cfg = Bitirim.Config
local Theme = Bitirim.Theme

local perfCfg = Cfg.performance
local boneId = perfCfg.anchorBone
local heightOffset = perfCfg.anchorHeightOffset

local scaleMin = Theme.scale.min
local scaleMax = Theme.scale.max
local scaleBase = Theme.scale.base
local maxDist = Cfg.interaction.indicatorDistance

CreateThread(function()
    local wasActive = false
    while true do
        local tracked = Bitirim.Proximity.tracked
        local target = Bitirim.Proximity.target
        local wait = 0

        if tracked and #tracked > 0 then
            local items = {}
            for i = 1, #tracked do
                local t = tracked[i]
                local ped = t.ped
                if DoesEntityExist(ped) then
                    local coords = GetPedBoneCoords(ped, boneId, 0.0, 0.0, heightOffset)
                    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
                    if onScreen then
                        local label = Bitirim.Identity.label(t.serverId)
                        local scale = Utils.remap(t.dist, 0.0, maxDist, scaleMax, scaleMin) * scaleBase
                        items[#items + 1] = {
                            id = t.serverId,
                            x = sx,                 -- 0..1 screen space
                            y = sy,
                            scale = scale,
                            name = label.name,
                            known = label.known,
                            sid = t.serverId,
                            isTarget = (target == t.serverId),
                        }
                    end
                end
            end
            SendNUIMessage({ action = 'indicators', items = items })
            wasActive = true
        else
            if wasActive then
                SendNUIMessage({ action = 'indicators', items = {} })
                wasActive = false
            end
            wait = 200
        end

        Wait(perfCfg.renderInterval > 0 and perfCfg.renderInterval or wait)
    end
end)
