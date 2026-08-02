---@diagnostic disable: deprecated

local config = require 'config.config_c'

---@class CustomEquipmentData
---@field equipmentType string
---@field coords vector3
---@field heading number
---@field locationName string?
---@field instanceName string
---@field inUse boolean
---@field timestamp number

local customEquipment = {}
local gymLocations = {}

---@type table<string, table<string, boolean>>
local resourceLocations = {}

---@param coords vector3
---@return string? locationName, number distance
local function findNearestLocation(coords)
    local nearestLocation = nil
    local nearestDistance = math.huge

    for locationName, locationData in pairs(config.locations) do
        local distance = #(coords - locationData.coords)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestLocation = locationName
        end
    end

    return nearestLocation, nearestDistance
end

---@param equipmentType string
---@return string
local function generateInstanceName(equipmentType)
    local timestamp = os.time()
    local random = math.random(1000, 9999)
    return string.format("custom_%s_%d_%d", equipmentType, timestamp, random)
end

---@param equipmentType string
---@return table?
local function getEquipmentConfig(equipmentType)
    return config.props[equipmentType]
end

---@param equipmentType string Equipment type (e.g., "speedbag", "leg_press")
---@param coords vector3 Spawn coordinates
---@param heading number Heading (0-360)
---@param locationName string? Optional location name (will auto-detect if not provided)
---@param instanceName string? Optional unique identifier
---@return boolean success
---@deprecated Use native gym API instead
local function SpawnGymEquipment(equipmentType, coords, heading, locationName, instanceName)
    local invokingResource = GetInvokingResource()

    local equipmentConfig = getEquipmentConfig(equipmentType)
    if not equipmentConfig then
        lib.print.error(string.format("Invalid equipment type: %s", equipmentType))
        return false
    end

    instanceName = instanceName or generateInstanceName(equipmentType)

    if customEquipment[instanceName] then
        lib.print.error(string.format("Equipment instance '%s' already exists", instanceName))
        return false
    end

    if not locationName then
        local nearestLoc, distance = findNearestLocation(coords)
        if nearestLoc and distance < 200.0 then
            locationName = nearestLoc
        else
            locationName = "custom_location"
        end
    end

    customEquipment[instanceName] = {
        equipmentType = equipmentType,
        coords = coords,
        heading = heading,
        locationName = locationName,
        instanceName = instanceName,
        inUse = false,
        timestamp = os.time(),
        _createdBy = invokingResource
    }

    if invokingResource then
        if not resourceLocations[invokingResource] then
            resourceLocations[invokingResource] = {}
        end
        resourceLocations[invokingResource][instanceName] = true
    end

    lib.print.info(string.format("Spawned equipment '%s' (type: %s) at %s (by %s)", 
        instanceName, equipmentType, locationName, invokingResource or "internal"))
    lib.print.debug(string.format("Equipment spawn details - coords: %s, heading: %.2f", 
        coords, heading))

    TriggerClientEvent('gym:syncCustomEquipment', -1, customEquipment)

    return true
end

---@param instanceName string Unique equipment identifier
---@return boolean success, string? error
---@deprecated Use native gym API instead
local function DespawnGymEquipment(instanceName)
    local equipment = customEquipment[instanceName]
    if not equipment then
        return false, string.format("Equipment instance '%s' not found", instanceName)
    end

    if equipment.inUse then
        return false, string.format("Equipment '%s' is currently in use", instanceName)
    end

    customEquipment[instanceName] = nil

    lib.print.info(string.format("Despawned equipment '%s'", instanceName))
    lib.print.debug("Equipment despawned successfully")

    TriggerClientEvent('gym:syncCustomEquipment', -1, customEquipment)

    return true
end

---@return table<number, string>
---@deprecated Use native gym API instead
local function GetEquipmentTypes()
    local types = {}
    for equipmentType, _ in pairs(config.props) do
        table.insert(types, equipmentType)
    end
    return types
end

---@param instanceName string Unique equipment identifier
---@return boolean isBusy
---@deprecated Use native gym API instead
local function IsEquipmentBusy(instanceName)
    local equipment = customEquipment[instanceName]
    if not equipment then
        return false
    end
    return equipment.inUse or false
end

---@return table<string, CustomEquipmentData>
---@deprecated Use native gym API instead
local function GetSpawnedEquipment()
    local response = {}

    for k, v in pairs(customEquipment) do
        response[k] = v
    end

    for k, v in pairs(gymLocations) do
        response[k] = v
    end

    return response
end

---@param instanceName string
---@param inUse boolean
local function SetEquipmentUse(instanceName, inUse)
    if customEquipment[instanceName] then
        customEquipment[instanceName].inUse = inUse
    end
end

