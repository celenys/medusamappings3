local config = require 'config.config_c'
local state = require 'server.state'
local utils = require 'server.utils'
local configServer = require 'config.config_s'
local editable = require 'config.server'
local functions = require 'server.exports'
local legacy = require 'server.legacy_events'
lib.locale(require('config.config_c').language ~= 'auto' and require('config.config_c').language or nil)

---@param source Source
---@param data {machine: string, coords: vector3}
---@return boolean?, string?
lib.callback.register('gym:canUseMachine', function(source, data)
    local machine = data.machine
    local coords = data.coords

    lib.print.debug(string.format("Player %d attempting to use machine: %s at coords: %s", source, machine, coords))

    if not config.props[machine] then
        lib.print.warn(string.format("Unknown equipment type requested: %s by player %d", machine, source))
        return false, locale('error_unknown_equipment')
    end

    local index, foundMachine = utils.getMachineByCoords(coords, machine)
    if not index then
        lib.print.warn(string.format("Equipment not found at coords for player %d", source))
        return false, locale('error_equipment_not_found')
    end

    if state.getMachineUser(machine, index) then
        lib.print.debug(string.format("Machine %s[%d] already in use", machine, index))
        return false, locale('error_equipment_in_use')
    end
    state.setMachineInUse(machine, index, source)

    local objectCoords
    for _, loc in pairs(config.locations) do
        for _, propCoords in pairs(loc.props[machine] or {}) do
            local actualCoords = propCoords
            if type(propCoords) == 'table' and propCoords.coords then
                actualCoords = propCoords.coords
            end
            if #(vec3(actualCoords.x, actualCoords.y, actualCoords.z) - vec3(coords.x, coords.y, coords.z)) < 0.5 then
                objectCoords = actualCoords
                break
            end
        end
        if objectCoords then
            break
        end
    end

    if not objectCoords then
        local customEquipment = functions.GetSpawnedEquipment()
        if customEquipment then
            for instanceName, equipment in pairs(customEquipment) do
                if equipment.equipmentType == machine and type(index) == 'string' and index == instanceName then
                    objectCoords = vec4(equipment.coords.x, equipment.coords.y, equipment.coords.z, equipment.heading)
                    break
                elseif equipment.props and equipment.props[machine] then
                    for i, propCoords in ipairs(equipment.props[machine]) do
                        if i == index then
                            local actualCoords = propCoords
                            if type(propCoords) == 'table' and propCoords.coords then
                                actualCoords = propCoords.coords
                            end
                            if #(vec3(actualCoords.x, actualCoords.y, actualCoords.z) - vec3(coords.x, coords.y, coords.z)) < 0.5 then
                                objectCoords = actualCoords
                                break
                            end
                        end
                    end
                    if objectCoords then
                        break
                    end
                end
            end
        end
    end

    if not objectCoords then
        state.setMachineInUse(machine, index, nil)
        return false, locale('error_equipment_not_found')
    end

    local locationName = nil
    local isCustomEquipment = type(index) == 'string'

    -- Helper: check if two coordinate sets match (within tolerance)
    local function coordsMatch(a, b)
        if not a or not b then return false end
        return #(vec3(a.x, a.y, a.z) - vec3(b.x, b.y, b.z)) < 0.5
    end

    local spawnedEquipment = functions.GetSpawnedEquipment()
    if spawnedEquipment then
        for locName, equipment in pairs(spawnedEquipment) do
            if equipment.equipmentType and type(index) == 'string' and index == locName then
                locationName = equipment.locationName
                break
            elseif equipment.props and equipment.props[machine] then
                for _, propCoords in ipairs(equipment.props[machine]) do
                    local actualCoords = propCoords
                    if type(propCoords) == 'table' and propCoords.coords then
                        actualCoords = propCoords.coords
                    end
                    if coordsMatch(actualCoords, objectCoords) then
                        locationName = locName
                        break
                    end
                end
                if locationName then
                    break
                end
            end
        end
    end

    if not locationName then
        for locName, location in pairs(config.locations) do
            if location.props and location.props[machine] then
                for _, propCoords in ipairs(location.props[machine]) do
                    local actualCoords = propCoords
                    if type(propCoords) == 'table' and propCoords.coords then
                        actualCoords = propCoords.coords
                    end
                    if coordsMatch(actualCoords, objectCoords) then
                        locationName = locName
                        break
                    end
                end
            end
            if locationName then break end
        end
    end

    local success, message = editable.canUseMachine(source, { 
        machine = machine,
        index = index,
        locationName = locationName,
        coords = objectCoords,
        isCustomEquipment = isCustomEquipment
    })
    if not success then
        state.setMachineInUse(machine, index, nil)
        lib.print.debug(string.format("Player %d not allowed to use machine %s[%s] at location %s", source, machine, tostring(index), locationName or "unknown"))
        return false, message
    end
    coords = objectCoords

    local obj = CreateObjectNoOffset(joaat(config.props[machine].model), coords.x, coords.y, coords.z, true, false, false)
    lib.waitFor(function()
        if DoesEntityExist(obj) and NetworkGetNetworkIdFromEntity(obj) then
            return true
        end
    end)
    Wait(100)
    SetEntityHeading(obj, coords.w)
    FreezeEntityPosition(obj, true)

    local netID = NetworkGetNetworkIdFromEntity(obj)

    lib.print.debug(string.format("Created machine object for player %d - netID: %d, machine: %s", source, netID, machine))

    local players = lib.getNearbyPlayers(GetEntityCoords(GetPlayerPed(source)), configServer.syncDistance)
    for _, player in pairs(players) do
        TriggerClientEvent('gym:toggleMachineVisibility', player.id, {
            coords = coords,
            machine = machine,
            visible = false,
        })
        if player.id ~= source then
            TriggerClientEvent('gym:syncAnim', player.id, {
                machine = machine,
                coords = coords,
                netID = netID,
                source = source,
                lastFrame = true
            })
        end
    end
    local sourceMap = {}
    for _, src in pairs(players) do
        table.insert(sourceMap, src.id)
    end

    state.setMachineObject(source, {
        obj = obj,
        players = sourceMap,
        coords = coords,
        netID = netID,
        locationName = locationName,
        isCustomEquipment = isCustomEquipment,
    })

    return true, netID
end)

