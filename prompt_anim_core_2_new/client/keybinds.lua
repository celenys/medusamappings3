local state = require 'client.state'
local client = require 'config.client'
lib.locale(require('config.config_c').language ~= 'auto' and require('config.config_c').language or nil)

lib.addKeybind({
    name = 'gym:exitMachine',
    description = locale('exit_machine'),
    defaultKey = 'X',
    onPressed = function()
        if state.getCurrentMachine() and not state.isAnimInProgress() then
            lib.print.debug("Player exiting machine via keybind")

            local success = lib.callback.await('gym:stopUsingMachine', 300)
            if not success then
                lib.print.warn("Failed to stop using machine")
                client.notify(locale('error_title'), locale('error_exit_failed'), 'error')
                return
            end

            ClearPedTasks(cache.ped)

            local attachedProp = state.getAttachedProp()
            if attachedProp and DoesEntityExist(attachedProp) then
                DeleteEntity(attachedProp)
            end

            Wait(100)

            state.reset()
            DetachEntity(cache.ped, true, true)
            Wait(100)
            lib.playAnim(cache.ped, 'anim@mp_player_intselfiethumbs_up', 'idle_a', 8.0, -8.0, -1, 1, 0)
            while not IsEntityPlayingAnim(cache.ped, 'anim@mp_player_intselfiethumbs_up', 'idle_a', 3) do
                Wait(10)
            end
            Wait(100)
            ClearPedTasksImmediately(cache.ped)

            sendNui({
                action = 'toggleUI',
                data = false
            })
        end
    end
})

lib.addKeybind({
    name = 'gym:performExercise',
    description = locale('perform_exercise'),
    defaultKey = 'E',
    onPressed = function(self)
        if state.getCurrentMachine() and not state.isAnimInProgress() then
            lib.print.debug("Player performing exercise via keybind")

            local success, message = lib.callback.await('gym:attemptExercise', 300)
            if not success then
                lib.print.debug(string.format("Exercise attempt failed: %s", message or "unknown"))
                client.notify(locale('error_title'), message or locale('error_exercise_failed'), 'error')
            end
        end
    end
})
