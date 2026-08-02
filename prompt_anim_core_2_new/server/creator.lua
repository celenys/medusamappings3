local config = require 'config.config_s'

lib.addCommand('gymcreator', {
    help = 'Open gym creator debug menu',
    restricted = config.gymCreator.restricted,
    params = {},
}, function(source, args)
    if not config.gymCreator.canAccess(source) then
        lib.print.warn(string.format("Player %d attempted to access gym creator without permission", source))
        return
    end

    TriggerClientEvent('gym:openCreator', source)
end)

---@param source Source
---@param data {model: string|number, coords: vector4, machine: string}[]
---@param name string
lib.callback.register('gym:saveCreatorData', function(source, data, name)
    if not data or #data == 0 or not name or name == '' then return false end

    if not config.gymCreator.restricted or not IsPrincipalAceAllowed(config.gymCreator.restricted, 'command.gymcreator') or not config.gymCreator.canAccess(source) then
        lib.print.warn(string.format("Player %d attempted to save gym creator data without permission", source))
        return false
    end

    local machineGroups = {}
    for _, item in pairs(data) do
        if not machineGroups[item.machine] then
            machineGroups[item.machine] = {}
        end
        table.insert(machineGroups[item.machine], item.coords)
    end

    local sumX, sumY, sumZ = 0, 0, 0
    local totalPoints = 0
    for _, item in pairs(data) do
        local coordsToCount = item.coords
        if type(item.coords) == 'table' and item.coords.coords then
            coordsToCount = item.coords.coords
        end
        sumX = sumX + coordsToCount.x
        sumY = sumY + coordsToCount.y
        sumZ = sumZ + coordsToCount.z
        totalPoints = totalPoints + 1
    end

    local avgCoords = vec3(
        math.floor(sumX / totalPoints * 100) / 100,
        math.floor(sumY / totalPoints * 100) / 100,
        math.floor(sumZ / totalPoints * 100) / 100
    )

    local locationConfig = {
        coords = avgCoords,
        props = {}
    }

    for machine, coordsList in pairs(machineGroups) do
        locationConfig.props[machine] = {}
        for _, coords in pairs(coordsList) do
            if type(coords) == 'table' and coords.coords and coords.bar then
                table.insert(locationConfig.props[machine], {
                    coords = vec4(
                        math.floor(coords.coords.x * 1000) / 1000,
                        math.floor(coords.coords.y * 1000) / 1000,
                        math.floor(coords.coords.z * 1000) / 1000,
                        math.floor(coords.coords.w * 1000) / 1000
                    ),
                    bar = vec4(
                        math.floor(coords.bar.x * 1000) / 1000,
                        math.floor(coords.bar.y * 1000) / 1000,
                        math.floor(coords.bar.z * 1000) / 1000,
                        math.floor(coords.bar.w * 1000) / 1000
                    )
                })
            else
                table.insert(locationConfig.props[machine], vec4(
                    math.floor(coords.x * 1000) / 1000,
                    math.floor(coords.y * 1000) / 1000,
                    math.floor(coords.z * 1000) / 1000,
                    math.floor(coords.w * 1000) / 1000
                ))
            end
        end
    end

    local configPath = GetResourcePath(cache.resource) .. '/config/config_c.lua'
    local file = io.open(configPath, 'r')
    if not file then
        lib.print.error('Failed to open config file')
        return false
    end

    local content = file:read('*all')
    file:close()

    -- Find locations table start
    local locationsStart, locationsOpenBrace = content:find('locations%s*=%s*{')
    if not locationsStart then
        lib.print.error('Failed to find locations table')
        return false
    end

    local newLocation = string.format([[
        ['%s'] = { -- Created by %s on %s
            coords = vec3(%.2f, %.2f, %.2f),

            props = {
]], name, GetPlayerName(source), os.date("%Y-%m-%d %H:%M:%S"), avgCoords.x, avgCoords.y, avgCoords.z)
    
    for machine, coordsList in pairs(machineGroups) do
        newLocation = newLocation .. string.format('                %s = {\n', machine)
        for _, coords in pairs(coordsList) do
            if type(coords) == 'table' and coords.coords and coords.bar then
                newLocation = newLocation .. string.format('                    {coords = vec4(%.3f, %.3f, %.3f, %.3f), bar = vec4(%.3f, %.3f, %.3f, %.3f)},\n',
                    coords.coords.x, coords.coords.y, coords.coords.z, coords.coords.w,
                    coords.bar.x, coords.bar.y, coords.bar.z, coords.bar.w)
            else
                newLocation = newLocation .. string.format('                    vec4(%.3f, %.3f, %.3f, %.3f),\n', 
                    coords.x, coords.y, coords.z, coords.w)
            end
        end
        newLocation = newLocation .. '                },\n'
    end

    newLocation = newLocation .. [[            }
        },
]]

    -- Find the closing brace of locations table
    -- Strategy: Look for "},\n\n" followed by comment or props definition at same indentation level as "locations"
    local afterLocations = locationsOpenBrace + 1
    
    -- Simple approach: find the pattern "    },\n\n    --" or "    },\n\n    props"
    -- This represents the end of locations table followed by next section
    local locationsEnd = content:find('\n    },%s*\n%s*\n%s*%-%-', afterLocations)
    
    if not locationsEnd then
        -- Try finding before props table
        locationsEnd = content:find('\n    },%s*\n%s*\n%s*props%s*=%s*{', afterLocations)
    end
    
    if not locationsEnd then
        lib.print.error('Failed to find end of locations table')
        return false
    end
    
    -- Move to position right before the closing brace
    local insertPos = locationsEnd + 1  -- After first \n
    
    local newContent = content:sub(1, insertPos - 1) .. newLocation .. content:sub(insertPos)

    file = io.open(configPath, 'w')
    if not file then
        lib.print.error('Failed to write config file')
        return false
    end

    file:write(newContent)
    file:close()

    local machineCount = 0
    for _ in pairs(machineGroups) do
        machineCount = machineCount + 1
    end

    exports[cache.resource]:CreateGymLocation(name, locationConfig)

    lib.print.info(string.format('Successfully saved gym location with %d machines and %d total points', 
        machineCount, totalPoints))
    lib.print.debug(string.format('Location center coords: %.2f, %.2f, %.2f', avgCoords.x, avgCoords.y, avgCoords.z))

    return true
end)