-- Styled Button Component with assets and theme support
-- Enhanced version of mobile_button with visual polish

local StyledButton = {}
StyledButton.__index = StyledButton

local Theme = require("ui.theme")
local AssetLoader = require("assets.asset_loader")
local MobileConfig = require("mobile.mobile_config")

function StyledButton.new(text, x, y, width, height, options)
    local self = setmetatable({}, StyledButton)
    
    options = options or {}
    local buttonConfig = MobileConfig.getButtonConfig()
    
    -- Basic properties
    self.text = text or "Button"
    self.x = x or 0
    self.y = y or 0
    self.width = width or buttonConfig.minWidth
    self.height = height or buttonConfig.minHeight
    
    -- Ensure minimum touch target size
    self.width = math.max(self.width, buttonConfig.minWidth)
    self.height = math.max(self.height, buttonConfig.minHeight)
    
    -- Button type and size
    self.type = options.type or "primary"  -- primary, secondary
    self.size = options.size or (self.width > 250 and "large" or (self.width > 180 and "medium" or "small"))
    
    -- Visual state
    self.state = "normal"  -- normal, hover, pressed, disabled
    self.enabled = true
    self.visible = true
    
    -- Touch/mouse handling
    self.hovered = false
    self.pressed = false
    self.touchId = nil
    self.pressTime = 0
    
    -- Animation
    self.scale = 1.0
    self.targetScale = 1.0
    self.scaleSpeed = 8.0
    self.alpha = 1.0
    self.targetAlpha = 1.0
    self.alphaSpeed = 5.0
    
    -- Load assets
    self.assets = {}
    self:loadAssets()
    
    -- Style override options
    self.customStyle = options.style or {}
    self.icon = options.icon  -- optional icon name
    self.iconPosition = options.iconPosition or "left"  -- left, right
    
    -- Font
    self.font = love.graphics.newFont(Theme.fonts[self.size == "large" and "large" or "medium"])
    
    -- Callbacks
    self.onTap = options.onTap
    self.onLongPress = options.onLongPress
    self.onPress = options.onPress
    self.onRelease = options.onRelease
    
    return self
end

function StyledButton:loadAssets()
    -- Try to load button assets
    for _, state in ipairs({"normal", "hover", "pressed", "disabled"}) do
        self.assets[state] = AssetLoader.getButton(self.size, self.type, state)
    end
    
    -- Load icon if specified
    if self.icon then
        self.iconAsset = AssetLoader.load("icon_" .. self.icon)
    end
end

function StyledButton:update(dt)
    if not self.visible then return end
    
    -- Update animations
    self.scale = self.scale + (self.targetScale - self.scale) * self.scaleSpeed * dt
    self.alpha = self.alpha + (self.targetAlpha - self.alpha) * self.alphaSpeed * dt
    
    -- Update state
    local oldState = self.state
    
    if not self.enabled then
        self.state = "disabled"
        self.targetScale = 1.0
        self.targetAlpha = 0.8
    elseif self.pressed then
        self.state = "pressed"
        self.targetScale = 0.95
        self.targetAlpha = 1.0
    elseif self.hovered then
        self.state = "hover"
        self.targetScale = 1.05
        self.targetAlpha = 1.0
    else
        self.state = "normal"
        self.targetScale = 1.0
        self.targetAlpha = 1.0
    end
    
    -- Handle long press
    if self.pressed then
        self.pressTime = self.pressTime + dt
        if self.pressTime > 0.5 and self.onLongPress then
            self.onLongPress()
            self.pressed = false  -- Release after long press
        end
    end
end

