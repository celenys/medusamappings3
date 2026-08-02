local state = require 'server.state'
local utils = require 'server.utils'
local legacy = require 'server.legacy_events'

AddEventHandler('playerDropped', function()
    local source = source --[[@as Source]]
    lib.print.debug(string.format("Player %d disconnected - cleaning up machine state", source))
    
    local machineName, index = utils.getMachineByUser(source)
    if not machineName or not index then
        legacy.clearExercise(source)
        return
    end

    lib.print.debug(string.format("Freeing machine %s[%d] from disconnected player", machineName, index))
    state.setMachineInUse(machineName, index, nil)
    local objData = state.getMachineObject(source)
    if objData then
        for _, playerId in pairs(objData.players) do
            TriggerClientEvent('gym:toggleMachineVisibility', playerId, {
                coords = objData.coords,
                machine = machineName,
                visible = true,
            })
        end
        if DoesEntityExist(objData.obj) then
            DeleteEntity(objData.obj)
            state.removeMachineObject(source)
        end
    end

    legacy.clearExercise(source)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        lib.print.info("Resource stopping - cleaning up machine objects")
        
        local cleanupCount = 0
        for source, data in pairs(state.machineObjects) do
            if data and DoesEntityExist(data.obj) then
                DeleteEntity(data.obj)
                cleanupCount = cleanupCount + 1
            end
        end
        
        lib.print.info(string.format("Cleaned up %d machine objects", cleanupCount))
    end
end)
