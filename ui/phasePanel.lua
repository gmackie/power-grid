-- PhasePanel UI component for Power Grid Digital
-- Displays game phase and step information

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"

local PhasePanel = class('PhasePanel')

-- Create a new phase panel
function PhasePanel.new(x, y, width, height, options)
    local panel = PhasePanel()
    panel:initialize(x, y, width, height, options)
    return panel
end

-- Initialize the phase panel
function PhasePanel:initialize(x, y, width, height, options)
    -- Set default options
    self.options = options or {}
    self.options.backgroundColor = self.options.backgroundColor or {0.2, 0.2, 0.3, 0.8}
    self.options.borderColor = self.options.borderColor or {0.3, 0.3, 0.4, 1}
    self.options.textColor = self.options.textColor or {1, 1, 1, 1}
    self.options.fontSize = self.options.fontSize or 14
    self.options.padding = self.options.padding or 10
    self.options.cornerRadius = self.options.cornerRadius or 5
    
    -- Set position and size
    self.x = x or 0
    self.y = y or 0
    self.width = width or 200
    self.height = height or 300
    
    -- Create panel
    self.panel = Panel.new(x, y, width, height, {
        backgroundColor = self.options.backgroundColor,
        borderColor = self.options.borderColor,
        cornerRadius = self.options.cornerRadius
    })
    
    -- Create title label
    self.titleLabel = Label.new("Game Phase", x + self.options.padding, y + self.options.padding, 
        width - (2 * self.options.padding), 30, {
            fontSize = self.options.fontSize + 4,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Create phase label
    self.phaseLabel = Label.new("Phase: ", x + self.options.padding, y + 50, 
        width - (2 * self.options.padding), 20, {
            fontSize = self.options.fontSize,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Create step label
    self.stepLabel = Label.new("Step: ", x + self.options.padding, y + 80, 
        width - (2 * self.options.padding), 20, {
            fontSize = self.options.fontSize,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Create current player label
    self.currentPlayerLabel = Label.new("Current Player: ", x + self.options.padding, y + 110, 
        width - (2 * self.options.padding), 20, {
            fontSize = self.options.fontSize,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Phase panel state
    self.visible = true
    self.phase = "Phase 1"
    self.step = "Step 1"
    self.currentPlayer = "Player 1"
    
    return self
end

-- Set phase panel position
function PhasePanel:setPosition(x, y)
    self.x = x
    self.y = y
    self.panel:setPosition(x, y)
    self.titleLabel:setPosition(x + self.options.padding, y + self.options.padding)
    self.phaseLabel:setPosition(x + self.options.padding, y + 50)
    self.stepLabel:setPosition(x + self.options.padding, y + 80)
    self.currentPlayerLabel:setPosition(x + self.options.padding, y + 110)
end

-- Set phase panel size
function PhasePanel:setSize(width, height)
    self.width = width
    self.height = height
    self.panel:setSize(width, height)
    self.titleLabel:setSize(width - (2 * self.options.padding), 30)
    self.phaseLabel:setSize(width - (2 * self.options.padding), 20)
    self.stepLabel:setSize(width - (2 * self.options.padding), 20)
    self.currentPlayerLabel:setSize(width - (2 * self.options.padding), 20)
end

-- Set phase panel visibility
function PhasePanel:setVisible(visible)
    self.visible = visible
    self.panel:setVisible(visible)
    self.titleLabel:setVisible(visible)
    self.phaseLabel:setVisible(visible)
    self.stepLabel:setVisible(visible)
    self.currentPlayerLabel:setVisible(visible)
end

-- Get phase panel visibility
function PhasePanel:isVisible()
    return self.visible
end

-- Set phase
function PhasePanel:setPhase(phase)
    self.phase = phase
    self.phaseLabel:setText("Phase: " .. phase)
end

-- Set step
function PhasePanel:setStep(step)
    self.step = step
    self.stepLabel:setText("Step: " .. step)
end

-- Set current player
function PhasePanel:setCurrentPlayer(player)
    self.currentPlayer = player
    self.currentPlayerLabel:setText("Current Player: " .. player)
end

-- Draw the phase panel
function PhasePanel:draw()
    if not self.visible then return end
    
    -- Draw panel
    self.panel:draw()
    
    -- Draw labels
    self.titleLabel:draw()
    self.phaseLabel:draw()
    self.stepLabel:draw()
    self.currentPlayerLabel:draw()
end

-- Handle mouse press
function PhasePanel:mousepressed(x, y, button)
    if not self.visible then return false end
    return false
end

-- Handle mouse move
function PhasePanel:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    return false
end

-- Handle mouse release
function PhasePanel:mousereleased(x, y, button)
    if not self.visible then return false end
    return false
end

-- Handle key press
function PhasePanel:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    return false
end

-- Handle text input
function PhasePanel:textinput(text)
    if not self.visible then return false end
    return false
end

-- Handle window resize
function PhasePanel:resize(width, height)
    -- Update phase panel size if it's the main panel
    if self.x == 0 and self.y == 0 then
        self:setSize(width, height)
    end
end

return PhasePanel 