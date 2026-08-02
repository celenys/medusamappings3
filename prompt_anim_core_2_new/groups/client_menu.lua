--[[
    ═══════════════════════════════════════════════════════════════════════════
    GROUP MANAGEMENT MENU - CLIENT SIDE
    ═══════════════════════════════════════════════════════════════════════════
    
    Single menu for:
    - Creating/managing prop groups
    - Loading/unloading groups
    - Editing groups (add props, mark despawns)
    - Saving group changes
    - Toggling autoload
    
    Command: /gym_groups (configurable)
    
    ═══════════════════════════════════════════════════════════════════════════
]]--

local client = require 'config.client'

-- Preview entities placed during group editing session
-- These are temporary local entities that must be deleted before the location
-- system spawns its own managed props (on save/cancel).
local previewEntities = {}

--- Delete all preview entities and clear the tracking table
local function CleanupPreviewEntities()
    for i = #previewEntities, 1, -1 do
        local ent = previewEntities[i]
        if ent and DoesEntityExist(ent) then
            SetEntityAsMissionEntity(ent, true, true)
            DeleteEntity(ent)
        end
        previewEntities[i] = nil
    end
end

-- Forward declarations (functions reference each other)
local ShowMainMenu
local ShowActiveGroupMenu
local ShowGroupManageMenu
local ShowPropEditMenu

--[[
    ═══════════════════════════════════════════════════════════════════════════
    MAIN MENU
    ═══════════════════════════════════════════════════════════════════════════
]]--

ShowMainMenu = function()
    local groups, activeGroup, hasChanges = lib.callback.await('gym_group:getMenuData', false)
    groups = groups or {}

    local options = {}

    -- Create New Group
    table.insert(options, {
        title = 'Create New Group',
        description = 'Start creating a new prop group',
        icon = 'plus-circle',
        iconColor = '#00ff00',
        onSelect = function()
            local input = lib.inputDialog('Create New Group', {
                {
                    type = 'input',
                    label = 'Group Name',
                    description = 'Enter a unique name for this group',
                    required = true,
                    min = 3,
                    max = 50
                }
            })

            if not input then
                ShowMainMenu()
                return
            end

            local success, message = lib.callback.await('gym_group:createGroup', false, input[1])
            if success then
                client.notify('Group Created', message, 'success')
            else
                client.notify('Creation Failed', message, 'error')
            end
            ShowMainMenu()
        end
    })

    -- Active Group (if exists)
    if activeGroup then
        local statusText = hasChanges and 'UNSAVED CHANGES' or 'Up to date'

        table.insert(options, {
            title = '-----------------------------',
            disabled = true,
        })

        table.insert(options, {
            title = 'Active Group: ' .. activeGroup.name,
            description = string.format('%d props | %d despawned | %s',
                #activeGroup.props,
                activeGroup.despawnedEntities and #activeGroup.despawnedEntities or 0,
                statusText),
            icon = 'box-open',
            iconColor = hasChanges and '#ffa500' or '#00ff00',
            onSelect = function()
                ShowActiveGroupMenu(activeGroup, hasChanges)
            end
        })
    end

    -- Separator for saved groups
    if #groups > 0 then
        table.insert(options, {
            title = '-----------------------------',
            disabled = true,
        })

        table.insert(options, {
            title = 'Saved Groups (' .. #groups .. ')',
            icon = 'folder',
            disabled = true
        })
    end

    -- List Saved Groups
    for _, group in ipairs(groups) do
        local statusText = group.loaded and 'LOADED' or 'UNLOADED'
        local autoloadText = group.autoload and ' | AUTO' or ''
        local creatorText = group.isCreator and ' | YOURS' or ''

        table.insert(options, {
            title = group.name,
            description = string.format('%s | %d props%s%s', statusText, #group.props, autoloadText, creatorText),
            icon = group.loaded and 'check-circle' or 'circle',
            iconColor = group.loaded and '#00ff00' or '#888888',
            onSelect = function()
                ShowGroupManageMenu(group)
            end
        })
    end

    lib.registerContext({
        id = 'gym_group_main_menu',
        title = 'Group Manager',
        options = options
    })

    lib.showContext('gym_group_main_menu')
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    ACTIVE GROUP MENU
    ═══════════════════════════════════════════════════════════════════════════
]]--

