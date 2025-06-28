-- ErrorPanel UI component for Power Grid Digital
-- Displays error messages and allows dismissing them

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"
local Button = require "src.ui.button"

local ErrorPanel = class('ErrorPanel')

-- Create a new error panel
function ErrorPanel.new(x, y, width, height, options)
    local panel = ErrorPanel()
    panel:initialize(x, y, width, height, options)
    return panel
end

-- Initialize the error panel
function ErrorPanel:initialize(x, y, width, height, options)
    -- Set default options
    self.options = options or {}
    self.options.backgroundColor = self.options.backgroundColor or {0.3, 0.1, 0.1, 0.9}
    self.options.borderColor = self.options.borderColor or {0.4, 0.2, 0.2, 1}
    self.options.textColor = self.options.textColor or {1, 1, 1, 1}
    self.options.fontSize = self.options.fontSize or 14
    self.options.padding = self.options.padding or 10
    self.options.cornerRadius = self.options.cornerRadius or 5
    
    -- Set position and size
    self.x = x or 0
    self.y = y or 0
    self.width = width or 300
    self.height = height or 150
    
    -- Create panel
    self.panel = Panel.new(x, y, width, height, {
        backgroundColor = self.options.backgroundColor,
        borderColor = self.options.borderColor,
        cornerRadius = self.options.cornerRadius
    })
    
    -- Create title label
    self.titleLabel = Label.new("Error", x + self.options.padding, y + self.options.padding, 
        width - (2 * self.options.padding), 30, {
            fontSize = self.options.fontSize + 4,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Create message label
    self.messageLabel = Label.new("", x + self.options.padding, y + 50, 
        width - (2 * self.options.padding), 60, {
            fontSize = self.options.fontSize,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Create dismiss button
    self.dismissButton = Button.new("Dismiss", x + width - 100, y + height - 40, 80, 30, {
        backgroundColor = {0.4, 0.2, 0.2, 1},
        borderColor = {0.5, 0.3, 0.3, 1},
        textColor = self.options.textColor,
        fontSize = self.options.fontSize,
        padding = 5,
        cornerRadius = 5,
        hoverColor = {0.5, 0.3, 0.3, 1},
        pressColor = {0.6, 0.4, 0.4, 1}
    })
    
    -- Error panel state
    self.visible = false
    self.message = ""
    self.onDismiss = nil
    
    return self
end

-- Set error panel position
function ErrorPanel:setPosition(x, y)
    self.x = x
    self.y = y
    self.panel:setPosition(x, y)
    self.titleLabel:setPosition(x + self.options.padding, y + self.options.padding)
    self.messageLabel:setPosition(x + self.options.padding, y + 50)
    self.dismissButton:setPosition(x + self.width - 100, y + self.height - 40)
end

-- Set error panel size
function ErrorPanel:setSize(width, height)
    self.width = width
    self.height = height
    self.panel:setSize(width, height)
    self.titleLabel:setSize(width - (2 * self.options.padding), 30)
    self.messageLabel:setSize(width - (2 * self.options.padding), 60)
    self.dismissButton:setPosition(x + width - 100, y + height - 40)
end

-- Set error panel visibility
function ErrorPanel:setVisible(visible)
    self.visible = visible
    self.panel:setVisible(visible)
    self.titleLabel:setVisible(visible)
    self.messageLabel:setVisible(visible)
    self.dismissButton:setVisible(visible)
end

-- Get error panel visibility
function ErrorPanel:isVisible()
    return self.visible
end

-- Set error message
function ErrorPanel:setMessage(message)
    self.message = message
    self.messageLabel:setText(message)
end

-- Set dismiss handler
function ErrorPanel:setOnDismiss(handler)
    self.onDismiss = handler
    self.dismissButton:setOnClick(function()
        self:setVisible(false)
        if self.onDismiss then
            self.onDismiss()
        end
    end)
end

-- Show error message
function ErrorPanel:show(message)
    self:setMessage(message)
    self:setVisible(true)
end

-- Draw the error panel
function ErrorPanel:draw()
    if not self.visible then return end
    
    -- Draw panel
    self.panel:draw()
    
    -- Draw labels
    self.titleLabel:draw()
    self.messageLabel:draw()
    
    -- Draw button
    self.dismissButton:draw()
end

-- Handle mouse press
function ErrorPanel:mousepressed(x, y, button)
    if not self.visible then return false end
    
    -- Check if click is inside panel
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        -- Check if click is on dismiss button
        if self.dismissButton:mousepressed(x, y, button) then
            return true
        end
    end
    
    return false
end

-- Handle mouse move
function ErrorPanel:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    
    -- Check if mouse is inside panel
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        -- Check if mouse is on dismiss button
        if self.dismissButton:mousemoved(x, y, dx, dy) then
            return true
        end
    end
    
    return false
end

-- Handle mouse release
function ErrorPanel:mousereleased(x, y, button)
    if not self.visible then return false end
    
    -- Check if mouse is inside panel
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        -- Check if mouse is on dismiss button
        if self.dismissButton:mousereleased(x, y, button) then
            return true
        end
    end
    
    return false
end

-- Handle key press
function ErrorPanel:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    
    -- Dismiss on Escape key
    if key == "escape" then
        self:setVisible(false)
        if self.onDismiss then
            self.onDismiss()
        end
        return true
    end
    
    return false
end

-- Handle text input
function ErrorPanel:textinput(text)
    if not self.visible then return false end
    return false
end

-- Handle window resize
function ErrorPanel:resize(width, height)
    -- Update error panel size if it's the main panel
    if self.x == 0 and self.y == 0 then
        self:setSize(width, height)
    end
end

return ErrorPanel 