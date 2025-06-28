-- MarketPanel UI component for Power Grid Digital
-- Displays market information and allows resource trading

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"
local Button = require "src.ui.button"

local MarketPanel = class('MarketPanel')

-- Create a new market panel
function MarketPanel.new(x, y, width, height, options)
    local panel = MarketPanel()
    panel:initialize(x, y, width, height, options)
    return panel
end

-- Initialize the market panel
function MarketPanel:initialize(x, y, width, height, options)
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
    self.titleLabel = Label.new("Market", x + self.options.padding, y + self.options.padding, 
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
    
    -- Create resource labels
    self.resourceLabels = {}
    local resources = {"Coal", "Oil", "Garbage", "Uranium", "Hybrid"}
    for i, resource in ipairs(resources) do
        self.resourceLabels[resource] = Label.new(resource .. ": ", x + self.options.padding, y + 110 + (i - 1) * 30, 
            width - (2 * self.options.padding), 20, {
                fontSize = self.options.fontSize,
                textColor = self.options.textColor,
                backgroundColor = {0, 0, 0, 0},
                borderColor = {0, 0, 0, 0}
            })
    end
    
    -- Market panel state
    self.visible = true
    self.phase = "Phase 1"
    self.step = "Step 1"
    self.resources = {
        Coal = {price = 0, available = 0},
        Oil = {price = 0, available = 0},
        Garbage = {price = 0, available = 0},
        Uranium = {price = 0, available = 0},
        Hybrid = {price = 0, available = 0}
    }
    
    return self
end

-- Set market panel position
function MarketPanel:setPosition(x, y)
    self.x = x
    self.y = y
    self.panel:setPosition(x, y)
    self.titleLabel:setPosition(x + self.options.padding, y + self.options.padding)
    self.phaseLabel:setPosition(x + self.options.padding, y + 50)
    self.stepLabel:setPosition(x + self.options.padding, y + 80)
    for resource, label in pairs(self.resourceLabels) do
        local index = 0
        for r in pairs(self.resourceLabels) do
            if r == resource then break end
            index = index + 1
        end
        label:setPosition(x + self.options.padding, y + 110 + index * 30)
    end
end

-- Set market panel size
function MarketPanel:setSize(width, height)
    self.width = width
    self.height = height
    self.panel:setSize(width, height)
    self.titleLabel:setSize(width - (2 * self.options.padding), 30)
    self.phaseLabel:setSize(width - (2 * self.options.padding), 20)
    self.stepLabel:setSize(width - (2 * self.options.padding), 20)
    for _, label in pairs(self.resourceLabels) do
        label:setSize(width - (2 * self.options.padding), 20)
    end
end

-- Set market panel visibility
function MarketPanel:setVisible(visible)
    self.visible = visible
    self.panel:setVisible(visible)
    self.titleLabel:setVisible(visible)
    self.phaseLabel:setVisible(visible)
    self.stepLabel:setVisible(visible)
    for _, label in pairs(self.resourceLabels) do
        label:setVisible(visible)
    end
end

-- Get market panel visibility
function MarketPanel:isVisible()
    return self.visible
end

-- Set phase
function MarketPanel:setPhase(phase)
    self.phase = phase
    self.phaseLabel:setText("Phase: " .. phase)
end

-- Set step
function MarketPanel:setStep(step)
    self.step = step
    self.stepLabel:setText("Step: " .. step)
end

-- Set resource info
function MarketPanel:setResourceInfo(resource, price, available)
    if self.resources[resource] then
        self.resources[resource].price = price
        self.resources[resource].available = available
        self.resourceLabels[resource]:setText(resource .. ": " .. price .. " (" .. available .. ")")
    end
end

-- Draw the market panel
function MarketPanel:draw()
    if not self.visible then return end
    
    -- Draw panel
    self.panel:draw()
    
    -- Draw labels
    self.titleLabel:draw()
    self.phaseLabel:draw()
    self.stepLabel:draw()
    for _, label in pairs(self.resourceLabels) do
        label:draw()
    end
end

-- Handle mouse press
function MarketPanel:mousepressed(x, y, button)
    if not self.visible then return false end
    return false
end

-- Handle mouse move
function MarketPanel:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    return false
end

-- Handle mouse release
function MarketPanel:mousereleased(x, y, button)
    if not self.visible then return false end
    return false
end

-- Handle key press
function MarketPanel:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    return false
end

-- Handle text input
function MarketPanel:textinput(text)
    if not self.visible then return false end
    return false
end

-- Handle window resize
function MarketPanel:resize(width, height)
    -- Update market panel size if it's the main panel
    if self.x == 0 and self.y == 0 then
        self:setSize(width, height)
    end
end

return MarketPanel 