ShowActiveGroupMenu = function(activeGroup, hasChanges)
    -- Refresh data from server
    local _, freshActiveGroup, freshHasChanges = lib.callback.await('gym_group:getMenuData', false)
    if freshActiveGroup then activeGroup = freshActiveGroup end
    if freshHasChanges ~= nil then hasChanges = freshHasChanges end

    if not activeGroup then
        client.notify('No Active Group', 'Group session ended', 'error')
        ShowMainMenu()
        return
    end

    local options = {}

    -- Group Info
    table.insert(options, {
        title = activeGroup.name,
        description = string.format('%d props | %d despawned',
            #activeGroup.props,
            activeGroup.despawnedEntities and #activeGroup.despawnedEntities or 0),
        icon = 'info-circle',
        iconColor = '#00aaff',
        disabled = true
    })

    if hasChanges then
        table.insert(options, {
            title = 'UNSAVED CHANGES',
            description = 'Props have been added/removed since last save',
            icon = 'exclamation-triangle',
            iconColor = '#ffa500',
            disabled = true
        })
    end

    table.insert(options, {
        title = '-----------------------------',
        disabled = true,
    })

    -- Add Prop
    table.insert(options, {
        title = 'Add Prop',
        description = 'Place a new equipment prop (opens gym creator)',
        icon = 'plus',
        iconColor = '#00ff00',
        onSelect = function()
            TriggerEvent('gym_group:startPropPlacement')
        end
    })

    -- Mark Prop for Despawn
    table.insert(options, {
        title = 'Mark Prop for Despawn',
        description = 'Target a world prop to remove when this group loads',
        icon = 'crosshairs',
        iconColor = '#ff6600',
        onSelect = function()
            lib.hideContext()
            TriggerEvent('gym_group:startDespawnTargeting')
        end
    })

    table.insert(options, {
        title = '-----------------------------',
        disabled = true,
    })

    -- Save Changes (only if editing an existing group with changes)
    if activeGroup.isSaved and hasChanges then
        table.insert(options, {
            title = 'Save Changes',
            description = 'Update this group in saved_groups.json',
            icon = 'save',
            iconColor = '#00ff00',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Save Changes?',
                    content = string.format('Update group "%s"? This will overwrite the existing group.', activeGroup.name),
                    centered = true,
                    cancel = true
                })

                if alert == 'confirm' then
                    -- Delete preview entities so location system can spawn proper managed ones
                    CleanupPreviewEntities()
                    local success, message = lib.callback.await('gym_group:saveChanges', false)
                    if success then
                        ClearMarkedEntities()
                        client.notify('Changes Saved', message, 'success')
                    else
                        client.notify('Save Failed', message, 'error')
                    end
                end
                ShowMainMenu()
            end
        })
    end

    -- Save Group (if new)
    if not activeGroup.isSaved then
        table.insert(options, {
            title = 'Save Group',
            description = 'Save this new group to file',
            icon = 'save',
            iconColor = '#00ff00',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Save Group?',
                    content = string.format('Save new group "%s" with %d props?', activeGroup.name, #activeGroup.props),
                    centered = true,
                    cancel = true
                })

                if alert == 'confirm' then
                    -- Delete preview entities so location system can spawn proper managed ones
                    CleanupPreviewEntities()
                    local success, message = lib.callback.await('gym_group:saveGroup', false)
                    if success then
                        ClearMarkedEntities()
                        client.notify('Group Saved', message, 'success')
                    else
                        client.notify('Save Failed', message, 'error')
                    end
                end
                ShowMainMenu()
            end
        })
    end

    -- Cancel Group
    table.insert(options, {
        title = 'Cancel / Exit Editing',
        description = 'Discard changes and exit editing mode',
        icon = 'times-circle',
        iconColor = '#ff0000',
        onSelect = function()
            local alert = lib.alertDialog({
                header = 'Cancel Group?',
                content = string.format('Discard all changes to "%s"?', activeGroup.name),
                centered = true,
                cancel = true
            })

            if alert == 'confirm' then
                -- Delete all preview entities (they're being discarded)
                CleanupPreviewEntities()
                local success, message = lib.callback.await('gym_group:cancelGroup', false)
                ClearMarkedEntities()
                client.notify('Group Cancelled', message or 'Cancelled', 'warning')
            end
            ShowMainMenu()
        end
    })

    -- List Props (clickable to move/delete)
    if #activeGroup.props > 0 then
        table.insert(options, {
            title = '-----------------------------',
            disabled = true,
        })

        table.insert(options, {
            title = 'Spawned Props (' .. #activeGroup.props .. ') - Click to edit',
            icon = 'box',
            iconColor = '#00ff00',
            disabled = true
        })

        for i, prop in ipairs(activeGroup.props) do
            local propIndex = i
            local propData = prop
            table.insert(options, {
                title = string.format('%d. %s', i, prop.equipmentType),
                description = string.format('%.1f, %.1f, %.1f | %.1f heading  |  Click to Move/Delete',
                    prop.coords.x, prop.coords.y, prop.coords.z, prop.coords.w),
                icon = 'dumbbell',
                iconColor = '#00aaff',
                onSelect = function()
                    ShowPropEditMenu(propIndex, propData, activeGroup, hasChanges)
                end
            })
        end
    end

    -- List Despawned Entities (clickable to unmark)
    if activeGroup.despawnedEntities and #activeGroup.despawnedEntities > 0 then
        table.insert(options, {
            title = '-----------------------------',
            disabled = true,
        })

        table.insert(options, {
            title = 'Despawned Props (' .. #activeGroup.despawnedEntities .. ') - Click to unmark',
            icon = 'trash',
            iconColor = '#ff0000',
            disabled = true
        })

        for i, entity in ipairs(activeGroup.despawnedEntities) do
            local entityIndex = i
            table.insert(options, {
                title = string.format('%d. Model: %s', i, entity.model),
                description = string.format('%.1f, %.1f, %.1f  |  Click to REMOVE from despawn list',
                    entity.coords.x, entity.coords.y, entity.coords.z),
                icon = 'times-circle',
                iconColor = '#ff0000',
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = 'Remove Despawn?',
                        content = string.format('Remove Model %s from despawn list?\nThis prop will no longer be deleted when the group loads.', entity.model),
                        centered = true,
                        cancel = true
                    })

                    if alert == 'confirm' then
                        TriggerServerEvent('gym_group:removeDespawnEntity', entityIndex)
                        client.notify('Despawn Removed', 'Prop removed from despawn list', 'warning')
                    end
                    ShowActiveGroupMenu(activeGroup, hasChanges)
                end
            })
        end
    end

    lib.registerContext({
        id = 'gym_group_active_menu',
        title = 'Active: ' .. activeGroup.name,
        menu = 'gym_group_main_menu',
        options = options
    })

    lib.showContext('gym_group_active_menu')
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    MANAGE SAVED GROUP
    ═══════════════════════════════════════════════════════════════════════════
]]--

