local config = require 'config.config_c'
local clientConfig = require 'config.client'
local interactionType = require('client.points').interactionType
local ringCoords
local inBoxingFight = false
local perRingCancelDistance = {}
local conditionalRingIndices = {}
lib.locale(require('config.config_c').language ~= 'auto' and require('config.config_c').language or nil)

local function getConditionalCancelDistance()
    if not ringCoords then return nil end
    for idx, ringCrds in ipairs(config.boxingRing.coords) do
        if #(ringCoords - vec3(ringCrds.x, ringCrds.y, ringCrds.z)) < 0.5 then
            if conditionalRingIndices[idx] then
                return perRingCancelDistance[idx] or config.boxingRing.cancelDistance or 6.0
            end
            return nil
        end
    end
    return nil
end

local function startFightThread()
    local cancelDist = getConditionalCancelDistance()

    CreateThread(function()
        while inBoxingFight do
            Wait(300)
            local ped = cache.ped
            if not ped or not DoesEntityExist(ped) then
                break
            end
            if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) then
                inBoxingFight = false
                TriggerServerEvent('gym:fighterDown')
                break
            end
            if cancelDist and ringCoords then
                local playerCoords = GetEntityCoords(ped)
                local dx = playerCoords.x - ringCoords.x
                local dy = playerCoords.y - ringCoords.y
                if (dx * dx + dy * dy) > cancelDist * cancelDist then
                    inBoxingFight = false
                    TriggerServerEvent('gym:fighterDown')
                    break
                end
            end
        end
    end)

    if cancelDist and config.boxingRing.showBoundary ~= false and ringCoords then
        CreateThread(function()
            local diameter = cancelDist * 2.0
            while inBoxingFight do
                DrawMarker(1, ringCoords.x, ringCoords.y, ringCoords.z - 0.5,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    diameter, diameter, 3.0,
                    255, 0, 0, 100,
                    false, false, 2, false, nil, nil, false)
                Wait(0)
            end
        end)
    end
end

function openRingUI(entityOrCoords)
    local coords
    if type(entityOrCoords) == 'vector3' then
        coords = entityOrCoords
    else
        coords = GetEntityCoords(entityOrCoords)
    end

    lib.print.debug(string.format("Player opening boxing ring UI at coords: %s", coords))

    local data, message = lib.callback.await('gym:getRingData', 500, coords)
    if not data then
        lib.print.warn(string.format("Failed to get ring data: %s", message or "unknown"))
        return clientConfig.notify(locale('error_title'), message or locale('error_unknown'), 'error')
    end

    ringCoords = coords
    lib.print.debug("Ring data retrieved successfully")
    SendNUIMessage({
        action = 'setRingData',
        data = data
    })
    SetNuiFocus(true, true)
end
exports('openRingUI', openRingUI)

local ringTextUiShown = false
local appliedConditionals = {}

local function canInteractWithRing(entity)
    local crds = GetEntityCoords(entity)
    for _, ringCrds in pairs(config.boxingRing.coords) do
        if #(crds - vec3(ringCrds.x, ringCrds.y, ringCrds.z)) < 0.5 then
            return true
        end
    end
    return false
end

local function createRingTextUIPoint(ringCrds)
    local modelHash = joaat(config.boxingRing.model)
    lib.points.new({
        coords = vec3(ringCrds.x, ringCrds.y, ringCrds.z),
        distance = 2.5,
        onEnter = function()
            if not ringTextUiShown then
                ringTextUiShown = true
                lib.showTextUI('[E] ' .. locale('ring_open'))
            end
        end,
        onExit = function()
            ringTextUiShown = false
            lib.hideTextUI()
        end,
        nearby = function(self)
            if IsControlJustReleased(0, 38) then
                local entity = GetClosestObjectOfType(self.coords.x, self.coords.y, self.coords.z, 3.0, modelHash, false, false, false)
                if entity ~= 0 then
                    openRingUI(entity)
                    lib.hideTextUI()
                    ringTextUiShown = false
                end
            elseif not ringTextUiShown then
                lib.showTextUI('[E] ' .. locale('ring_open'))
                ringTextUiShown = true
            end
        end,
    })
