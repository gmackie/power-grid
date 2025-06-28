-- Test Simulator for Power Grid Love2D Client
-- This module provides automated testing capabilities by simulating user input

local Simulator = {}
Simulator.__index = Simulator

local AIPlayer = require("test.ai_player")

function Simulator.new()
    local self = setmetatable({}, Simulator)
    self.enabled = false
    self.currentTest = nil
    self.testQueue = {}
    self.eventQueue = {}
    self.timer = 0
    self.testResults = {}
    self.verbose = true
    self.aiPlayers = {}
    return self
end

-- Enable simulation mode
function Simulator:enable(testName)
    self.enabled = true
    self.currentTest = testName or "default"
    self.timer = 0
    self.eventQueue = {}
    if self.verbose then
        print("[SIMULATOR] Enabled - Running test: " .. self.currentTest)
    end
end

-- Disable simulation mode
function Simulator:disable()
    if self.enabled and self.verbose then
        print("[SIMULATOR] Disabled")
    end
    self.enabled = false
    self.currentTest = nil
    self.eventQueue = {}
end

-- Add a simulated event to the queue
function Simulator:addEvent(delay, eventType, ...)
    if not self.enabled then return end
    
    local event = {
        time = self.timer + delay,
        type = eventType,
        args = {...}
    }
    table.insert(self.eventQueue, event)
    
    -- Sort events by time
    table.sort(self.eventQueue, function(a, b) return a.time < b.time end)
    
    if self.verbose then
        print("[SIMULATOR] Queued " .. eventType .. " at " .. event.time .. "s")
    end
end

-- Update simulator (call from main update loop)
function Simulator:update(dt)
    if not self.enabled then return end
    
    self.timer = self.timer + dt
    
    -- Process events that are ready
    while #self.eventQueue > 0 and self.eventQueue[1].time <= self.timer do
        local event = table.remove(self.eventQueue, 1)
        self:executeEvent(event)
    end
end

-- Execute a simulated event
function Simulator:executeEvent(event)
    if self.verbose then
        print("[SIMULATOR] Executing " .. event.type)
    end
    
    if event.type == "mousepressed" then
        self:simulateMousePressed(unpack(event.args))
    elseif event.type == "mousereleased" then
        self:simulateMouseReleased(unpack(event.args))
    elseif event.type == "keypressed" then
        self:simulateKeyPressed(unpack(event.args))
    elseif event.type == "textinput" then
        self:simulateTextInput(unpack(event.args))
    elseif event.type == "wait" then
        -- Do nothing, just wait
    elseif event.type == "log" then
        print("[SIMULATOR] " .. (event.args[1] or ""))
    elseif event.type == "assert" then
        self:runAssertion(event.args[1], event.args[2])
    elseif event.type == "custom" then
        if event.args[1] and type(event.args[1]) == "function" then
            event.args[1](unpack(event.args, 2))
        end
    end
end

-- Simulate mouse press
function Simulator:simulateMousePressed(x, y, button)
    button = button or 1
    if love.mousepressed then
        love.mousepressed(x, y, button)
    end
end

-- Simulate mouse release
function Simulator:simulateMouseReleased(x, y, button)
    button = button or 1
    if love.mousereleased then
        love.mousereleased(x, y, button)
    end
end

-- Simulate key press
function Simulator:simulateKeyPressed(key, scancode, isrepeat)
    isrepeat = isrepeat or false
    if love.keypressed then
        love.keypressed(key, scancode, isrepeat)
    end
end

-- Simulate text input
function Simulator:simulateTextInput(text)
    if love.textinput then
        love.textinput(text)
    end
end

-- Run an assertion
function Simulator:runAssertion(condition, message)
    local success, result = pcall(condition)
    if not success or not result then
        local msg = message or "Assertion failed"
        print("[SIMULATOR ERROR] " .. msg)
        self.testResults[self.currentTest] = {success = false, error = msg}
    else
        if self.verbose then
            print("[SIMULATOR] Assertion passed: " .. (message or ""))
        end
    end
end

