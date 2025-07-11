-- Integration Test Harness for End-to-End Server/Client Testing
-- This module provides automated testing capabilities for the Love2D client
-- including simulated user interactions and server communication testing

local IntegrationTestHarness = {}
IntegrationTestHarness.__index = IntegrationTestHarness

local json = require("lib.json")

function IntegrationTestHarness:new()
    local self = setmetatable({}, IntegrationTestHarness)
    
    self.isRunning = false
    self.currentTest = nil
    self.testQueue = {}
    self.results = {}
    self.startTime = 0
    self.timeout = 30 -- Default 30 second timeout per test
    
    -- Mouse simulation state
    self.mouseSimulator = {
        x = 0,
        y = 0,
        clickQueue = {},
        delayTimer = 0,
        isSimulating = false
    }
    
    -- Test state tracking
    self.testState = {
        serverConnected = false,
        lobbyCreated = false,
        gameJoined = false,
        gameStarted = false,
        phaseTransitions = {},
        errors = {}
    }
    
    return self
end

-- Test definition structure
function IntegrationTestHarness:defineTest(name, description, steps)
    return {
        name = name,
        description = description,
        steps = steps,
        startTime = 0,
        timeout = self.timeout,
        status = "pending", -- pending, running, passed, failed, timeout
        error = nil,
        results = {}
    }
end

-- Add predefined test suites
function IntegrationTestHarness:addBasicNetworkTests()
    -- Test 1: Basic Connection Test
    self:addTest(self:defineTest(
        "basic_connection",
        "Test basic WebSocket connection to server",
        {
            {action = "wait", duration = 1}, -- Wait for UI to load
            {action = "click", target = "play_online_button", description = "Click Play Online"},
            {action = "wait_for_state", state = "lobbyBrowser", timeout = 10},
            {action = "verify", condition = "network_connected"},
            {action = "screenshot", name = "lobby_browser_connected"}
        }
    ))
    
    -- Test 2: Create Game Test
    self:addTest(self:defineTest(
        "create_game",
        "Test creating a new game lobby",
        {
            {action = "wait", duration = 1},
            {action = "click", target = "play_online_button"},
            {action = "wait_for_state", state = "lobbyBrowser", timeout = 10},
            {action = "click", target = "create_game_button"},
            {action = "wait", duration = 0.5},
            {action = "type", text = "Test Game"},
            {action = "click", target = "create_dialog_create_button"},
            {action = "wait_for_state", state = "gameLobby", timeout = 5},
            {action = "verify", condition = "game_created"},
            {action = "screenshot", name = "game_lobby_created"}
        }
    ))
    
    -- Test 3: Full Game Flow Test
    self:addTest(self:defineTest(
        "full_game_flow",
        "Test complete game flow from menu to first turn",
        {
            {action = "wait", duration = 1},
            {action = "click", target = "play_online_button"},
            {action = "wait_for_state", state = "lobbyBrowser", timeout = 10},
            {action = "click", target = "create_game_button"},
            {action = "wait", duration = 0.5},
            {action = "type", text = "Integration Test Game"},
            {action = "click", target = "create_dialog_create_button"},
            {action = "wait_for_state", state = "gameLobby", timeout = 5},
            {action = "add_ai_players", count = 1}, -- Add AI player for testing
            {action = "click", target = "start_game_button"},
            {action = "wait_for_state", state = "game", timeout = 10},
            {action = "verify", condition = "game_started"},
            {action = "wait_for_phase", phase = "auction", timeout = 5},
            {action = "screenshot", name = "game_auction_phase"}
        }
    ))
end

function IntegrationTestHarness:addTest(test)
    table.insert(self.testQueue, test)
end

