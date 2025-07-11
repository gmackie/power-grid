-- Power Grid Digital - Mobile Edition
-- Enhanced main.lua with mobile support

local currentState
local states = {}
local State = require("state")
local Player = require("models.player")
local PowerPlant = require("models.power_plant")
local ResourceMarket = require("models.resource_market")
local json = require("lib.json")
local enums = require("models.enums")
local Simulator = require("test.simulator")

-- Mobile support
local MobileConfig = require("mobile.mobile_config")
local TouchAdapter = require("mobile.touch_adapter")

local touchAdapter = nil

function love.load()
    print("Power Grid Digital - Mobile Edition starting...")
    
    -- Initialize mobile configuration
    MobileConfig.initialize()
    
    local screenConfig = MobileConfig.getScreenConfig()
    print("Platform:", screenConfig.os)
    print("Screen:", screenConfig.width .. "x" .. screenConfig.height)
    print("Mobile:", screenConfig.isMobile and "Yes" or "No")
    print("Tablet:", screenConfig.isTablet and "Yes" or "No")
    print("Orientation:", screenConfig.orientation)
    
    -- Set up touch adapter for mobile
    if screenConfig.isMobile then
        touchAdapter = TouchAdapter.new()
        touchAdapter:install()
        
        -- Add gesture callbacks
        touchAdapter.onDoubleTap = function(x, y)
            print("Double tap at", x, y)
            -- Could be used for quick actions
        end
        
        touchAdapter.onLongPress = function(x, y)
            print("Long press at", x, y)
            -- Could open context menus
        end
        
        touchAdapter.onPinch = function(scale)
            print("Pinch scale:", scale)
            -- Could be used for zooming the game board
        end
    end
    
    -- Set window properties based on platform
    if not screenConfig.isMobile then
        love.window.setMode(1600, 900, {
            resizable = true,
            vsync = true,
            minwidth = 1200,
            minheight = 800
        })
    end
    
    love.window.setTitle("Power Grid")
    
    -- Initialize state
    State.init()
    
    -- Initialize simulator (desktop only)
    if not screenConfig.isMobile then
        local simulator = Simulator.new()
        _G.simulator = simulator
    end
    
    -- Set initial state
    changeState("menu")
end

function love.update(dt)
    -- Update touch adapter
    if touchAdapter then
        touchAdapter:update(dt)
    end
    
    -- Update current state
    if currentState and currentState.update then
        currentState:update(dt)
    end
end

function love.draw()
    local screenConfig = MobileConfig.getScreenConfig()
    
    -- Handle safe area on mobile
    if screenConfig.isMobile and screenConfig.useSafeArea then
        love.graphics.push()
        love.graphics.translate(screenConfig.safeArea.x, screenConfig.safeArea.y)
        love.graphics.setScissor(screenConfig.safeArea.x, screenConfig.safeArea.y, 
                               screenConfig.safeArea.w, screenConfig.safeArea.h)
    end
    
    -- Draw current state
    if currentState and currentState.draw then
        currentState:draw()
    end
    
    -- Draw debug info on desktop
    if not screenConfig.isMobile and love.keyboard.isDown("f1") then
        drawDebugInfo()
    end
    
    -- Restore graphics state
    if screenConfig.isMobile and screenConfig.useSafeArea then
        love.graphics.setScissor()
        love.graphics.pop()
    end
end

function drawDebugInfo()
    local screenConfig = MobileConfig.getScreenConfig()
    local fps = love.timer.getFPS()
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 10, 10, 300, 150)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("Debug Info (F1 to toggle)", 15, 15)
    love.graphics.print("FPS: " .. fps, 15, 35)
    love.graphics.print("Platform: " .. screenConfig.os, 15, 55)
    love.graphics.print("Resolution: " .. screenConfig.width .. "x" .. screenConfig.height, 15, 75)
    love.graphics.print("Scale: " .. string.format("%.2f", MobileConfig.getUIScale()), 15, 95)
    love.graphics.print("Touch Targets: " .. MobileConfig.getTouchTargetSize() .. "px", 15, 115)
    
    if touchAdapter then
        love.graphics.print("Touches: " .. touchAdapter:getTouchCount(), 15, 135)
    end
end

-- Input handling with mobile support
function love.mousepressed(x, y, button)
    if currentState and currentState.mousepressed then
        currentState:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    if currentState and currentState.mousereleased then
        currentState:mousereleased(x, y, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    if currentState and currentState.mousemoved then
        currentState:mousemoved(x, y, dx, dy)
    end
end

function love.keypressed(key)
    -- Handle global key commands
    if key == "f1" and not MobileConfig.isMobile() then
        -- Toggle debug info
        return
    elseif key == "escape" then
        if currentState and currentState.keypressed then
            currentState:keypressed(key)
        else
            love.event.quit()
        end
        return
    end
    
    if currentState and currentState.keypressed then
        currentState:keypressed(key)
    end
end

function love.textinput(text)
    if currentState and currentState.textinput then
        currentState:textinput(text)
    end
end

-- Mobile-specific input handlers
function love.touchpressed(id, x, y, dx, dy, pressure)
    -- TouchAdapter will handle this and convert to mouse events
    if currentState and currentState.touchpressed then
        currentState:touchpressed(id, x, y, dx, dy, pressure)
    end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if currentState and currentState.touchmoved then
        currentState:touchmoved(id, x, y, dx, dy, pressure)
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    if currentState and currentState.touchreleased then
        currentState:touchreleased(id, x, y, dx, dy, pressure)
    end
end

-- Handle app lifecycle (important for mobile)
function love.focus(focused)
    print("App focus changed:", focused)
    
    if focused then
        -- App resumed
        if currentState and currentState.resume then
            currentState:resume()
        end
    else
        -- App paused
        if currentState and currentState.pause then
            currentState:pause()
        end
        
        -- Auto-save on mobile
        if MobileConfig.isMobile() then
            -- Save game state
            print("Auto-saving game state...")
        end
    end
end

function love.lowmemory()
    print("Low memory warning - clearing caches")
    -- Clear texture caches, reduce memory usage
    collectgarbage("collect")
end

-- State management (unchanged)
function changeState(newStateName, ...)
    print("Changing state to: " .. newStateName)
    
    if currentState and currentState.leave then
        currentState:leave()
    end
    
    if states[newStateName] == nil then
        states[newStateName] = require('states.' .. newStateName)
    end
    
    currentState = states[newStateName]
    
    if currentState.enter then
        currentState:enter(...)
    end
end

-- Global helper functions
function getScreenConfig()
    return MobileConfig.getScreenConfig()
end

function getTouchTargetSize()
    return MobileConfig.getTouchTargetSize()
end

function getUIScale()
    return MobileConfig.getUIScale()
end

-- Export for global access
_G.changeState = changeState
_G.getScreenConfig = getScreenConfig
_G.getTouchTargetSize = getTouchTargetSize
_G.getUIScale = getUIScale