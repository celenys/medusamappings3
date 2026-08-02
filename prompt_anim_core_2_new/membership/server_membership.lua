--[[
    ═══════════════════════════════════════════════════════════════════════════
    MEMBERSHIP SYSTEM - SERVER SIDE
    ═══════════════════════════════════════════════════════════════════════════
    
    Handles:
    - JSON-based membership storage (membership/members.json)
    - Membership check (with expiry support)
    - Admin command to grant/revoke memberships
    - Exports for external resources to check/grant/revoke
    - Override hook so frameworks can replace the default check entirely
    - Startup cleanup of expired memberships
    
    ═══════════════════════════════════════════════════════════════════════════
]]--

local config = require 'config.config_s'
local cconfig = require 'config.config_c'

-- File path for saved memberships
local MEMBERS_FILE = "membership/members.json"

-- In-memory cache of memberships (loaded from JSON on startup)
local memberships = {}

-- Custom check handler (set via export to override default JSON check)
-- If set, this function is called instead of the built-in JSON lookup
local customCheckHandler = nil

--[[
    ═══════════════════════════════════════════════════════════════════════════
    FILE OPERATIONS
    ═══════════════════════════════════════════════════════════════════════════
]]--

local function LoadMembersFromFile()
    local file = LoadResourceFile(GetCurrentResourceName(), MEMBERS_FILE)

    if not file then
        lib.print.debug("[MEMBERSHIP] No members file found, starting fresh")
        return {}
    end

    local success, data = pcall(json.decode, file)

    if not success then
        lib.print.error("[MEMBERSHIP] Failed to parse members.json")
        return {}
    end

    return data or {}
end

local function SaveMembersToFile()
    local json_data = json.encode(memberships, {indent = true})

    if not json_data then
        lib.print.error("[MEMBERSHIP] Failed to encode memberships to JSON")
        return false
    end

    SaveResourceFile(GetCurrentResourceName(), MEMBERS_FILE, json_data, -1)
    return true
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    UTILITY
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

--- Find a membership entry by license
---@param license string
---@return table? entry, number? index
local function FindMemberByLicense(license)
    for i, member in ipairs(memberships) do
        if member.license == license then
            return member, i
        end
    end
    return nil, nil
end

--- Check if a membership entry is expired
---@param member table
---@return boolean expired
local function IsMembershipExpired(member)
    if not member.expiresAt then return false end -- nil = permanent
    return os.time() > member.expiresAt
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    CORE MEMBERSHIP CHECK
    ═══════════════════════════════════════════════════════════════════════════
]]--

--- Check if a player has an active membership
--- If a custom handler is set (via SetMembershipCheckHandler export), it is used instead
---@param source number Player server ID
---@return boolean hasMembership
local function CheckPlayerMembership(source)
    -- Custom handler overrides everything
    if customCheckHandler then
        local ok, result = pcall(customCheckHandler, source)
        if ok then
            return result == true
        else
            lib.print.error(string.format("[MEMBERSHIP] Custom check handler error: %s", tostring(result)))
            return false
        end
    end

    -- Default: JSON-based check
    local license = GetPlayerLicense(source)
    if not license then
        lib.print.warn(string.format("[MEMBERSHIP] Could not get license for player %d", source))
        return false
    end

    local member = FindMemberByLicense(license)
    if not member then return false end

    -- Check expiry
    if IsMembershipExpired(member) then
        lib.print.debug(string.format("[MEMBERSHIP] Player %d membership expired", source))
        return false
    end

    return true
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    LOCATION MEMBERSHIP REQUIREMENT CHECK
    ═══════════════════════════════════════════════════════════════════════════
]]--

--- Determine if a specific location requires membership
--- When membership.enable = true:
---   - All locations require membership by default
---   - Exempt locations (config list) are always free
---   - Config locations can opt out with requireMembership = false
---   - Group locations do NOT require membership UNLESS they set requireMembership = true
---   - Custom equipment never requires membership
---@param locationName string? The location identifier
---@param isCustomEquipment boolean? Whether this is custom-spawned equipment
---@return boolean requiresMembership
local function DoesLocationRequireMembership(locationName, isCustomEquipment)
    -- Custom equipment (spawned via creator, not in a group) never requires membership
    if isCustomEquipment then return false end

    -- No location name, treat as requiring membership when enabled
    if not locationName then return true end

    -- Check exempt locations list (e.g., 'prison')
    local exemptList = config.membership.exemptLocations
    if exemptList then
        for _, exemptName in ipairs(exemptList) do
            if locationName == exemptName then
                return false
            end
        end
    end

    -- Group locations: do NOT require membership unless explicitly flagged
    if string.sub(locationName, 1, 6) == 'group_' then
        local groupName = string.sub(locationName, 7)
        local groupsFile = LoadResourceFile(GetCurrentResourceName(), "groups/saved_groups.json")
        if groupsFile then
            local ok, groups = pcall(json.decode, groupsFile)
            if ok and groups then
                for _, group in ipairs(groups) do
                    if group.name == groupName then
                        return group.requireMembership == true
                    end
                end
            end
        end
        return false
    end

    -- Config locations: can opt out with requireMembership = false
    if cconfig.locations and cconfig.locations[locationName] then
        local loc = cconfig.locations[locationName]
        if loc.requireMembership == false then
            return false
        end
    end

    -- All other locations require membership when the system is enabled
    return true
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    MAIN MEMBERSHIP GATE (called from canUseMachine)
    ═══════════════════════════════════════════════════════════════════════════
]]--

