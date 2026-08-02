local config = require 'config.config_c'
local editable = require 'config.server'
lib.locale(require('config.config_c').language ~= 'auto' and require('config.config_c').language or nil)
local rings = {}

local appliedServerConditionals = {}
local conditionalRingIndices = {}

if config.boxingRing.conditionalCoords then
    for i, entry in ipairs(config.boxingRing.conditionalCoords) do
        for _, res in ipairs(entry.resources) do
            if GetResourceState(res) == 'started' then
                appliedServerConditionals[i] = true
                local idx = #config.boxingRing.coords + 1
                table.insert(config.boxingRing.coords, entry.coords)
                conditionalRingIndices[idx] = true
                break
            end
        end
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if not config.boxingRing.conditionalCoords then return end
    for i, entry in ipairs(config.boxingRing.conditionalCoords) do
        if not appliedServerConditionals[i] then
            for _, res in ipairs(entry.resources) do
                if res == resourceName then
                    appliedServerConditionals[i] = true
                    local idx = #config.boxingRing.coords + 1
                    table.insert(config.boxingRing.coords, entry.coords)
                    conditionalRingIndices[idx] = true
                    lib.print.info(string.format("Boxing ring enabled at conditional location (resource: %s)", resourceName))
                    break
                end
            end
        end
    end
end)

local offsets = {
    player1 = vec4(-1.33, 1.89, -0.14, 224.0),
    player2 = vec4(2.27, -1.82, -0.14, 42.64),
}

local fightTimers = {}

local function getRingBySource(source)
    for _, data in pairs(rings) do
        if (data.player1 and data.player1.source == source) or (data.player2 and data.player2.source == source) or lib.table.contains(data.openedBy, source) then
            return data
        end
    end
end

local function clearFightTimer(ringIndex)
    if fightTimers[ringIndex] then
        if fightTimers[ringIndex].timer then
            ClearTimeout(fightTimers[ringIndex].timer)
        end
        fightTimers[ringIndex] = nil
    end
end

local function endFight(ringData, reason)
    if not ringData or not ringData.index then
        lib.print.warn("Attempted to end fight with invalid ring data")
        return
    end

    lib.print.debug(string.format("Ending fight in ring %d - reason: %s", ringData.index, reason or "unknown"))

    clearFightTimer(ringData.index)

    ringData.fightInProgress = false
    ringData.currentRound = nil
    if ringData.border and DoesEntityExist(ringData.border) then
        DeleteEntity(ringData.border)
        ringData.border = nil
    end

    if editable.boxingRing.onFightEnd then
        editable.boxingRing.onFightEnd(
            ringData.player1,
            ringData.player2,
            reason
        )
    end

    if ringData.player1 and ringData.player1.savedCoords then
        local ped1 = GetPlayerPed(ringData.player1.source)
        if ringData.player1.savedArmor then
            SetPedArmour(ped1, ringData.player1.savedArmor)
        end
        TriggerClientEvent('gym:endFight', ringData.player1.source, ringData.player1.savedCoords, ringData.player1.savedHealth)
    end

    if ringData.player2 and ringData.player2.savedCoords then
        local ped2 = GetPlayerPed(ringData.player2.source)
        if ringData.player2.savedArmor then
            SetPedArmour(ped2, ringData.player2.savedArmor)
        end
        TriggerClientEvent('gym:endFight', ringData.player2.source, ringData.player2.savedCoords, ringData.player2.savedHealth)
    end

    ringData.player1 = nil
    ringData.player2 = nil
end