ShowGroupManageMenu = function(group)
    local options = {}

    -- Group Info
    table.insert(options, {
        title = group.name,
        description = string.format('%d props | by %s%s%s',
            #group.props,
            group.createdBy or 'Unknown',
            group.autoload and ' | AUTO-LOAD' or '',
            group.requireMembership and ' | MEMBERS ONLY' or ''),
        icon = 'info-circle',
        iconColor = '#00aaff',
        disabled = true
    })

    table.insert(options, {
        title = '-----------------------------',
        disabled = true,
    })

    -- Load/Unload
    if group.loaded then
        table.insert(options, {
            title = 'Unload Group',
            description = 'Despawn all props (group stays saved)',
            icon = 'pause-circle',
            iconColor = '#ffa500',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Unload Group?',
                    content = string.format('Unload "%s"? Props will despawn but the group stays saved.', group.name),
                    centered = true,
                    cancel = true
                })

                if alert == 'confirm' then
                    local success, message = lib.callback.await('gym_group:unloadGroup', false, group.name)
                    client.notify(success and 'Group Unloaded' or 'Unload Failed', message, success and 'success' or 'error')
                end
                ShowMainMenu()
            end
        })

        -- Edit Group (only if loaded and has permission)
        if group.canEdit then
            table.insert(options, {
                title = 'Edit Group',
                description = 'Add/remove props and despawns',
                icon = 'edit',
                iconColor = '#00aaff',
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = 'Edit Group?',
                        content = string.format('Start editing "%s"? You can add/remove props, then save changes.', group.name),
                        centered = true,
                        cancel = true
                    })

                    if alert == 'confirm' then
                        local success, message = lib.callback.await('gym_group:editGroup', false, group.name)
                        if success then
                            client.notify('Editing Group', message, 'success')
                        else
                            client.notify('Edit Failed', message, 'error')
                        end
                    end
                    ShowMainMenu()
                end
            })
        end
    else
        table.insert(options, {
            title = 'Load Group',
            description = 'Spawn all props',
            icon = 'play-circle',
            iconColor = '#00ff00',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Load Group?',
                    content = string.format('Load "%s"? (%d props)', group.name, #group.props),
                    centered = true,
                    cancel = true
                })

                if alert == 'confirm' then
                    local success, message = lib.callback.await('gym_group:loadGroup', false, group.name)
                    client.notify(success and 'Group Loaded' or 'Load Failed', message, success and 'success' or 'error')
                end
                ShowMainMenu()
            end
        })
    end

    -- Toggle Autoload
    table.insert(options, {
        title = group.autoload and 'Disable Auto-Load' or 'Enable Auto-Load',
        description = group.autoload and 'Group will NOT load on server start' or 'Group will auto-load on server start',
        icon = group.autoload and 'toggle-on' or 'toggle-off',
        iconColor = group.autoload and '#00ff00' or '#888888',
        onSelect = function()
            local success, newState = lib.callback.await('gym_group:toggleAutoload', false, group.name)
            if success then
                client.notify('Auto-Load ' .. (newState and 'Enabled' or 'Disabled'),
                    string.format('"%s" will %sload on server start', group.name, newState and 'auto-' or 'NOT auto-'),
                    'info')
            else
                client.notify('Failed', 'Could not toggle auto-load', 'error')
            end
            ShowMainMenu()
        end
    })

    -- Toggle Membership Requirement
    local membershipEnabled = group.requireMembership or false
    table.insert(options, {
        title = membershipEnabled and 'Disable Membership Requirement' or 'Enable Membership Requirement',
        description = membershipEnabled and 'Anyone can use this gym' or 'Only members can use this gym',
        icon = membershipEnabled and 'id-card' or 'id-card',
        iconColor = membershipEnabled and '#ffa500' or '#888888',
        onSelect = function()
            local success, newState = lib.callback.await('gym_group:toggleMembership', false, group.name)
            if success then
                client.notify('Membership ' .. (newState and 'Required' or 'Not Required'),
                    string.format('"%s" %s membership to use', group.name, newState and 'now requires' or 'no longer requires'),
                    'info')
            else
                client.notify('Failed', 'Could not toggle membership requirement', 'error')
            end
            ShowMainMenu()
        end
    })

    -- Delete Group
    if group.canDelete then
        table.insert(options, {
            title = 'Delete Group',
            description = 'Permanently delete from file',
            icon = 'trash',
            iconColor = '#ff0000',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Delete Group?',
                    content = string.format('PERMANENTLY DELETE "%s"?\n\nThis CANNOT be undone!', group.name),
                    centered = true,
                    cancel = true
                })

                if alert == 'confirm' then
                    local success, message = lib.callback.await('gym_group:deleteGroup', false, group.name)
                    client.notify(success and 'Group Deleted' or 'Delete Failed', message, success and 'success' or 'error')
                end
                ShowMainMenu()
            end
        })
    end

    -- List Props
    if #group.props > 0 then
        table.insert(options, {
            title = '-----------------------------',
            disabled = true,
        })

        for i, prop in ipairs(group.props) do
            table.insert(options, {
                title = string.format('%d. %s', i, prop.equipmentType),
                description = string.format('%.1f, %.1f, %.1f',
                    prop.coords.x, prop.coords.y, prop.coords.z),
                icon = 'dumbbell',
                iconColor = '#888888',
                disabled = true
            })
        end
    end

    lib.registerContext({
        id = 'gym_group_manage_menu',
        title = 'Manage: ' .. group.name,
        menu = 'gym_group_main_menu',
        options = options
    })

    lib.showContext('gym_group_manage_menu')
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    PROP PLACEMENT (integrates with existing creator flow)
    ═══════════════════════════════════════════════════════════════════════════
]]--

