--[[
    ═══════════════════════════════════════════════════════════════════════════
    DESPAWN SYSTEM - CLIENT SIDE
    ═══════════════════════════════════════════════════════════════════════════
    
    Handles:
    - Entity targeting mode (aim at world props, mark for despawn)
    - Persistent despawn monitoring (tied to location onEnter/onExit)
    - Re-deleting respawned world props
    - Respawning entities when groups unload
    
    ═══════════════════════════════════════════════════════════════════════════
]]--

local config = require 'config.config_s'
local client = require 'config.client'

-- Despawned entities data, keyed by location name
-- { [locationName] = { {model, coords, heading}, ... } }
local despawnData = {}

-- Active monitoring threads, keyed by location name
-- Stores thread handles so we can stop them on exit
local activeMonitors = {}

-- Track which locations the player is currently inside
-- Needed so that if despawn data arrives AFTER onEnter, we can still start monitoring
local playerInsideLocations = {}

-- Targeting mode state
local targetingMode = {
    active = false,
    confirmed = false, -- true after user applies (ENTER), outlines turn RED
    markedEntities = {},
    onConfirm = nil,
}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    DESPAWN HELPER - Called from points.lua onEnter/onExit
    ═══════════════════════════════════════════════════════════════════════════
]]--

--- Try to delete a specific world prop at known coordinates
---@param entityInfo table {model: number|string, coords: table {x,y,z}, heading: number}
---@return boolean deleted
local function TryDeleteEntity(entityInfo)
    local model = entityInfo.model
    if type(model) == 'string' then
        model = joaat(model)
    end

    local coords = entityInfo.coords
    local object = GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, model, false, false, false)

    if object and object ~= 0 and DoesEntityExist(object) then
        SetEntityAsMissionEntity(object, true, true)
        DeleteEntity(object)
        lib.print.debug(string.format("[DESPAWN] Deleted entity model %s at %.1f, %.1f, %.1f", entityInfo.model, coords.x, coords.y, coords.z))
        return true
    end

    return false
end

--- Run a despawn check for all entities at a location
---@param locationName string
---@return number deletedCount
local function RunDespawnCheck(locationName)
    local entities = despawnData[locationName]
    if not entities or #entities == 0 then return 0 end

    local deletedCount = 0
    for _, entityInfo in ipairs(entities) do
        if TryDeleteEntity(entityInfo) then
            deletedCount = deletedCount + 1
        end
    end

    return deletedCount
end

--- Called when player enters a location point - starts despawn monitoring
---@param locationName string The location identifier (e.g., "group_my_gym")
function OnLocationEnter(locationName)
    playerInsideLocations[locationName] = true

    if not despawnData[locationName] or #despawnData[locationName] == 0 then
        return
    end

    lib.print.debug(string.format("[DESPAWN] Player entered location '%s' - checking %d despawn targets", locationName, #despawnData[locationName]))

    -- Immediate check
    local deleted = RunDespawnCheck(locationName)
    if deleted > 0 then
        lib.print.debug(string.format("[DESPAWN] Immediately deleted %d entities at '%s'", deleted, locationName))
    end

    -- Start monitoring thread for this location
    if activeMonitors[locationName] then return end -- Already monitoring

    local interval = config.groups and config.groups.despawnCheckInterval or 10000

    activeMonitors[locationName] = true
    CreateThread(function()
        while activeMonitors[locationName] do
            Wait(interval)

            if not activeMonitors[locationName] then break end
            if not despawnData[locationName] then break end

            local count = RunDespawnCheck(locationName)
            if count > 0 then
                lib.print.debug(string.format("[DESPAWN] Re-deleted %d respawned entities at '%s'", count, locationName))
            end
        end

        lib.print.debug(string.format("[DESPAWN] Stopped monitoring '%s'", locationName))
    end)
end

--- Called when player exits a location point - stops despawn monitoring
---@param locationName string The location identifier
function OnLocationExit(locationName)
    playerInsideLocations[locationName] = nil

    if activeMonitors[locationName] then
        activeMonitors[locationName] = nil
        lib.print.debug(string.format("[DESPAWN] Player exited location '%s' - stopping monitor", locationName))
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    DESPAWN/RESPAWN EVENTS FROM SERVER
    ═══════════════════════════════════════════════════════════════════════════
]]--

