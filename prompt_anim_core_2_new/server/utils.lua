local config = require 'config.config_c'
local configServer = require 'config.config_s'
local functions    = require 'server.exports'

---@param coords vector3
---@param name string?
function getMachineByCoords(coords, name)
    local machineIndex, closestDistance = nil, math.huge
    local foundMachineName = nil

    for _, location in pairs(config.locations) do
        for machineName, machineData in pairs(location.props or {}) do
            if not name or machineName == name then
                for i, machineCoords in ipairs(machineData) do
                    local actualCoords = machineCoords
                    if type(machineCoords) == 'table' and machineCoords.coords then
                        actualCoords = machineCoords.coords
                    end

                    local distance = #(coords - vec3(actualCoords.x, actualCoords.y, actualCoords.z))
                    if distance < closestDistance then
                        closestDistance = distance
                        machineIndex = i
                        foundMachineName = machineName
                    end
                end
            end
        end
    end

    local customEquipment = functions.GetSpawnedEquipment()
    if customEquipment then
        for instanceName, equipment in pairs(customEquipment) do
            if equipment.equipmentType then
                if not name or equipment.equipmentType == name then
                    local distance = #(coords - equipment.coords)
                    if distance < closestDistance then
                        closestDistance = distance
                        machineIndex = instanceName
                        foundMachineName = equipment.equipmentType
                    end
                end
            elseif equipment.props then
                for machineName, machineData in pairs(equipment.props) do
                    if not name or machineName == name then
                        for i, machineCoords in ipairs(machineData) do
                            local actualCoords = machineCoords
                            if type(machineCoords) == 'table' and machineCoords.coords then
                                actualCoords = machineCoords.coords
                            end

                            local distance = #(coords - vec3(actualCoords.x, actualCoords.y, actualCoords.z))
                            if distance < closestDistance then
                                closestDistance = distance
                                machineIndex = i
                                foundMachineName = machineName
                            end
                        end
                    end
                end
            end
        end
    end

    return machineIndex, foundMachineName
end

---@param source Source
---@return string?, integer?
function getMachineByUser(source)
    local state = require 'server.state'
    local machinesInUse = state.machinesInUse

    for machineName, machineData in pairs(machinesInUse) do
        for index, userSource in pairs(machineData) do
            if userSource == source then
                return machineName, index
            end
        end
    end
    return nil
end

---@param machine string
---@return string
function getMuscleGroup(machine)
    if configServer.exhaustion.enableMuscleGroups and configServer.exhaustion.muscleGroups then
        for group, machines in pairs(configServer.exhaustion.muscleGroups) do
            for _, machineName in ipairs(machines) do
                if machineName == machine then
                    return group
                end
            end
        end
    end
    return 'unknown'
end

return {
    getMachineByCoords = getMachineByCoords,
    getMachineByUser = getMachineByUser,
    getMuscleGroup = getMuscleGroup
}