local function updateFightUI(ringData, state, countdown, winnerSource)
    if not ringData or not ringData.player1 or not ringData.player2 then
        return
    end

    local player1Data = {
        state = state,
        countdown = countdown,
        timeRemaining = ringData.timeRemaining or 0
    }
    local player2Data = {
        state = state,
        countdown = countdown,
        timeRemaining = ringData.timeRemaining or 0
    }

    if state == 'winner' or state == 'loser' then
        if winnerSource == ringData.player1.source then
            player1Data.state = 'winner'
            player1Data.winnerName = ringData.player1.name
            player2Data.state = 'loser'
            player2Data.winnerName = ringData.player1.name
        elseif winnerSource == ringData.player2.source then
            player1Data.state = 'loser'
            player1Data.winnerName = ringData.player2.name
            player2Data.state = 'winner'
            player2Data.winnerName = ringData.player2.name
        end
    elseif state == 'draw' then
        player1Data.state = 'draw'
        player2Data.state = 'draw'
    end

    TriggerClientEvent('gym:updateFightUI', ringData.player1.source, player1Data)
    TriggerClientEvent('gym:updateFightUI', ringData.player2.source, player2Data)
end

-- Fighters report "I'm down" from their client (reliable). We just track the 2 players:
-- when one says they died, the other wins. No server-side ped/health checks needed.
local function monitorFighterHealth(_ringData)
    -- No-op: death is handled by client TriggerServerEvent('gym:fighterDown')
end

local function startRound(ringData, roundNumber)
    if not ringData or not ringData.player1 or not ringData.player2 then
        lib.print.error("Cannot start round - invalid ring data")
        return
    end

    lib.print.debug(string.format("Starting round %d in ring %d", roundNumber, ringData.index))

    ringData.currentRound = roundNumber
    ringData.timeRemaining = config.boxingRing.roundDuration

    editable.boxingRing.onFightStart(
        ringData.player1,
        ringData.player2
    )

    local ped1 = GetPlayerPed(ringData.player1.source)
    local ped2 = GetPlayerPed(ringData.player2.source)
    FreezeEntityPosition(ped1, true)
    FreezeEntityPosition(ped2, true)

    for i = 3, 1, -1 do
        SetTimeout((4 - i) * 1000, function()
            if ringData and ringData.fightInProgress then
                updateFightUI(ringData, 'countdown', i)
            end
        end)
    end

    SetTimeout(4000, function()
        if ringData and ringData.fightInProgress then
            FreezeEntityPosition(ped1, false)
            FreezeEntityPosition(ped2, false)
            updateFightUI(ringData, 'fighting', nil)
            monitorFighterHealth(ringData)

            local function roundTick()
                if not ringData or not ringData.fightInProgress then
                    return
                end

                ringData.timeRemaining = ringData.timeRemaining - 1

                if ringData.timeRemaining <= 0 then
                    updateFightUI(ringData, 'draw')
                    SetTimeout(2000, function()
                        endFight(ringData, 'Draw - Time expired!')
                    end)
                else
                    fightTimers[ringData.index].timer = SetTimeout(1000, roundTick)
                end
            end

            fightTimers[ringData.index] = { timer = SetTimeout(1000, roundTick) }
        end
    end)
end