--- Server tells us to register despawn data for a location
RegisterNetEvent('gym_group:despawnEntities')
AddEventHandler('gym_group:despawnEntities', function(locationName, entitiesToDespawn)
    if not entitiesToDespawn or #entitiesToDespawn == 0 then
        lib.print.debug(string.format("[DESPAWN] No entities to despawn for location '%s'", locationName))
        return
    end

    lib.print.info(string.format("[DESPAWN] Registered %d despawn targets for location '%s'", #entitiesToDespawn, locationName))

    -- Store for monitoring
    despawnData[locationName] = entitiesToDespawn

    -- Try immediate deletion in case player is already near
    local deleted = RunDespawnCheck(locationName)
    if deleted > 0 then
        lib.print.info(string.format("[DESPAWN] Immediately deleted %d/%d entities for '%s'", deleted, #entitiesToDespawn, locationName))
    end

    -- If player is already inside this location (onEnter fired before this data arrived),
    -- start the monitoring thread now to handle the race condition
    if playerInsideLocations[locationName] and not activeMonitors[locationName] then
        lib.print.debug(string.format("[DESPAWN] Player already inside '%s' - starting monitor now", locationName))
        OnLocationEnter(locationName)
    end
end)

--- Server tells us to stop despawning and optionally respawn entities
RegisterNetEvent('gym_group:respawnEntities')
AddEventHandler('gym_group:respawnEntities', function(locationName)
    -- Stop monitoring
    activeMonitors[locationName] = nil

    if not despawnData[locationName] then
        lib.print.debug(string.format("[DESPAWN] No despawn data to clear for '%s'", locationName))
        return
    end

    lib.print.info(string.format("[DESPAWN] Clearing despawn data for location '%s'", locationName))
    despawnData[locationName] = nil
end)

--[[
    ═══════════════════════════════════════════════════════════════════════════
    ENTITY TARGETING MODE
    ═══════════════════════════════════════════════════════════════════════════
    
    Allows admin to aim at world props and mark them for despawn.
    - E: Mark/unmark targeted entity
    - ENTER: Apply (confirm all marked, turn RED)
    - BACKSPACE: Cancel
    ═══════════════════════════════════════════════════════════════════════════
]]--

--- Convert camera rotation to direction vector
---@param rotation vector3
---@return vector3
local function RotationToDirection(rotation)
    local x = rotation.x * math.pi / 180.0
    local z = rotation.z * math.pi / 180.0
    local num = math.abs(math.cos(x))
    return vector3(
        -math.sin(z) * num,
        math.cos(z) * num,
        math.sin(x)
    )
end

--- Check if an entity is a gym equipment prop (spawned by the location system)
--- We skip these in targeting mode to avoid accidentally despawning our own equipment
---@param entity number
---@return boolean
local function IsGymEquipmentEntity(entity)
    if not entity or entity == 0 then return false end
    local entityModel = GetEntityModel(entity)
    local cconfig = require 'config.config_c'
    for _, propData in pairs(cconfig.props) do
        if propData.model then
            local hash = type(propData.model) == 'string' and joaat(propData.model) or propData.model
            if entityModel == hash then
                return true
            end
        end
    end
    return false
end

--- Get the entity the player is aiming at (world objects only)
--- Uses native StartShapeTestRay with flag 16 (objects) for reliable object targeting
---@param skipGymEquipment? boolean If true, skip entities that match gym equipment models
---@return number? entity
local function GetTargetedEntity(skipGymEquipment)
    local ped = PlayerPedId()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local camDir = RotationToDirection(camRot)
    local destination = camCoords + (camDir * 100.0)

    local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, destination.x, destination.y, destination.z, 16, ped, 0)
    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)

    if hit and DoesEntityExist(entityHit) and IsEntityAnObject(entityHit) then
        -- Skip gym equipment models so we don't accidentally mark our own props for despawn
        if skipGymEquipment and IsGymEquipmentEntity(entityHit) then
            return nil
        end
        return entityHit
    end

    return nil
end

--- Draw 2D text on screen
---@param x number
---@param y number
---@param text string
---@param scale number
local function DrawText2D(x, y, text, scale)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

-- Thread to keep marked entities highlighted (outlines reset every frame)
-- Orange during targeting, RED after confirmed (applied)
-- Sleeps when nothing is marked to avoid wasting CPU
CreateThread(function()
    while true do
        if next(targetingMode.markedEntities) then
            Wait(0)
            for entity, _ in pairs(targetingMode.markedEntities) do
                if DoesEntityExist(entity) then
                    SetEntityDrawOutline(entity, true)
                    if targetingMode.confirmed then
                        SetEntityDrawOutlineColor(255, 0, 0, 255)   -- Red = confirmed for deletion
                    else
                        SetEntityDrawOutlineColor(255, 100, 0, 255) -- Orange = marked during targeting
                    end
                else
                    targetingMode.markedEntities[entity] = nil
                end
            end
        else
            Wait(500) -- Sleep when nothing to draw
        end
    end
end)

--- Start entity targeting mode for marking props to despawn
---@param onConfirm? function Called for each marked entity
---@param onComplete? function Called when targeting mode ends (apply or cancel)
function StartEntityTargetingMode(onConfirm, onComplete)
    targetingMode.active = true
    targetingMode.onConfirm = onConfirm

    client.notify('Entity Targeting Mode', 'Aim at props and press E to mark\nENTER to apply | BACKSPACE to cancel', 'info')

    CreateThread(function()
        local lastHighlightedEntity = nil

        while targetingMode.active do
            Wait(0)

            local entity = GetTargetedEntity(true) -- skip gym equipment models

            -- Highlight targeted entity
            if entity and entity ~= lastHighlightedEntity then
                if lastHighlightedEntity and not targetingMode.markedEntities[lastHighlightedEntity] then
                    SetEntityDrawOutline(lastHighlightedEntity, false)
                end

                if targetingMode.markedEntities[entity] then
                    SetEntityDrawOutline(entity, true)
                    SetEntityDrawOutlineColor(255, 255, 0, 255) -- Yellow = already marked
                else
                    SetEntityDrawOutline(entity, true)
                    SetEntityDrawOutlineColor(0, 255, 0, 255) -- Green = targetable
                end

                lastHighlightedEntity = entity
            elseif not entity and lastHighlightedEntity and not targetingMode.markedEntities[lastHighlightedEntity] then
                SetEntityDrawOutline(lastHighlightedEntity, false)
                lastHighlightedEntity = nil
            end

            -- Draw center crosshair dot
            if entity then
                DrawRect(0.5, 0.5, 0.004, 0.007, 0, 255, 0, 220)   -- Green dot when targeting
            else
                DrawRect(0.5, 0.5, 0.004, 0.007, 255, 255, 255, 180) -- White dot otherwise
            end

            -- Draw instructions
            local markedCount = 0
            for _ in pairs(targetingMode.markedEntities) do markedCount = markedCount + 1 end

            DrawText2D(0.5, 0.85, string.format('[~b~E~s~] Mark | [~g~ENTER~s~] Apply (%d marked) | [~r~BACKSPACE~s~] Cancel', markedCount), 0.4)

            if entity then
                local model = GetEntityModel(entity)
                local isMarked = targetingMode.markedEntities[entity] and " ~o~(MARKED)~s~" or ""
                DrawText2D(0.5, 0.90, 'Targeting: Model ' .. model .. isMarked, 0.35)
            end

            -- Input handling
            if IsControlJustPressed(0, 38) then -- E - Mark/unmark entity
                if entity then
                    if targetingMode.markedEntities[entity] then
                        -- Unmark
                        targetingMode.markedEntities[entity] = nil
                        SetEntityDrawOutline(entity, true)
                        SetEntityDrawOutlineColor(0, 255, 0, 255)

                        client.notify('Entity Unmarked', 'Prop removed from despawn list', 'warning')
                    else
                        -- Mark
                        local entityData = {
                            entity = entity,
                            model = GetEntityModel(entity),
                            coords = GetEntityCoords(entity),
                            heading = GetEntityHeading(entity)
                        }

                        targetingMode.markedEntities[entity] = entityData
                        SetEntityDrawOutline(entity, true)
                        SetEntityDrawOutlineColor(255, 100, 0, 255) -- Orange = marked

                        client.notify('Entity Marked', 'Prop marked for despawn', 'success')
                    end
                else
                    client.notify('No Entity', 'No valid entity targeted', 'error')
                end
            elseif IsControlJustPressed(0, 191) then -- ENTER - Apply (confirm all marked)
                if lastHighlightedEntity and not targetingMode.markedEntities[lastHighlightedEntity] then
                    SetEntityDrawOutline(lastHighlightedEntity, false)
                end

                targetingMode.active = false
                targetingMode.confirmed = true -- Switch outline color to RED

                -- Send all marked entities to server now
                for _, entityData in pairs(targetingMode.markedEntities) do
                    if targetingMode.onConfirm then
                        targetingMode.onConfirm(entityData)
                    end
                end

                local markedFinalCount = 0
                for _ in pairs(targetingMode.markedEntities) do markedFinalCount = markedFinalCount + 1 end

                client.notify('Targeting Applied', string.format('%d props confirmed for despawn (shown in RED)', markedFinalCount), 'success')

                -- Reopen menu after a short delay so the notification is visible
                if onComplete then
                    Wait(500)
                    onComplete()
                end
            elseif IsControlJustPressed(0, 194) then -- BACKSPACE - Cancel
                if lastHighlightedEntity then
                    SetEntityDrawOutline(lastHighlightedEntity, false)
                end

                for ent, _ in pairs(targetingMode.markedEntities) do
                    if DoesEntityExist(ent) then
                        SetEntityDrawOutline(ent, false)
                    end
                end
                targetingMode.markedEntities = {}
                targetingMode.confirmed = false
                targetingMode.active = false

                client.notify('Targeting Cancelled', 'No props marked', 'warning')

                -- Reopen menu
                if onComplete then
                    Wait(500)
                    onComplete()
                end
            end
        end
    end)
end

--- Clear all marked entity highlights
function ClearMarkedEntities()
    for entity, _ in pairs(targetingMode.markedEntities) do
        if DoesEntityExist(entity) then
            SetEntityDrawOutline(entity, false)
        end
    end
    targetingMode.markedEntities = {}
    targetingMode.confirmed = false
end

--- Remove a specific confirmed entity outline by model + coords (called when unmarking from menu)
---@param model number
---@param coords table {x, y, z}
function RemoveConfirmedEntityOutline(model, coords)
    for entity, data in pairs(targetingMode.markedEntities) do
        if data.model == model then
            local eCoords = data.coords
            local dist = #(vector3(eCoords.x, eCoords.y, eCoords.z) - vector3(coords.x, coords.y, coords.z))
            if dist < 1.0 then
                if DoesEntityExist(entity) then
                    SetEntityDrawOutline(entity, false)
                end
                targetingMode.markedEntities[entity] = nil
                return true
            end
        end
    end
    return false
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    DESPAWN TARGETING EVENT (called from menu)
    ═══════════════════════════════════════════════════════════════════════════
]]--

