-- Label UI component for Power Grid Digital
-- A label that displays text

local class = require "lib.middleclass"

local Label = class('Label')

-- Initialize the label
function Label:initialize(text, x, y, width, height, options)
    -- Set default options
    self.options = options or {}
    self.options.backgroundColor = self.options.backgroundColor or {0, 0, 0, 0}
    self.options.borderColor = self.options.borderColor or {0, 0, 0, 0}
    self.options.textColor = self.options.textColor or {1, 1, 1, 1}
    self.options.padding = self.options.padding or 5
    self.options.cornerRadius = self.options.cornerRadius or 0
    self.options.alignment = self.options.alignment or "left"
    self.options.verticalAlignment = self.options.verticalAlignment or "top"
    self.options.fadeInDuration = self.options.fadeInDuration or 0.2
    self.options.fadeOutDuration = self.options.fadeOutDuration or 0.2
    
    -- Label state
    self.visible = false
    self.alpha = 0
    self.fadeInTimer = 0
    self.fadeOutTimer = 0
    self.x = x or 0
    self.y = y or 0
    self.width = width or 0
    self.height = height or 0
    self.text = text or ""
    
    return self
end

-- Set label position
function Label:setPosition(x, y)
    self.x = x
    self.y = y
end

-- Set label size
function Label:setSize(width, height)
    self.width = width
    self.height = height
end

-- Set label visibility
function Label:setVisible(visible)
    if visible ~= self.visible then
        self.visible = visible
        if visible then
            self.fadeInTimer = self.options.fadeInDuration
            self.fadeOutTimer = 0
        else
            self.fadeInTimer = 0
            self.fadeOutTimer = self.options.fadeOutDuration
        end
    end
end

-- Get label visibility
function Label:isVisible()
    return self.visible
end

-- Set text
function Label:setText(text)
    self.text = text
end

-- Get text
function Label:getText()
    return self.text
end

-- Set background color
function Label:setBackgroundColor(color)
    self.options.backgroundColor = color
end

-- Set border color
function Label:setBorderColor(color)
    self.options.borderColor = color
end

-- Set text color
function Label:setTextColor(color)
    self.options.textColor = color
end

-- Set padding
function Label:setPadding(padding)
    self.options.padding = padding
end

-- Set corner radius
function Label:setCornerRadius(radius)
    self.options.cornerRadius = radius
end

-- Set alignment
function Label:setAlignment(alignment)
    self.options.alignment = alignment
end

-- Set vertical alignment
function Label:setVerticalAlignment(alignment)
    self.options.verticalAlignment = alignment
end

-- Set fade in duration
function Label:setFadeInDuration(duration)
    self.options.fadeInDuration = duration
end

-- Set fade out duration
function Label:setFadeOutDuration(duration)
    self.options.fadeOutDuration = duration
end

-- Update label
function Label:update(dt)
    if not self.visible then
        if self.fadeOutTimer > 0 then
            self.fadeOutTimer = math.max(0, self.fadeOutTimer - dt)
            self.alpha = self.fadeOutTimer / self.options.fadeOutDuration
        end
        return
    end
    
    if self.fadeInTimer > 0 then
        self.fadeInTimer = math.max(0, self.fadeInTimer - dt)
        self.alpha = 1 - (self.fadeInTimer / self.options.fadeInDuration)
    end
end

-- Draw the label
function Label:draw()
    if not self.visible and self.alpha == 0 then return end
    
    -- Set alpha
    local oldColor = {love.graphics.getColor()}
    love.graphics.setColor(oldColor[1], oldColor[2], oldColor[3], oldColor[4] * self.alpha)
    
    -- Draw background
    if self.options.backgroundColor[4] > 0 then
        love.graphics.setColor(self.options.backgroundColor[1], self.options.backgroundColor[2],
            self.options.backgroundColor[3], self.options.backgroundColor[4] * self.alpha)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height,
            self.options.cornerRadius)
    end
    
    -- Draw border
    if self.options.borderColor[4] > 0 then
        love.graphics.setColor(self.options.borderColor[1], self.options.borderColor[2],
            self.options.borderColor[3], self.options.borderColor[4] * self.alpha)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height,
            self.options.cornerRadius)
    end
    
    -- Draw text
    if self.text ~= "" then
        love.graphics.setColor(self.options.textColor[1], self.options.textColor[2],
            self.options.textColor[3], self.options.textColor[4] * self.alpha)
        
        -- Calculate text position based on alignment
        local textX = self.x + self.options.padding
        local textY = self.y + self.options.padding
        local textWidth = self.width - (2 * self.options.padding)
        local textHeight = self.height - (2 * self.options.padding)
        
        -- Calculate vertical position
        if self.options.verticalAlignment == "center" then
            textY = self.y + (self.height - love.graphics.getFont():getHeight()) / 2
        elseif self.options.verticalAlignment == "bottom" then
            textY = self.y + self.height - love.graphics.getFont():getHeight() - self.options.padding
        end
        
        -- Draw text with alignment
        love.graphics.printf(self.text, textX, textY, textWidth, self.options.alignment)
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function Label:mousepressed(x, y, button)
    if not self.visible then return false end
    return false
end

-- Handle mouse move
function Label:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    return false
end

-- Handle mouse release
function Label:mousereleased(x, y, button)
    if not self.visible then return false end
    return false
end

-- Handle key press
function Label:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    return false
end

-- Handle text input
function Label:textinput(text)
    if not self.visible then return false end
    return false
end

return Label 