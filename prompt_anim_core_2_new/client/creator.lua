local config = require 'config.config_c'
local client = require 'config.client'
local creatorOpened = false
local placedEntity
local creatorData = {}

CreateThread(function()
    local machineOptions = {}
    for machine, data in pairs(config.props) do
        local label = locale('machine_' .. machine)
        table.insert(machineOptions, {
            title = label:sub(1, 1):upper() .. label:sub(2),
            description = machine,
            icon = 'dumbbell',
            onSelect = function()
                placeObject(data.model, label, machine)
                createDebugMenu()
                lib.showContext('gym_creator')
            end,
        })
    end
    table.sort(machineOptions, function(a, b)
        return a.title < b.title
    end)
    lib.registerContext({
        id = 'gym_add_machine_point',
        title = 'Add Machine Point',
        options = machineOptions
    })
end)

function createDebugMenu()
    local sconfig = require 'config.config_s'
    local options = {
        {
            title = 'Add new machine point',
            icon = 'plus',
            menu = 'gym_add_machine_point',
        }
    }

    -- Groups system button (if enabled)
    if sconfig.groups and sconfig.groups.enable then
        table.insert(options, {
            title = 'Manage Groups',
            description = 'Create, edit, load/unload prop groups',
            icon = 'layer-group',
            iconColor = '#00aaff',
            onSelect = function()
                creatorOpened = false
                TriggerEvent('gym_group:openMenu')
            end,
        })
    end
    for _, data in pairs(creatorData) do
        table.insert(options, {
            title = data.label:sub(1, 1):upper() .. data.label:sub(2),
            description = 'Click to remove ',
            icon = 'trash',
            onSelect = function()
                if DoesEntityExist(data.entity) then
                    DeleteEntity(data.entity)
                end
                if data.barEntity and DoesEntityExist(data.barEntity) then
                    DeleteEntity(data.barEntity)
                end
                for i, d in pairs(creatorData) do
                    if d == data then
                        table.remove(creatorData, i)
                        break
                    end
                end
                createDebugMenu()
                lib.showContext('gym_creator')
            end,
        })
    end
    table.insert(options, {
        title = '-----------------------------',
        readOnly = true,
    })
    table.insert(options, {
        title = 'Close',
        icon = 'times',
        description = 'Close the creator menu',
        onSelect = function()
            resetDebug()
            lib.hideContext()
        end,
    })
    table.insert(options, {
        title = 'Save',
        icon = 'save',
        description = 'Save current machine points',
        disabled = #creatorData == 0,
        onSelect = function()
            local saveData = {}
            for _, data in pairs(creatorData) do
                local coords = data.coords
                if type(coords) == 'table' and coords.barEntity then
                    coords = {
                        coords = coords.coords,
                        bar = coords.bar
                    }
                end
                table.insert(saveData, {
                    model = data.model,
                    coords = coords,
                    machine = data.machine,
                })
            end
            local input = lib.inputDialog('Save Gym Location', {
                {type = 'input', label = 'Location Name', required = true},
            })
            if not input or not input[1] then
                lib.print.warn("Save cancelled - no input provided")
                return
            end
            local success = lib.callback.await('gym:saveCreatorData', false, saveData, input[1])
            if success then
                client.notify('Success', 'Gym location saved successfully!', 'success')
            else
                client.notify('Error', 'Failed to save gym location!', 'error')
            end
            resetDebug()
            lib.hideContext()
        end,
    })
    lib.registerContext({
        id = 'gym_creator',
        title = 'Gym Creator',
        onExit = function()
            resetDebug()
        end,
        options = options
    })
end