---@param instanceName string
---@return CustomEquipmentData?
local function GetEquipmentData(instanceName)
    return customEquipment[instanceName]
end

exports('SpawnGymEquipment', function(equipmentType, coords, heading, locationName, instanceName)
    lib.print.warn("SpawnGymEquipment export is deprecated. Please use native prompt_anim_core API.")
    return SpawnGymEquipment(equipmentType, coords, heading, locationName, instanceName)
end)

exports('DespawnGymEquipment', function(instanceName)
    lib.print.warn("DespawnGymEquipment export is deprecated. Please use native prompt_anim_core API.")
    return DespawnGymEquipment(instanceName)
end)

exports('GetEquipmentTypes', function()
    lib.print.warn("GetEquipmentTypes export is deprecated. Please use native prompt_anim_core API.")
    return GetEquipmentTypes()
end)

exports('IsEquipmentBusy', function(instanceName)
    lib.print.warn("IsEquipmentBusy export is deprecated. Please use native prompt_anim_core API.")
    return IsEquipmentBusy(instanceName)
end)

exports('GetSpawnedEquipment', function()
    lib.print.warn("GetSpawnedEquipment export is deprecated. Please use native prompt_anim_core API.")
    return GetSpawnedEquipment()
end)

exports('_SetEquipmentUse', SetEquipmentUse)
exports('_GetEquipmentData', GetEquipmentData)


---@param locationName string Location identifier (e.g., 'vinewood', 'chumash')
---@param equipmentType string Equipment type (e.g., 'speedbag', 'leg_press')
---@param coords vector4|vector4[] Single coordinate or array of coordinates with heading vec4(x, y, z, heading)
---@return boolean success, number? count Number of equipment pieces added
local function AddEquipmentToLocation(locationName, equipmentType, coords)
    local invokingResource = GetInvokingResource()

    if not gymLocations[locationName] then
        lib.print.error(string.format("Location '%s' does not exist", locationName))
        return false, 0
    end

    if not config.props[equipmentType] then
        lib.print.error(string.format("Equipment type '%s' is not defined in config", equipmentType))
        return false, 0
    end

    if not gymLocations[locationName].props then
        gymLocations[locationName].props = {}
    end

    if not gymLocations[locationName].props[equipmentType] then
        gymLocations[locationName].props[equipmentType] = {}
    end

    local coordsList = {}
    if type(coords) == 'table' and coords.x then
        coordsList = {coords}
    elseif type(coords) == 'table' then
        coordsList = coords
    else
        lib.print.error("Invalid coords parameter - must be vector4 or array of vector4")
        return false, 0
    end

    local addedCount = 0
    for _, coord in ipairs(coordsList) do
        local isValid = false

        if type(coord) == 'vector4' then
            table.insert(gymLocations[locationName].props[equipmentType], coord)
            isValid = true
        elseif equipmentType == 'bench' and type(coord) == 'table' and coord.coords and type(coord.coords) == 'vector4' then
            if coord.bar and type(coord.bar) ~= 'vector4' then
                lib.print.warn("Bench bar coordinate must be vector4 - using simple format")
                table.insert(gymLocations[locationName].props[equipmentType], coord.coords)
            else
                table.insert(gymLocations[locationName].props[equipmentType], coord)
            end
            isValid = true
        end

        if isValid then
            addedCount = addedCount + 1
        else
            lib.print.warn(string.format("Skipping invalid coordinate for %s", equipmentType))
        end
    end

    if invokingResource then
        if not resourceLocations[invokingResource] then
            resourceLocations[invokingResource] = {}
        end
        resourceLocations[invokingResource][locationName] = true
    end

    lib.print.info(string.format("Added %d x %s to location '%s' (by %s)", addedCount, equipmentType, locationName, invokingResource or "internal"))

    TriggerClientEvent('gym:refreshLocation', -1, locationName, gymLocations[locationName])

    return true, addedCount
end

