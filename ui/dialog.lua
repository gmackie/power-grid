-- Dialog UI component for Power Grid Digital
-- A modal dialog with title, message, and optional buttons

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"
local Button = require "src.ui.button"

local Dialog = class('Dialog')

-- Create a new dialog
function Dialog.new(x, y, width, height, title, message, options)
    local dialog = Dialog()
    dialog:initialize(x, y, width, height, title, message, options)
    return dialog
end

-- Initialize the dialog
function Dialog:initialize(x, y, width, height, title, message, options)
    -- Set default options
    self.options = options or {}
    self.options.backgroundColor = self.options.backgroundColor or {0.2, 0.2, 0.2, 0.8}
    self.options.borderColor = self.options.borderColor or {0.3, 0.3, 0.3, 1}
    self.options.titleColor = self.options.titleColor or {1, 1, 1, 1}
    self.options.messageColor = self.options.messageColor or {1, 1, 1, 1}
    self.options.titleHeight = self.options.titleHeight or 30
    self.options.cornerRadius = self.options.cornerRadius or 5
    self.options.showCloseButton = self.options.showCloseButton or true
    self.options.closeButtonColor = self.options.closeButtonColor or {1, 1, 1, 1}
    self.options.closeButtonHoverColor = self.options.closeButtonHoverColor or {1, 0, 0, 1}
    self.options.buttonHeight = self.options.buttonHeight or 30
    self.options.buttonSpacing = self.options.buttonSpacing or 10
    self.options.buttonBackgroundColor = self.options.buttonBackgroundColor or {0.3, 0.3, 0.3, 1}
    self.options.buttonBorderColor = self.options.buttonBorderColor or {0.4, 0.4, 0.4, 1}
    self.options.buttonTextColor = self.options.buttonTextColor or {1, 1, 1, 1}
    self.options.buttonHoverColor = self.options.buttonHoverColor or {0.4, 0.4, 0.4, 1}
    self.options.buttonPressColor = self.options.buttonPressColor or {0.2, 0.2, 0.2, 1}
    self.options.fadeInDuration = self.options.fadeInDuration or 0.2
    self.options.fadeOutDuration = self.options.fadeOutDuration or 0.2
    
    -- Set position and size
    self.x = x or 0
    self.y = y or 0
    self.width = width or 400
    self.height = height or 300
    
    -- Dialog state
    self.visible = true
    self.alpha = 1
    self.fadeInTimer = 0
    self.fadeOutTimer = 0
    self.title = title or ""
    self.message = message or ""
    self.dragging = false
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    self.closeButtonHovered = false
    self.buttons = {}
    self.buttonHovered = nil
    self.buttonPressed = nil
    
    -- Child components
    self.children = {}
    
    return self
end

-- Add child component
function Dialog:addChild(child)
    table.insert(self.children, child)
end

-- Remove child component
function Dialog:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            break
        end
    end
end

-- Clear all child components
function Dialog:clearChildren()
    self.children = {}
end

-- Get child components
function Dialog:getChildren()
    return self.children
end

-- Set dialog position
function Dialog:setPosition(x, y)
    self.x = x
    self.y = y
end

-- Set dialog size
function Dialog:setSize(width, height)
    self.width = width
    self.height = height
end

-- Set dialog visibility
function Dialog:setVisible(visible)
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

-- Get dialog visibility
function Dialog:isVisible()
    return self.visible
end

-- Set dialog title
function Dialog:setTitle(title)
    self.title = title
end

-- Get dialog title
function Dialog:getTitle()
    return self.title
end

-- Set dialog message
function Dialog:setMessage(message)
    self.message = message
end

-- Get dialog message
function Dialog:getMessage()
    return self.message
end

-- Add button
function Dialog:addButton(text, onClick)
    table.insert(self.buttons, {
        text = text,
        onClick = onClick,
        hovered = false,
        pressed = false
    })
end

-- Clear buttons
function Dialog:clearButtons()
    self.buttons = {}
end

-- Set background color
function Dialog:setBackgroundColor(color)
    self.options.backgroundColor = color
end

-- Set border color
function Dialog:setBorderColor(color)
    self.options.borderColor = color
end

-- Set title color
function Dialog:setTitleColor(color)
    self.options.titleColor = color
end

-- Set message color
function Dialog:setMessageColor(color)
    self.options.messageColor = color
end

-- Set title height
function Dialog:setTitleHeight(height)
    self.options.titleHeight = height
end

-- Set corner radius
function Dialog:setCornerRadius(radius)
    self.options.cornerRadius = radius
end

-- Set close button visibility
function Dialog:setShowCloseButton(show)
    self.options.showCloseButton = show
end

-- Set close button color
function Dialog:setCloseButtonColor(color)
    self.options.closeButtonColor = color
end

-- Set close button hover color
function Dialog:setCloseButtonHoverColor(color)
    self.options.closeButtonHoverColor = color
end

-- Set button height
function Dialog:setButtonHeight(height)
    self.options.buttonHeight = height
