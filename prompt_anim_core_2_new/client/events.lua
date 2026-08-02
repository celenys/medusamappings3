local config = require 'config.config_c'
local state = require 'client.state'
local points = require 'client.points'

local customEquipmentPoints = {}

---@param data {coords: vector3, machine: string, lastFrame: boolean?, source: Source, repeats: number?, speed: number?, netID: number?}
RegisterNetEvent('gym:syncAnim', function(data)
    lib.print.debug(string.format("Syncing animation for machine: %s, source: %d", data.machine, data.source or 0))

    local location = state.getCurrentLocation()

    -- On high-pop servers the sync event can arrive before the prop entity has
    -- replicated to this client. Poll until the netID resolves — otherwise the
    -- prop animation silently no-ops and the attached player appears to float.
    local targetEntity
    local deadline = GetGameTimer() + 2000
    repeat
        local e = NetworkGetEntityFromNetworkId(data.netID)
        if e ~= 0 and DoesEntityExist(e) then
            targetEntity = e
            break
        end
        Wait(50)
    until GetGameTimer() >= deadline

    if not targetEntity then
        lib.print.warn(string.format("Failed to resolve entity from netID %s after 2s", tostring(data.netID)))
        return
    end

    -- Repair rotation: server-side SetEntityHeading can fail to replicate before
    -- FreezeEntityPosition locks it in on 2nd+ spawn, leaving the prop at heading 0.
    if data.coords and data.coords.w then
        SetEntityHeading(targetEntity, data.coords.w)
    end

    if not location then
        lib.print.debug("Not in gym location - checking custom equipment")

        local foundInCustom = false
        for instanceName, point in pairs(customEquipmentPoints) do
            if point.objects and point.objects[data.machine] then
                for _, entity in pairs(point.objects[data.machine]) do
                    if entity == targetEntity then
                        foundInCustom = true
                        lib.print.debug("Found entity in custom equipment")
                        break
                    end
                end
            end
            if foundInCustom then break end
        end

        if not foundInCustom then
            lib.print.debug("Not in gym location or custom equipment range - skipping sync")
            return
        end
    end

    local machineData = config.props[data.machine]
    if not machineData then
        lib.print.warn(string.format("Unknown machine type in sync: %s", data.machine))
        return
    end

    local repeatCount = data.repeats or 1
    local animSpeed = data.speed or 1.0
    local machineAnim = machineData.animations
    local playerAnim = machineData.playerAnimation
    local baseDuration = GetAnimDuration(machineAnim.dict, machineAnim.name) * 1000
    local adjustedDuration = baseDuration / animSpeed

    local targetPed
    if data.source then
        targetPed = GetPlayerPed(GetPlayerFromServerId(data.source))
        if not targetPed or not DoesEntityExist(targetPed) then
            targetPed = nil
        end
    end

    lib.requestAnimDict(machineAnim.dict)
    lib.requestAnimDict(playerAnim.dict)

    for i = 1, repeatCount do
        SetTimeout(machineAnim.delay or 0, function()
            PlayEntityAnim(targetEntity, machineAnim.name, machineAnim.dict, 8.0, false, true, false, 0.0, 0)
        end)
        if targetPed then
            TaskPlayAnim(targetPed, playerAnim.dict, playerAnim.name, 8.0, -8.0, -1, 2, 0, false, false, true)
        end

        Wait(1)
        SetEntityAnimSpeed(targetEntity, machineAnim.dict, machineAnim.name, animSpeed)
        if targetPed then
            SetEntityAnimSpeed(targetPed, playerAnim.dict, playerAnim.name, animSpeed)
        end

        if data.lastFrame then
            SetEntityAnimCurrentTime(targetEntity, machineAnim.dict, machineAnim.name, 0.99)
            if targetPed then
                SetEntityAnimCurrentTime(targetPed, playerAnim.dict, playerAnim.name, 0.99)
            end
        else
            Wait(adjustedDuration - 1)
        end
    end

    RemoveAnimDict(machineAnim.dict)
    RemoveAnimDict(playerAnim.dict)
end)