AddEventHandler('gym_group:startPropPlacement', function()
    local cconfig = require 'config.config_c'
    local machineOptions = {}

    for machine, data in pairs(cconfig.props) do
        local label = locale('machine_' .. machine) or machine
        table.insert(machineOptions, {
            title = label:sub(1, 1):upper() .. label:sub(2),
            description = machine,
            icon = 'dumbbell',
            onSelect = function()
                lib.hideContext()
                GroupPlaceObject(data.model, label, machine)
            end,
        })
    end

    table.sort(machineOptions, function(a, b)
        return a.title < b.title
    end)

    lib.registerContext({
        id = 'gym_group_add_prop',
        title = 'Add Equipment to Group',
        menu = 'gym_group_active_menu',
        options = machineOptions
    })

    lib.showContext('gym_group_add_prop')
end)

--[[
    ═══════════════════════════════════════════════════════════════════════════
    PROP EDIT MENU (Move / Delete an existing prop)
    ═══════════════════════════════════════════════════════════════════════════
]]--

ShowPropEditMenu = function(propIndex, propData, activeGroup, hasChanges)
    local cconfig = require 'config.config_c'
    local propConfig = cconfig.props[propData.equipmentType]
    local label = propData.equipmentType

    local options = {
        {
            title = string.format('%s (#%d)', label, propIndex),
            description = string.format('%.1f, %.1f, %.1f | %.1f heading',
                propData.coords.x, propData.coords.y, propData.coords.z, propData.coords.w),
            icon = 'dumbbell',
            iconColor = '#00aaff',
            disabled = true
        },
        {
            title = '-----------------------------',
            disabled = true,
        },
        {
            title = 'Move Prop',
            description = 'Pick up and reposition this prop',
            icon = 'arrows-alt',
            iconColor = '#00ff00',
            onSelect = function()
                lib.hideContext()
                GroupMoveProp(propIndex, propData)
            end
        },
        {
            title = 'Delete Prop',
            description = 'Remove this prop from the group',
            icon = 'trash',
            iconColor = '#ff0000',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Delete Prop?',
                    content = string.format('Remove %s (#%d) from the group?', label, propIndex),
                    centered = true,
                    cancel = true
                })

                if alert == 'confirm' then
                    -- Find and delete the world entity
                    local propModel = propConfig and propConfig.model
                    if propModel then
                        local hash = type(propModel) == 'string' and joaat(propModel) or propModel
                        local obj = GetClosestObjectOfType(
                            propData.coords.x, propData.coords.y, propData.coords.z,
                            2.0, hash, false, false, false
                        )
                        if obj and obj ~= 0 and DoesEntityExist(obj) then
                            -- Also remove from preview tracking if it was a preview entity
                            for pi = #previewEntities, 1, -1 do
                                if previewEntities[pi] == obj then
                                    table.remove(previewEntities, pi)
                                    break
                                end
                            end
                            SetEntityAsMissionEntity(obj, true, true)
                            DeleteEntity(obj)
                        end
                    end

                    TriggerServerEvent('gym_group:removeProp', propIndex)
                    client.notify('Prop Deleted', string.format('%s removed from group', label), 'warning')
                end
                ShowActiveGroupMenu(activeGroup, hasChanges)
            end
        },
    }

    lib.registerContext({
        id = 'gym_group_prop_edit',
        title = 'Edit Prop: ' .. label,
        menu = 'gym_group_active_menu',
        options = options
    })

    lib.showContext('gym_group_prop_edit')
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    MOVE EXISTING PROP (pick up, reposition, place back)
    ═══════════════════════════════════════════════════════════════════════════
]]--