function StyledButton:draw()
    if not self.visible then return end
    
    love.graphics.push()
    
    -- Apply scale animation
    local centerX = self.x + self.width / 2
    local centerY = self.y + self.height / 2
    love.graphics.translate(centerX, centerY)
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-centerX, -centerY)
    
    -- Set alpha
    local r, g, b, a = love.graphics.getColor()
    
    -- Draw button background
    if self.assets[self.state] then
        -- Use asset
        love.graphics.setColor(1, 1, 1, self.alpha)
        love.graphics.draw(self.assets[self.state], self.x, self.y, 0,
                          self.width / self.assets[self.state]:getWidth(),
                          self.height / self.assets[self.state]:getHeight())
    else
        -- Fallback to theme drawing
        love.graphics.setColor(1, 1, 1, self.alpha)
        Theme.drawButton(self.x, self.y, self.width, self.height, self.state, self.type)
    end
    
    -- Draw icon if present
    local textX = self.x
    local textWidth = self.width
    
    if self.iconAsset then
        local iconSize = self.height * 0.5
        local iconY = self.y + (self.height - iconSize) / 2
        local iconX
        
        if self.iconPosition == "left" then
            iconX = self.x + Theme.layout.padding
            textX = iconX + iconSize + Theme.layout.spacing
            textWidth = self.width - iconSize - Theme.layout.padding * 2 - Theme.layout.spacing
        else
            iconX = self.x + self.width - Theme.layout.padding - iconSize
            textWidth = self.width - iconSize - Theme.layout.padding * 2 - Theme.layout.spacing
        end
        
        love.graphics.setColor(1, 1, 1, self.alpha)
        love.graphics.draw(self.iconAsset, iconX, iconY, 0,
                          iconSize / self.iconAsset:getWidth(),
                          iconSize / self.iconAsset:getHeight())
    end
    
    -- Draw text
    if self.text and self.text ~= "" then
        love.graphics.setFont(self.font)
        
        -- Set text color based on state
        local buttonStyle = Theme.button[self.type][self.state]
        love.graphics.setColor(buttonStyle.text[1], buttonStyle.text[2], 
                              buttonStyle.text[3], buttonStyle.text[4] * self.alpha)
        
        -- Center text vertically and horizontally
        local textHeight = self.font:getHeight()
        local textY = self.y + (self.height - textHeight) / 2
        
        love.graphics.printf(self.text, textX, textY, textWidth, "center")
    end
    
    love.graphics.pop()
end

function StyledButton:mousepressed(x, y, button)
    if not self.visible or not self.enabled then return false end
    if button ~= 1 then return false end
    
    if self:contains(x, y) then
        self.pressed = true
        self.pressTime = 0
        if self.onPress then
            self.onPress()
        end
        return true
    end
    return false
end

function StyledButton:mousereleased(x, y, button)
    if not self.visible or not self.enabled then return false end
    if button ~= 1 then return false end
    
    if self.pressed then
        self.pressed = false
        if self:contains(x, y) then
            if self.pressTime < 0.5 and self.onTap then
                self.onTap()
            end
            if self.onRelease then
                self.onRelease()
            end
        end
        return true
    end
    return false
end

function StyledButton:mousemoved(x, y)
    if not self.visible or not self.enabled then return end
    self.hovered = self:contains(x, y)
end

function StyledButton:touchpressed(id, x, y)
    if not self.visible or not self.enabled then return false end
    
    if self.touchId == nil and self:contains(x, y) then
        self.touchId = id
        self.pressed = true
        self.pressTime = 0
        if self.onPress then
            self.onPress()
        end
        return true
    end
    return false
end

function StyledButton:touchreleased(id, x, y)
    if not self.visible or not self.enabled then return false end
    
    if self.touchId == id then
        self.touchId = nil
        self.pressed = false
        
        if self:contains(x, y) then
            if self.pressTime < 0.5 and self.onTap then
                self.onTap()
            end
            if self.onRelease then
                self.onRelease()
            end
        end
        return true
    end
    return false
end

function StyledButton:touchmoved(id, x, y)
    if self.touchId == id then
        -- Optional: could handle drag gestures here
    end
end

function StyledButton:contains(x, y)
    return x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + self.height
end

function StyledButton:setEnabled(enabled)
    self.enabled = enabled
end

function StyledButton:setVisible(visible)
    self.visible = visible
end

function StyledButton:setText(text)
    self.text = text
end

return StyledButton