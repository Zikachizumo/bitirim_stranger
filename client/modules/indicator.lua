--[[
    client/modules/indicator.lua
    ----------------------------
    Projects two world anchors per tracked player to screen space each frame:
        1. Name/ID label   -> slightly above the HEAD bone (follows the ped)
        2. Circular G key   -> chest / waist bone (interaction target only)

    Fixed size, no fade/scale animation — the label is simply pinned in world
    space and tracks the character. One SendNUIMessage per frame carries all
    indicators.
]]

local Cfg = Bitirim.Config
local perfCfg = Cfg.performance

local labelBone = perfCfg.labelBone
local labelOff = perfCfg.labelHeightOffset
local keyBone = perfCfg.keyBone
local keyOff = perfCfg.keyHeightOffset

CreateThread(function()
    local wasActive = false
    while true do
        local tracked = Bitirim.Proximity.tracked
        local target = Bitirim.Proximity.target

        if tracked and #tracked > 0 then
            local items = {}
            for i = 1, #tracked do
                local t = tracked[i]
                local ped = t.ped
                if DoesEntityExist(ped) then
                    -- Label anchor: just above the head bone.
                    local head = GetPedBoneCoords(ped, labelBone, 0.0, 0.0, 0.0)
                    local lok, lx, ly = GetScreenCoordFromWorldCoord(head.x, head.y, head.z + labelOff)
                    if lok then
                        -- Key anchor: chest / waist bone.
                        local chest = GetPedBoneCoords(ped, keyBone, 0.0, 0.0, keyOff)
                        local kok, kx, ky = GetScreenCoordFromWorldCoord(chest.x, chest.y, chest.z)
                        local label = Bitirim.Identity.label(t.serverId)
                        items[#items + 1] = {
                            id = t.serverId,
                            sid = t.serverId,
                            name = label.name,
                            known = label.known,
                            labelX = lx, labelY = ly,
                            keyX = kx, keyY = ky, keyOn = kok,
                            isTarget = (target == t.serverId),
                        }
                    end
                end
            end
            SendNUIMessage({ action = 'indicators', items = items })
            wasActive = true
            Wait(perfCfg.renderInterval)
        else
            if wasActive then
                SendNUIMessage({ action = 'indicators', items = {} })
                wasActive = false
            end
            Wait(200)
        end
    end
end)