--- Move an existing placed prop to a new position
---@param propIndex number Index of the prop in the group
---@param propData table The prop data {equipmentType, coords {x,y,z,w}, bar?}
function GroupMoveProp(propIndex, propData)
    local cconfig = require 'config.config_c'
    local propConfig = cconfig.props[propData.equipmentType]

    if not propConfig then
        client.notify('Error', 'Unknown equipment type: ' .. propData.equipmentType, 'error')
        TriggerEvent('gym_group:reopenActiveMenu')
        return
    end

    local propModel = propConfig.model
    local hash = type(propModel) == 'string' and joaat(propModel) or propModel

    -- Find the existing world entity
    local existingEntity = GetClosestObjectOfType(
        propData.coords.x, propData.coords.y, propData.coords.z,
        2.0, hash, false, false, false
    )

    if not existingEntity or existingEntity == 0 or not DoesEntityExist(existingEntity) then
        client.notify('Error', 'Could not find prop in world. Is the group loaded?', 'error')
        TriggerEvent('gym_group:reopenActiveMenu')
        return
    end

    -- Check if entity is currently hidden (another player may be using it)
    if not IsEntityVisible(existingEntity) then
        client.notify('In Use', 'This prop is currently being used by another player. Try again later.', 'error')
        TriggerEvent('gym_group:reopenActiveMenu')
        return
    end

    -- Pick up the entity - make it ghosted and movable
    SetEntityAsMissionEntity(existingEntity, true, true)
    SetEntityAlpha(existingEntity, 150, false)
    FreezeEntityPosition(existingEntity, true)
    SetEntityCollision(existingEntity, false, true)
    SetEntityDrawOutline(existingEntity, true)

    local placing = true
    local heading = GetEntityHeading(existingEntity)
    local hit, coords

    CreateThread(function()
        while placing do
            local hitt, _, coordss = lib.raycast.fromCamera(511, 4, 30.0)
            hit = hitt
            coords = coordss
            Wait(1)
        end
    end)

    lib.showTextUI('[Scroll] Rotate  \n[Enter] Confirm  \n[Backspace] Cancel')
    while placing do
        Wait(0)
        SetPauseMenuActive(false)
        DisableControlAction(0, 15, true)
        DisableControlAction(0, 14, true)

        if hit and coords then
            SetEntityCoordsNoOffset(existingEntity, coords.x, coords.y, coords.z, false, false, false)
            SetEntityHeading(existingEntity, heading)
            PlaceObjectOnGroundProperly(existingEntity)

            if IsDisabledControlPressed(0, 15) then
                heading = heading + 5.0
            elseif IsDisabledControlPressed(0, 14) then
                heading = heading - 5.0
            elseif IsControlJustPressed(0, 191) then -- ENTER - Confirm new position
                local objCoords = GetEntityCoords(existingEntity)
                local objHeading = GetEntityHeading(existingEntity)

                local newPropData = {
                    equipmentType = propData.equipmentType,
                    coords = {
                        x = objCoords.x,
                        y = objCoords.y,
                        z = objCoords.z,
                        w = objHeading,
                    },
                }

                -- Handle bench bar repositioning
                if propData.equipmentType == 'bench' and cconfig.props.bench.playerAnimation.prop then
                    local barModel = cconfig.props.bench.playerAnimation.prop.model
                    local barHash = type(barModel) == 'string' and joaat(barModel) or barModel

                    -- Find existing bar entity if present
                    local existingBar = nil
                    if propData.bar then
                        existingBar = GetClosestObjectOfType(
                            propData.bar.x, propData.bar.y, propData.bar.z,
                            2.0, barHash, false, false, false
                        )
                    end

                    -- Use existing bar or create a new one for positioning
                    local barEntity
                    if existingBar and existingBar ~= 0 and DoesEntityExist(existingBar) then
                        barEntity = existingBar
                        SetEntityAsMissionEntity(barEntity, true, true)
                    else
                        lib.requestModel(barHash)
                        barEntity = CreateObjectNoOffset(barHash, objCoords.x, objCoords.y, objCoords.z + 1.0, false, false, false)
                    end

                    SetEntityAlpha(barEntity, 150, false)
                    FreezeEntityPosition(barEntity, true)
                    SetEntityCollision(barEntity, false, true)
                    SetEntityDrawOutline(barEntity, true)

                    local barHeading = objHeading
                    local barPlaced = false

                    lib.showTextUI('[Scroll] Rotate  \n[Enter] Place Bar  \n[Backspace] Skip')
                    while not barPlaced do
                        Wait(0)
                        SetPauseMenuActive(false)
                        local barHit, _, barCoords = lib.raycast.fromCamera(511, 4, 30.0)

                        if barHit and barCoords then
                            SetEntityCoordsNoOffset(barEntity, barCoords.x, barCoords.y, barCoords.z, false, false, false)
                            SetEntityHeading(barEntity, barHeading)
                            PlaceObjectOnGroundProperly(barEntity)

                            if IsControlPressed(0, 15) then
                                barHeading = barHeading + 5.0
                            elseif IsControlPressed(0, 14) then
                                barHeading = barHeading - 5.0
                            elseif IsControlJustPressed(0, 191) then
                                local barFinalCoords = GetEntityCoords(barEntity)
                                local barFinalHeading = GetEntityHeading(barEntity)
                                newPropData.bar = {
                                    x = barFinalCoords.x,
                                    y = barFinalCoords.y,
                                    z = barFinalCoords.z,
                                    w = barFinalHeading,
                                }
                                SetEntityAlpha(barEntity, 255, false)
                                SetEntityDrawOutline(barEntity, false)
                                FreezeEntityPosition(barEntity, false)
                                SetEntityCollision(barEntity, true, true)
                                barPlaced = true
                            elseif IsControlJustPressed(0, 177) then
                                -- Keep bar at old position or skip
                                if propData.bar then
                                    newPropData.bar = propData.bar
                                end
                                SetEntityAlpha(barEntity, 255, false)
                                SetEntityDrawOutline(barEntity, false)
                                FreezeEntityPosition(barEntity, false)
                                SetEntityCollision(barEntity, true, true)
                                barPlaced = true
                            end
                        end
                    end
                    lib.hideTextUI()
                    SetModelAsNoLongerNeeded(barHash)
                elseif propData.bar then
                    -- Non-bench with bar data, preserve it with offset
                    newPropData.bar = propData.bar
                end

                -- Update server with new position
                TriggerServerEvent('gym_group:updateProp', propIndex, newPropData)

                -- Finalize the entity
                SetEntityAlpha(existingEntity, 255, false)
                SetEntityCollision(existingEntity, true, true)
                SetEntityDrawOutline(existingEntity, false)
                FreezeEntityPosition(existingEntity, false)

                client.notify('Prop Moved', string.format('%s repositioned', propData.equipmentType), 'success')
                placing = false
            elseif IsControlJustPressed(0, 177) then -- BACKSPACE - Cancel
                -- Move back to original position
                SetEntityCoordsNoOffset(existingEntity,
                    propData.coords.x, propData.coords.y, propData.coords.z,
                    false, false, false)
                SetEntityHeading(existingEntity, propData.coords.w)
                PlaceObjectOnGroundProperly(existingEntity)

                SetEntityAlpha(existingEntity, 255, false)
                SetEntityCollision(existingEntity, true, true)
                SetEntityDrawOutline(existingEntity, false)
                FreezeEntityPosition(existingEntity, false)

                client.notify('Move Cancelled', 'Prop returned to original position', 'warning')
                placing = false
            end
        end
    end
    lib.hideTextUI()

    -- Reopen menu
    Wait(500)
    TriggerEvent('gym_group:reopenActiveMenu')
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    PROP PLACEMENT (new prop)
    ═══════════════════════════════════════════════════════════════════════════
]]--

