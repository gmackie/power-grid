-- Phase Manager with network support
local PhaseManager = {}
PhaseManager.__index = PhaseManager

local State = require("state")
local enums = require("models.enums")

function PhaseManager.new()
    local self = setmetatable({}, PhaseManager)
    
    -- Check if we're in online mode
    local isOnline = State.networkGame and State.networkGame.isOnline
    
    -- Load phase handlers based on mode
    if isOnline then
        -- Use networked versions
        self.phases = {
            [enums.GamePhase.PLAYER_ORDER] = require("phases.player_order").new(),
            [enums.GamePhase.AUCTION] = require("phases.auction_networked").new(),
            [enums.GamePhase.RESOURCE_BUYING] = require("phases.resource_buying_networked").new(),
            [enums.GamePhase.BUILDING] = require("phases.building_networked").new(),
            [enums.GamePhase.BUREAUCRACY] = require("phases.bureaucracy_networked").new()
        }
        print("PhaseManager: Using networked phase handlers")
    else
        -- Use offline versions
        self.phases = {
            [enums.GamePhase.PLAYER_ORDER] = require("phases.player_order").new(),
            [enums.GamePhase.AUCTION] = require("phases.auction").new(),
            [enums.GamePhase.RESOURCE_BUYING] = require("phases.resource_buying").new(),
            [enums.GamePhase.BUILDING] = require("phases.building").new(),
            [enums.GamePhase.BUREAUCRACY] = require("phases.bureaucracy").new()
        }
        print("PhaseManager: Using offline phase handlers")
    end
    
    self.currentPhaseName = nil
    return self
end

function PhaseManager:update(dt)
    local targetPhaseName = State.currentPhase
    local currentPhaseObj = self.phases[targetPhaseName]

    if not targetPhaseName then
        return
    end

    -- Check if the phase has changed
    if self.currentPhaseName ~= targetPhaseName then
        print("PhaseManager: Phase change detected. Old: " .. tostring(self.currentPhaseName) .. ", New: " .. tostring(targetPhaseName))
        
        -- Exit old phase
        local oldPhaseObj = self.phases[self.currentPhaseName]
        if oldPhaseObj and oldPhaseObj.exit then
            print("PhaseManager: Calling exit() on phase: " .. tostring(self.currentPhaseName))
            oldPhaseObj:exit()
        end

        self.currentPhaseName = targetPhaseName
        
        -- Enter new phase
        if currentPhaseObj and currentPhaseObj.enter then
            print("PhaseManager: Calling enter() on phase: " .. tostring(targetPhaseName))
            currentPhaseObj:enter()
        else
            if not currentPhaseObj then
                print("PhaseManager: ERROR - No phase object found for phase: " .. tostring(targetPhaseName))
            elseif not currentPhaseObj.enter then
                print("PhaseManager: WARNING - Phase object for " .. tostring(targetPhaseName) .. " has no enter() method.")
            end
        end
    end

    -- Update current phase
    if currentPhaseObj and currentPhaseObj.update then
        currentPhaseObj:update(dt)
    end
end

function PhaseManager:draw()
    local currentPhaseObj = self.phases[self.currentPhaseName]
    if currentPhaseObj and currentPhaseObj.draw then
        currentPhaseObj:draw()
    end
end

function PhaseManager:mousepressed(x, y, button)
    local currentPhaseObj = self.phases[self.currentPhaseName]
    if currentPhaseObj and currentPhaseObj.mousepressed then
        currentPhaseObj:mousepressed(x, y, button)
    end
end

function PhaseManager:mousereleased(x, y, button)
    local currentPhaseObj = self.phases[self.currentPhaseName]
    if currentPhaseObj and currentPhaseObj.mousereleased then
        currentPhaseObj:mousereleased(x, y, button)
    end
end

function PhaseManager:keypressed(key)
    local currentPhaseObj = self.phases[self.currentPhaseName]
    if currentPhaseObj and currentPhaseObj.keypressed then
        currentPhaseObj:keypressed(key)
    end
end

function PhaseManager:textinput(text)
    local currentPhaseObj = self.phases[self.currentPhaseName]
    if currentPhaseObj and currentPhaseObj.textinput then
        currentPhaseObj:textinput(text)
    end
end

return PhaseManager