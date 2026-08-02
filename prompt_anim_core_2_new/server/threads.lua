local configServer = require 'config.config_s'
local state = require 'server.state'
local editable = require 'config.server'

CreateThread(function()
    lib.print.info("Starting gym stats degradation thread")

    while true do
        Wait(60000)

        if configServer.stats.decrease.enable ~= false then
            local multiplier = configServer.stats.decrease.multiplier or 1.0
            local decayDeltas = {
                speed    = -((configServer.stats.decrease.speed    or 0.02)  * multiplier),
                stamina  = -((configServer.stats.decrease.stamina  or 0.02)  * multiplier),
                combat   = -((configServer.stats.decrease.combat   or 0.015) * multiplier),
                strength = -((configServer.stats.decrease.strength or 0.01)  * multiplier),
            }

            local players = GetPlayers()
            for _, playerId in ipairs(players) do
                local source = tonumber(playerId)
                if source then
                    editable.updateStats(source, decayDeltas)
                end
            end
        end

        if configServer.exhaustion.enable then
            for source, groups in pairs(state.getAllExhaustion()) do
                for group, value in pairs(groups) do
                    if value > 0 then
                        state.setExhaustion(source, group, math.max(0, value - (configServer.exhaustion.recoveryRate or 0.01)))

                        local hasExhaustion = false
                        for _, v in pairs(groups) do
                            if v > 0 then
                                hasExhaustion = true
                                break
                            end
                        end
                        if not hasExhaustion then
                            state.clearExhaustion(source)
                        end
                    end
                end
            end
        end
    end
end)
