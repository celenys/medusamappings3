--[[
    ═══════════════════════════════════════════════════════════════════════════
    PROP GROUP MANAGER - SERVER SIDE
    ═══════════════════════════════════════════════════════════════════════════
    
    Handles:
    - Group creation/saving/loading/editing/deleting
    - Tracking changes to loaded groups
    - File persistence (groups/saved_groups.json)
    - Permission checks (ACE + creator license)
    - Auto-loading groups on server start
    
    ═══════════════════════════════════════════════════════════════════════════
]]--

local config = require 'config.config_s'
local cconfig = require 'config.config_c'

-- Active group editing sessions (per player source)
local activeSessions = {}

-- Loaded groups (currently spawned) - maps groupName -> list of instanceNames
local loadedGroups = {}

-- Track original group state for change detection
local originalGroupStates = {}

-- File path for saved groups
local GROUPS_FILE = "groups/saved_groups.json"

--[[
    ═══════════════════════════════════════════════════════════════════════════
    UTILITY FUNCTIONS
    ═══════════════════════════════════════════════════════════════════════════
]]--

--- Get player license identifier (framework-agnostic)
---@param source number Player server ID
---@return string? license
local function GetPlayerLicense(source)
    local license = GetPlayerIdentifierByType(source, 'license')
    if not license then
        for _, id in ipairs(GetPlayerIdentifiers(source)) do
            if string.find(id, 'license:') then
                license = id
                break
            end
        end
    end
    return license
end

--- Check if a player has permission for a group action
---@param source number Player server ID
---@param groupData? table Group data (for creator check)
---@param action 'create'|'edit'|'delete'|'load'|'unload'|'autoload'
---@return boolean hasPermission
local function HasGroupPermission(source, groupData, action)
    local aceGroup = config.gymCreator.restricted
    local isAdmin = false

    if aceGroup and aceGroup ~= false then
        isAdmin = IsPlayerAceAllowed(source, 'command.gymcreator')
    else
        isAdmin = true -- No restriction set, everyone has access
    end

    -- Admin always has full access
    if isAdmin then return true end

    -- Creator-based permissions
    if groupData and groupData.creatorLicense then
        local playerLicense = GetPlayerLicense(source)
        if playerLicense and playerLicense == groupData.creatorLicense then
            if action == 'edit' and config.groups.creatorCanEdit then
                return true
            end
            if action == 'delete' and config.groups.creatorCanDelete then
                return true
            end
        end
    end

    return false
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    FILE OPERATIONS
    ═══════════════════════════════════════════════════════════════════════════
]]--

local function LoadGroupsFromFile()
    local file = LoadResourceFile(GetCurrentResourceName(), GROUPS_FILE)

    if not file then
        lib.print.debug("[GROUP MANAGER] No saved groups file found")
        return {}
    end

    local success, groups = pcall(json.decode, file)

    if not success then
        lib.print.error("[GROUP MANAGER] Failed to parse saved_groups.json")
        return {}
    end

    return groups or {}
end

local function SaveGroupsToFile(groups)
    local json_data = json.encode(groups, {indent = true})

    if not json_data then
        lib.print.error("[GROUP MANAGER] Failed to encode groups to JSON")
        return false
    end

    SaveResourceFile(GetCurrentResourceName(), GROUPS_FILE, json_data, -1)
    return true
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    CHANGE DETECTION
    ═══════════════════════════════════════════════════════════════════════════
]]--

local function HasGroupChanged(groupName, session)
    if not originalGroupStates[groupName] then return false end

    local original = originalGroupStates[groupName]

    -- Check prop count changed
    if #original.props ~= #session.props then return true end

    -- Check despawn count changed
    local origDespawn = original.despawnedEntities or {}
    local sessDespawn = session.despawnedEntities or {}
    if #origDespawn ~= #sessDespawn then return true end

    -- Deep-check each prop (coords, equipment type, bar data)
    for i, origProp in ipairs(original.props) do
        local sessProp = session.props[i]
        if not sessProp then return true end
        if origProp.equipmentType ~= sessProp.equipmentType then return true end
        if origProp.coords.x ~= sessProp.coords.x or origProp.coords.y ~= sessProp.coords.y
            or origProp.coords.z ~= sessProp.coords.z or origProp.coords.w ~= sessProp.coords.w then
            return true
        end
        -- Check bar data changes
        local origBar = origProp.bar
        local sessBar = sessProp.bar
        if (origBar and not sessBar) or (not origBar and sessBar) then return true end
        if origBar and sessBar then
            if origBar.x ~= sessBar.x or origBar.y ~= sessBar.y
                or origBar.z ~= sessBar.z or origBar.w ~= sessBar.w then
                return true
            end
        end
    end

    -- Deep-check each despawned entity (model, coords)
    for i, origEnt in ipairs(origDespawn) do
        local sessEnt = sessDespawn[i]
        if not sessEnt then return true end
        if origEnt.model ~= sessEnt.model then return true end
        if origEnt.coords.x ~= sessEnt.coords.x or origEnt.coords.y ~= sessEnt.coords.y
            or origEnt.coords.z ~= sessEnt.coords.z then
            return true
        end
    end

    return false
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    GROUP LOADING / UNLOADING (using existing exports)
    ═══════════════════════════════════════════════════════════════════════════
]]--