---@param source Source
---@return boolean?, string?
lib.callback.register('gym:attemptExercise', function(source)
    lib.print.debug(string.format("Player %d attempting exercise", source))
    
    local machineName, index = utils.getMachineByUser(source)
    if not machineName or not index then
        lib.print.warn(string.format("Player %d not using any machine", source))
        return false
    end

    local objData = state.getMachineObject(source)
    local locationName = objData and objData.locationName or nil
    local isCustomEquipment = objData and objData.isCustomEquipment or false

    local canUse, err = editable.canDoExercise(source, { 
        machine = machineName, 
        index = index, 
        locationName = locationName,
        coords = objData and objData.coords,
        isCustomEquipment = isCustomEquipment
    })
    if not canUse then
        lib.print.debug(string.format("Player %d cannot perform exercise: %s", source, err or "unknown"))
        return false, err
    end

    lib.print.debug(string.format("Player %d starting minigame for %s", source, machineName))
    local minigame = configServer.enableMinigame and lib.callback.await('gym:minigame', source, machineName) or true
    if minigame then
        local totalReps =  1
        local speed = state.getAnimSpeed(source, machineName)

        if config.props[machineName].animations then
            local machineCoords = nil
            local objData = state.getMachineObject(source)
            if objData then
                machineCoords = objData.coords
            end

            local players = lib.getNearbyPlayers(GetEntityCoords(GetPlayerPed(source)), configServer.syncDistance)
            for _, player in pairs(players) do
                if player.id ~= source then
                    TriggerClientEvent('gym:syncAnim', player.id, {
                        machine = machineName,
                        coords = machineCoords,
                        repeats = totalReps,
                        speed = speed,
                        netID = objData and objData.netID,
                        source = source,
                    })
                end
            end
        end

        legacy.trackExerciseStart(source, machineName, index, locationName, objData and objData.coords)
        local completed = lib.callback.await('gym:startExercise', source, {
            repeats = totalReps,
            speed = speed,
        })

        if completed then
            legacy.trackExerciseComplete(source, machineName, index, locationName, objData and objData.coords)
            state.addExhaustion(source, machineName)

            local statGains = configServer.stats.rates[machineName]
            if statGains then
                local parts = {}
                for k, v in pairs(statGains) do
                    parts[#parts + 1] = string.format("%s: %.1f", k, v)
                end
                lib.print.debug(string.format("Player %d stats updated - %s", source, table.concat(parts, ', ')))

                editable.updateStats(source, statGains)
            end
        else
            lib.print.debug(string.format("Player %d did not complete exercise", source))
        end
    end

    return minigame
end)

lib.callback.register('gym:stopUsingMachine', function(source)
    lib.print.debug(string.format("Player %d stopping machine use", source))
    
    local machineName, index = utils.getMachineByUser(source)
    if not machineName or not index then
        lib.print.warn(string.format("Player %d tried to stop machine but is not using any", source))
        return false
    end

    state.setMachineInUse(machineName, index, nil)
    local objData = state.getMachineObject(source)
    if objData then
        for _, playerId in pairs(objData.players) do
            TriggerClientEvent('gym:toggleMachineVisibility', playerId, {
                coords = objData.coords,
                machine = machineName,
                visible = true,
            })
        end
        if DoesEntityExist(objData.obj) then
            DeleteEntity(objData.obj)
            state.removeMachineObject(source)
            lib.print.debug(string.format("Deleted machine object for player %d", source))
        end
    end

    return true
end)
