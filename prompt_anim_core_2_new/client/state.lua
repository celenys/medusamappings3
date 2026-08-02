---@class ClientState
local State = {
    currentMachine = nil,
    animInProgress = false,
    currentLocation = nil,
    currentLocationPoint = nil,
    attachedProp = nil
}

---@param machine table?
---@param entity number?
function State.setCurrentMachine(machine, entity)
    State.currentMachine = machine
    if machine and entity then
        State.currentMachine.entity = entity
    end
end

---@return table?
function State.getCurrentMachine()
    return State.currentMachine
end

---@param inProgress boolean
function State.setAnimInProgress(inProgress)
    State.animInProgress = inProgress
end

---@return boolean
function State.isAnimInProgress()
    return State.animInProgress
end

---@param location table?
---@param point table?
function State.setCurrentLocation(location, point)
    State.currentLocation = location
    State.currentLocationPoint = point
end

---@return table?, table?
function State.getCurrentLocation()
    return State.currentLocation, State.currentLocationPoint
end

---@param prop number?
function State.setAttachedProp(prop)
    State.attachedProp = prop
end

---@return number?
function State.getAttachedProp()
    return State.attachedProp
end

function State.reset()
    State.currentMachine = nil
    State.animInProgress = false

    if State.attachedProp and DoesEntityExist(State.attachedProp) then
        DeleteEntity(State.attachedProp)
    end
    State.attachedProp = nil
end

return State
