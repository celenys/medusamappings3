local config = require 'config.config_c'
local state = require 'client.state'
local client = require 'config.client'
lib.locale(config.language ~= 'auto' and config.language or nil)
local showedTextUiInteraction = false
local textUiPoints = {}

---@type table<string, table>
local locationPoints = {}

local interactionType

if config.interaction == 'auto' then
    if GetResourceState('ox_target') == 'started' then
        interactionType = 'ox_target'
    elseif GetResourceState('qb-target') == 'started' then
        interactionType = 'qb_target'
    else
        interactionType = 'textUI'
    end
elseif config.interaction == 'ox_target' then
    if GetResourceState('ox_target') ~= 'started' then
        lib.print.error('ox_target is not started but is set as target system in config!')
    end
    interactionType = 'ox_target'
elseif config.interaction == 'qb_target' then
    if GetResourceState('qb-target') ~= 'started' then
        lib.print.error('qb-target is not started but is set as target system in config!')
    end
    interactionType = 'qb_target'
elseif config.interaction == 'custom' then
    interactionType = 'custom'
else
    interactionType = 'textUI'
end

---@param coords vector3 Blip coordinates
---@param locationName string Location name for blip label
---@return number? blip The created blip handle or nil if blips are disabled
local function createBlip(coords, locationName)
    if not config.blip or not config.blip.enable then
        return nil
    end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, config.blip.sprite or 311)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, config.blip.scale or 0.7)
    SetBlipColour(blip, config.blip.color or 2)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(config.blip.label or 'Gym')
    EndTextCommandSetBlipName(blip)

    lib.print.debug(string.format("Created blip for location: %s", locationName or "unknown"))

    return blip
end

---@param blip number? Blip handle to remove
local function removeBlip(blip)
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
        lib.print.debug("Removed blip")
    end
end

---@param object string Equipment type
---@param coordsData table Array of coordinates (vector4 or table with coords/bar)
---@return table normalizedCoords Array of vector4 coordinates
---@return table? barCoords Array of vector4 bar coordinates (only for bench)
local function normalizeEquipmentCoords(object, coordsData)
    local normalizedCoords = {}
    local barCoords = nil

    if object == 'bench' then
        barCoords = {}
        for _, data in pairs(coordsData) do
            if type(data) == 'vector4' then
                table.insert(normalizedCoords, data)
            elseif type(data) == 'table' and data.coords then
                table.insert(normalizedCoords, data.coords)
                if data.bar then
                    table.insert(barCoords, data.bar)
                end
            end
        end
    else
        normalizedCoords = coordsData
    end
    
    return normalizedCoords, barCoords
end

---@param entity number
---@param object string
local function useMachine(entity, object)
    local propData = config.props[object]
    if not propData then 
        lib.print.error(string.format("Invalid machine type: %s", object))
        return 
    end

    lib.print.debug(string.format("Attempting to use machine: %s, entity: %d", object, entity))

    local success, message = lib.callback.await('gym:canUseMachine', false, {
        machine = object,
        coords = GetEntityCoords(entity)
    })
    if not success then
        if message and type(message) == 'string' then
            lib.print.debug(string.format("Cannot use machine: %s", message))
            client.notify(locale('error_title'), message, 'error')
        end
        return
    end

    lib.print.debug(string.format("Machine approved, netID: %s", message))
    entity = NetworkGetEntityFromNetworkId(message)
    sendNui({
        action = 'toggleUI',
        data = true
    })

    local propAnim = propData.animations
    local plyAnim = propData.playerAnimation
    local offsets = plyAnim.offsets

    state.setCurrentMachine(config.props[object], entity)
    Wait(300)
    AttachEntityToEntity(cache.ped, entity, -1, offsets[1].x, offsets[1].y, offsets[1].z, offsets[2].x, offsets[2].y, offsets[2].z, false, false, false, false, 2, true)

    if plyAnim.prop then
        local propModel = plyAnim.prop.model
        lib.requestModel(propModel)
        local prop = CreateObject(propModel, 0, 0, 0, true, true, true)
        local propOffsets = plyAnim.prop.offsets
        local bone = plyAnim.prop.bone or 57005

        AttachEntityToEntity(prop, cache.ped, GetPedBoneIndex(cache.ped, bone), propOffsets[1], propOffsets[2], true, true, false, true, 1, true)
        state.setAttachedProp(prop)
        SetModelAsNoLongerNeeded(propModel)
    end

    if propAnim then
        lib.requestAnimDict(propAnim.dict)
    end
    lib.requestAnimDict(plyAnim.dict)

    if propAnim then
        PlayEntityAnim(entity, propAnim.name, propAnim.dict, 8.0, false, true, false, 0.99, 0)
    end
    TaskPlayAnim(cache.ped, plyAnim.dict, plyAnim.name, 8.0, -8.0, -1, 2, 0, false, false, false)

    Wait(1)
    SetEntityAnimCurrentTime(cache.ped, plyAnim.dict, plyAnim.name, 0.99)