-- Predefined test scenarios
function Simulator:runFullGameTest()
    self:enable("full_game_test")
    
    -- Create AI players for this test
    self.aiPlayers = AIPlayer.createTeam(3, "easy")
    
    -- Test scenario: Complete game flow with 3 AI players
    self:addEvent(0.5, "log", "Starting full game test with AI players")
    
    -- Navigate to pass and play (button is at 400-600 x 300-350)
    self:addEvent(1.0, "mousepressed", 500, 325) -- Click Pass and Play button center
    self:addEvent(1.1, "mousereleased", 500, 325)
    
    -- Add AI players
    self:addEvent(2.0, "log", "Adding AI players")
    
    for i, aiPlayer in ipairs(self.aiPlayers) do
        local delay = 2 + (i * 2) -- Space out player additions
        
        -- Click name input (centered at ~800,200 for 1600x900 window)
        self:addEvent(delay, "mousepressed", 800, 200)
        self:addEvent(delay + 0.1, "mousereleased", 800, 200)
        
        -- Enter AI player name
        self:addEvent(delay + 0.5, "textinput", aiPlayer.name)
        
        -- Select different color (colors are near input box)
        if i > 1 then
            local colorCoords = {
                {750, 280}, -- First color
                {780, 280}, -- Second color  
                {810, 280}, -- Third color
                {840, 280}, -- Fourth color
            }
            if colorCoords[i] then
                self:addEvent(delay + 1.0, "mousepressed", colorCoords[i][1], colorCoords[i][2])
                self:addEvent(delay + 1.1, "mousereleased", colorCoords[i][1], colorCoords[i][2])
            end
        end
        
        -- Click add button (centered below colors)
        self:addEvent(delay + 1.5, "mousepressed", 800, 350)
        self:addEvent(delay + 1.6, "mousereleased", 800, 350)
    end
    
    -- Start game (start button is below add button)
    local startDelay = 2 + (#self.aiPlayers * 2) + 1
    self:addEvent(startDelay, "log", "Starting game")
    self:addEvent(startDelay + 0.5, "mousepressed", 800, 420) -- Click start game button
    self:addEvent(startDelay + 0.6, "mousereleased", 800, 420)
    
    -- Test game phases with AI decisions
    local phaseDelay = startDelay + 2
    self:addEvent(phaseDelay, "log", "Testing game phases with AI")
    
    -- Player order phase (should auto-complete)
    self:addEvent(phaseDelay + 1, "assert", function() 
        local State = require("state")
        return State.currentPhase ~= "PLAYER_ORDER"
    end, "Player order phase should complete")
    
    -- Auction phase - let AI make some basic decisions
    self:addEvent(phaseDelay + 2, "log", "AI testing auction phase")
    self:addEvent(phaseDelay + 4, "keypressed", "c") -- Skip after brief AI test
    
    -- Resource buying phase
    self:addEvent(phaseDelay + 5, "log", "AI testing resource buying phase")
    self:addEvent(phaseDelay + 7, "keypressed", "c") -- Skip after brief AI test
    
    -- Building phase - AI makes building decisions
    self:addEvent(phaseDelay + 8, "log", "AI testing building phase")
    self:addEvent(phaseDelay + 9, "custom", function() self:runAIBuildingDecisions() end)
    
    -- Bureaucracy phase (should auto-advance)
    self:addEvent(phaseDelay + 15, "log", "Testing bureaucracy phase")
    self:addEvent(phaseDelay + 18, "assert", function()
        local State = require("state")
        return State.currentPhase == "PLAYER_ORDER" -- Should cycle back to start
    end, "Should cycle back to player order phase")
    
    self:addEvent(phaseDelay + 20, "log", "Full game test completed")
    self:addEvent(phaseDelay + 20.5, "custom", function() self:disable() end)
end

-- Run a simple menu navigation test
function Simulator:runMenuTest()
    self:enable("menu_test")
    
    self:addEvent(0.5, "log", "Testing menu navigation")
    
    -- Click Pass and Play button
    self:addEvent(1.0, "log", "Clicking Pass and Play button at (500, 325)")
    self:addEvent(1.5, "mousepressed", 500, 325)
    self:addEvent(1.6, "mousereleased", 500, 325)
    
    -- Check if we transitioned to playerSetup
    self:addEvent(3.0, "assert", function()
        local currentState = _G.currentState
        return currentState and currentState == _G.states["playerSetup"]
    end, "Should transition to playerSetup state")
    
    self:addEvent(4.0, "log", "Menu test completed")
    self:addEvent(4.5, "custom", function() self:disable() end)
end

-- Run a quick phase test
function Simulator:runPhaseTest(startPhase)
    self:enable("phase_test_" .. (startPhase or "auction"))
    
    self:addEvent(0.5, "log", "Starting phase test for " .. (startPhase or "auction"))
    
    -- Simulate starting the game in a specific phase
    self:addEvent(1.0, "custom", function()
        local State = require("state")
        -- Create test players
        State.players = {
            {name = "TestPlayer1", money = 100, powerPlants = {}, cities = {}, color = "RED"},
            {name = "TestPlayer2", money = 100, powerPlants = {}, cities = {}, color = "BLUE"},
            {name = "TestPlayer3", money = 100, powerPlants = {}, cities = {}, color = "GREEN"}
        }
        State.currentPlayerIndex = 1
        
        if startPhase then
            local enums = require("models.enums")
            State.currentPhase = enums.GamePhase[startPhase:upper()]
        end
    end)
    
    self:addEvent(5.0, "log", "Phase test completed")
    self:addEvent(5.5, "custom", function() self:disable() end)
end

-- Run a building phase specific test
function Simulator:runBuildingTest()
    self:enable("building_test")
    
    self:addEvent(0.5, "log", "Starting building phase test")
    
    -- Set up game state for building
    self:addEvent(1.0, "custom", function()
        local State = require("state")
        local enums = require("models.enums")
        
        -- Create test players with money
        State.players = {
            {name = "Builder1", money = 50, powerPlants = {}, cities = {}, color = "RED"},
            {name = "Builder2", money = 50, powerPlants = {}, cities = {}, color = "BLUE"}
        }
        State.currentPlayerIndex = 1
        State.currentPhase = enums.GamePhase.BUILDING
        
        print("[SIMULATOR] Set up building test with 2 players")
    end)
    
    -- Test building in multiple cities
    self:addEvent(2.0, "log", "Testing city building")
    
    -- First player builds in Seattle
    self:addEvent(3.0, "mousepressed", 320, 200) -- Seattle position + offset
    self:addEvent(3.1, "mousereleased", 320, 200)
    self:addEvent(4.0, "mousepressed", 320, 200) -- Confirm build
    self:addEvent(4.1, "mousereleased", 320, 200)
    
    -- Second player builds in Portland
    self:addEvent(5.0, "mousepressed", 340, 280) -- Portland position + offset
    self:addEvent(5.1, "mousereleased", 340, 280)
    self:addEvent(6.0, "mousepressed", 340, 280) -- Confirm build
    self:addEvent(6.1, "mousereleased", 340, 280)
    
    -- First player passes
    self:addEvent(7.0, "keypressed", "p")
    
    -- Second player passes
    self:addEvent(8.0, "keypressed", "p")
    
    self:addEvent(9.0, "assert", function()
        local State = require("state")
        return #State.players[1].cities > 0 and #State.players[2].cities > 0
    end, "Both players should have built cities")
    
    self:addEvent(10.0, "log", "Building test completed")
    self:addEvent(10.5, "custom", function() self:disable() end)
end

-- Get test results
function Simulator:getResults()
    return self.testResults
end

-- Check if simulator is running
function Simulator:isRunning()
    return self.enabled
end

-- AI Building Decisions
function Simulator:runAIBuildingDecisions()
    local State = require("state")
    
    if not State.cities or #State.cities == 0 then
        print("[SIMULATOR] No cities available for AI building")
        return
    end
    
    -- Simulate AI players making building decisions
    for i, aiPlayer in ipairs(self.aiPlayers) do
        if State.players and State.players[i] then
            local gamePlayer = State.players[i]
            local decision = aiPlayer:makeBuildingDecision(State, gamePlayer, State.cities)
            
            if decision.action == "build" and decision.city then
                local x, y = aiPlayer:getCityClickCoords(decision.city)
                
                -- Add building actions for this AI player
                local delay = i * 2 -- Space out AI actions
                self:addEvent(delay, "log", aiPlayer.name .. " deciding to build in " .. decision.city.name)
                self:addEvent(delay + 0.5, "mousepressed", x, y)
                self:addEvent(delay + 0.6, "mousereleased", x, y)
                self:addEvent(delay + 1.0, "mousepressed", x, y) -- Confirm build
                self:addEvent(delay + 1.1, "mousereleased", x, y)
            else
                -- AI decides to pass
                local delay = i * 2
                self:addEvent(delay, "log", aiPlayer.name .. " passing building turn")
                self:addEvent(delay + 0.5, "keypressed", "p")
            end
        end
    end
    
    -- Final pass to end building phase
    self:addEvent((#self.aiPlayers * 2) + 1, "keypressed", "p")
end

return Simulator