-- Simple test to verify the integration test harness works
-- This runs in Love2D without needing the server

-- Set up a minimal Love2D environment for testing
_G.love = _G.love or {}
_G.love.timer = _G.love.timer or {}
_G.love.graphics = _G.love.graphics or {}
_G.love.filesystem = _G.love.filesystem or {}
_G.love.math = _G.love.math or {}

-- Mock Love2D functions
_G.love.timer.getTime = function() return os.clock() end
_G.love.graphics.newCanvas = function() return {} end
_G.love.graphics.setCanvas = function() end
_G.love.filesystem.createDirectory = function() return true end
_G.love.math.random = function(min, max) return math.random(min, max) end
_G.love.mousepressed = function() end
_G.love.mousereleased = function() end
_G.love.textinput = function() end

-- Mock global state tracking
_G.currentStateName = "menu"
_G.changeState = function(newState)
    print("State changed to: " .. newState)
    _G.currentStateName = newState
end

-- Load the test harness
local IntegrationTestHarness = require("test.integration_test_harness")

-- Create and configure test harness
local testHarness = IntegrationTestHarness:new()
testHarness:installGlobalHooks()

-- Add a simple test
local simpleTest = testHarness:defineTest(
    "simple_mock_test",
    "Test basic harness functionality with mocked components",
    {
        {action = "wait", duration = 0.1},
        {action = "verify", condition = "network_connected"}, -- This should fail
        {action = "click", target = "play_online_button"},
        {action = "wait", duration = 0.1},
        {action = "screenshot", name = "test_screenshot"}
    }
)

testHarness:addTest(simpleTest)

-- Start the test
print("Starting simple integration test...")
testHarness:start()

-- Simulate update loop
local totalTime = 0
local maxTime = 10 -- Run for max 10 seconds

while testHarness.isRunning and totalTime < maxTime do
    local dt = 0.016 -- 60 FPS
    testHarness:update(dt)
    totalTime = totalTime + dt
    
    -- Simulate some state changes for testing
    if totalTime > 2 and _G.currentStateName == "menu" then
        _G.changeState("lobbyBrowser")
    end
end

print("Test completed!")
print("Total time: " .. totalTime .. " seconds")
print("Results: " .. #testHarness.results .. " tests")

for _, result in ipairs(testHarness.results) do
    print(string.format("  %s: %s", result.name, result.status))
    if result.error then
        print("    Error: " .. result.error)
    end
end