---@param locationName string Location identifier
---@param equipmentType string Equipment type
---@param coords vector4|vector4[]|nil Single coordinate, array of coordinates, or nil to remove all
---@param tolerance number? Distance tolerance for matching (default: 0.1)
---@return boolean success, number? count Number of equipment pieces removed
local function RemoveEquipmentFromLocation(locationName, equipmentType, coords, tolerance)
    tolerance = tolerance or 0.1

    if not gymLocations[locationName] then
        lib.print.error(string.format("Location '%s' does not exist", locationName))
        return false, 0
    end

    if not gymLocations[locationName].props or not gymLocations[locationName].props[equipmentType] then
        lib.print.error(string.format("No equipment of type '%s' found in location '%s'", equipmentType, locationName))
        return false, 0
    end

    local equipmentList = gymLocations[locationName].props[equipmentType]
    local removedCount = 0

    if coords == nil then
        removedCount = #equipmentList
        gymLocations[locationName].props[equipmentType] = {}
        lib.print.info(string.format("Removed all %d x %s from location '%s'", removedCount, equipmentType, locationName))
    else
        local coordsList = {}
        if type(coords) == 'vector4' or (type(coords) == 'table' and coords.x) then
            coordsList = {coords}
        elseif type(coords) == 'table' then
            coordsList = coords
        else
            lib.print.error("Invalid coords parameter - must be vector4, array of vector4, or nil")
            return false, 0
        end

        for _, targetCoord in ipairs(coordsList) do
            for i = #equipmentList, 1, -1 do
                local equipment = equipmentList[i]
                
                local equipCoords = equipment
                if type(equipment) == 'table' and equipment.coords then
                    equipCoords = equipment.coords
                end
                
                local targetCoords = targetCoord
                if type(targetCoord) == 'table' and targetCoord.coords then
                    targetCoords = targetCoord.coords
                end
                
                local distance = #(vec3(equipCoords.x, equipCoords.y, equipCoords.z) - vec3(targetCoords.x, targetCoords.y, targetCoords.z))

                if distance <= tolerance then
                    table.remove(equipmentList, i)
                    removedCount = removedCount + 1
                    break
                end
            end
        end

        lib.print.info(string.format("Removed %d x %s from location '%s'", removedCount, equipmentType, locationName))
    end

    if removedCount > 0 then
        TriggerClientEvent('gym:refreshLocation', -1, locationName, gymLocations[locationName])
        return true, removedCount
    end

    return false, 0
end

---@param locationName string Location identifier
---@return table<string, vector4[]>? equipment Map of equipment types to coordinates
local function GetLocationEquipment(locationName)
    if not gymLocations[locationName] then
        lib.print.error(string.format("Location '%s' does not exist", locationName))
        return nil
    end

    return gymLocations[locationName].props or {}
end

---@return table<string, table> locations Map of location names to location data
local function GetAllLocations()
    return config.locations
end

---@param locationName string Unique location identifier
---@param data table Location configuration { coords: vector3, renderDistance?: number, props?: table<string, vector4[]> }
---@return boolean success, string? error
local function CreateGymLocation(locationName, data)
    local invokingResource = GetInvokingResource()

    if gymLocations[locationName] then
        lib.print.error(string.format("Location '%s' already exists", locationName))
        return false, "Location already exists"
    end

    if type(data) ~= 'table' then
        lib.print.error("CreateGymLocation: data parameter must be a table")
        return false, "Invalid data parameter"
    end

    if not data.coords then
        lib.print.error("CreateGymLocation: coords is required")
        return false, "Missing coords parameter"
    end

    if type(data.coords) ~= 'vector3' then
        lib.print.error("CreateGymLocation: coords must be a vector3")
        return false, "Invalid coords type"
    end

    if data.renderDistance and type(data.renderDistance) ~= 'number' then
        lib.print.error("CreateGymLocation: renderDistance must be a number")
        return false, "Invalid renderDistance type"
    end

    if data.props then
        if type(data.props) ~= 'table' then
            lib.print.error("CreateGymLocation: props must be a table")
            return false, "Invalid props type"
        end

        for equipmentType, coordsList in pairs(data.props) do
            if not config.props[equipmentType] then
                lib.print.error(string.format("CreateGymLocation: Unknown equipment type '%s'", equipmentType))
                return false, string.format("Unknown equipment type: %s", equipmentType)
            end

            if type(coordsList) ~= 'table' then
                lib.print.error(string.format("CreateGymLocation: props.%s must be a table", equipmentType))
                return false, string.format("Invalid props.%s type", equipmentType)
            end

            for i, coords in ipairs(coordsList) do
                if type(coords) ~= 'vector4' and (equipmentType ~= 'bench' and not coords.coords) then
                    lib.print.error(string.format("CreateGymLocation: props.%s[%d] must be a vector4", equipmentType, i))
                    return false, string.format("Invalid coordinate at props.%s[%d]", equipmentType, i)
                end
            end
        end
    end

    gymLocations[locationName] = {
        coords = data.coords,
        renderDistance = data.renderDistance,
        props = data.props or {},
        _createdBy = invokingResource
    }

    if invokingResource then
        if not resourceLocations[invokingResource] then
            resourceLocations[invokingResource] = {}
        end
        resourceLocations[invokingResource][locationName] = true
    end

    lib.print.info(string.format("Created new gym location '%s' at %s (by %s)", locationName, data.coords, invokingResource or "internal"))
    if data.props then
        local equipmentCount = 0
        for _, coordsList in pairs(data.props) do
            equipmentCount = equipmentCount + #coordsList
        end
        lib.print.info(string.format("Location '%s' initialized with %d equipment pieces", locationName, equipmentCount))
    end

    TriggerClientEvent('gym:locationCreated', -1, locationName, gymLocations[locationName])

    return true
