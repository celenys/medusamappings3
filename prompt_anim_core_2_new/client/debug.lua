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
    local options = {
        {
            title = 'Add new machine point',
            icon = 'plus',
            menu = 'gym_add_machine_point',
        }
    }
    for _, data in pairs(creatorData) do
        table.insert(options, {
            title = data.label:sub(1, 1):upper() .. data.label:sub(2),
            description = 'Click to remove ',
            icon = 'trash',
            onSelect = function()
                if DoesEntityExist(data.entity) then
                    DeleteEntity(data.entity)
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
                table.insert(saveData, {
                    model = data.model,
                    coords = data.coords,
                    machine = data.machine,
                })
            end
            local success = lib.callback.await('gym:saveCreatorData', false, saveData)
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

            if IsControlPressed(0, 15) then -- scroll up
                heading = heading + 5.0
            elseif IsControlPressed(0, 14) then -- scroll down
                heading = heading - 5.0
            elseif IsControlJustPressed(0, 191) then
                local objCoords = GetEntityCoords(placedEntity)
                local objHeading = GetEntityHeading(placedEntity)
                
                lib.print.debug(string.format("Placed %s at %.2f, %.2f, %.2f, heading: %.2f", 
                    machine, objCoords.x, objCoords.y, objCoords.z, objHeading))
                
                creatorData[#creatorData + 1] = {
                    model = model,
                    machine = machine,
                    coords = {
                        x = objCoords.x,
                        y = objCoords.y,
                        z = objCoords.z,
                        w = objHeading,
                    },
                    entity = placedEntity,
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