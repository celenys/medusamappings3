local hasOxLib = false

-- SAHP Interior IDs will be loaded after a delay
local InteriorIds = {}

CreateThread(function()
    Wait(500) -- Increased delay to ensure both the Config and interiors are loaded

    -- Re-check ox_lib state inside the thread for reliability
    hasOxLib = GetResourceState('ox_lib') == 'started'
    
    if not Config then
        print("^1[SAHP Entity Sets]^7 Config not loaded")
        return
    end

    -- Get interior IDs after a delay to ensure they are loaded
    InteriorIds = {
        GetInteriorAtCoords(839.7197, -1291.275, 27.0595),
        GetInteriorAtCoords(1538.29822, 803.9021, 77.9835052)
    }

    if hasOxLib and Config.EnableMenu then
        print("^2[SAHP Entity Sets]^7 ox_lib detected, menu system enabled")
        print("^2[SAHP Entity Sets]^7 Registering command: /" .. (Config.MenuCommand or "sahp"))
        RegisterCommand(Config.MenuCommand or "sahp", function()
            showEntitySetsMenu()
        end, false)
        
        -- Event to open menu from other resources
        RegisterNetEvent("sahp:openEntitySetsMenu", function()
            showEntitySetsMenu()
        end)
        
        -- Apply default entity sets from config even when menu is enabled
        print("^3[SAHP Entity Sets]^7 Applying default entity sets from config...")
        TriggerServerEvent('sahp:sync:applyDefaults')
    else
        -- This block now handles both cases: ox_lib not present or menu disabled in config
        print("^3[SAHP Entity Sets]^7 Applying default entity sets from config...")
        TriggerServerEvent('sahp:sync:applyDefaults')
    end
end)

-- Entity Set labels
local ENTITY_SET_LABELS = {
    ["onlychairs"] = "Only Chairs",
    ["chairsandtables"] = "Chairs and Tables"
}

-- Function to toggle entity set for a specific interior
local function toggleEntitySet(entitySet, interiorIndex)
    local stateKey = "sahp_entitySets_interior" .. interiorIndex
    local currentState = GlobalState[stateKey] and GlobalState[stateKey][entitySet] or false
    TriggerServerEvent('sahp:sync:toggleEntitySet', entitySet, not currentState, interiorIndex)
    
    -- Small delay to allow server sync
    if hasOxLib and Config.EnableMenu then
        SetTimeout(100, function()
            showInteriorEntitySetsMenu(interiorIndex)
        end)
    end
end

-- Function to get current player's closest interior
local function getClosestInterior()
    local playerPos = GetEntityCoords(PlayerPedId())
    local dist1 = #(playerPos - vector3(839.7197, -1291.275, 27.0595))
    local dist2 = #(playerPos - vector3(1538.29822, 803.9021, 77.9835052))
    
    if dist1 < dist2 then
        return 1
    else
        return 2
    end
end

-- Function to get icon based on state
local function getIcon(state)
    return state and 'fas fa-check' or 'fas fa-times'
end

-- Main Entity Sets menu (only available with ox_lib)
function showEntitySetsMenu()
    if not hasOxLib then
        print("^1[SAHP Entity Sets]^7 Menu requires ox_lib")
        return
    end
    
    local menuOptions = {
        {
            title = "SAHP Station (City)",
            description = "Manage entity sets for the city SAHP station",
            icon = 'fas fa-building',
            onSelect = function()
                showInteriorEntitySetsMenu(1)
            end
        },
        {
            title = "SAHP Station (Highway)",
            description = "Manage entity sets for the highway SAHP station", 
            icon = 'fas fa-road',
            onSelect = function()
                showInteriorEntitySetsMenu(2)
            end
        },
        {
            title = "Auto-Select Closest",
            description = "Automatically select the closest SAHP station",
            icon = 'fas fa-location-arrow',
            onSelect = function()
                local closestInterior = getClosestInterior()
                showInteriorEntitySetsMenu(closestInterior)
            end
        }
    }
    
    lib.registerContext({
        id = 'sahp_entitysets_menu',
        title = 'SAHP Entity Sets Manager',
        options = menuOptions,
    })
    
    lib.showContext('sahp_entitysets_menu')
end

-- Interior-specific Entity Sets menu
function showInteriorEntitySetsMenu(interiorIndex)
    if not hasOxLib then
        print("^1[SAHP Entity Sets]^7 Menu requires ox_lib")
        return
    end
    
    local stateKey = "sahp_entitySets_interior" .. interiorIndex
    local interiorName = interiorIndex == 1 and "City Station" or "Highway Station"
    local menuOptions = {}
    
    for entitySet, label in pairs(ENTITY_SET_LABELS) do
        local isActive = GlobalState[stateKey] and GlobalState[stateKey][entitySet] or false
        table.insert(menuOptions, {
            title = label,
            icon = getIcon(isActive),
            description = isActive and "Enabled" or "Disabled",
            onSelect = function()
                toggleEntitySet(entitySet, interiorIndex)
            end
        })
    end
    
    -- Add back button
    table.insert(menuOptions, {
        title = "← Back to Main Menu",
        icon = 'fas fa-arrow-left',
        onSelect = function()
            showEntitySetsMenu()
        end
    })
    
    lib.registerContext({
        id = 'sahp_interior_entitysets_menu',
        title = 'SAHP ' .. interiorName .. ' - Entity Sets',
        options = menuOptions,
    })
    
    lib.showContext('sahp_interior_entitysets_menu')
end

-- Handler for GlobalState changes to sync entity sets for interior 1
AddStateBagChangeHandler('sahp_entitySets_interior1', 'global', function(bagName, key, value)
    if value and InteriorIds[1] and InteriorIds[1] ~= 0 then
        for entitySet, state in pairs(value) do
            if state then
                ActivateInteriorEntitySet(InteriorIds[1], entitySet)
            else
                DeactivateInteriorEntitySet(InteriorIds[1], entitySet)
            end
        end
        RefreshInterior(InteriorIds[1])
    end
end)

-- Handler for GlobalState changes to sync entity sets for interior 2
AddStateBagChangeHandler('sahp_entitySets_interior2', 'global', function(bagName, key, value)
    if value and InteriorIds[2] and InteriorIds[2] ~= 0 then
        for entitySet, state in pairs(value) do
            if state then
                ActivateInteriorEntitySet(InteriorIds[2], entitySet)
            else
                DeactivateInteriorEntitySet(InteriorIds[2], entitySet)
            end
        end
        RefreshInterior(InteriorIds[2])
    end
end)