function placeObject(model, label, machine)
    lib.print.debug(string.format("Starting object placement for machine: %s", machine))

    local hash = type(model) == 'string' and joaat(model) or model
    lib.requestModel(hash)
    placedEntity = true

    local heading = GetEntityHeading(cache.ped)
    local hit, coords

    CreateThread(function()
        while placedEntity do
            local hitt, _, coordss = lib.raycast.fromCamera(511, 4, 30.0)
            hit = hitt
            coords = coordss
            Wait(1)
        end
    end)

    lib.showTextUI('[Scroll] Rotate  \n[Enter] Place  \n[Backspace] Cancel')
    while placedEntity do
        Wait(0)
        SetPauseMenuActive(false)
        DisableControlAction(0, 15, true)
        DisableControlAction(0, 14, true)
        if hit and coords then
            if not placedEntity or type(placedEntity) == 'boolean' then
                placedEntity = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
                SetEntityAlpha(placedEntity, 150, false)
                FreezeEntityPosition(placedEntity, true)
                SetEntityHeading(placedEntity, heading)
                SetEntityCollision(placedEntity, false, true)
                SetEntityDrawOutline(placedEntity, true)
            else
                SetEntityCoordsNoOffset(placedEntity, coords.x, coords.y, coords.z, false, false, false)
                SetEntityHeading(placedEntity, heading)
            end
            PlaceObjectOnGroundProperly(placedEntity)

            if IsDisabledControlPressed(0, 15) then
                heading = heading + 5.0
            elseif IsDisabledControlPressed(0, 14) then
                heading = heading - 5.0
            elseif IsControlJustPressed(0, 191) then
                local objCoords = GetEntityCoords(placedEntity)
                local objHeading = GetEntityHeading(placedEntity)

                lib.print.debug(string.format("Placed %s at %.2f, %.2f, %.2f, heading: %.2f", 
                    machine, objCoords.x, objCoords.y, objCoords.z, objHeading))

                local benchCoords = nil
                if machine == 'bench' then
                    local barModel = config.props.bench.playerAnimation.prop.model
                    local barHash = type(barModel) == 'string' and joaat(barModel) or barModel
                    lib.requestModel(barHash)

                    local barEntity = CreateObjectNoOffset(barHash, objCoords.x, objCoords.y, objCoords.z + 1.0, false, false, false)
                    SetEntityAlpha(barEntity, 150, false)
                    FreezeEntityPosition(barEntity, true)
                    SetEntityHeading(barEntity, objHeading)
                    SetEntityCollision(barEntity, false, true)
                    SetEntityDrawOutline(barEntity, true)

                    local barHeading = objHeading
                    local barPlaced = false

                    lib.showTextUI('[Scroll] Rotate  \n[Enter] Place Bar  \n[Backspace] Cancel')
                    while not barPlaced do
                        Wait(0)
                        SetPauseMenuActive(false)
                        local barHit, _, barCoords = lib.raycast.fromCamera(511, 4, 30.0)

                        if barHit and barCoords then
                            SetEntityCoordsNoOffset(barEntity, barCoords.x, barCoords.y, barCoords.z, false, false, false)
                            SetEntityHeading(barEntity, barHeading)
                            PlaceObjectOnGroundProperly(barEntity)

                            if IsControlPressed(0, 15) then
                                barHeading = barHeading + 5.0
                            elseif IsControlPressed(0, 14) then
                                barHeading = barHeading - 5.0
                            elseif IsControlJustPressed(0, 191) then
                                local barFinalCoords = GetEntityCoords(barEntity)
                                local barFinalHeading = GetEntityHeading(barEntity)
                                benchCoords = {
                                    coords = {
                                        x = objCoords.x,
                                        y = objCoords.y,
                                        z = objCoords.z,
                                        w = objHeading,
                                    },
                                    bar = {
                                        x = barFinalCoords.x,
                                        y = barFinalCoords.y,
                                        z = barFinalCoords.z,
                                        w = barFinalHeading,
                                    },
                                    barEntity = barEntity
                                }
                                SetEntityAlpha(barEntity, 255, false)
                                SetEntityCollision(barEntity, true, true)
                                SetEntityDrawOutline(barEntity, false)
                                barPlaced = true
                            elseif IsControlJustPressed(0, 177) then
                                DeleteEntity(barEntity)
                                barPlaced = true
                                benchCoords = nil
                            end
                        end
                    end
                    lib.hideTextUI()
                    SetModelAsNoLongerNeeded(barHash)
                end

                creatorData[#creatorData + 1] = {
                    model = model,
                    machine = machine,
                    coords = benchCoords or {
                        x = objCoords.x,
                        y = objCoords.y,
                        z = objCoords.z,
                        w = objHeading,
                    },
                    entity = placedEntity,
                    barEntity = benchCoords and benchCoords.barEntity or nil,
                    label = label,
                }
                SetEntityAlpha(placedEntity, 255, false)
                SetEntityCollision(placedEntity, true, true)
                SetEntityDrawOutline(placedEntity, false)
                placedEntity = nil
            elseif IsControlJustPressed(0, 177) then
                DeleteEntity(placedEntity)
                placedEntity = nil
            end

        end
    end
    lib.hideTextUI()
    SetModelAsNoLongerNeeded(hash)
    lib.showContext('gym_creator')
end

function resetDebug()
    if placedEntity and DoesEntityExist(placedEntity) then
        DeleteEntity(placedEntity)
    end
    for _, data in pairs(creatorData) do
        if DoesEntityExist(data.entity) then
            DeleteEntity(data.entity)
        end
        if data.barEntity and DoesEntityExist(data.barEntity) then
            DeleteEntity(data.barEntity)
        end
    end
    creatorData = {}
    placedEntity = nil
    creatorOpened = false
end

RegisterNetEvent('gym:openCreator', function()
    if creatorOpened then
        lib.print.warn("Creator already opened")
        return
    end

    lib.print.info("Opening gym creator menu")
    creatorOpened = true

    createDebugMenu()
    lib.showContext('gym_creator')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        resetDebug()
    end
end)