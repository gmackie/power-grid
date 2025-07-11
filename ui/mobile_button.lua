-- Mobile-friendly button component with touch support

local MobileButton = {}
MobileButton.__index = MobileButton

local MobileConfig = require("mobile.mobile_config")

function MobileButton.new(text, x, y, width, height)
    local self = setmetatable({}, MobileButton)
    
    local buttonConfig = MobileConfig.getButtonConfig()
    
    self.text = text or "Button"
    self.x = x or 0
    self.y = y or 0
    self.width = width or buttonConfig.minWidth
    self.height = height or buttonConfig.minHeight
    
    -- Ensure minimum touch target size
    self.width = math.max(self.width, buttonConfig.minWidth)
    self.height = math.max(self.height, buttonConfig.minHeight)
    
    -- Visual state
    self.pressed = false
    self.hovered = false
    self.enabled = true
    self.visible = true
    
    -- Touch handling
    self.touchId = nil
    self.pressTime = 0
    
    -- Style
    self.backgroundColor = {0.3, 0.7, 0.3, 1}
    self.backgroundColorPressed = {0.2, 0.6, 0.2, 1}
    self.backgroundColorDisabled = {0.5, 0.5, 0.5, 1}
    self.textColor = {1, 1, 1, 1}
    self.textColorDisabled = {0.7, 0.7, 0.7, 1}
    self.borderColor = {1, 1, 1, 0.5}
    self.cornerRadius = buttonConfig.cornerRadius
    self.fontSize = buttonConfig.fontSize
    
    -- Callbacks
    self.onTap = nil
    self.onLongPress = nil
    self.onPress = nil
    self.onRelease = nil
    
    return self
end

function MobileButton:update(dt)
    if not self.visible or not self.enabled then
        return
    end
    
    -- Update press animation
    if self.pressed then
        self.pressTime = self.pressTime + dt
    else
        self.pressTime = 0
    end
end

function MobileButton:draw()
    if not self.visible then
        return
    end
    
    -- Choose colors based on state
    local bgColor = self.backgroundColor
    local textColor = self.textColor
    
    if not self.enabled then
        bgColor = self.backgroundColorDisabled
        textColor = self.textColorDisabled
    elseif self.pressed then
        bgColor = self.backgroundColorPressed
    end
    
    -- Draw background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, self.cornerRadius)
    
    -- Draw border
    if self.enabled then
        love.graphics.setColor(self.borderColor)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height, self.cornerRadius)
    end
    
    -- Draw text
    love.graphics.setColor(textColor)
    love.graphics.setFont(love.graphics.newFont(self.fontSize))
    
    -- Center text
    local textWidth = love.graphics.getFont():getWidth(self.text)
    local textHeight = love.graphics.getFont():getHeight()
    local textX = self.x + (self.width - textWidth) / 2
    local textY = self.y + (self.height - textHeight) / 2
    
    -- Add press effect
    if self.pressed then
        textY = textY + 2
    end
    
    love.graphics.print(self.text, textX, textY)
    
    -- Draw touch feedback (optional ripple effect)
    if self.pressed and self.pressTime < 0.3 then
        local alpha = 1 - (self.pressTime / 0.3)
        love.graphics.setColor(1, 1, 1, alpha * 0.3)
        local rippleRadius = (self.pressTime / 0.3) * math.min(self.width, self.height) / 2
        love.graphics.circle("fill", self.x + self.width/2, self.y + self.height/2, rippleRadius)
    end
end

-- Touch input handling
function MobileButton:touchpressed(id, x, y, dx, dy, pressure)
    if not self.visible or not self.enabled or self.touchId then
        return false
    end
    
    if self:contains(x, y) then
        self.touchId = id
        self.pressed = true
        self.pressTime = 0
        
        -- Haptic feedback
        if love.system.vibrate and MobileConfig.isMobile() then
            love.system.vibrate(0.01)  -- Light tap
        end
        
        if self.onPress then
            self.onPress()
        end
        
        return true
    end
    
    return false
end

function MobileButton:touchmoved(id, x, y, dx, dy, pressure)
    if id ~= self.touchId then
        return false
    end
    
    -- Update pressed state based on whether touch is still over button
    local wasPressed = self.pressed
    self.pressed = self:contains(x, y)
    
    -- Visual feedback when leaving/entering button area
    if wasPressed ~= self.pressed and love.system.vibrate and MobileConfig.isMobile() then
        love.system.vibrate(0.005)  -- Very light feedback
    end
    
    return true
end

function MobileButton:touchreleased(id, x, y, dx, dy, pressure)
    if id ~= self.touchId then
        return false
    end
    
    local wasPressed = self.pressed
    self.pressed = false
    self.touchId = nil
    
    if self.onRelease then
        self.onRelease()
    end
    
    -- Trigger tap if released over button
    if wasPressed and self:contains(x, y) then
        local thresholds = MobileConfig.getGestureThresholds()
        
        if self.pressTime >= thresholds.longPressTime then
            -- Long press
            if self.onLongPress then
                self.onLongPress()
            end
        else
            -- Regular tap
            if self.onTap then
                self.onTap()
            end
        end
        
        -- Stronger haptic for successful tap
        if love.system.vibrate and MobileConfig.isMobile() then
            love.system.vibrate(0.02)
        end
        
        return true
    end
    
    return false
end

-- Mouse input handling (for desktop compatibility)
function MobileButton:mousepressed(x, y, button)
    if button == 1 then
        return self:touchpressed("mouse", x, y, 0, 0, 1)
    end
    return false
end

function MobileButton:mousemoved(x, y, dx, dy)
    if self.touchId == "mouse" then
        return self:touchmoved("mouse", x, y, dx, dy, 1)
    end
    
    -- Update hover state for desktop
    self.hovered = self:contains(x, y)
    return false
end

function MobileButton:mousereleased(x, y, button)
    if button == 1 and self.touchId == "mouse" then
        return self:touchreleased("mouse", x, y, 0, 0, 1)
    end
    return false
end

-- Utility functions
function MobileButton:contains(x, y)
    return x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + self.height
end

function MobileButton:setPosition(x, y)
    self.x = x
    self.y = y
end

function MobileButton:setSize(width, height)
    local buttonConfig = MobileConfig.getButtonConfig()
    self.width = math.max(width, buttonConfig.minWidth)
    self.height = math.max(height, buttonConfig.minHeight)
end

function MobileButton:setText(text)
    self.text = text
end

function MobileButton:setEnabled(enabled)
    if not enabled and self.touchId then
        -- Cancel current touch
        self.pressed = false
        self.touchId = nil
    end
    self.enabled = enabled
end

function MobileButton:setVisible(visible)
    if not visible and self.touchId then
        -- Cancel current touch
        self.pressed = false
        self.touchId = nil
    end
    self.visible = visible
end

-- Style setters
function MobileButton:setBackgroundColor(r, g, b, a)
    self.backgroundColor = {r, g, b, a or 1}
end

function MobileButton:setTextColor(r, g, b, a)
    self.textColor = {r, g, b, a or 1}
end

return MobileButton