end

-- Set button spacing
function Dialog:setButtonSpacing(spacing)
    self.options.buttonSpacing = spacing
end

-- Set button background color
function Dialog:setButtonBackgroundColor(color)
    self.options.buttonBackgroundColor = color
end

-- Set button border color
function Dialog:setButtonBorderColor(color)
    self.options.buttonBorderColor = color
end

-- Set button text color
function Dialog:setButtonTextColor(color)
    self.options.buttonTextColor = color
end

-- Set button hover color
function Dialog:setButtonHoverColor(color)
    self.options.buttonHoverColor = color
end

-- Set button press color
function Dialog:setButtonPressColor(color)
    self.options.buttonPressColor = color
end

-- Set fade in duration
function Dialog:setFadeInDuration(duration)
    self.options.fadeInDuration = duration
end

-- Set fade out duration
function Dialog:setFadeOutDuration(duration)
    self.options.fadeOutDuration = duration
end

-- Update dialog
function Dialog:update(dt)
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
    
    -- Update children
    for _, child in ipairs(self.children) do
        if child.update then
            child:update(dt)
        end
    end
end

-- Draw the dialog
function Dialog:draw()
    if not self.visible and self.alpha == 0 then return end
    
    -- Set alpha
    local oldColor = {love.graphics.getColor()}
    love.graphics.setColor(oldColor[1], oldColor[2], oldColor[3], oldColor[4] * self.alpha)
    
    -- Draw background
    love.graphics.setColor(self.options.backgroundColor[1], self.options.backgroundColor[2],
        self.options.backgroundColor[3], self.options.backgroundColor[4] * self.alpha)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height,
        self.options.cornerRadius)
    
    -- Draw border
    love.graphics.setColor(self.options.borderColor[1], self.options.borderColor[2],
        self.options.borderColor[3], self.options.borderColor[4] * self.alpha)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height,
        self.options.cornerRadius)
    
    -- Draw title bar
    love.graphics.setColor(self.options.titleColor[1], self.options.titleColor[2],
        self.options.titleColor[3], self.options.titleColor[4] * self.alpha)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.options.titleHeight)
    
    -- Draw title text
    love.graphics.setColor(self.options.titleColor[1], self.options.titleColor[2],
        self.options.titleColor[3], self.options.titleColor[4] * self.alpha)
    love.graphics.printf(self.title, self.x + 10, self.y + (self.options.titleHeight - 20) / 2,
        self.width - 20, "left")
    
    -- Draw close button if enabled
    if self.options.showCloseButton then
        local closeButtonColor = self.closeButtonHovered and self.options.closeButtonHoverColor or self.options.closeButtonColor
        love.graphics.setColor(closeButtonColor[1], closeButtonColor[2],
            closeButtonColor[3], closeButtonColor[4] * self.alpha)
        love.graphics.rectangle("line", self.x + self.width - 30, self.y + 5, 20, 20)
        love.graphics.line(self.x + self.width - 25, self.y + 10,
            self.x + self.width - 15, self.y + 20)
        love.graphics.line(self.x + self.width - 15, self.y + 10,
            self.x + self.width - 25, self.y + 20)
    end
    
    -- Draw message
    love.graphics.setColor(self.options.messageColor[1], self.options.messageColor[2],
        self.options.messageColor[3], self.options.messageColor[4] * self.alpha)
    love.graphics.printf(self.message, self.x + 20, self.y + self.options.titleHeight + 20,
        self.width - 40, "left")
    
    -- Draw children
    for _, child in ipairs(self.children) do
        if child.draw then
            child:draw()
        end
    end
    
    -- Draw buttons
    local buttonY = self.y + self.height - self.options.buttonHeight - 20
    local totalButtonWidth = 0
    for _, button in ipairs(self.buttons) do
        totalButtonWidth = totalButtonWidth + love.graphics.getFont():getWidth(button.text) + 40
    end
    totalButtonWidth = totalButtonWidth + (self.options.buttonSpacing * (#self.buttons - 1))
    
    local buttonX = self.x + (self.width - totalButtonWidth) / 2
    for _, button in ipairs(self.buttons) do
        local buttonWidth = love.graphics.getFont():getWidth(button.text) + 40
        
        -- Draw button background
        local buttonColor = button.pressed and self.options.buttonPressColor or
            (button.hovered and self.options.buttonHoverColor or self.options.buttonBackgroundColor)
        love.graphics.setColor(buttonColor[1], buttonColor[2],
            buttonColor[3], buttonColor[4] * self.alpha)
        love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, self.options.buttonHeight,
            self.options.cornerRadius)
        
        -- Draw button border
        love.graphics.setColor(self.options.buttonBorderColor[1], self.options.buttonBorderColor[2],
            self.options.buttonBorderColor[3], self.options.buttonBorderColor[4] * self.alpha)
        love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, self.options.buttonHeight,
            self.options.cornerRadius)
        
        -- Draw button text
        love.graphics.setColor(self.options.buttonTextColor[1], self.options.buttonTextColor[2],
            self.options.buttonTextColor[3], self.options.buttonTextColor[4] * self.alpha)
        love.graphics.printf(button.text, buttonX, buttonY + (self.options.buttonHeight - 20) / 2,
            buttonWidth, "center")
        
        buttonX = buttonX + buttonWidth + self.options.buttonSpacing
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function Dialog:mousepressed(x, y, button)
    if not self.visible then return false end
    
    -- Check if click is inside dialog
    if x >= self.x and x <= self.x + self.width and
        y >= self.y and y <= self.y + self.height then
        -- Check if click is in title bar
        if y <= self.y + self.options.titleHeight then
            -- Check if click is on close button
            if self.options.showCloseButton and
                x >= self.x + self.width - 30 and x <= self.x + self.width - 10 and
                y >= self.y + 5 and y <= self.y + 25 then
                self:setVisible(false)
                return true
            end
            -- Start dragging
            self.dragging = true
            self.dragOffsetX = x - self.x
            self.dragOffsetY = y - self.y
            return true
        end
        
        -- Check if click is on a button
        local buttonY = self.y + self.height - self.options.buttonHeight - 20
        local totalButtonWidth = 0
        for _, button in ipairs(self.buttons) do
            totalButtonWidth = totalButtonWidth + love.graphics.getFont():getWidth(button.text) + 40
        end
        totalButtonWidth = totalButtonWidth + (self.options.buttonSpacing * (#self.buttons - 1))
        
        local buttonX = self.x + (self.width - totalButtonWidth) / 2
        for _, button in ipairs(self.buttons) do
            local buttonWidth = love.graphics.getFont():getWidth(button.text) + 40
            
            if x >= buttonX and x <= buttonX + buttonWidth and
                y >= buttonY and y <= buttonY + self.options.buttonHeight then
                button.pressed = true
                self.buttonPressed = button
                return true
            end
            
            buttonX = buttonX + buttonWidth + self.options.buttonSpacing
        end
        
        return true
    end
    
    return false
end

-- Handle mouse move
function Dialog:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    
    -- Handle dragging
    if self.dragging then
        self.x = x - self.dragOffsetX
        self.y = y - self.dragOffsetY
        return true
    end
    
    -- Check if mouse is inside dialog
    if x >= self.x and x <= self.x + self.width and
        y >= self.y and y <= self.y + self.height then
        -- Check if mouse is over close button
        if self.options.showCloseButton and
            x >= self.x + self.width - 30 and x <= self.x + self.width - 10 and
            y >= self.y + 5 and y <= self.y + 25 then
            self.closeButtonHovered = true
        else
            self.closeButtonHovered = false
        end
        
        -- Check if mouse is over a button
        local buttonY = self.y + self.height - self.options.buttonHeight - 20
        local totalButtonWidth = 0
        for _, button in ipairs(self.buttons) do
            totalButtonWidth = totalButtonWidth + love.graphics.getFont():getWidth(button.text) + 40
        end
        totalButtonWidth = totalButtonWidth + (self.options.buttonSpacing * (#self.buttons - 1))
        
        local buttonX = self.x + (self.width - totalButtonWidth) / 2
        self.buttonHovered = nil
        for _, button in ipairs(self.buttons) do
            local buttonWidth = love.graphics.getFont():getWidth(button.text) + 40
            
            if x >= buttonX and x <= buttonX + buttonWidth and
                y >= buttonY and y <= buttonY + self.options.buttonHeight then
                button.hovered = true
                self.buttonHovered = button
            else
                button.hovered = false
            end
            
            buttonX = buttonX + buttonWidth + self.options.buttonSpacing
        end
        
        return true
    end
    
    self.closeButtonHovered = false
    self.buttonHovered = nil
    for _, button in ipairs(self.buttons) do
        button.hovered = false
    end
    return false
end

-- Handle mouse release
function Dialog:mousereleased(x, y, button)
    if not self.visible then return false end
    
    -- Stop dragging
    if self.dragging then
        self.dragging = false
        return true
    end
    
    -- Check if click is inside dialog
    if x >= self.x and x <= self.x + self.width and
        y >= self.y and y <= self.y + self.height then
        -- Check if click is on a button
        if self.buttonPressed then
            self.buttonPressed.pressed = false
            if self.buttonPressed.hovered and self.buttonPressed.onClick then
                self.buttonPressed.onClick()
            end
            self.buttonPressed = nil
        end
        return true
    end
    
    return false
end

-- Handle key press
function Dialog:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    
    -- Handle escape key
    if key == "escape" then
        self:setVisible(false)
        return true
    end
    
    return false
end

-- Handle text input
function Dialog:textinput(text)
    if not self.visible then return false end
    return false
end

-- Handle window resize
function Dialog:resize(width, height)
    -- Update dialog position if it's the main dialog
    if self.x == 0 and self.y == 0 then
        self:setPosition(width / 2 - self.width / 2, height / 2 - self.height / 2)
    end
end

return Dialog 