end

---@param entities table
---@param object string
local function setupInteraction(entities, object)
    local propData = config.props[object]
    if not propData then 
        lib.print.error(string.format("Invalid prop data for object: %s", object))
        return 
    end

    if interactionType == 'ox_target' then
        if GetResourceState('ox_target') ~= 'started' then
            lib.print.error('ox_target is not started but is set as target system in config!')
            return
        end
        exports.ox_target:addLocalEntity(entities, {
            {
                icon = 'fa-solid fa-dumbbell',
                label = locale('use_machine', locale('machine_' .. object)),
                distance = 2,
                onSelect = function(data)
                    useMachine(data.entity, object)
                end
            }
        })
    elseif interactionType == 'qb_target' then
        if GetResourceState('qb-target') ~= 'started' then
            lib.print.error('qb-target is not started but is set as target system in config!')
            return
        end
        exports['qb-target']:AddTargetEntity(entities, {
            options = {
                {
                    icon = 'fa-solid fa-dumbbell',
                    label = locale('use_machine', locale('machine_' .. object)),
                    action = function(entity)
                        useMachine(entity, object)
                    end
                }
            },
            distance = 2.0,
        })
    elseif interactionType == 'custom' then
        config.customInteraction(entities, object, function(entity)
            useMachine(entity, object)
        end)
    end
end