--- Full membership gate check. Returns true if player can proceed.
--- Called from config/server.lua canUseMachine via export.
---@param source number Player server ID
---@param data table {machine, index, locationName, coords, isCustomEquipment}
---@return boolean allowed
---@return string? errorMessage
local function CheckMembershipGate(source, data)
    local playerName = GetPlayerName(source) or tostring(source)
    local sconfig = require 'config.config_s'
    local debugMode = sconfig.debug

    -- Global toggle
    if not config.membership or not config.membership.enable then
        if debugMode then
            lib.print.info(string.format("[MEMBERSHIP] System disabled - allowing %s (ID: %d) to use %s at %s",
                playerName, source, data.machine or '?', data.locationName or '?'))
        end
        return true
    end

    -- Check if this location requires membership
    local locationRequires = DoesLocationRequireMembership(data.locationName, data.isCustomEquipment)
    if not locationRequires then
        if debugMode then
            lib.print.info(string.format("[MEMBERSHIP] Location '%s' does not require membership - allowing %s (ID: %d) to use %s",
                data.locationName or '?', playerName, source, data.machine or '?'))
        end
        return true
    end

    -- Check player membership
    local hasMembership = CheckPlayerMembership(source)
    if debugMode then
        lib.print.info(string.format("[MEMBERSHIP] %s (ID: %d) | Machine: %s | Location: %s | Has membership: %s | Result: %s",
            playerName, source, data.machine or '?', data.locationName or '?',
            tostring(hasMembership), hasMembership and 'ALLOWED' or 'DENIED'))
    end

    if hasMembership then
        return true
    end

    return false, locale('error_membership_required')
end

exports('CheckMembershipGate', CheckMembershipGate)

--[[
    ═══════════════════════════════════════════════════════════════════════════
    GRANT / REVOKE
    ═══════════════════════════════════════════════════════════════════════════
]]--

--- Grant membership to a player
---@param source number Player server ID
---@param durationDays number? Duration in days (nil = permanent)
---@return boolean success
local function GrantMembershipToPlayer(source, durationDays)
    local license = GetPlayerLicense(source)
    if not license then
        lib.print.warn(string.format("[MEMBERSHIP] Cannot grant - no license for player %d", source))
        return false
    end

    local playerName = GetPlayerName(source) or tostring(source)

    -- Check if already has membership
    local existing, existingIndex = FindMemberByLicense(license)
    if existing and existingIndex then
        -- Update existing entry
        memberships[existingIndex].grantedAt = os.time()
        memberships[existingIndex].grantedBy = "system"
        memberships[existingIndex].playerName = playerName
        if durationDays then
            memberships[existingIndex].expiresAt = os.time() + (durationDays * 86400)
        else
            memberships[existingIndex].expiresAt = nil
        end
    else
        -- Create new entry
        table.insert(memberships, {
            license = license,
            playerName = playerName,
            grantedBy = "system",
            grantedAt = os.time(),
            expiresAt = durationDays and (os.time() + (durationDays * 86400)) or nil,
        })
    end

    SaveMembersToFile()
    lib.print.info(string.format("[MEMBERSHIP] Granted membership to %s (%s)%s",
        playerName, license,
        durationDays and string.format(" for %d days", durationDays) or " (permanent)"))
    return true
end

--- Revoke membership from a player
---@param source number Player server ID
---@return boolean success
local function RevokeMembershipFromPlayer(source)
    local license = GetPlayerLicense(source)
    if not license then
        lib.print.warn(string.format("[MEMBERSHIP] Cannot revoke - no license for player %d", source))
        return false
    end

    local _, index = FindMemberByLicense(license)
    if not index then
        return false
    end

    local playerName = memberships[index].playerName or tostring(source)
    table.remove(memberships, index)
    SaveMembersToFile()

    lib.print.info(string.format("[MEMBERSHIP] Revoked membership from %s (%s)", playerName, license))
    return true
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    ADMIN COMMAND
    ═══════════════════════════════════════════════════════════════════════════
]]--

