-- TransitionOverlay UI component for Power Grid Digital
-- Displays a smooth transition overlay between game states

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"

local TransitionOverlay = class('TransitionOverlay')

-- Create a new transition overlay
function TransitionOverlay.new(x, y, width, height, options)
    local overlay = TransitionOverlay()
    overlay:initialize(x, y, width, height, options)
    return overlay
end

-- Initialize the transition overlay
function TransitionOverlay:initialize(x, y, width, height, options)
    -- Set default options
    self.options = options or {}
    self.options.backgroundColor = self.options.backgroundColor or {0, 0, 0, 0}
    self.options.textColor = self.options.textColor or {1, 1, 1, 1}
    self.options.fontSize = self.options.fontSize or 24
    self.options.padding = self.options.padding or 20
    self.options.cornerRadius = self.options.cornerRadius or 0
    self.options.transitionDuration = self.options.transitionDuration or 0.5
    self.options.fadeInDuration = self.options.fadeInDuration or 0.3
    self.options.fadeOutDuration = self.options.fadeOutDuration or 0.3
    
    -- Set position and size
    self.x = x or 0
    self.y = y or 0
    self.width = width or 800
    self.height = height or 600
    
    -- Create panel
    self.panel = Panel.new(x, y, width, height, {
        backgroundColor = self.options.backgroundColor,
        borderColor = {0, 0, 0, 0},
        cornerRadius = self.options.cornerRadius
    })
    
    -- Create message label
    self.messageLabel = Label.new("", x + self.options.padding, y + (height/2) - 20, 
        width - (2 * self.options.padding), 40, {
            fontSize = self.options.fontSize,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0},
            alignment = "center",
            verticalAlignment = "center"
        })
    
    -- Transition overlay state
    self.visible = false
    self.message = ""
    self.alpha = 0
    self.transitionStart = 0
    self.transitionEnd = 0
    self.onTransitionComplete = nil
    
    return self
end

-- Set transition overlay position
function TransitionOverlay:setPosition(x, y)
    self.x = x
    self.y = y
    self.panel:setPosition(x, y)
    self.messageLabel:setPosition(x + self.options.padding, y + (self.height/2) - 20)
end

-- Set transition overlay size
function TransitionOverlay:setSize(width, height)
    self.width = width
    self.height = height
    self.panel:setSize(width, height)
    self.messageLabel:setSize(width - (2 * self.options.padding), 40)
    self.messageLabel:setPosition(self.x + self.options.padding, self.y + (height/2) - 20)
end

-- Set transition overlay visibility
function TransitionOverlay:setVisible(visible)
    self.visible = visible
    self.panel:setVisible(visible)
    self.messageLabel:setVisible(visible)
end

-- Get transition overlay visibility
function TransitionOverlay:isVisible()
    return self.visible
end

-- Set transition message
function TransitionOverlay:setMessage(message)
    self.message = message
    self.messageLabel:setText(message)
end

-- Set transition complete handler
function TransitionOverlay:setOnTransitionComplete(handler)
    self.onTransitionComplete = handler
end

-- Start transition
function TransitionOverlay:start(message)
    self:setMessage(message)
    self:setVisible(true)
    self.alpha = 0
    self.transitionStart = love.timer.getTime()
    self.transitionEnd = self.transitionStart + self.options.transitionDuration
end

-- Update the transition overlay
function TransitionOverlay:update(dt)
    if not self.visible then return end
    
    local currentTime = love.timer.getTime()
    
    -- Calculate transition progress
    local progress = (currentTime - self.transitionStart) / self.options.transitionDuration
    
    -- Update alpha based on progress
    if progress < self.options.fadeInDuration / self.options.transitionDuration then
        -- Fade in
        self.alpha = progress * (self.options.transitionDuration / self.options.fadeInDuration)
    elseif progress > 1 - (self.options.fadeOutDuration / self.options.transitionDuration) then
        -- Fade out
        self.alpha = (1 - progress) * (self.options.transitionDuration / self.options.fadeOutDuration)
    else
        -- Full opacity
        self.alpha = 1
    end
    
    -- Check if transition is complete
    if progress >= 1 then
        self:setVisible(false)
        if self.onTransitionComplete then
            self.onTransitionComplete()
        end
    end
end

-- Draw the transition overlay
function TransitionOverlay:draw()
    if not self.visible then return end
    
    -- Set alpha for fade
    local bgColor = {0, 0, 0, self.alpha}
    local textColor = {1, 1, 1, self.alpha}
    
    -- Update colors with alpha
    self.panel.options.backgroundColor = bgColor
    self.messageLabel.options.textColor = textColor
    
    -- Draw panel and label
    self.panel:draw()
    self.messageLabel:draw()
end

-- Handle mouse press
function TransitionOverlay:mousepressed(x, y, button)
    if not self.visible then return false end
    return false
end

-- Handle mouse move
function TransitionOverlay:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    return false
end

-- Handle mouse release
function TransitionOverlay:mousereleased(x, y, button)
    if not self.visible then return false end
    return false
end

-- Handle key press
function TransitionOverlay:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    return false
end

-- Handle text input
function TransitionOverlay:textinput(text)
    if not self.visible then return false end
    return false
end

-- Handle window resize
function TransitionOverlay:resize(width, height)
    -- Update transition overlay size if it's the main overlay
    if self.x == 0 and self.y == 0 then
        self:setSize(width, height)
    end
end

return TransitionOverlay 