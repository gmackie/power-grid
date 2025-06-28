-- PlayerPanel UI component for Power Grid Digital
-- Displays player information and allows color selection

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"
local ColorSelector = require "src.ui.colorSelector"

local PlayerPanel = class('PlayerPanel')

-- Create a new player panel
function PlayerPanel.new(x, y, width, height, options)
    local panel = PlayerPanel()
    panel:initialize(x, y, width, height, options)
    return panel
end

-- Initialize the player panel
function PlayerPanel:initialize(x, y, width, height, options)
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
    self.titleLabel = Label.new("Player Information", x + self.options.padding, y + self.options.padding, 
        width - (2 * self.options.padding), 30, {
            fontSize = self.options.fontSize + 4,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Create player name label
    self.playerNameLabel = Label.new("Player: ", x + self.options.padding, y + 50, 
        width - (2 * self.options.padding), 20, {
            fontSize = self.options.fontSize,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Create color selector
    self.colorSelector = ColorSelector.new(x + self.options.padding, y + 80, 
        width - (2 * self.options.padding), 100, {
            backgroundColor = {0.1, 0.1, 0.2, 0.8},
            borderColor = {0.2, 0.2, 0.3, 1},
            padding = 5,
            cornerRadius = 5,
            gridSize = 5,
            colorSize = 15,
            spacing = 5,
            selectedBorderColor = {1, 1, 1, 1},
            hoverBorderColor = {0.8, 0.8, 0.8, 1}
        })
    
    -- Create status label
    self.statusLabel = Label.new("Status: ", x + self.options.padding, y + 190, 
        width - (2 * self.options.padding), 20, {
            fontSize = self.options.fontSize,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Create resources label
    self.resourcesLabel = Label.new("Resources: ", x + self.options.padding, y + 220, 
        width - (2 * self.options.padding), 20, {
            fontSize = self.options.fontSize,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Player panel state
    self.visible = true
    self.playerName = "Player 1"
    self.color = {1, 0, 0, 1} -- Red
    self.status = "Active"
    self.resources = {
        money = 0,
        coal = 0,
        oil = 0,
        garbage = 0,
        uranium = 0,
        hybrid = 0
    }
    
    return self
end

-- Set player panel position
function PlayerPanel:setPosition(x, y)
    self.x = x
    self.y = y
    self.panel:setPosition(x, y)
    self.titleLabel:setPosition(x + self.options.padding, y + self.options.padding)
    self.playerNameLabel:setPosition(x + self.options.padding, y + 50)
    self.colorSelector:setPosition(x + self.options.padding, y + 80)
    self.statusLabel:setPosition(x + self.options.padding, y + 190)
    self.resourcesLabel:setPosition(x + self.options.padding, y + 220)
end

-- Set player panel size
function PlayerPanel:setSize(width, height)
    self.width = width
    self.height = height
    self.panel:setSize(width, height)
    self.titleLabel:setSize(width - (2 * self.options.padding), 30)
    self.playerNameLabel:setSize(width - (2 * self.options.padding), 20)
    self.colorSelector:setSize(width - (2 * self.options.padding), 100)
    self.statusLabel:setSize(width - (2 * self.options.padding), 20)
    self.resourcesLabel:setSize(width - (2 * self.options.padding), 20)
end

-- Set player panel visibility
function PlayerPanel:setVisible(visible)
    self.visible = visible
    self.panel:setVisible(visible)
    self.titleLabel:setVisible(visible)
    self.playerNameLabel:setVisible(visible)
    self.colorSelector:setVisible(visible)
    self.statusLabel:setVisible(visible)
    self.resourcesLabel:setVisible(visible)
end

-- Get player panel visibility
function PlayerPanel:isVisible()
    return self.visible
end

-- Set player name
function PlayerPanel:setPlayerName(name)
    self.playerName = name
    self.playerNameLabel:setText("Player: " .. name)
end

-- Set player color
function PlayerPanel:setPlayerColor(color)
    self.color = color
    self.colorSelector:setSelectedColor(color)
end

-- Set player status
function PlayerPanel:setPlayerStatus(status)
    self.status = status
    self.statusLabel:setText("Status: " .. status)
end

-- Set player resources
function PlayerPanel:setPlayerResources(resources)
    self.resources = resources
    local text = "Resources: "
    if resources.money then
        text = text .. "Money: " .. resources.money .. " "
    end
    if resources.coal then
        text = text .. "Coal: " .. resources.coal .. " "
    end
    if resources.oil then
        text = text .. "Oil: " .. resources.oil .. " "
    end
    if resources.garbage then
        text = text .. "Garbage: " .. resources.garbage .. " "
    end
    if resources.uranium then
        text = text .. "Uranium: " .. resources.uranium .. " "
    end
    if resources.hybrid then
        text = text .. "Hybrid: " .. resources.hybrid
    end
    self.resourcesLabel:setText(text)
end

-- Draw the player panel
function PlayerPanel:draw()
    if not self.visible then return end
    
    -- Draw panel
    self.panel:draw()
    
    -- Draw labels
    self.titleLabel:draw()
    self.playerNameLabel:draw()
    self.colorSelector:draw()
    self.statusLabel:draw()
    self.resourcesLabel:draw()
end

-- Handle mouse press
function PlayerPanel:mousepressed(x, y, button)
    if not self.visible then return false end
    
    -- Check if click is inside panel
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        -- Check if click is on color selector
        if self.colorSelector:mousepressed(x, y, button) then
            return true
        end
    end
    
    return false
end

-- Handle mouse move
function PlayerPanel:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    
    -- Check if mouse is inside panel
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        -- Check if mouse is on color selector
        if self.colorSelector:mousemoved(x, y, dx, dy) then
            return true
        end
    end
    
    return false
end

-- Handle mouse release
function PlayerPanel:mousereleased(x, y, button)
    if not self.visible then return false end
    
    -- Check if mouse is inside panel
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        -- Check if mouse is on color selector
        if self.colorSelector:mousereleased(x, y, button) then
            return true
        end
    end
    
    return false
end

-- Handle key press
function PlayerPanel:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    return false
end

-- Handle text input
function PlayerPanel:textinput(text)
    if not self.visible then return false end
    return false
end

-- Handle window resize
function PlayerPanel:resize(width, height)
    -- Update player panel size if it's the main panel
    if self.x == 0 and self.y == 0 then
        self:setSize(width, height)
    end
end

return PlayerPanel 