end

local function createConditionalRingZone(crds)
    local coords = vec3(crds.x, crds.y, crds.z)

    if interactionType == 'ox_target' then
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 2.0,
            options = {
                {
                    icon = 'fas fa-dumbbell',
                    label = locale('ring_open'),
                    onSelect = function()
                        openRingUI(coords)
                    end
                }
            }
        })
    elseif interactionType == 'qb_target' then
        exports['qb-target']:AddCircleZone('boxing_ring_' .. tostring(crds.x), coords, 2.0, {
            name = 'boxing_ring_' .. tostring(crds.x),
            useZ = true,
            debugPoly = false,
        }, {
            options = {
                {
                    icon = 'fas fa-dumbbell',
                    label = locale('ring_open'),
                    action = function()
                        openRingUI(coords)
                    end
                }
            },
            distance = 2.0,
        })
    elseif interactionType == 'textUI' then
        lib.points.new({
            coords = coords,
            distance = 2.5,
            onEnter = function()
                if not ringTextUiShown then
                    ringTextUiShown = true
                    lib.showTextUI('[E] ' .. locale('ring_open'))
                end
            end,
            onExit = function()
                ringTextUiShown = false
                lib.hideTextUI()
            end,
            nearby = function()
                if IsControlJustReleased(0, 38) then
                    openRingUI(coords)
                    lib.hideTextUI()
                    ringTextUiShown = false
                elseif not ringTextUiShown then
                    lib.showTextUI('[E] ' .. locale('ring_open'))
                    ringTextUiShown = true
                end
            end,
        })
    end
end

local function applyConditionalCoord(i, entry)
    if appliedConditionals[i] then return end
    appliedConditionals[i] = true
    local idx = #config.boxingRing.coords + 1
    table.insert(config.boxingRing.coords, entry.coords)
    if entry.cancelDistance then
        perRingCancelDistance[idx] = entry.cancelDistance
    end
    conditionalRingIndices[idx] = true
    createConditionalRingZone(entry.coords)
end

if config.boxingRing.conditionalCoords then
    for i, entry in ipairs(config.boxingRing.conditionalCoords) do
        for _, res in ipairs(entry.resources) do
            if GetResourceState(res) == 'started' then
                applyConditionalCoord(i, entry)
                break
            end
        end
    end
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if not config.boxingRing.conditionalCoords then return end
    for i, entry in ipairs(config.boxingRing.conditionalCoords) do
        if not appliedConditionals[i] then
            for _, res in ipairs(entry.resources) do
                if res == resourceName then
                    applyConditionalCoord(i, entry)
                    break
                end
            end
        end
    end
end)

if interactionType == 'ox_target' then
    exports.ox_target:addModel(config.boxingRing.model, {
        {
            icon = 'fas fa-dumbbell',
            label = locale('ring_open'),
            onSelect = function(data)
                openRingUI(data.entity)
            end,
            canInteract = canInteractWithRing
        },
    })
elseif interactionType == 'qb_target' then
    exports['qb-target']:AddTargetModel(config.boxingRing.model, {
        options = {
            {
                icon = 'fas fa-dumbbell',
                label = locale('ring_open'),
                action = function(entity)
                    openRingUI(entity)
                end,
                canInteract = canInteractWithRing
            },
        },
        distance = 2.0,
    })
elseif interactionType == 'textUI' then
    for _, ringCrds in pairs(config.boxingRing.coords) do
        createRingTextUIPoint(ringCrds)
    end
elseif interactionType == 'custom' then
    lib.print.warn("Boxing ring does not support 'custom' interaction mode - use ox_target, qb_target, or textUI")
end