end

---@param locationName string Location identifier
---@return boolean success
local function RemoveGymLocation(locationName)
    if not gymLocations[locationName] then
        lib.print.error(string.format("Location '%s' does not exist", locationName))
        return false
    end

    gymLocations[locationName] = nil
    lib.print.info(string.format("Removed gym location '%s'", locationName))

    TriggerClientEvent('gym:locationRemoved', -1, locationName)

    return true
end

---@return string[] equipmentTypes List of equipment type names
local function GetAvailableEquipmentTypes()
    local types = {}
    for equipmentType, _ in pairs(config.props) do
        table.insert(types, equipmentType)
    end
    return types
end

exports('AddEquipmentToLocation', AddEquipmentToLocation)
exports('RemoveEquipmentFromLocation', RemoveEquipmentFromLocation)
exports('GetLocationEquipment', GetLocationEquipment)
exports('GetAllLocations', GetAllLocations)
exports('CreateGymLocation', CreateGymLocation)
exports('RemoveGymLocation', RemoveGymLocation)
exports('GetAvailableEquipmentTypes', GetAvailableEquipmentTypes)

lib.callback.register('gym:getSpawnedEquipment', function(source)
    local deprecatedCount = 0
    for _ in pairs(customEquipment) do
        deprecatedCount = deprecatedCount + 1
    end
    
    local locationsCount = 0
    for _ in pairs(gymLocations) do
        locationsCount = locationsCount + 1
    end
    
    lib.print.debug(string.format("Player %d requesting spawned equipment - deprecated: %d, locations: %d", source, deprecatedCount, locationsCount))
    
    return {
        deprecated = customEquipment,
        locations = gymLocations
    }
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        lib.print.info("Cleaning up all custom equipment...")
        local cleanupCount = 0
        local locationCount = 0

        for instanceName, equipment in pairs(customEquipment) do
            cleanupCount = cleanupCount + 1
        end
        
        for locationName, _ in pairs(gymLocations) do
            locationCount = locationCount + 1
        end

        customEquipment = {}
        gymLocations = {}

        lib.print.info(string.format("Cleaned up %d custom equipment entries and %d gym locations", cleanupCount, locationCount))
        return
    end

    if resourceLocations[resourceName] then
        lib.print.info(string.format("Cleaning up resources created by '%s'...", resourceName))
        local cleanupCount = 0
        local customCleanupCount = 0

        for itemName, _ in pairs(resourceLocations[resourceName]) do
            if gymLocations[itemName] and gymLocations[itemName]._createdBy == resourceName then
                gymLocations[itemName] = nil
                TriggerClientEvent('gym:locationRemoved', -1, itemName)
                cleanupCount = cleanupCount + 1
                lib.print.debug(string.format("Removed location '%s'", itemName))
            elseif gymLocations[itemName] then
                TriggerClientEvent('gym:refreshLocation', -1, itemName, gymLocations[itemName])
                lib.print.debug(string.format("Refreshed location '%s'", itemName))
            end

            if customEquipment[itemName] and customEquipment[itemName]._createdBy == resourceName then
                customEquipment[itemName] = nil
                customCleanupCount = customCleanupCount + 1
                lib.print.debug(string.format("Removed custom equipment '%s'", itemName))
            end
        end

        resourceLocations[resourceName] = nil

        if cleanupCount > 0 then
            lib.print.info(string.format("Cleaned up %d gym locations from resource '%s'", cleanupCount, resourceName))
        end
        if customCleanupCount > 0 then
            lib.print.info(string.format("Cleaned up %d custom equipment from resource '%s'", customCleanupCount, resourceName))
        end
    end
end)

return {
    SpawnGymEquipment = SpawnGymEquipment,
    DespawnGymEquipment = DespawnGymEquipment,
    GetEquipmentTypes = GetEquipmentTypes,
    IsEquipmentBusy = IsEquipmentBusy,
    GetSpawnedEquipment = GetSpawnedEquipment,
    SetEquipmentUse = SetEquipmentUse,
    GetEquipmentData = GetEquipmentData,

    AddEquipmentToLocation = AddEquipmentToLocation,
    RemoveEquipmentFromLocation = RemoveEquipmentFromLocation,
    GetLocationEquipment = GetLocationEquipment,
    GetAllLocations = GetAllLocations,
    CreateGymLocation = CreateGymLocation,
    RemoveGymLocation = RemoveGymLocation,
    GetAvailableEquipmentTypes = GetAvailableEquipmentTypes,
}