function IntegrationTestHarness:start()
    if self.isRunning then
        print("Test harness already running")
        return false
    end
    
    print("Starting Integration Test Harness")
    print("Tests queued: " .. #self.testQueue)
    
    self.isRunning = true
    self.currentTestIndex = 1
    self.results = {}
    
    if #self.testQueue > 0 then
        self:startNextTest()
    else
        print("No tests to run")
        self.isRunning = false
    end
    
    return true
end

function IntegrationTestHarness:startNextTest()
    if self.currentTestIndex > #self.testQueue then
        self:finishAllTests()
        return
    end
    
    self.currentTest = self.testQueue[self.currentTestIndex]
    self.currentTest.status = "running"
    self.currentTest.startTime = love.timer.getTime()
    self.currentStepIndex = 1
    
    print(string.format("Starting test %d/%d: %s", 
          self.currentTestIndex, #self.testQueue, self.currentTest.name))
    print("Description: " .. self.currentTest.description)
    
    self:executeNextStep()
end

function IntegrationTestHarness:executeNextStep()
    if not self.currentTest or self.currentStepIndex > #self.currentTest.steps then
        self:completeCurrentTest("passed")
        return
    end
    
    local step = self.currentTest.steps[self.currentStepIndex]
    print(string.format("  Step %d: %s", self.currentStepIndex, step.action))
    
    self:executeStep(step)
end

function IntegrationTestHarness:executeStep(step)
    if step.action == "wait" then
        self:scheduleNextStep(step.duration or 1)
        
    elseif step.action == "click" then
        self:simulateClick(step.target, step.x, step.y)
        self:scheduleNextStep(0.1)
        
    elseif step.action == "type" then
        self:simulateTyping(step.text)
        self:scheduleNextStep(0.2)
        
    elseif step.action == "wait_for_state" then
        self:waitForState(step.state, step.timeout or 5)
        
    elseif step.action == "wait_for_phase" then
        self:waitForPhase(step.phase, step.timeout or 5)
        
    elseif step.action == "verify" then
        if self:verifyCondition(step.condition) then
            self:scheduleNextStep(0.1)
        else
            self:completeCurrentTest("failed", "Verification failed: " .. step.condition)
        end
        
    elseif step.action == "screenshot" then
        self:takeScreenshot(step.name)
        self:scheduleNextStep(0.1)
        
    elseif step.action == "add_ai_players" then
        self:addAIPlayers(step.count or 1)
        self:scheduleNextStep(0.5)
        
    else
        print("Unknown step action: " .. step.action)
        self:scheduleNextStep(0.1)
    end
end

function IntegrationTestHarness:scheduleNextStep(delay)
    self.stepTimer = delay
    self.waitingForNextStep = true
end

function IntegrationTestHarness:simulateClick(target, x, y)
    -- Predefined click targets
    local targets = {
        play_online_button = {x = 400, y = 300}, -- Estimated positions
        create_game_button = {x = 125, y = 520},
        create_dialog_create_button = {x = 270, y = 400},
        start_game_button = {x = 400, y = 475},
        join_game_button = {x = 295, y = 520}
    }
    
    local clickPos = targets[target]
    if clickPos then
        self:queueMouseClick(clickPos.x, clickPos.y)
    elseif x and y then
        self:queueMouseClick(x, y)
    else
        print("Warning: Unknown click target: " .. tostring(target))
    end
end

function IntegrationTestHarness:queueMouseClick(x, y)
    table.insert(self.mouseSimulator.clickQueue, {
        x = x, y = y, delay = 0.1
    })
    self.mouseSimulator.isSimulating = true
end

function IntegrationTestHarness:simulateTyping(text)
    -- Simulate text input by calling love.textinput for each character
    for i = 1, #text do
        local char = text:sub(i, i)
        love.textinput(char)
    end
end

function IntegrationTestHarness:waitForState(stateName, timeout)
    self.waitCondition = {
        type = "state",
        target = stateName,
        timeout = timeout,
        startTime = love.timer.getTime()
    }
end

function IntegrationTestHarness:waitForPhase(phaseName, timeout)
    self.waitCondition = {
        type = "phase",
        target = phaseName,
        timeout = timeout,
        startTime = love.timer.getTime()
    }
end

function IntegrationTestHarness:verifyCondition(condition)
    if condition == "network_connected" then
        local NetworkManager = require("network.network_manager")
        local network = NetworkManager.getInstance()
        return network.isOnline
        
    elseif condition == "game_created" then
        -- Check if we're in game lobby state
        return self:getCurrentStateName() == "gameLobby"
        
    elseif condition == "game_started" then
        return self:getCurrentStateName() == "game"
        
    else
        print("Unknown verification condition: " .. condition)
        return false
    end
end

function IntegrationTestHarness:takeScreenshot(name)
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = string.format("test_screenshots/%s_%s.png", name, timestamp)
    
    -- Create screenshots directory if it doesn't exist
    love.filesystem.createDirectory("test_screenshots")
    
    -- Take screenshot using Love2D's screenshot function
    local canvas = love.graphics.newCanvas()
    love.graphics.setCanvas(canvas)
    
    -- Draw current frame to canvas
    if currentState and currentState.draw then
        currentState:draw()
    end
    
    love.graphics.setCanvas()
    
    -- Save canvas as image
    local imageData = canvas:newImageData()
    imageData:encode("png", filename)
    
    print("Screenshot saved: " .. filename)
end

function IntegrationTestHarness:addAIPlayers(count)
    -- Simulate additional players joining for testing
    -- This would normally be handled by the server, but for testing
    -- we can mock additional players
    local NetworkManager = require("network.network_manager")
    local network = NetworkManager.getInstance()
    
    for i = 1, count do
        -- Simulate a player join message from server
        local colors = {"blue", "green", "yellow", "purple", "black"}
        local mockPlayer = {
            id = "ai_player_" .. i,
            name = "AI Player " .. i,
            color = colors[i] or "black",
            is_ready = true
        }
        
        -- This would normally come from the server
        if network.onGameStateUpdate then
            local mockGameState = {
                players = {[mockPlayer.id] = mockPlayer},
                status = "LOBBY"
            }
            network.onGameStateUpdate(mockGameState)
        end
    end
end

function IntegrationTestHarness:update(dt)
    if not self.isRunning then return end
    
    -- Update mouse simulator
    self:updateMouseSimulator(dt)
    
    -- Check for test timeout
    if self.currentTest then
        local elapsed = love.timer.getTime() - self.currentTest.startTime
        if elapsed > self.currentTest.timeout then
            self:completeCurrentTest("timeout", "Test timed out after " .. elapsed .. " seconds")
            return
        end
    end
    
    -- Handle step timing
    if self.waitingForNextStep and self.stepTimer then
        self.stepTimer = self.stepTimer - dt
        if self.stepTimer <= 0 then
            self.waitingForNextStep = false
            self.stepTimer = nil
            self.currentStepIndex = self.currentStepIndex + 1
            self:executeNextStep()
        end
    end
    
    -- Handle wait conditions
    if self.waitCondition then
        local elapsed = love.timer.getTime() - self.waitCondition.startTime
        if elapsed > self.waitCondition.timeout then
            self:completeCurrentTest("failed", "Wait condition timed out: " .. self.waitCondition.type)
            return
        end
        
        local conditionMet = false
        if self.waitCondition.type == "state" then
            conditionMet = self:getCurrentStateName() == self.waitCondition.target
        elseif self.waitCondition.type == "phase" then
            conditionMet = self:getCurrentPhaseName() == self.waitCondition.target
        end
        
        if conditionMet then
            self.waitCondition = nil
            self.currentStepIndex = self.currentStepIndex + 1
            self:executeNextStep()
        end
    end
end

function IntegrationTestHarness:updateMouseSimulator(dt)
    if not self.mouseSimulator.isSimulating then return end
    
    if self.mouseSimulator.delayTimer > 0 then
        self.mouseSimulator.delayTimer = self.mouseSimulator.delayTimer - dt
        return
    end
    
    if #self.mouseSimulator.clickQueue > 0 then
        local click = table.remove(self.mouseSimulator.clickQueue, 1)
        
        -- Simulate mouse press and release
        love.mousepressed(click.x, click.y, 1)
        love.mousereleased(click.x, click.y, 1)
        
        self.mouseSimulator.delayTimer = click.delay
        print(string.format("Simulated click at (%d, %d)", click.x, click.y))
    else
        self.mouseSimulator.isSimulating = false
    end
end

function IntegrationTestHarness:getCurrentStateName()
    -- This requires access to the global state system
    -- We'll need to expose the current state name globally
    return _G.currentStateName or "unknown"
end

function IntegrationTestHarness:getCurrentPhaseName()
    local State = require("state")
    if State.gameState and State.gameState.currentPhase then
        return State.gameState.currentPhase
    end
    return "unknown"
end

function IntegrationTestHarness:completeCurrentTest(status, error)
    if not self.currentTest then return end
    
    self.currentTest.status = status
    self.currentTest.error = error
    self.currentTest.endTime = love.timer.getTime()
    self.currentTest.duration = self.currentTest.endTime - self.currentTest.startTime
    
    table.insert(self.results, self.currentTest)
    
    print(string.format("Test '%s' completed: %s", self.currentTest.name, status))
    if error then
        print("Error: " .. error)
    end
    print(string.format("Duration: %.2f seconds", self.currentTest.duration))
    
    self.currentTest = nil
    self.waitCondition = nil
    self.waitingForNextStep = false
    self.currentTestIndex = self.currentTestIndex + 1
    
    -- Start next test after a brief delay
    self.stepTimer = 1
    self.waitingForNextStep = true
    self.nextTestScheduled = true
end

function IntegrationTestHarness:finishAllTests()
    self.isRunning = false
    
    print("\n=== Integration Test Results ===")
    local passed = 0
    local failed = 0
    local timeouts = 0
    
    for _, result in ipairs(self.results) do
        print(string.format("%s: %s (%.2fs)", result.name, result.status, result.duration))
        if result.error then
            print("  Error: " .. result.error)
        end
        
        if result.status == "passed" then passed = passed + 1
        elseif result.status == "failed" then failed = failed + 1
        elseif result.status == "timeout" then timeouts = timeouts + 1 end
    end
    
    print(string.format("\nSummary: %d passed, %d failed, %d timeouts", passed, failed, timeouts))
    
    -- Save detailed results
    self:saveResults()
end

function IntegrationTestHarness:saveResults()
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = "test_results_" .. timestamp .. ".json"
    
    local results = {
        timestamp = timestamp,
        summary = {
            total = #self.results,
            passed = 0,
            failed = 0,
            timeouts = 0
        },
        tests = self.results
    }
    
    for _, result in ipairs(self.results) do
        if result.status == "passed" then results.summary.passed = results.summary.passed + 1
        elseif result.status == "failed" then results.summary.failed = results.summary.failed + 1
        elseif result.status == "timeout" then results.summary.timeouts = results.summary.timeouts + 1 end
    end
    
    local jsonStr = json.encode(results)
    love.filesystem.write(filename, jsonStr)
    print("Results saved to: " .. filename)
end

-- Global access for state tracking
function IntegrationTestHarness:installGlobalHooks()
    -- Hook into state changes
    local originalChangeState = _G.changeState
    _G.changeState = function(newStateName, ...)
        _G.currentStateName = newStateName
        return originalChangeState(newStateName, ...)
    end
end

return IntegrationTestHarness