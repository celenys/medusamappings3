local configServer = require 'config.config_s'
local utils = require 'server.utils'

---@class ServerState
local State = {
    machinesInUse = {},
    exhaustion = {},
    machineObjects = {}
}

---@param machine string
---@param index number|string
---@param source Source?
function State.setMachineInUse(machine, index, source)
    State.machinesInUse[machine] = State.machinesInUse[machine] or {}
    State.machinesInUse[machine][index] = source
    
    if source then
        lib.print.debug(string.format("Machine %s[%s] now in use by player %d", machine, tostring(index), source))
    else
        lib.print.debug(string.format("Machine %s[%s] freed", machine, tostring(index)))
    end
end

---@param machine string
---@param index number
---@return Source?
function State.getMachineUser(machine, index)
    if not State.machinesInUse[machine] then return nil end
    return State.machinesInUse[machine][index]
end

---@param source Source
---@param machine string
function State.addExhaustion(source, machine)
    if not configServer.exhaustion.enable then return end
    State.exhaustion[source] = State.exhaustion[source] or {}

    local muscleGroup = utils.getMuscleGroup(machine)
    local exhaustionAmount = configServer.exhaustion.rates[machine] or 1
    State.exhaustion[source][muscleGroup] = (State.exhaustion[source][muscleGroup] or 0) + exhaustionAmount
    
    lib.print.debug(string.format("Player %d exhaustion increased - %s: %.2f (+%.2f)", 
        source, muscleGroup, State.exhaustion[source][muscleGroup], exhaustionAmount))
end

---@param source Source
---@param machine string
---@return number
function State.getAnimSpeed(source, machine)
    local baseSpeed = 1.0
    if not configServer.exhaustion.enable then return baseSpeed end
    if not State.exhaustion[source] then return baseSpeed end

    local muscleGroup = utils.getMuscleGroup(machine)
    local exhaustionLevel = State.exhaustion[source][muscleGroup] or 0

    local speedReduction = exhaustionLevel * 0.02
    local finalSpeed = math.max(baseSpeed - speedReduction, 0.5)
    
    lib.print.debug(string.format("Player %d anim speed for %s: %.2f (exhaustion: %.2f)", 
        source, machine, finalSpeed, exhaustionLevel))

    return finalSpeed
end

---@param source Source
---@param data table
function State.setMachineObject(source, data)
    State.machineObjects[source] = data
end

---@param source Source
---@return table?
function State.getMachineObject(source)
    return State.machineObjects[source]
end

---@param source Source
function State.removeMachineObject(source)
    State.machineObjects[source] = nil
end

---@return table
function State.getAllExhaustion()
    return State.exhaustion
end

---@param source Source
---@param group string
---@param value number
function State.setExhaustion(source, group, value)
    if not State.exhaustion[source] then return end
    State.exhaustion[source][group] = value
end

---@param source Source
function State.clearExhaustion(source)
    State.exhaustion[source] = nil
end

return State