--- Build a location config from group data and load it via CreateGymLocation
---@param groupName string
---@param groupData table
---@return boolean success
local function LoadGroupLocation(groupName, groupData)
    local props = groupData.props
    if not props or #props == 0 then
        lib.print.warn(string.format("[GROUP MANAGER] Group '%s' has no props to load", groupName))
        return false
    end

    -- Calculate center coords from all props
    local sumX, sumY, sumZ = 0, 0, 0
    for _, prop in ipairs(props) do
        local c = prop.coords
        sumX = sumX + c.x
        sumY = sumY + c.y
        sumZ = sumZ + c.z
    end
    local count = #props
    local centerCoords = vector3(sumX / count, sumY / count, sumZ / count)

    -- Build props table grouped by equipment type
    local propsTable = {}
    for _, prop in ipairs(props) do
        if not propsTable[prop.equipmentType] then
            propsTable[prop.equipmentType] = {}
        end
        if prop.bar then
            table.insert(propsTable[prop.equipmentType], {
                coords = vector4(prop.coords.x, prop.coords.y, prop.coords.z, prop.coords.w),
                bar = vector4(prop.bar.x, prop.bar.y, prop.bar.z, prop.bar.w)
            })
        else
            table.insert(propsTable[prop.equipmentType], vector4(prop.coords.x, prop.coords.y, prop.coords.z, prop.coords.w))
        end
    end

    local locationName = "group_" .. groupName

    local locationData = {
        coords = centerCoords,
        props = propsTable,
    }

    local success, err = exports[cache.resource]:CreateGymLocation(locationName, locationData)
    if not success then
        lib.print.error(string.format("[GROUP MANAGER] Failed to create location for group '%s': %s", groupName, err or "unknown"))
        return false
    end

    -- Track loaded group (including despawn data for late-joiner sync)
    loadedGroups[groupName] = {
        locationName = locationName,
        propCount = count,
        despawnedEntities = groupData.despawnedEntities or {},
    }

    -- Notify clients about despawned entities
    local despawnedEntities = groupData.despawnedEntities
    if despawnedEntities and #despawnedEntities > 0 then
        TriggerClientEvent('gym_group:despawnEntities', -1, locationName, despawnedEntities)
        lib.print.info(string.format("[GROUP MANAGER] Sent despawn request for group '%s' (%d entities)", groupName, #despawnedEntities))
    end

    lib.print.info(string.format("[GROUP MANAGER] Loaded group '%s' as location '%s' (%d props, %d despawned)", groupName, locationName, count, despawnedEntities and #despawnedEntities or 0))
    return true
end

--- Unload a group by removing its gym location
---@param groupName string
---@return boolean success
local function UnloadGroupLocation(groupName)
    if not loadedGroups[groupName] then
        return false
    end

    local locationName = loadedGroups[groupName].locationName

    -- Notify clients to stop despawn monitoring and respawn entities
    TriggerClientEvent('gym_group:respawnEntities', -1, locationName)

    exports[cache.resource]:RemoveGymLocation(locationName)

    loadedGroups[groupName] = nil
    originalGroupStates[groupName] = nil

    lib.print.info(string.format("[GROUP MANAGER] Unloaded group '%s'", groupName))
    return true
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    CALLBACKS FOR MENU
    ═══════════════════════════════════════════════════════════════════════════
]]--

lib.callback.register('gym_group:checkPermission', function(source)
    return HasGroupPermission(source, nil, 'create')
end)

lib.callback.register('gym_group:getMenuData', function(source)
    local savedGroups = LoadGroupsFromFile()

    -- Add loaded status and permission info
    local playerLicense = GetPlayerLicense(source)
    for _, group in ipairs(savedGroups) do
        group.loaded = loadedGroups[group.name] ~= nil
        group.canEdit = HasGroupPermission(source, group, 'edit')
        group.canDelete = HasGroupPermission(source, group, 'delete')
        group.isCreator = playerLicense and group.creatorLicense == playerLicense or false
    end

    -- Get active session (return a copy so we don't mutate the real session)
    local activeGroup = nil
    local session = activeSessions[source]
    if session then
        activeGroup = {
            name = session.name,
            originalName = session.originalName,
            props = session.props,
            despawnedEntities = session.despawnedEntities,
            createdAt = session.createdAt,
            isSaved = session.originalName ~= nil,
        }
    end

    -- Check if active group has changes
    local hasChanges = false
    if session and session.originalName then
        hasChanges = HasGroupChanged(session.originalName, session)
    end

    return savedGroups, activeGroup, hasChanges
end)

--[[
    ═══════════════════════════════════════════════════════════════════════════
    GROUP CRUD CALLBACKS
    ═══════════════════════════════════════════════════════════════════════════
]]--

lib.callback.register('gym_group:createGroup', function(source, groupName)
    if not HasGroupPermission(source, nil, 'create') then
        return false, "Permission denied"
    end

    if not groupName or groupName == "" then
        return false, "Invalid group name"
    end

    -- Check if group already exists
    local savedGroups = LoadGroupsFromFile()
    for _, group in ipairs(savedGroups) do
        if group.name == groupName then
            return false, "Group already exists"
        end
    end

    -- Cancel any existing session
    if activeSessions[source] then
        activeSessions[source] = nil
    end

    -- Create new session
    activeSessions[source] = {
        name = groupName,
        props = {},
        despawnedEntities = {},
        createdAt = os.time(),
        isSaved = false
    }

    lib.print.info(string.format("[GROUP MANAGER] Player %d created group session '%s'", source, groupName))
    return true, string.format('Group "%s" created', groupName)
end)

lib.callback.register('gym_group:saveGroup', function(source)
    if not activeSessions[source] then
        return false, "No active group"
    end

    local session = activeSessions[source]

    if #session.props == 0 then
        return false, "Add at least one prop"
    end

    local savedGroups = LoadGroupsFromFile()

    local playerLicense = GetPlayerLicense(source)

    table.insert(savedGroups, {
        name = session.name,
        props = session.props,
        despawnedEntities = session.despawnedEntities or {},
        createdAt = session.createdAt,
        createdBy = GetPlayerName(source),
        creatorLicense = playerLicense,
        autoload = true,
        requireMembership = false,
    })

    if SaveGroupsToFile(savedGroups) then
        -- Load the group immediately
        local groupData = savedGroups[#savedGroups]
        LoadGroupLocation(session.name, groupData)

        -- Store original state for change detection
        originalGroupStates[session.name] = {
            props = json.decode(json.encode(session.props)),
            despawnedEntities = json.decode(json.encode(session.despawnedEntities or {})),
        }

        activeSessions[source] = nil

        lib.print.info(string.format("[GROUP MANAGER] Group '%s' saved by %s (%d props, %d despawned)",
            session.name, GetPlayerName(source), #groupData.props, #groupData.despawnedEntities))

        return true, string.format('Group "%s" saved with %d props', session.name, #groupData.props)
    else
        return false, "Failed to save"
    end
end)

lib.callback.register('gym_group:saveChanges', function(source)
    if not activeSessions[source] then
        return false, "No active group"
    end

    local session = activeSessions[source]

    if not session.originalName then
        return false, "This is a new group, use Save Group instead"
    end

    local savedGroups = LoadGroupsFromFile()
    local updated = false

    for i, group in ipairs(savedGroups) do
        if group.name == session.originalName then
            savedGroups[i].props = session.props
            savedGroups[i].despawnedEntities = session.despawnedEntities or {}
            updated = true
            break
        end
    end

    if updated and SaveGroupsToFile(savedGroups) then
        -- Unload and reload the group with updated data
        UnloadGroupLocation(session.originalName)

        local groupData
        for _, group in ipairs(savedGroups) do
            if group.name == session.originalName then
                groupData = group
                break
            end
        end

        if groupData then
            LoadGroupLocation(session.originalName, groupData)
        end

        -- Update original state
        originalGroupStates[session.originalName] = {
            props = json.decode(json.encode(session.props)),
            despawnedEntities = json.decode(json.encode(session.despawnedEntities or {})),
        }

        activeSessions[source] = nil

        lib.print.info(string.format("[GROUP MANAGER] Changes saved to '%s' (%d props, %d despawned)",
            session.originalName, #session.props, session.despawnedEntities and #session.despawnedEntities or 0))

        return true, string.format('Changes saved to "%s"', session.originalName)
    else
        return false, "Failed to save changes"
    end
end)

lib.callback.register('gym_group:cancelGroup', function(source)
    if activeSessions[source] then
        local groupName = activeSessions[source].name
        activeSessions[source] = nil
        return true, string.format('Cancelled "%s"', groupName)
    end
    return false, "No active group"
end)

lib.callback.register('gym_group:loadGroup', function(source, groupName)
    if not HasGroupPermission(source, nil, 'load') then
        return false, "Permission denied"
    end

    if loadedGroups[groupName] then
        return false, "Already loaded"
    end

    local savedGroups = LoadGroupsFromFile()
    local targetGroup = nil

    for _, group in ipairs(savedGroups) do
        if group.name == groupName then
            targetGroup = group
            break
        end
    end

    if not targetGroup then
        return false, "Group not found"
    end

    if LoadGroupLocation(groupName, targetGroup) then
        -- Store original state
        originalGroupStates[groupName] = {
            props = json.decode(json.encode(targetGroup.props)),
            despawnedEntities = json.decode(json.encode(targetGroup.despawnedEntities or {})),
        }

        return true, string.format('Loaded "%s" (%d props)', groupName, #targetGroup.props)
    else
        return false, "Failed to load group"
    end
end)

lib.callback.register('gym_group:unloadGroup', function(source, groupName)
    if not HasGroupPermission(source, nil, 'unload') then
        return false, "Permission denied"
    end

    if not loadedGroups[groupName] then
        return false, "Not loaded"
    end

    -- Block if someone is editing this group
    for otherSource, otherSession in pairs(activeSessions) do
        if otherSession.originalName == groupName then
            local otherName = GetPlayerName(otherSource) or tostring(otherSource)
            return false, string.format('Cannot unload - being edited by %s', otherName)
        end
    end

    if UnloadGroupLocation(groupName) then
        return true, string.format('Unloaded "%s"', groupName)
    else
        return false, "Failed to unload"
    end
end)

lib.callback.register('gym_group:editGroup', function(source, groupName)
    local savedGroups = LoadGroupsFromFile()
    local targetGroup = nil

    for _, group in ipairs(savedGroups) do
        if group.name == groupName then
            targetGroup = group
            break
        end
    end

    if not targetGroup then
        return false, "Group not found"
    end

    if not HasGroupPermission(source, targetGroup, 'edit') then
        return false, "Permission denied"
    end

    if not loadedGroups[groupName] then
        return false, "Group must be loaded to edit"
    end

    -- Check if another player is already editing this group
    for otherSource, otherSession in pairs(activeSessions) do
        if otherSource ~= source and otherSession.originalName == groupName then
            local otherName = GetPlayerName(otherSource) or tostring(otherSource)
            return false, string.format('Already being edited by %s', otherName)
        end
    end

    -- Cancel any existing session for this player
    if activeSessions[source] then
        activeSessions[source] = nil
    end

    -- Create active session from saved group data
    activeSessions[source] = {
        name = groupName,
        originalName = groupName,
        props = json.decode(json.encode(targetGroup.props)),
        despawnedEntities = json.decode(json.encode(targetGroup.despawnedEntities or {})),
        createdAt = targetGroup.createdAt,
        isSaved = true,
    }

    lib.print.info(string.format("[GROUP MANAGER] Player %d editing group '%s'", source, groupName))
    return true, string.format('Editing "%s"', groupName)
end)

lib.callback.register('gym_group:deleteGroup', function(source, groupName)
    local savedGroups = LoadGroupsFromFile()
    local targetGroup = nil

    for _, group in ipairs(savedGroups) do
        if group.name == groupName then
            targetGroup = group
            break
        end
    end

    if not targetGroup then
        return false, "Group not found"
    end

    if not HasGroupPermission(source, targetGroup, 'delete') then
        return false, "Permission denied"
    end

    -- Block if someone is editing this group
    for otherSource, otherSession in pairs(activeSessions) do
        if otherSource ~= source and otherSession.originalName == groupName then
            local otherName = GetPlayerName(otherSource) or tostring(otherSource)
            return false, string.format('Cannot delete - being edited by %s', otherName)
        end
    end

    -- Unload if loaded
    if loadedGroups[groupName] then
        UnloadGroupLocation(groupName)
    end

    -- Remove from saved groups
    local newGroups = {}
    for _, group in ipairs(savedGroups) do
        if group.name ~= groupName then
            table.insert(newGroups, group)
        end
    end

    if SaveGroupsToFile(newGroups) then
        lib.print.info(string.format("[GROUP MANAGER] Group '%s' deleted by player %d", groupName, source))
        return true, string.format('Deleted "%s"', groupName)
    else
        return false, "Failed to save"
    end
end)

lib.callback.register('gym_group:toggleAutoload', function(source, groupName)
    if not HasGroupPermission(source, nil, 'autoload') then
        return false, "Permission denied"
    end

    local savedGroups = LoadGroupsFromFile()
    local found = false
    local newState = false

    for i, group in ipairs(savedGroups) do
        if group.name == groupName then
            savedGroups[i].autoload = not savedGroups[i].autoload
            newState = savedGroups[i].autoload
            found = true
            break
        end
    end

    if not found then
        return false, "Group not found"
    end

    if SaveGroupsToFile(savedGroups) then
        return true, newState
    else
        return false, "Failed to save"
    end
end)

lib.callback.register('gym_group:toggleMembership', function(source, groupName)
    if not HasGroupPermission(source, nil, 'edit') then
        return false, "Permission denied"
    end

    local savedGroups = LoadGroupsFromFile()
    local found = false
    local newState = false

    for i, group in ipairs(savedGroups) do
        if group.name == groupName then
            savedGroups[i].requireMembership = not (savedGroups[i].requireMembership or false)
            newState = savedGroups[i].requireMembership
            found = true
            break
        end
    end

    if not found then
        return false, "Group not found"
    end

    if SaveGroupsToFile(savedGroups) then
        return true, newState
    else
        return false, "Failed to save"
    end
end)

--[[
    ═══════════════════════════════════════════════════════════════════════════
    ADD/REMOVE PROPS FROM ACTIVE GROUP
    ═══════════════════════════════════════════════════════════════════════════
]]--

RegisterNetEvent('gym_group:addProp')
AddEventHandler('gym_group:addProp', function(propData)
    local src = source

    if not activeSessions[src] then return end

    -- Validate equipment type exists in config
    if not propData.equipmentType or not cconfig.props[propData.equipmentType] then
        lib.print.warn(string.format("[GROUP MANAGER] Player %d sent invalid equipment type: %s", src, tostring(propData.equipmentType)))
        return
    end

    -- Validate coords
    if not propData.coords or not propData.coords.x or not propData.coords.y or not propData.coords.z or not propData.coords.w then
        lib.print.warn(string.format("[GROUP MANAGER] Player %d sent invalid coords for prop", src))
        return
    end

    table.insert(activeSessions[src].props, {
        equipmentType = propData.equipmentType,
        coords = propData.coords,
        bar = propData.bar or nil,
    })

    TriggerClientEvent('gym_group:propAdded', src, propData, #activeSessions[src].props)
end)

RegisterNetEvent('gym_group:removeProp')
AddEventHandler('gym_group:removeProp', function(propIndex)
    local src = source

    if not activeSessions[src] then return end

    if activeSessions[src].props[propIndex] then
        local removed = table.remove(activeSessions[src].props, propIndex)
        TriggerClientEvent('gym_group:propRemoved', src, removed, #activeSessions[src].props)
    end
end)

RegisterNetEvent('gym_group:updateProp')
AddEventHandler('gym_group:updateProp', function(propIndex, newPropData)
    local src = source

    if not activeSessions[src] then return end

    if activeSessions[src].props[propIndex] then
        activeSessions[src].props[propIndex] = {
            equipmentType = newPropData.equipmentType,
            coords = newPropData.coords,
            bar = newPropData.bar or nil,
        }

        lib.print.debug(string.format("[GROUP MANAGER] Updated prop #%d (%s) position in group '%s'",
            propIndex, newPropData.equipmentType, activeSessions[src].name))

        TriggerClientEvent('gym_group:propUpdated', src, propIndex, newPropData)
    end
end)

RegisterNetEvent('gym_group:addDespawnEntity')
AddEventHandler('gym_group:addDespawnEntity', function(entityData)
    local src = source

    if not activeSessions[src] then return end

    -- Validate entity data
    if not entityData.model or not entityData.coords then
        lib.print.warn(string.format("[GROUP MANAGER] Player %d sent invalid despawn entity data", src))
        return
    end

    if not entityData.coords.x or not entityData.coords.y or not entityData.coords.z then
        lib.print.warn(string.format("[GROUP MANAGER] Player %d sent invalid despawn entity coords", src))
        return
    end

    if not activeSessions[src].despawnedEntities then
        activeSessions[src].despawnedEntities = {}
    end

    table.insert(activeSessions[src].despawnedEntities, {
        model = entityData.model,
        coords = {
            x = entityData.coords.x,
            y = entityData.coords.y,
            z = entityData.coords.z
        },
        heading = entityData.heading
    })

    lib.print.debug(string.format("[GROUP MANAGER] Added despawn entity (model: %s) to group '%s' (%d total)",
        entityData.model, activeSessions[src].name, #activeSessions[src].despawnedEntities))

    TriggerClientEvent('gym_group:despawnEntityAdded', src, entityData, #activeSessions[src].despawnedEntities)
end)

RegisterNetEvent('gym_group:removeDespawnEntity')
AddEventHandler('gym_group:removeDespawnEntity', function(entityIndex)
    local src = source

    if not activeSessions[src] then return end

    if activeSessions[src].despawnedEntities and activeSessions[src].despawnedEntities[entityIndex] then
        local removedEntity = table.remove(activeSessions[src].despawnedEntities, entityIndex)
        TriggerClientEvent('gym_group:despawnEntityRemoved', src, removedEntity, #activeSessions[src].despawnedEntities)
    end
end)

--[[
    ═══════════════════════════════════════════════════════════════════════════
    ACTIVE SESSION QUERY (for client-side checks)
    ═══════════════════════════════════════════════════════════════════════════
]]--

lib.callback.register('gym_group:getActiveSession', function(source)
    return activeSessions[source] or nil
end)

--- Late-joiner sync: returns despawn data for all currently loaded groups
lib.callback.register('gym_group:getDespawnData', function(source)
    local result = {}
    for groupName, groupInfo in pairs(loadedGroups) do
        if groupInfo.despawnedEntities and #groupInfo.despawnedEntities > 0 then
            result[groupInfo.locationName] = groupInfo.despawnedEntities
        end
    end
    return result
end)

--[[
    ═══════════════════════════════════════════════════════════════════════════
    CLEANUP
    ═══════════════════════════════════════════════════════════════════════════
]]--

AddEventHandler('playerDropped', function()
    local src = source
    if activeSessions[src] then
        lib.print.debug(string.format("[GROUP MANAGER] Cleaning up session for disconnected player %d", src))
        activeSessions[src] = nil
    end
end)

--[[
    ═══════════════════════════════════════════════════════════════════════════
    AUTO-LOAD ON SERVER START
    ═══════════════════════════════════════════════════════════════════════════
]]--

CreateThread(function()
    Wait(3000) -- Wait for server to fully initialize and exports to be ready

    local savedGroups = LoadGroupsFromFile()

    if #savedGroups == 0 then
        lib.print.debug("[GROUP MANAGER] No saved groups to auto-load")
        return
    end

    local autoloadCount = 0
    local autoloadAttempted = 0
    local totalCount = #savedGroups

    for _, group in ipairs(savedGroups) do
        if group.autoload then
            autoloadAttempted = autoloadAttempted + 1
            lib.print.info(string.format("[GROUP MANAGER] Auto-loading group '%s' (%d props)", group.name, #group.props))
            if LoadGroupLocation(group.name, group) then
                -- Store original state
                originalGroupStates[group.name] = {
                    props = json.decode(json.encode(group.props)),
                    despawnedEntities = json.decode(json.encode(group.despawnedEntities or {})),
                }
                autoloadCount = autoloadCount + 1
            end
        end
    end

    lib.print.info(string.format("[GROUP MANAGER] Auto-loaded %d/%d groups (total saved: %d)", autoloadCount, autoloadAttempted, totalCount))
end)

lib.print.info("[GROUP MANAGER] Group management system loaded")
