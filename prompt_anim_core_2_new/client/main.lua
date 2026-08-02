local config = require 'config.config_c'
lib.locale(config.language ~= 'auto' and config.language or nil)
local uiReady = false

local points = require 'client.points'
require 'client.keybinds'
require 'client.callbacks'
require 'client.events'
require 'client.creator'

if config.boxingRing.enable then
    require 'client.boxing_ring'
end

points.InitializeLocationPoints()

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(100) end

    Wait(1500)
    lib.print.debug("Requesting custom equipment from server")
    local data = lib.callback.await('gym:getSpawnedEquipment', false)

    if data then
        if data.deprecated and next(data.deprecated) then
            local count = 0
            for _ in pairs(data.deprecated) do
                count = count + 1
            end
            lib.print.info(string.format("Received %d deprecated custom equipment items from server", count))
            TriggerEvent('gym:syncCustomEquipment', data.deprecated)
        end

        if data.locations and next(data.locations) then
            local count = 0
            for locationName, locationData in pairs(data.locations) do
                count = count + 1
                TriggerEvent('gym:locationCreated', locationName, locationData)
            end
            lib.print.info(string.format("Received %d gym locations from server", count))
        end

        if not (data.deprecated and next(data.deprecated)) and not (data.locations and next(data.locations)) then
            lib.print.debug("No equipment or locations to sync")
        end
    else
        lib.print.debug("No data received from server")
    end
end)

CreateThread(function()
    while not uiReady do Wait(300) end
    sendNui({
        action = 'setLocale',
        data = {
            start_training = locale('ui.start_training'),
            stop_training = locale('ui.stop_training'),
            ring_lobby = locale('ui.ring_lobby'),
            ring_leave = locale('ui.ring_leave'),
            ring_join = locale('ui.ring_join'),
            ring_ready = locale('ui.ring_ready'),
            ring_waiting = locale('ui.ring_waiting'),
            ring_vs = locale('ui.ring_vs'),
            ring_you = locale('ui.ring_you'),
            ring_im_ready = locale('ui.ring_im_ready'),
            ring_cancel_ready = locale('ui.ring_cancel_ready'),
            ring_victory = locale('ui.ring_victory'),
            ring_defeat = locale('ui.ring_defeat'),
            ring_draw = locale('ui.ring_draw'),
        }
    })
end)

RegisterNUICallback('uiReady', function(_, cb)
    uiReady = true
    cb('ok')
end)