--- Place an object for group editing (simplified version of creator's placeObject)
function GroupPlaceObject(model, label, machine)
    local hash = type(model) == 'string' and joaat(model) or model
    lib.requestModel(hash)

    local placing = true
    local heading = GetEntityHeading(cache.ped)
    local placedEntity = nil
    local hit, coords

    CreateThread(function()
        while placing do
            local hitt, _, coordss = lib.raycast.fromCamera(511, 4, 30.0)
            hit = hitt
            coords = coordss
            Wait(1)
        end
    end)

    lib.showTextUI('[Scroll] Rotate  \n[Enter] Place  \n[Backspace] Cancel')
    while placing do
        Wait(0)
        SetPauseMenuActive(false)
        DisableControlAction(0, 15, true)
        DisableControlAction(0, 14, true)
        if hit and coords then
            if not placedEntity then
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

            if IsDisabledControlPressed(0, 15) then
                heading = heading + 5.0
            elseif IsDisabledControlPressed(0, 14) then
                heading = heading - 5.0
            elseif IsControlJustPressed(0, 191) then -- ENTER - Place
                local objCoords = GetEntityCoords(placedEntity)
                local objHeading = GetEntityHeading(placedEntity)

                local propData = {
                    equipmentType = machine,
                    coords = {
                        x = objCoords.x,
                        y = objCoords.y,
                        z = objCoords.z,
                        w = objHeading,
                    },
                }

                -- Handle bench bar placement
                local cconfig = require 'config.config_c'
                if machine == 'bench' and cconfig.props.bench.playerAnimation.prop then
                    local barModel = cconfig.props.bench.playerAnimation.prop.model
                    local barHash = type(barModel) == 'string' and joaat(barModel) or barModel
                    lib.requestModel(barHash)

                    local barEntity = CreateObjectNoOffset(barHash, objCoords.x, objCoords.y, objCoords.z + 1.0, false, false, false)
                    SetEntityAlpha(barEntity, 150, false)
                    FreezeEntityPosition(barEntity, true)
                    SetEntityHeading(barEntity, objHeading)
                    SetEntityCollision(barEntity, false, true)
                    SetEntityDrawOutline(barEntity, true)

                    local barHeading = objHeading
                    local barPlaced = false

                    lib.showTextUI('[Scroll] Rotate  \n[Enter] Place Bar  \n[Backspace] Skip')
                    while not barPlaced do
                        Wait(0)
                        SetPauseMenuActive(false)
                        local barHit, _, barCoords = lib.raycast.fromCamera(511, 4, 30.0)

                        if barHit and barCoords then
                            SetEntityCoordsNoOffset(barEntity, barCoords.x, barCoords.y, barCoords.z, false, false, false)
                            SetEntityHeading(barEntity, barHeading)
                            PlaceObjectOnGroundProperly(barEntity)

                            if IsControlPressed(0, 15) then
                                barHeading = barHeading + 5.0
                            elseif IsControlPressed(0, 14) then
                                barHeading = barHeading - 5.0
                            elseif IsControlJustPressed(0, 191) then
                                local barFinalCoords = GetEntityCoords(barEntity)
                                local barFinalHeading = GetEntityHeading(barEntity)
                                propData.bar = {
                                    x = barFinalCoords.x,
                                    y = barFinalCoords.y,
                                    z = barFinalCoords.z,
                                    w = barFinalHeading,
                                }
                                -- Track bar as preview entity too
                                table.insert(previewEntities, barEntity)
                                SetEntityAlpha(barEntity, 255, false)
                                SetEntityDrawOutline(barEntity, false)
                                barPlaced = true
                            elseif IsControlJustPressed(0, 177) then
                                DeleteEntity(barEntity)
                                barPlaced = true
                            end
                        end
                    end
                    lib.hideTextUI()
                    SetModelAsNoLongerNeeded(barHash)
                end

                -- Send to server
                TriggerServerEvent('gym_group:addProp', propData)

                -- Track as preview entity (will be cleaned up on save when location system takes over)
                table.insert(previewEntities, placedEntity)

                SetEntityAlpha(placedEntity, 255, false)
                SetEntityCollision(placedEntity, true, true)
                SetEntityDrawOutline(placedEntity, false)

                client.notify('Prop Placed', string.format('%s added to group', label), 'success')
                placedEntity = nil
                placing = false
            elseif IsControlJustPressed(0, 177) then -- BACKSPACE - Cancel
                if placedEntity and DoesEntityExist(placedEntity) then
                    DeleteEntity(placedEntity)
                end
                placedEntity = nil
                placing = false
            end
        end
    end
    lib.hideTextUI()
    SetModelAsNoLongerNeeded(hash)

    -- Reopen the active group menu after a short delay
    Wait(500)
    TriggerEvent('gym_group:reopenActiveMenu')
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    EVENT HANDLERS
    ═══════════════════════════════════════════════════════════════════════════
]]--

