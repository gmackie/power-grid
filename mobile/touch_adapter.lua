-- Touch Adapter - Converts touch input to mouse input for compatibility
-- This allows gradual migration to full touch support

local TouchAdapter = {}
TouchAdapter.__index = TouchAdapter

function TouchAdapter.new()
    local self = setmetatable({}, TouchAdapter)
    self.touches = {}
    self.primaryTouch = nil
    self.emulatedMouse = {x = 0, y = 0, pressed = false}
    self.longPressTime = 0.5
    self.doubleTapTime = 0.3
    self.lastTapTime = 0
    self.lastTapX = 0
    self.lastTapY = 0
    return self
end

function TouchAdapter:touchpressed(id, x, y, dx, dy, pressure)
    self.touches[id] = {
        id = id,
        startX = x,
        startY = y,
        x = x,
        y = y,
        startTime = love.timer.getTime(),
        moved = false
    }
    
    -- First touch becomes primary (emulates mouse)
    if not self.primaryTouch then
        self.primaryTouch = id
        self.emulatedMouse.x = x
        self.emulatedMouse.y = y
        self.emulatedMouse.pressed = true
        
        -- Check for double tap
        local currentTime = love.timer.getTime()
        local tapDist = math.sqrt((x - self.lastTapX)^2 + (y - self.lastTapY)^2)
        
        if currentTime - self.lastTapTime < self.doubleTapTime and tapDist < 50 then
            -- Double tap detected
            if self.onDoubleTap then
                self.onDoubleTap(x, y)
            end
        end
        
        self.lastTapTime = currentTime
        self.lastTapX = x
        self.lastTapY = y
        
        -- Emulate mouse press
        if love.mousepressed then
            love.mousepressed(x, y, 1)
        end
    end
    
    -- Handle multi-touch gestures
    local touchCount = self:getTouchCount()
    if touchCount == 2 then
        self:startPinchGesture()
    end
end

function TouchAdapter:touchmoved(id, x, y, dx, dy, pressure)
    if self.touches[id] then
        self.touches[id].x = x
        self.touches[id].y = y
        
        -- Check if moved significantly
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 5 then
            self.touches[id].moved = true
        end
        
        -- Update emulated mouse if this is primary touch
        if id == self.primaryTouch then
            self.emulatedMouse.x = x
            self.emulatedMouse.y = y
            
            -- Emulate mouse move
            if love.mousemoved then
                love.mousemoved(x, y, dx, dy)
            end
        end
        
        -- Handle pinch gesture
        if self:getTouchCount() == 2 then
            self:updatePinchGesture()
        end
    end
end

function TouchAdapter:touchreleased(id, x, y, dx, dy, pressure)
    local touch = self.touches[id]
    if touch then
        local duration = love.timer.getTime() - touch.startTime
        
        -- Check for tap vs long press
        if not touch.moved then
            if duration >= self.longPressTime then
                -- Long press
                if self.onLongPress then
                    self.onLongPress(x, y)
                end
            else
                -- Regular tap
                if self.onTap then
                    self.onTap(x, y)
                end
            end
        end
        
        -- Handle primary touch release
        if id == self.primaryTouch then
            self.emulatedMouse.pressed = false
            self.primaryTouch = nil
            
            -- Emulate mouse release
            if love.mousereleased then
                love.mousereleased(x, y, 1)
            end
            
            -- Find new primary touch if any remain
            for touchId, _ in pairs(self.touches) do
                if touchId ~= id then
                    self.primaryTouch = touchId
                    self.emulatedMouse.x = self.touches[touchId].x
                    self.emulatedMouse.y = self.touches[touchId].y
                    self.emulatedMouse.pressed = true
                    break
                end
            end
        end
        
        self.touches[id] = nil
    end
end

function TouchAdapter:update(dt)
    -- Check for long press
    if self.primaryTouch and self.touches[self.primaryTouch] then
        local touch = self.touches[self.primaryTouch]
        if not touch.moved then
            local duration = love.timer.getTime() - touch.startTime
            if duration >= self.longPressTime and not touch.longPressTriggered then
                touch.longPressTriggered = true
                if self.onLongPress then
                    self.onLongPress(touch.x, touch.y)
                end
            end
        end
    end
end

function TouchAdapter:getTouchCount()
    local count = 0
    for _ in pairs(self.touches) do
        count = count + 1
    end
    return count
end

function TouchAdapter:startPinchGesture()
    local touches = {}
    for _, touch in pairs(self.touches) do
        table.insert(touches, touch)
    end
    
    if #touches >= 2 then
        local dx = touches[2].x - touches[1].x
        local dy = touches[2].y - touches[1].y
        self.pinchStartDistance = math.sqrt(dx*dx + dy*dy)
        self.pinchScale = 1.0
    end
end

function TouchAdapter:updatePinchGesture()
    local touches = {}
    for _, touch in pairs(self.touches) do
        table.insert(touches, touch)
    end
    
    if #touches >= 2 and self.pinchStartDistance then
        local dx = touches[2].x - touches[1].x
        local dy = touches[2].y - touches[1].y
        local currentDistance = math.sqrt(dx*dx + dy*dy)
        
        self.pinchScale = currentDistance / self.pinchStartDistance
        
        if self.onPinch then
            self.onPinch(self.pinchScale)
        end
    end
end

-- Get emulated mouse position
function TouchAdapter:getMousePosition()
    return self.emulatedMouse.x, self.emulatedMouse.y
end

-- Check if emulated mouse is pressed
function TouchAdapter:isMouseDown()
    return self.emulatedMouse.pressed
end

-- Install touch adapter globally
function TouchAdapter:install()
    local adapter = self
    
    -- Override love.mouse functions
    local originalGetPosition = love.mouse.getPosition
    love.mouse.getPosition = function()
        if adapter:getTouchCount() > 0 then
            return adapter:getMousePosition()
        end
        return originalGetPosition()
    end
    
    local originalIsDown = love.mouse.isDown
    love.mouse.isDown = function(button)
        if button == 1 and adapter:getTouchCount() > 0 then
            return adapter:isMouseDown()
        end
        return originalIsDown(button)
    end
    
    -- Install touch callbacks
    love.touchpressed = function(id, x, y, dx, dy, pressure)
        adapter:touchpressed(id, x, y, dx, dy, pressure)
    end
    
    love.touchmoved = function(id, x, y, dx, dy, pressure)
        adapter:touchmoved(id, x, y, dx, dy, pressure)
    end
    
    love.touchreleased = function(id, x, y, dx, dy, pressure)
        adapter:touchreleased(id, x, y, dx, dy, pressure)
    end
end

return TouchAdapter