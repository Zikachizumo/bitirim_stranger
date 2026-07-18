--[[
    client/modules/proximity.lua
    ----------------------------
    Adaptive nearby-player scanner. This is the ONLY loop that iterates players;
    everything else (indicator, interaction) reads its cached results.

    Adaptive tick:
        someone within indicatorDistance -> scanIntervalNear (fast)
        players around but out of range   -> scanIntervalMid
        nobody nearby                      -> scanIntervalIdle (relax)

    Exposes:
        Bitirim.Proximity.tracked  -> array { serverId, ped, dist } (sorted, capped)
        Bitirim.Proximity.target   -> serverId of the current interaction target
]]

local Utils = Bitirim.Utils
local Cfg = Bitirim.Config

local Proximity = {}
Proximity.tracked = {}
Proximity.target = nil

local interactCfg = Cfg.interaction
local perfCfg = Cfg.performance

--- Is a candidate ped a valid interaction target right now?
local function isValidTarget(myPed, ped, dist)
    if dist > interactCfg.targetDistance then return false end
    if interactCfg.onFootOnly and IsPedInAnyVehicle(ped, false) then return false end
    if interactCfg.requireLineOfSight and not HasEntityClearLosToEntity(myPed, ped, 17) then
        return false
    end
    return true
end

local function scan()
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local players = GetActivePlayers()

    local found = {}
    local anyMid = false
    local bestTarget, bestTargetDist = nil, math.huge

    for i = 1, #players do
        local pIndex = players[i]
        local ped = GetPlayerPed(pIndex)
        if ped ~= myPed and DoesEntityExist(ped) then
            local dist = #(myCoords - GetEntityCoords(ped))
            if dist <= interactCfg.indicatorDistance then
                local serverId = GetPlayerServerId(pIndex)
                found[#found + 1] = { serverId = serverId, ped = ped, dist = dist }
                -- Track nearest valid interaction target.
                if dist < bestTargetDist and isValidTarget(myPed, ped, dist) then
                    bestTarget, bestTargetDist = serverId, dist
                end
            elseif dist <= interactCfg.indicatorDistance * 3 then
                anyMid = true
            end
        end
    end

    -- Sort nearest-first and cap to the configured maximum.
    table.sort(found, function(a, b) return a.dist < b.dist end)
    for i = #found, perfCfg.maxTrackedPlayers + 1, -1 do
        found[i] = nil
    end

    Proximity.tracked = found
    Proximity.target = bestTarget

    -- Choose the next wait based on activity.
    if #found > 0 then
        return perfCfg.scanIntervalNear
    elseif anyMid then
        return perfCfg.scanIntervalMid
    end
    return perfCfg.scanIntervalIdle
end

CreateThread(function()
    while true do
        local wait = perfCfg.scanIntervalIdle
        -- Only scan when the character is actually in the world & logged in.
        if LocalPlayer.state.isLoggedIn then
            local ok, result = pcall(scan)
            if ok and result then wait = result end
        else
            Proximity.tracked = {}
            Proximity.target = nil
        end
        Wait(wait)
    end
end)

Bitirim.Proximity = Proximity