---@param data {coords: vector3, machine: string, visible: boolean}
RegisterNetEvent('gym:toggleMachineVisibility', function(data)
    lib.print.debug(string.format("Toggling machine visibility: %s, visible: %s at coords: %s", data.machine, tostring(data.visible), data.coords))

    local foundEntity = false
    local location, point = state.getCurrentLocation()

    if location and point then
        for _, entity in pairs(point.objects[data.machine] or {}) do
            local entityCoords = GetEntityCoords(entity)
            local distance = #(vec3(entityCoords.x, entityCoords.y, entityCoords.z) - vec3(data.coords.x, data.coords.y, data.coords.z))
            lib.print.debug(string.format("Checking normal location entity - distance: %.2f", distance))
            if distance < 1.0 then
                SetEntityVisible(entity, data.visible, false)
                lib.print.debug(string.format("Toggled visibility for normal location machine: %s", data.visible))

                if data.machine == 'bench' and point.objects.bench_bars then
                    for barIdx, barEntity in pairs(point.objects.bench_bars) do
                        if DoesEntityExist(barEntity) then
                            local barCoords = GetEntityCoords(barEntity)
                            if #(vec3(barCoords.x, barCoords.y, barCoords.z) - vec3(data.coords.x, data.coords.y, data.coords.z)) < 5.0 then
                                SetEntityVisible(barEntity, data.visible, false)
                                lib.print.debug(string.format("Toggled bar visibility: %s", data.visible))
                            end
                        end
                    end
                end

                foundEntity = true
                return
            end
        end
    end

    lib.print.debug(string.format("Checking custom equipment - total points: %d", #customEquipmentPoints))

    for instanceName, customPoint in pairs(customEquipmentPoints) do
        lib.print.debug(string.format("Checking custom point: %s", instanceName))
        if customPoint.objects then
            for equipmentType, entityList in pairs(customPoint.objects) do
                lib.print.debug(string.format("  Equipment type: %s (looking for %s)", equipmentType, data.machine))
                if equipmentType == data.machine then
                    for _, entity in pairs(entityList) do
                        if DoesEntityExist(entity) then
                            local entityCoords = GetEntityCoords(entity)
                            local distance = #(vec3(entityCoords.x, entityCoords.y, entityCoords.z) - vec3(data.coords.x, data.coords.y, data.coords.z))
                            lib.print.debug(string.format("    Entity distance: %.2f", distance))
                            if distance < 1.0 then
                                SetEntityVisible(entity, data.visible, false)
                                lib.print.debug(string.format("Toggled visibility for custom equipment: %s (visible: %s)", instanceName, data.visible))
                                foundEntity = true
                                return
                            end
                        end
                    end
                end
            end
        end
    end

    if not foundEntity then
        lib.print.warn(string.format("Machine %s not found at coords %s", data.machine, data.coords))
    end
end)


---@param instanceName string
---@param equipment CustomEquipmentData
local function createCustomEquipmentPoint(instanceName, equipment)
    lib.print.debug(string.format("Creating custom equipment point: %s at %s", instanceName, equipment.coords))

    return lib.points.new({
        coords = equipment.coords,
        distance = 100.0,
        objects = {},
        onEnter = function(self)
            lib.print.debug(string.format("Player entered custom equipment range: %s", instanceName))

            local propData = config.props[equipment.equipmentType]
            if propData then
                local model = propData.model
                if type(model) == "string" then
                    model = joaat(model)
                end

                lib.requestModel(model)

                local entity = CreateObjectNoOffset(model, equipment.coords.x, equipment.coords.y, equipment.coords.z, false, false, false)
                if DoesEntityExist(entity) then
                    SetEntityHeading(entity, equipment.heading)
                    FreezeEntityPosition(entity, true)

                    self.objects[equipment.equipmentType] = {entity}

                    points.setupInteraction(self.objects[equipment.equipmentType], equipment.equipmentType)

                    lib.print.debug(string.format("Custom equipment entity created: %d", entity))
                else
                    lib.print.error(string.format("Failed to create custom equipment entity for %s", instanceName))
                end

                SetModelAsNoLongerNeeded(model)
            else
                lib.print.error(string.format("Unknown equipment type: %s", equipment.equipmentType))
            end
        end,
        onExit = function(self)
            lib.print.debug(string.format("Player exited custom equipment range: %s", instanceName))

            for equipmentType, objectList in pairs(self.objects) do
                if points.interactionType == 'ox_target' then
                    exports.ox_target:removeLocalEntity(objectList)
                elseif points.interactionType == 'qb_target' then
                    exports['qb-target']:RemoveTargetEntity(objectList)
                elseif points.interactionType == 'custom' then
                    config.removeCustomInteraction(objectList)
                end

                for _, obj in pairs(objectList) do
                    if DoesEntityExist(obj) then
                        DeleteEntity(obj)
                    end
                end
                self.objects[equipmentType] = nil
            end
            self.objects = {}
        end,
    })
end

---@param equipmentData table<string, CustomEquipmentData>
RegisterNetEvent('gym:syncCustomEquipment', function(equipmentData)
    lib.print.debug(string.format("Syncing custom equipment - %d items", #equipmentData or 0))

    for instanceName, point in pairs(customEquipmentPoints) do
        if not equipmentData[instanceName] then
            lib.print.debug(string.format("Removing custom equipment point: %s", instanceName))

            if point.onExit then
                point:onExit()
            end
            point:remove()

            customEquipmentPoints[instanceName] = nil
        end
    end

    for instanceName, equipment in pairs(equipmentData) do
        if not customEquipmentPoints[instanceName] then
            lib.print.debug(string.format("Creating point for custom equipment: %s (type: %s)", instanceName, equipment.equipmentType))
            customEquipmentPoints[instanceName] = createCustomEquipmentPoint(instanceName, equipment)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        lib.print.info("Resource stopping - cleaning up...")

        for instanceName, point in pairs(customEquipmentPoints) do
            if point.onExit then
                point:onExit()
            end
            point:remove()
        end
        customEquipmentPoints = {}

        points.CleanupLocationPoints()

        if state.getCurrentMachine() then
            lib.print.debug("Clearing player tasks from machine")
            ClearPedTasks(cache.ped)
            DetachEntity(cache.ped, true, true)
        end

        local attachedProp = state.getAttachedProp()
        if attachedProp and DoesEntityExist(attachedProp) then
            lib.print.debug("Deleting attached prop")
            DeleteEntity(attachedProp)
            lib.playAnim(cache.ped, 'anim@mp_player_intselfiethumbs_up', 'idle_a', 8.0, -8.0, -1, 1, 0)
            while not IsEntityPlayingAnim(cache.ped, 'anim@mp_player_intselfiethumbs_up', 'idle_a', 3) do
                Wait(10)
            end
            SetTimeout(100, function()
                ClearPedTasksImmediately(cache.ped)
            end)
        end

        state.reset()
    end
end)
