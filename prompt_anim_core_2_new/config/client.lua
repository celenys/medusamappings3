local client = {}

---@param title string The title of the notification
---@param message string The message content
---@param type? 'info' | 'success' | 'error' | 'warning' The type of notification
client.notify = function(title, message, type)
    lib.notify({
        title = title,
        description = message,
        type = type,
    })
end

---@param machine string The machine/equipment type being used
---@return boolean Returns true if the minigame was successful
client.minigame = function(machine)
    local success = lib.skillCheck({
        'easy',
        'easy',
    }, {'1', '2', '3', '4'})
    return success --[[@as boolean]]
end

---@param machine string The machine/equipment type
---@param repeatCount number Number of repetitions
---@param animSpeed number Animation playback speed
client.onExerciseStart = function(machine, repeatCount, animSpeed)
    LocalPlayer.state:set('invBusy', true, false)
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:disableTargeting(true)
    elseif GetResourceState('qb-target') == 'started' then
        exports['qb-target']:DisableTarget(true)
    end
end

---@param machine string The machine/equipment type
client.onExerciseEnd = function(machine)
    LocalPlayer.state:set('invBusy', false, false)
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:disableTargeting(false)
    elseif GetResourceState('qb-target') == 'started' then
        exports['qb-target']:DisableTarget(false)
    end
end

client.boxingRing = {
    -- Called when a boxing match starts
    onFightStart = function()
        LocalPlayer.state:set('invBusy', true, false)
    end,

    -- Called when a boxing match ends
    ---@param result string 'winner' | 'loser' | 'draw' The result of the match
    onFightEnd = function(result)
        LocalPlayer.state:set('invBusy', false, false)
    end
}

local cachedStats = { speed = 0, stamina = 0, combat = 0, strength = 0 }

local function applyGymStats(stats)
    local speed    = stats.speed    or 0
    local stamina  = stats.stamina  or 0
    local combat   = stats.combat   or 0
    local strength = stats.strength or 0

    local sprintBonus = 1.0 + (speed / 100) * 0.25 + (stamina / 100) * 0.15
    SetRunSprintMultiplierForPlayer(cache.playerId, sprintBonus)
    SetSwimMultiplierForPlayer(cache.playerId, 1.0 + (stamina / 100) * 0.3)

    SetPlayerMeleeWeaponDamageModifier(cache.playerId, 1.0 + (combat / 100) * 0.5)

    SetPlayerMeleeWeaponDefenseModifier(cache.playerId, 1.0 + (strength / 100) * 0.3)
    SetPlayerHealthRechargeMultiplier(cache.playerId, 1.0 + (strength / 100) * 0.5)
end

RegisterNetEvent('gym:updateGymData', function(data)
    cachedStats = {
        speed    = data.speed    or 0,
        stamina  = data.stamina  or 0,
        combat   = data.combat   or 0,
        strength = data.strength or 0,
    }
    lib.print.debug(string.format("Gym stats updated - Speed: %.1f, Stamina: %.1f, Combat: %.1f, Strength: %.1f",
        cachedStats.speed, cachedStats.stamina, cachedStats.combat, cachedStats.strength))
    applyGymStats(cachedStats)
end)

CreateThread(function()
    while true do
        Wait(1000)
        if cachedStats.stamina > 0 then
            RestorePlayerStamina(cache.playerId, cachedStats.stamina * 0.0003)
        end
    end
end)

RegisterNetEvent('gym:showStats', function(stats)
    local speed    = stats.speed    or 0
    local stamina  = stats.stamina  or 0
    local combat   = stats.combat   or 0
    local strength = stats.strength or 0

    lib.registerContext({
        id = 'gym_stats',
        title = locale('stats_title'),
        options = {
            {
                title = string.format('%s  —  %.1f / 100', locale('stats_speed_title'), speed),
                icon = 'person-running',
                iconColor = '#3b82f6',
                progress = math.floor(speed),
                colorScheme = 'blue',
                description = locale('stats_speed_desc'),
                readOnly = true,
            },
            {
                title = string.format('%s  —  %.1f / 100', locale('stats_stamina_title'), stamina),
                icon = 'heart-pulse',
                iconColor = '#22c55e',
                progress = math.floor(stamina),
                colorScheme = 'green',
                description = locale('stats_stamina_desc'),
                readOnly = true,
            },
            {
                title = string.format('%s  —  %.1f / 100', locale('stats_combat_title'), combat),
                icon = 'hand-fist',
                iconColor = '#ef4444',
                progress = math.floor(combat),
                colorScheme = 'red',
                description = locale('stats_combat_desc'),
                readOnly = true,
            },
            {
                title = string.format('%s  —  %.1f / 100', locale('stats_strength_title'), strength),
                icon = 'shield-halved',
                iconColor = '#f59e0b',
                progress = math.floor(strength),
                colorScheme = 'yellow',
                description = locale('stats_strength_desc'),
                readOnly = true,
            },
        }
    })
    lib.showContext('gym_stats')
end)

return client