local config = require 'config.config_c'
local state = require 'client.state'
local client = require 'config.client'

function sendNui(data)
    if config.progressBar == 'built-in' then
        SendNUIMessage(data)
    end
end

---@param data {repeats: number?, speed: number?}
lib.callback.register('gym:startExercise', function(data)
    lib.print.debug(string.format("Starting exercise - repeats: %d, speed: %.2f", data.repeats or 1, data.speed or 1.0))

    state.setAnimInProgress(true)

    local currentMachine = state.getCurrentMachine()
    local repeatCount = data.repeats or 1
    local animSpeed = data.speed or 1.0

    local playerAnim = currentMachine.playerAnimation
    local baseDuration = GetAnimDuration(playerAnim.dict, playerAnim.name) * 1000
    local adjustedDuration = baseDuration / animSpeed

    lib.print.debug(string.format("Exercise duration: %.0fms (base: %.0fms)", adjustedDuration * repeatCount, baseDuration * repeatCount))

    sendNui({
        action = 'toggleTraining',
        data = adjustedDuration * repeatCount
    })
    if config.progressBar == 'custom' then
        local machine
        for name, prop in pairs(config.props) do
            if prop.model == currentMachine.model then
                machine = name
                break
            end
        end
        pcall(config.customProgressBar, machine, adjustedDuration * repeatCount)
    end
    client.onExerciseStart(currentMachine, repeatCount, animSpeed)
    local machineAnim = currentMachine.animations

    for i = 1, repeatCount do
        if machineAnim then
            SetTimeout(machineAnim.delay or 0, function()
                PlayEntityAnim(currentMachine.entity, machineAnim.name,machineAnim.dict, 8.0, false, true, false, 0.0, 0)
            end)
        end
        TaskPlayAnim(cache.ped, playerAnim.dict, playerAnim.name, 8.0, -8.0, -1, 2, 0, false, false, true)
        Wait(1)

        if machineAnim then
            SetEntityAnimSpeed(currentMachine.entity, machineAnim.dict, machineAnim.name, animSpeed)
        end
        SetEntityAnimSpeed(cache.ped, playerAnim.dict, playerAnim.name, animSpeed)

        Wait(adjustedDuration - 1)
    end

    client.onExerciseEnd(currentMachine)
    state.setAnimInProgress(false)

    sendNui({
        action = 'toggleTraining'
    })

    lib.print.debug("Exercise completed successfully")

    return true
end)

lib.callback.register('gym:minigame', function(data)
    lib.print.debug(string.format("Minigame requested for machine: %s", data))

    return client.minigame(data)
end)