RegisterNUICallback('closeRingUI', function()
    TriggerServerEvent('gym:closeRing')
    SetNuiFocus(false, false)
end)

RegisterNUICallback('ringReady', function(_, cb)
    local response = lib.callback.await('gym:ringReady', 300)
    cb(response)
end)

RegisterNUICallback('ringLeave', function(_, cb)
    local response = lib.callback.await('gym:ringLeave', 300)
    cb(response)
end)

RegisterNUICallback('ringJoin', function(_, cb)
    local response = lib.callback.await('gym:ringJoin', 300)
    cb(response)
end)

RegisterNetEvent('gym:updateRingData', function(data)
    SendNUIMessage({
        action = 'setRingData',
        data = data
    })
    if not data then
        SetNuiFocus(false, false)
    end
end)

RegisterNetEvent('gym:startFight', function(data)
    lib.print.info("Starting boxing fight - teleporting player to ring")

    local coords = data.coords
    local heading = data.heading
    SetNuiFocus(false, false)

    DoScreenFadeOut(500)
    Wait(500)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    SetEntityCoordsNoOffset(cache.ped, coords.x, coords.y, coords.z, 0, 0, 0, false)
    SetEntityHeading(cache.ped, heading)
    lib.playAnim(cache.ped, 'anim@deathmatch_intros@unarmed', 'intro_male_unarmed_e')
    SetTimeout(4000, function()
        StopAnimTask(cache.ped, 'anim@deathmatch_intros@unarmed', 'intro_male_unarmed_e', 1.0)
    end)
    Wait(500)
    DoScreenFadeIn(500)
    inBoxingFight = true
    startFightThread()
    if clientConfig.boxingRing.onFightStart then
        pcall(clientConfig.boxingRing.onFightStart)
    end
end)

RegisterNetEvent('gym:endFight', function(coords, health)
    lib.print.info("Ending boxing fight - returning player to original position")
    inBoxingFight = false
    if health then
        SetEntityHealth(cache.ped, health)
    end

    ringCoords = nil
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoordsNoOffset(cache.ped, coords.x, coords.y, coords.z, 0, 0, 0, false)
    Wait(500)
    DoScreenFadeIn(500)
end)

function playRingAudio(name)
    local ok = pcall(lib.requestAudioBank, 'audiodirectory/prompt_gym')
    if not ok then
        lib.print.warn('Failed to load audio bank audiodirectory/prompt_gym - skipping sound: ' .. name)
        return
    end
    local soundId = GetSoundId()
    if ringCoords then
        PlaySoundFromCoord(soundId, name, ringCoords.x, ringCoords.y, ringCoords.z, 'prompt_gym', false, 15.0, 0)
    else
        PlaySoundFromEntity(soundId, name, cache.ped, 'prompt_gym', false, 0)
    end
    CreateThread(function()
        while not HasSoundFinished(soundId) do
            Wait(0)
        end
        ReleaseSoundId(soundId)
    end)
end
RegisterNetEvent('gym:updateFightUI', function(data)
    SendNUIMessage({
        action = 'setRingFightData',
        data = data
    })
    if data and data.state == 'fighting' then
        CreateThread(function() playRingAudio('start') end)
    end
    if data and (data.state == 'winner' or data.state == 'draw' or data.state == 'loser') then
        CreateThread(function()
            if data.state == 'winner' then
                playRingAudio('victory')
            else
                playRingAudio('defeat')
            end
        end)
        if clientConfig.boxingRing.onFightEnd then
            pcall(clientConfig.boxingRing.onFightEnd, data.state)
        end
        SetTimeout(5000, function()
            SendNUIMessage({
                action = 'setRingFightData',
                data = false
            })
        end)
    end
end)

AddStateBagChangeHandler('isBoxingRingBorder', nil, function(bagName, key, value)
    local entityId = GetEntityFromStateBagName(bagName)
    if not entityId then return end

    SetEntityVisible(entityId, false, 0)
end)