RegisterNetEvent('gym_group:propAdded')
AddEventHandler('gym_group:propAdded', function(propData, totalProps)
    client.notify('Prop Added', string.format('Added %s (%d props total)', propData.equipmentType, totalProps), 'info')
end)

RegisterNetEvent('gym_group:propRemoved')
AddEventHandler('gym_group:propRemoved', function(propData, totalProps)
    client.notify('Prop Removed', string.format('Removed %s (%d props remaining)', propData.equipmentType, totalProps), 'warning')
end)

--- Reopen the active group menu (called after prop placement / targeting / etc.)
AddEventHandler('gym_group:reopenActiveMenu', function()
    ShowActiveGroupMenu({}, false)
end)

--[[
    ═══════════════════════════════════════════════════════════════════════════
    OPEN MENU (called from creator menu or directly)
    ═══════════════════════════════════════════════════════════════════════════
]]--

--- Open the groups menu (called from gym creator's "Manage Groups" button)
RegisterNetEvent('gym_group:openMenu')
AddEventHandler('gym_group:openMenu', function()
    local hasPermission = lib.callback.await('gym_group:checkPermission', false)
    if not hasPermission then
        client.notify('Permission Denied', 'You do not have permission to use this menu', 'error')
        return
    end

    ShowMainMenu()
end)

lib.print.info("[GROUP MENU] Group management menu loaded")