local function RegisterMembershipCommands()
    local cmdRestricted = config.membership and config.membership.commandRestricted or 'group.admin'

    -- /gymmembership <playerId> [days]
    lib.addCommand('gymmembership', {
        help = 'Grant gym membership. No days = permanent.',
        restricted = cmdRestricted,
        params = {
            { name = 'id', type = 'playerId', help = 'Player server ID' },
            { name = 'days', type = 'number', help = 'Duration in days (leave empty for permanent)', optional = true },
        },
    }, function(source, args)
        local targetId = args.id
        local targetName = GetPlayerName(targetId)
        if not targetName then
            lib.print.info("[MEMBERSHIP] Player not found")
            return
        end

        local days = args.days -- nil = permanent

        if GrantMembershipToPlayer(targetId, days) then
            local durationText = days and string.format('%d days', days) or 'permanent'
            lib.print.info(string.format("[MEMBERSHIP] Granted %s membership to %s (ID: %d)", durationText, targetName, targetId))
            if source > 0 then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Membership Granted',
                    description = string.format('Granted %s gym membership to %s', durationText, targetName),
                    type = 'success',
                })
            end
        else
            lib.print.info("[MEMBERSHIP] Failed to grant membership (no license found)")
            if source > 0 then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Failed',
                    description = 'Could not grant membership (no license found)',
                    type = 'error',
                })
            end
        end
    end)

    -- /gymrevoke <playerId>
    lib.addCommand('gymrevoke', {
        help = 'Revoke gym membership from a player.',
        restricted = cmdRestricted,
        params = {
            { name = 'id', type = 'playerId', help = 'Player server ID' },
        },
    }, function(source, args)
        local targetId = args.id
        local targetName = GetPlayerName(targetId)
        if not targetName then
            lib.print.info("[MEMBERSHIP] Player not found")
            return
        end

        if RevokeMembershipFromPlayer(targetId) then
            lib.print.info(string.format("[MEMBERSHIP] Revoked membership from %s (ID: %d)", targetName, targetId))
            if source > 0 then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Membership Revoked',
                    description = string.format('Revoked gym membership from %s', targetName),
                    type = 'warning',
                })
            end
        else
            lib.print.info(string.format("[MEMBERSHIP] %s does not have a membership", targetName))
            if source > 0 then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'No Membership',
                    description = string.format('%s does not have a membership', targetName),
                    type = 'error',
                })
            end
        end
    end)

    lib.print.info("[MEMBERSHIP] Registered commands /gymmembership and /gymrevoke")
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    EXPORTS
    ═══════════════════════════════════════════════════════════════════════════
]]--

--- Check if a player currently has an active membership
---@param source number Player server ID
---@return boolean hasMembership
exports('IsPlayerMember', function(source)
    return CheckPlayerMembership(source)
end)

--- Grant membership to a player
---@param source number Player server ID
---@param durationDays number? Duration in days (nil = permanent)
---@return boolean success
exports('GrantMembership', function(source, durationDays)
    return GrantMembershipToPlayer(source, durationDays)
end)

--- Revoke membership from a player
---@param source number Player server ID
---@return boolean success
exports('RevokeMembership', function(source)
    return RevokeMembershipFromPlayer(source)
end)

--- Override the default membership check with a custom function
--- Pass nil to restore the default JSON-based check
---@param handler function(source: number): boolean
exports('SetMembershipCheckHandler', function(handler)
    if handler and type(handler) ~= 'function' then
        lib.print.error("[MEMBERSHIP] SetMembershipCheckHandler expects a function or nil")
        return
    end
    customCheckHandler = handler
    if handler then
        lib.print.info("[MEMBERSHIP] Custom membership check handler registered")
    else
        lib.print.info("[MEMBERSHIP] Custom membership check handler removed, using default JSON")
    end
end)

--[[
    ═══════════════════════════════════════════════════════════════════════════
    STARTUP
    ═══════════════════════════════════════════════════════════════════════════
]]--

CreateThread(function()
    -- Load memberships from file
    memberships = LoadMembersFromFile()

    -- Prune expired memberships
    local pruned = 0
    for i = #memberships, 1, -1 do
        if IsMembershipExpired(memberships[i]) then
            lib.print.debug(string.format("[MEMBERSHIP] Pruned expired membership: %s", memberships[i].playerName or memberships[i].license))
            table.remove(memberships, i)
            pruned = pruned + 1
        end
    end

    if pruned > 0 then
        SaveMembersToFile()
        lib.print.info(string.format("[MEMBERSHIP] Pruned %d expired memberships", pruned))
    end

    -- Register admin commands
    RegisterMembershipCommands()

    lib.print.info(string.format("[MEMBERSHIP] Membership system loaded (%d active members, enabled: %s)",
        #memberships, tostring(config.membership and config.membership.enable or false)))
end)
