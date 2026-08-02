local config = require 'config.config_c'

local legacy = {}

local activeSessions = {}

---@param equipmentType string
---@return string
local function generateInstanceName(equipmentType)
    local timestamp = os.time()
    local random = math.random(1000, 9999)
    return string.format("custom_%s_%d_%d", equipmentType, timestamp, random)
end

---@param machineName string
---@param index number|string?
---@return string
local function resolveMachineInstance(machineName, index)
    if type(index) == 'string' then
        return index
    end
    if index ~= nil then
        return string.format('%s_%s', machineName, tostring(index))
    end
    return machineName
end

---@param source Source
---@param machineName string
---@param index number|string?
---@param locationName string?
---@param coords vector4?
---@return table
local function buildSessionData(source, machineName, index, locationName, coords)
    local propData = config.props[machineName]
    local playerAnim = propData and propData.playerAnimation or nil

    return {
        playerId = source,
        playerName = GetPlayerName(source) or 'Unknown',
        machineName = resolveMachineInstance(machineName, index),
        machineType = machineName,
        animationDict = playerAnim and playerAnim.dict or nil,
        animationName = playerAnim and playerAnim.name or nil,
        position = coords and vec3(coords.x, coords.y, coords.z) or nil,
        heading = coords and coords.w or nil,
        location = locationName or 'unknown',
        timestamp = os.time(),
        startTime = os.time(),
    }
end

---@param source Source
---@param machineName string
---@param index number|string?
---@param locationName string?
---@param coords vector4?
function legacy.trackExerciseStart(source, machineName, index, locationName, coords)
    if not source or not machineName then return end

    local session = buildSessionData(source, machineName, index, locationName, coords)
    activeSessions[source] = session
    TriggerEvent('gym:exerciseStarted', session)
end

---@param source Source
---@param machineName string
---@param index number|string?
---@param locationName string?
---@param coords vector4?
function legacy.trackExerciseComplete(source, machineName, index, locationName, coords)
    if not source or not machineName then return end

    local session = activeSessions[source] or buildSessionData(source, machineName, index, locationName, coords)
    session.duration = os.time() - (session.startTime or os.time())
    session.completedAt = os.time()

    TriggerEvent('gym:exerciseCompleted', session)
    activeSessions[source] = nil
end

---@param source Source
function legacy.clearExercise(source)
    activeSessions[source] = nil
end

RegisterNetEvent('gym_animations:request_spawn_equipment', function(data)
    local src = source
    if not data or not data.equipmentType or not data.coords then
        return
    end

    local instanceName = data.instanceName or generateInstanceName(data.equipmentType)
    local success = exports[cache.resource]:SpawnGymEquipment(
        data.equipmentType,
        data.coords,
        data.heading or 0.0,
        data.locationName,
        instanceName
    )

    if success then
        TriggerClientEvent('gym_animations:spawn_confirmed', src, instanceName)
    else
        TriggerClientEvent('gym_animations:spawn_confirmed', src, nil)
    end
end)

RegisterNetEvent('gym_animations:request_despawn_equipment', function(instanceName)
    local src = source
    if not instanceName then
        return
    end

    local success = exports[cache.resource]:DespawnGymEquipment(instanceName)
    if success then
        TriggerEvent('gym_group:removeProp', src, instanceName)
    end
    TriggerClientEvent('gym_animations:despawn_confirmed', src, instanceName, success and true or false)
end)

return legacy
