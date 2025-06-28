local PhaseManager = {}
PhaseManager.__index = PhaseManager

local State = require("state")
local enums = require("models.enums")

function PhaseManager.new()
    local self = setmetatable({}, PhaseManager)
    
    -- Load all phase handlers and instantiate them
    self.phases = {
        [enums.GamePhase.PLAYER_ORDER] = require("phases.player_order").new(),
        [enums.GamePhase.AUCTION] = require("phases.auction").new(),
        [enums.GamePhase.RESOURCE_BUYING] = require("phases.resource_buying").new(),
        [enums.GamePhase.BUILDING] = require("phases.building").new(),
        [enums.GamePhase.BUREAUCRACY] = require("phases.bureaucracy").new()
    }
    self.currentPhaseName = nil -- Keep track of the initialized phase
    return self
end

function PhaseManager:update(dt)
    local targetPhaseName = State.currentPhase
    local currentPhaseObj = self.phases[targetPhaseName]

    if not targetPhaseName then
        -- print("PhaseManager: No current phase set in State.")
        return
    end

    -- Check if the phase has changed or not yet initialized
    if self.currentPhaseName ~= targetPhaseName then
        print("PhaseManager: Detected phase change or initial phase. Old: " .. tostring(self.currentPhaseName) .. ", New: " .. tostring(targetPhaseName))
        -- Potentially call exit on self.phases[self.currentPhaseName] if it exists and has an exit method
        local oldPhaseObj = self.phases[self.currentPhaseName]
        if oldPhaseObj and oldPhaseObj.exit then
            print("PhaseManager: Calling exit() on phase: " .. self.currentPhaseName)
            oldPhaseObj:exit()
        end

        self.currentPhaseName = targetPhaseName -- Update the record of the current phase
        if currentPhaseObj and currentPhaseObj.enter then
            print("PhaseManager: Calling enter() on phase: " .. targetPhaseName)
            currentPhaseObj:enter()
        else
            if not currentPhaseObj then
                print("PhaseManager: ERROR - No phase object found for phase: " .. targetPhaseName)
            elseif not currentPhaseObj.enter then
                 print("PhaseManager: WARNING - Phase object for " .. targetPhaseName .. " has no enter() method.")
            end
        end
    end

    if currentPhaseObj then
        if currentPhaseObj.update then
            currentPhaseObj:update(dt)
        end
        
        if currentPhaseObj.isPhaseComplete and currentPhaseObj:isPhaseComplete() then
            print("Phase " .. targetPhaseName .. " complete. Transitioning to next phase.")
            self:nextPhase() 
            -- The next call to update will handle the enter() for the new phase due to self.currentPhaseName ~= State.currentPhase
        end
    end
end

function PhaseManager:draw()
    local currentPhase = self.phases[State.currentPhase]
    if currentPhase and currentPhase.draw then
        currentPhase:draw()
    end
end

function PhaseManager:mousepressed(x, y, button)
    local currentPhase = self.phases[State.currentPhase]
    if currentPhase and currentPhase.mousepressed then
        currentPhase:mousepressed(x, y, button)
    end
end

function PhaseManager:mousereleased(x, y, button)
    local currentPhase = self.phases[State.currentPhase]
    if currentPhase and currentPhase.mousereleased then
        currentPhase:mousereleased(x, y, button)
    end
end

function PhaseManager:mousemoved(x, y)
    local currentPhase = self.phases[State.currentPhase]
    if currentPhase and currentPhase.mousemoved then
        currentPhase:mousemoved(x, y)
    end
end

function PhaseManager:keypressed(key)
    local currentPhase = self.phases[State.currentPhase]
    if currentPhase and currentPhase.keypressed then
        currentPhase:keypressed(key)
    end
end

function PhaseManager:textinput(t)
    local currentPhase = self.phases[State.currentPhase]
    if currentPhase and currentPhase.textinput then
        currentPhase:textinput(t)
    end
end

function PhaseManager:nextPhase()
    -- Get the next phase in sequence
    local phases = {
        enums.GamePhase.PLAYER_ORDER,
        enums.GamePhase.AUCTION,
        enums.GamePhase.RESOURCE_BUYING,
        enums.GamePhase.BUILDING,
        enums.GamePhase.BUREAUCRACY
    }
    
    -- Find current phase index
    local currentIndex = 1
    for i, phase in ipairs(phases) do
        if phase == State.currentPhase then
            currentIndex = i
            break
        end
    end
    
    -- Set next phase
    local nextIndex = currentIndex % #phases + 1
    State.setCurrentPhase(phases[nextIndex])
    print("PhaseManager: Switched State.currentPhase to " .. phases[nextIndex])
end

function PhaseManager:getCurrentPhase()
    return State.currentPhase
end

function PhaseManager:getCurrentPhaseObject()
    if State.currentPhase and self.phases[State.currentPhase] then
        return self.phases[State.currentPhase]
    end
    return nil
end

return PhaseManager 