local function startFight(ringData)
    if not ringData.player1 or not ringData.player2 or not ringData.index then
        lib.print.error("Cannot start fight - invalid ring data")
        return
    end

    lib.print.info(string.format("Starting fight in ring %d between %s and %s", 
        ringData.index, ringData.player1.name, ringData.player2.name))

    local ringCoords = config.boxingRing.coords[ringData.index]
    if not ringCoords then
        return
    end

    local ped1 = GetPlayerPed(ringData.player1.source)
    local ped2 = GetPlayerPed(ringData.player2.source)

    ringData.player1.savedCoords = GetEntityCoords(ped1)
    ringData.player1.savedHealth = GetEntityHealth(ped1)
    ringData.player1.savedArmor = GetPedArmour(ped1)

    ringData.player2.savedCoords = GetEntityCoords(ped2)
    ringData.player2.savedHealth = GetEntityHealth(ped2)
    ringData.player2.savedArmor = GetPedArmour(ped2)

    local base = vec3(ringCoords.x, ringCoords.y, ringCoords.z)
    if not conditionalRingIndices[ringData.index] then
        ringData.border = CreateObject(joaat('vision_gymboxingring_border'), base.x, base.y, base.z, true, false, false)
        if ringData.border and ringData.border ~= 0 then
            SetEntityHeading(ringData.border, ringCoords.w)
            local ok, err = pcall(function()
                lib.waitFor(function()
                    return DoesEntityExist(ringData.border) or nil
                end, 'Failed to create ring collisions', 5000)
            end)
            if not ok then
                lib.print.warn(string.format("Ring %d: could not create border collisions - fight continues without them. %s", ringData.index, err or ""))
                ringData.border = nil
            elseif ringData.border and DoesEntityExist(ringData.border) then
                pcall(function()
                    Entity(ringData.border).state:set('isBoxingRingBorder', true, true)
                end)
            end
        else
            ringData.border = nil
        end
    end

    local rad = math.rad(ringCoords.w)
    local cos = math.cos(rad)
    local sin = math.sin(rad)

    local p1x = offsets.player1.x * cos - offsets.player1.y * sin
    local p1y = offsets.player1.x * sin + offsets.player1.y * cos
    local p1heading = (offsets.player1.w + ringCoords.w) % 360

    local p2x = offsets.player2.x * cos - offsets.player2.y * sin
    local p2y = offsets.player2.x * sin + offsets.player2.y * cos
    local p2heading = (offsets.player2.w + ringCoords.w) % 360

    TriggerClientEvent('gym:startFight', ringData.player1.source, {
        coords = base + vec3(p1x, p1y, offsets.player1.z),
        heading = p1heading,
        ringCoords = ringCoords
    })
    TriggerClientEvent('gym:startFight', ringData.player2.source, {
        coords = base + vec3(p2x, p2y, offsets.player2.z),
        heading = p2heading,
        ringCoords = ringCoords
    })

    for _, src in pairs(ringData.openedBy) do
        TriggerClientEvent('gym:updateRingData', src, nil)
    end
    ringData.openedBy = {}

    SetTimeout(1000, function()
        if ringData and ringData.fightInProgress then
            startRound(ringData, 1)
        end
    end)
end

local function updateRingForAll(ringData)
    for _, src in pairs(ringData.openedBy) do
        local ringDataToSend = {
            player1 = ringData.player1 and {
                source = ringData.player1.source,
                name = ringData.player1.name,
                ready = ringData.player1.ready,
            } or nil,
            player2 = ringData.player2 and {
                source = ringData.player2.source,
                name = ringData.player2.name,
                ready = ringData.player2.ready,
            } or nil,
        }

        if ringData.player1 and ringData.player1.source == src then
            ringDataToSend.player1.isMe = true
        end

        if ringData.player2 and ringData.player2.source == src then
            ringDataToSend.player2.isMe = true
        end

        TriggerClientEvent('gym:updateRingData', src, ringDataToSend)
    end
end

RegisterNetEvent('gym:closeRing', function()
    local source = source
    local ringData = getRingBySource(source)
    if not ringData then
        return
    end

    for i, src in pairs(ringData.openedBy) do
        if src == source then
            table.remove(ringData.openedBy, i)
            break
        end
    end
end)

lib.callback.register('gym:getRingData', function(source, coords)
    lib.print.debug(string.format("Player %d requesting ring data at coords: %s", source, coords))

    local ringIndex
    for i, ring in pairs(config.boxingRing.coords) do
        if #(coords - vec3(ring.x, ring.y, ring.z)) < 0.5 then
            ringIndex = i
            break
        end
    end

    if not ringIndex then
        lib.print.warn(string.format("Player %d tried to access non-existent ring", source))
        return false, locale('error_ring_not_found')
    end

    if not rings[ringIndex] then
        lib.print.debug(string.format("Creating new ring instance %d", ringIndex))
        rings[ringIndex] = {
            index = ringIndex,
            openedBy = {}
        }
    elseif rings[ringIndex].fightInProgress then
        lib.print.debug(string.format("Ring %d is already in use", ringIndex))
        return false, locale('error_ring_in_use')
    end

    table.insert(rings[ringIndex].openedBy, source)

    return rings[ringIndex]
end)