---@param location table
---@param locationName? string Location identifier (used for despawn monitoring)
local function createLocationPoint(location, locationName)
    lib.print.debug(string.format("Creating location point at coords: %s", location.coords))

    if not location._blip then
        location._blip = createBlip(location.coords, location.name or "Gym")
    end

    return lib.points.new({
        coords = location.coords,
        distance = location.renderDistance or config.renderDistance,
        objects = {},
        hiddenObjects = {},
        onEnter = function(self)
            lib.print.debug("Player entered gym location")

            if location.clearLocation then
                local clearRadius = location.clearLocation.radius or 20.0
                local modelsToHide = {}

                for _, model in ipairs(config.clearLocationModels or {}) do
                    table.insert(modelsToHide, model)
                end

                if location.clearLocation.additionalObjects then
                    for _, model in ipairs(location.clearLocation.additionalObjects) do
                        table.insert(modelsToHide, model)
                    end
                end

                local modelsHash = {}
                for _, modelName in pairs(modelsToHide) do
                    local hash = type(modelName) == 'string' and joaat(modelName) or modelName
                    table.insert(modelsHash, hash)
                end

                local objects = lib.getNearbyObjects(location.coords, clearRadius)
                for _, obj in pairs(objects) do
                    local model = GetEntityModel(obj.object)
                    if lib.table.contains(modelsHash, model) then
                        table.insert(self.hiddenObjects, {
                            entity = obj.object,
                            coords = obj.coords,
                            model = model
                        })

                        SetEntityVisible(obj.object, false, false)
                        SetEntityCollision(obj.object, false, false)
                        FreezeEntityPosition(obj.object, true)

                        lib.print.debug(string.format("Hidden entity: %d at distance: %.2f", obj.object, #(location.coords - obj.coords)))
                    end
                end
                lib.print.info(string.format("Hidden %d objects in gym location", #self.hiddenObjects))
            end

            for object, coordsData in pairs(location.props) do
                local model = config.props[object].model
                if model then
                    self.objects[object] = self.objects[object] or {}
                    lib.requestModel(model)

                    local normalizedCoords, barCoords = normalizeEquipmentCoords(object, coordsData)

                    lib.print.debug(string.format("Spawning %d instances of %s", #normalizedCoords, object))

                    for idx, coords in pairs(normalizedCoords) do
                        local obj = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, false, false, false)
                        SetEntityHeading(obj, coords.w)
                        FreezeEntityPosition(obj, true)
                        table.insert(self.objects[object], obj)

                        if object == 'bench' and barCoords and barCoords[idx] then
                            local barModel = config.props.bench.playerAnimation.prop.model
                            lib.requestModel(barModel)
                            local barObj = CreateObjectNoOffset(barModel, barCoords[idx].x, barCoords[idx].y, barCoords[idx].z, false, false, false)
                            SetEntityHeading(barObj, barCoords[idx].w)
                            FreezeEntityPosition(barObj, true)

                            if not self.objects.bench_bars then
                                self.objects.bench_bars = {}
                            end
                            table.insert(self.objects.bench_bars, barObj)
                            SetModelAsNoLongerNeeded(barModel)
                        end
                    end
                    if interactionType ~= 'textUI' then
                        setupInteraction(self.objects[object], object)
                    else
                        local points = {}

                        for _, crds in pairs(normalizedCoords) do
                            local point = lib.points.new({
                                coords = crds,
                                distance = 2.0,
                                onEnter = function()
                                    if not showedTextUiInteraction then
                                        showedTextUiInteraction = true
                                        lib.showTextUI('[E] ' .. locale('use_machine', locale('machine_' .. object)))
                                    end
                                end,
                                onExit = function()
                                    showedTextUiInteraction = false
                                    lib.hideTextUI()
                                end,
                                nearby = function()
                                    if IsControlJustReleased(0, 38) and not state.getCurrentMachine() then
                                        useMachine(GetClosestObjectOfType(crds.x, crds.y, crds.z, 2.0, model, false, false, false), object)
                                        lib.hideTextUI()
                                    elseif not showedTextUiInteraction then
                                        lib.showTextUI('[E] ' .. locale('use_machine', locale('machine_' .. object)))
                                        showedTextUiInteraction = true
                                    end
                                end,
                            })
                            table.insert(points, point)
                        end

                        textUiPoints[object] = points
                    end
                    SetModelAsNoLongerNeeded(model)
                end
            end

            state.setCurrentLocation(location, self)

            -- Despawn monitoring: check for world props that should be removed (groups system)
            if locationName and OnLocationEnter then
                OnLocationEnter(locationName)
            end
        end,
        onExit = function(self)
            lib.print.debug("Player exited gym location - cleaning up objects")

            -- Stop despawn monitoring for this location (groups system)
            if locationName and OnLocationExit then
                OnLocationExit(locationName)
            end

            if self.hiddenObjects and #self.hiddenObjects > 0 then
                for _, objData in ipairs(self.hiddenObjects) do
                    if DoesEntityExist(objData.entity) then
                        SetEntityVisible(objData.entity, true, false)
                        SetEntityCollision(objData.entity, true, true)
                    end
                end
                lib.print.info(string.format("Restored %d hidden objects", #self.hiddenObjects))
                self.hiddenObjects = {}
            end

            for object, objectList in pairs(self.objects) do
                if interactionType == 'ox_target' then
                    exports.ox_target:removeLocalEntity(objectList)
                elseif interactionType == 'qb_target' then
                    exports['qb-target']:RemoveTargetEntity(objectList)
                elseif interactionType == 'textUI' then
                    if textUiPoints[object] then
                        for _, point in pairs(textUiPoints[object]) do
                            point:onExit()
                            point:remove()
                        end
                        textUiPoints[object] = nil
                    end
                elseif interactionType == 'custom' then
                    config.removeCustomInteraction(objectList)
                end
                for _, obj in pairs(objectList) do
                    DeleteEntity(obj)
                end
                self.objects[object] = nil
            end
            self.objects = {}

            state.setCurrentLocation(nil, nil)
        end,
    })
end

local staticBlips = {}
local pendingBlips = {}

local function isBlipResourceReady(entry)
    if not entry.resources then return true end
    for _, res in ipairs(entry.resources) do
        if GetResourceState(res) == 'started' then
            return true
        end
    end
    return false
end

local function createStaticBlip(entry, index)
    if not config.blip or not config.blip.enable then return end
    if entry.enable == false then return end

    local blip = AddBlipForCoord(entry.coords.x, entry.coords.y, entry.coords.z)
    SetBlipSprite(blip, config.blip.sprite or 311)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, config.blip.scale or 0.7)
    SetBlipColour(blip, config.blip.color or 2)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(entry.label or config.blip.label or 'Gym')
    EndTextCommandSetBlipName(blip)

    staticBlips[index] = blip
end

local function initializeStaticBlips()
    if not config.blip or not config.blip.enable or not config.blip.coords then return end

    for i, entry in ipairs(config.blip.coords) do
        if isBlipResourceReady(entry) then
            createStaticBlip(entry, i)
        elseif entry.resources then
            pendingBlips[i] = entry
        end
    end
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if not next(pendingBlips) then return end
    for i, entry in pairs(pendingBlips) do
        for _, res in ipairs(entry.resources) do
            if res == resourceName then
                createStaticBlip(entry, i)
                pendingBlips[i] = nil
                break
            end
        end
    end
end)

function InitializeLocationPoints()
    local locCount = 0
    for _ in pairs(config.locations) do locCount = locCount + 1 end
    lib.print.info(string.format("Initializing %d gym locations", locCount))

    for locName, location in pairs(config.locations) do
        location._point = createLocationPoint(location, locName)
        table.insert(locationPoints, location)
    end

    initializeStaticBlips()

    lib.print.info("All gym locations initialized successfully")
end

function CleanupLocationPoints()
    lib.print.info("Cleaning up all gym location points")

    for _, location in pairs(locationPoints) do
        if location._point then
            location._point:onExit(location._point)
        end
        if location._blip then
            removeBlip(location._blip)
            location._blip = nil
        end
    end

    for i, blip in pairs(staticBlips) do
        removeBlip(blip)
        staticBlips[i] = nil
    end

    lib.print.debug("All location points cleaned up")
end

---@param locationName string Location identifier
---@param locationData table Location configuration
local function refreshLocation(locationName, locationData)
    lib.print.debug(string.format("Refreshing gym location: %s", locationName))
    
    for i, location in ipairs(locationPoints) do
        if location == config.locations[locationName] then
            if location._point then
                location._point:onExit(location._point)
                location._point:remove()
            end
            if location._blip then
                removeBlip(location._blip)
                location._blip = nil
            end
            table.remove(locationPoints, i)
            break
        end
    end
    
    config.locations[locationName] = locationData
    locationData._point = createLocationPoint(locationData, locationName)
    table.insert(locationPoints, locationData)
    
    lib.print.info(string.format("Gym location '%s' refreshed successfully", locationName))
end

---@param locationName string Location identifier
---@param locationData table Location configuration
local function onLocationCreated(locationName, locationData)
    lib.print.debug(string.format("Creating new gym location: %s", locationName))

    if config.locations[locationName] then
        lib.print.error(string.format("Location '%s' already exists!", locationName))
        return
    end

    config.locations[locationName] = locationData
    locationData._point = createLocationPoint(locationData, locationName)
    table.insert(locationPoints, locationData)

    lib.print.info(string.format("New gym location '%s' created successfully", locationName))
end

---@param locationName string Location identifier
local function onLocationRemoved(locationName)
    lib.print.debug(string.format("Removing gym location: %s", locationName))

    for i, location in ipairs(locationPoints) do
        if location == config.locations[locationName] then
            if location._point then
                location._point:onExit(location._point)
                location._point:remove()
            end
            if location._blip then
                removeBlip(location._blip)
                location._blip = nil
            end
            table.remove(locationPoints, i)
            break
        end
    end

    config.locations[locationName] = nil

    lib.print.info(string.format("Gym location '%s' removed successfully", locationName))
end

RegisterNetEvent('gym:refreshLocation', refreshLocation)
RegisterNetEvent('gym:locationCreated', onLocationCreated)
RegisterNetEvent('gym:locationRemoved', onLocationRemoved)

return {
    interactionType = interactionType,
    InitializeLocationPoints = InitializeLocationPoints,
    CleanupLocationPoints = CleanupLocationPoints,
    useMachine = useMachine,
    setupInteraction = setupInteraction,
    refreshLocation = refreshLocation,
    onLocationCreated = onLocationCreated,
    onLocationRemoved = onLocationRemoved,
}