AddEventHandler('gym_group:startDespawnTargeting', function()
    StartEntityTargetingMode(
        function(entityData) -- onConfirm: send each entity to server
            TriggerServerEvent('gym_group:addDespawnEntity', entityData)
        end,
        function() -- onComplete: reopen menu
            TriggerEvent('gym_group:reopenActiveMenu')
        end
    )
end)

-- Notify when despawn entity is added
RegisterNetEvent('gym_group:despawnEntityAdded')
AddEventHandler('gym_group:despawnEntityAdded', function(entityData, totalDespawned)
    client.notify('Entity Queued', string.format('Model %s will be despawned when group loads (%d total)', entityData.model, totalDespawned), 'info')
end)

RegisterNetEvent('gym_group:despawnEntityRemoved')
AddEventHandler('gym_group:despawnEntityRemoved', function(removedEntity, totalDespawned)
    -- Remove outline from the specific entity
    if removedEntity then
        RemoveConfirmedEntityOutline(removedEntity.model, removedEntity.coords)
    end
    client.notify('Entity Removed', string.format('%d despawn targets remaining', totalDespawned), 'warning')
end)

--[[
    ═══════════════════════════════════════════════════════════════════════════
    LATE JOINER SYNC - Request despawn data for groups loaded before we joined
    ═══════════════════════════════════════════════════════════════════════════
]]--

CreateThread(function()
    -- Wait for session to start and locations to sync (main.lua waits 1500ms + processing)
    while not NetworkIsSessionStarted() do Wait(100) end
    Wait(3000)

    local despawnMap = lib.callback.await('gym_group:getDespawnData', false)
    if despawnMap and next(despawnMap) then
        local count = 0
        for locationName, entities in pairs(despawnMap) do
            despawnData[locationName] = entities
            count = count + 1

            -- If we're already inside this location, start monitoring
            if playerInsideLocations[locationName] then
                OnLocationEnter(locationName)
            else
                -- Try immediate deletion anyway (we might be close enough to see them)
                RunDespawnCheck(locationName)
            end
        end
        lib.print.info(string.format("[DESPAWN] Late-joiner sync: received despawn data for %d locations", count))
    end
end)

--[[
    ═══════════════════════════════════════════════════════════════════════════
    CLEANUP
    ═══════════════════════════════════════════════════════════════════════════
]]--

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        ClearMarkedEntities()
        -- Stop all monitors
        for locationName, _ in pairs(activeMonitors) do
            activeMonitors[locationName] = nil
        end
        despawnData = {}
        playerInsideLocations = {}
    end
end)

lib.print.info("[DESPAWN] Despawn system loaded")