lib.callback.register('gym:ringReady', function(source)
    local ringData = getRingBySource(source)
    if not ringData then
        return false
    end

    if ringData.player1 and ringData.player1.source == source then
        ringData.player1.ready = not ringData.player1.ready
    elseif ringData.player2 and ringData.player2.source == source then
        ringData.player2.ready = not ringData.player2.ready
    else
        return false
    end

    if ringData.player1 and ringData.player2 and ringData.player1.ready and ringData.player2.ready then
        ringData.fightInProgress = true
        startFight(ringData)
        return true
    end

    updateRingForAll(ringData)

    return true
end)

lib.callback.register('gym:ringLeave', function(source)
    local ringData = getRingBySource(source)
    if not ringData then
        return false
    end

    if ringData.player1 and ringData.player1.source == source then
        ringData.player1 = nil
    elseif ringData.player2 and ringData.player2.source == source then
        ringData.player2 = nil
    else
        return false
    end

    updateRingForAll(ringData)

    return true
end)

lib.callback.register('gym:ringJoin', function(source)
    local ringData = getRingBySource(source)
    if not ringData then
        return false
    end

    if not ringData.player1 then
        ringData.player1 = {
            source = source,
            name = editable.getPlayerName(source),
            ready = false,
        }
    elseif not ringData.player2 then
        ringData.player2 = {
            source = source,
            name = editable.getPlayerName(source),
            ready = false,
        }
    else
        return false
    end

    updateRingForAll(ringData)

    return true
end)

-- Shared: any source says this fighter is down (client report, ev-medical, baseevents). Other wins.
local function onFighterDown(victimSource)
    local ringData = getRingBySource(victimSource)
    if not ringData or not ringData.fightInProgress or not ringData.player1 or not ringData.player2 then
        return
    end
    local winner = (ringData.player1.source == victimSource) and ringData.player2 or ringData.player1
    lib.print.info(string.format("Fighter %d down in ring %d - winner: %d", victimSource, ringData.index, winner.source))
    updateFightUI(ringData, 'winner', nil, winner.source)
    SetTimeout(2000, function()
        if ringData.fightInProgress then
            endFight(ringData, 'Knockout!')
        end
    end)
end

-- 1) Client tracks own ped and reports when dead/dying (works everywhere).
RegisterNetEvent('gym:fighterDown', function()
    onFighterDown(source)
end)

-- 2) ev-medical: servers that use this resource get knockout from it.
RegisterNetEvent('ev-medical:server:onPlayerDied', function()
    onFighterDown(source)
end)

-- 3) baseevents: standard FiveM death (IsPedFatallyInjured on client).
AddEventHandler('baseevents:onPlayerDied', function(_, _pos)
    onFighterDown(source)
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local ringData = getRingBySource(source)
    if not ringData then
        return
    end

    if ringData.fightInProgress then
        local winner, loser
        if ringData.player1 and ringData.player1.source == source then
            winner = ringData.player2
            loser = ringData.player1
        elseif ringData.player2 and ringData.player2.source == source then
            winner = ringData.player1
            loser = ringData.player2
        end

        if winner and loser then
            updateFightUI(ringData, 'winner', nil, winner.source)
            SetTimeout(2000, function()
                endFight(ringData, 'Opponent disconnected!')
            end)
        else
            endFight(ringData, 'Opponent disconnected!')
        end
    else
        if ringData.player1 and ringData.player1.source == source then
            ringData.player1 = nil
        elseif ringData.player2 and ringData.player2.source == source then
            ringData.player2 = nil
        end

        for i, src in pairs(ringData.openedBy) do
            if src == source then
                table.remove(ringData.openedBy, i)
                break
            end
        end

        updateRingForAll(ringData)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        for _, ringData in pairs(rings) do
            if ringData.border and DoesEntityExist(ringData.border) then
                DeleteEntity(ringData.border)
                ringData.border = nil
            end
        end
    end
end)