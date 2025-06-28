-- PowerPlantPanel UI component for Power Grid Digital
-- Displays power plant information and allows purchasing

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"
local Button = require "src.ui.button"

local PowerPlantPanel = class('PowerPlantPanel')

-- Create a new power plant panel
function PowerPlantPanel.new(x, y, width, height, options)
    local panel = PowerPlantPanel()
    panel:initialize(x, y, width, height, options)
    return panel
end

-- Initialize the power plant panel
function PowerPlantPanel:initialize(x, y, width, height, options)
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
    self.height = height or 400
    
    -- Create panel
    self.panel = Panel.new(x, y, width, height, {
        backgroundColor = self.options.backgroundColor,
        borderColor = self.options.borderColor,
        cornerRadius = self.options.cornerRadius
    })
    
    -- Create title label
    self.titleLabel = Label.new("Power Plants", x + self.options.padding, y + self.options.padding, 
        width - (2 * self.options.padding), 30, {
            fontSize = self.options.fontSize + 4,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Create power plant labels
    self.powerPlantLabels = {}
    for i = 1, 8 do
        self.powerPlantLabels[i] = Label.new("", x + self.options.padding, y + 50 + (i - 1) * 40, 
            width - (2 * self.options.padding), 30, {
                fontSize = self.options.fontSize,
                textColor = self.options.textColor,
                backgroundColor = {0, 0, 0, 0},
                borderColor = {0, 0, 0, 0}
            })
    end
    
    -- Create purchase button
    self.purchaseButton = Button.new("Purchase", x + self.options.padding, y + height - 50, 
        width - (2 * self.options.padding), 30, {
            fontSize = self.options.fontSize,
            textColor = self.options.textColor,
            backgroundColor = {0.3, 0.6, 0.3, 1},
            borderColor = {0.4, 0.7, 0.4, 1},
            cornerRadius = 5
        })
    
    -- Power plant panel state
    self.visible = true
    self.powerPlants = {}
    self.selectedPowerPlant = nil
    self.onPurchase = nil
    
    -- Load power plant data
    self:loadPowerPlantData()
    
    return self
end

-- Load power plant data
function PowerPlantPanel:loadPowerPlantData()
    -- TODO: Load power plants from game data
    -- This will be implemented when we have the game data structure
end

-- Set power plant panel position
function PowerPlantPanel:setPosition(x, y)
    self.x = x
    self.y = y
    self.panel:setPosition(x, y)
    self.titleLabel:setPosition(x + self.options.padding, y + self.options.padding)
    for i = 1, 8 do
        self.powerPlantLabels[i]:setPosition(x + self.options.padding, y + 50 + (i - 1) * 40)
    end
    self.purchaseButton:setPosition(x + self.options.padding, y + self.height - 50)
end

-- Set power plant panel size
function PowerPlantPanel:setSize(width, height)
    self.width = width
    self.height = height
    self.panel:setSize(width, height)
    self.titleLabel:setSize(width - (2 * self.options.padding), 30)
    for i = 1, 8 do
        self.powerPlantLabels[i]:setSize(width - (2 * self.options.padding), 30)
    end
    self.purchaseButton:setSize(width - (2 * self.options.padding), 30)
end

-- Set power plant panel visibility
function PowerPlantPanel:setVisible(visible)
    self.visible = visible
    self.panel:setVisible(visible)
    self.titleLabel:setVisible(visible)
    for i = 1, 8 do
        self.powerPlantLabels[i]:setVisible(visible)
    end
    self.purchaseButton:setVisible(visible)
end

-- Get power plant panel visibility
function PowerPlantPanel:isVisible()
    return self.visible
end

-- Set selected power plant
function PowerPlantPanel:setSelectedPowerPlant(powerPlant)
    self.selectedPowerPlant = powerPlant
    self:updatePowerPlantLabels()
end

-- Set purchase handler
function PowerPlantPanel:setOnPurchase(handler)
    self.onPurchase = handler
end

-- Update power plant labels
function PowerPlantPanel:updatePowerPlantLabels()
    for i, powerPlant in ipairs(self.powerPlants) do
        local text = string.format("%d. %s - Cost: %d", i, powerPlant.type, powerPlant.cost)
        if powerPlant == self.selectedPowerPlant then
            text = text .. " (Selected)"
        end
        self.powerPlantLabels[i]:setText(text)
    end
end

-- Draw the power plant panel
function PowerPlantPanel:draw()
    if not self.visible then return end
    
    -- Draw panel
    self.panel:draw()
    
    -- Draw labels
    self.titleLabel:draw()
    for i = 1, 8 do
        self.powerPlantLabels[i]:draw()
    end
    
    -- Draw purchase button
    self.purchaseButton:draw()
end

-- Handle mouse press
function PowerPlantPanel:mousepressed(x, y, button)
    if not self.visible then return false end
    
    -- Check if click is inside panel
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        -- Check if click is on a power plant label
        for i, label in ipairs(self.powerPlantLabels) do
            if x >= label.x and x <= label.x + label.width and
               y >= label.y and y <= label.y + label.height then
                self.selectedPowerPlant = self.powerPlants[i]
                self:updatePowerPlantLabels()
                return true
            end
        end
        
        -- Check if click is on purchase button
        if x >= self.purchaseButton.x and x <= self.purchaseButton.x + self.purchaseButton.width and
           y >= self.purchaseButton.y and y <= self.purchaseButton.y + self.purchaseButton.height then
            if self.selectedPowerPlant and self.onPurchase then
                self.onPurchase(self.selectedPowerPlant)
            end
            return true
        end
    end
    
    return false
end

-- Handle mouse move
function PowerPlantPanel:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    return false
end

-- Handle mouse release
function PowerPlantPanel:mousereleased(x, y, button)
    if not self.visible then return false end
    return false
end

-- Handle key press
function PowerPlantPanel:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    return false
end

-- Handle text input
function PowerPlantPanel:textinput(text)
    if not self.visible then return false end
    return false
end

-- Handle window resize
function PowerPlantPanel:resize(width, height)
    -- Update panel size if it's the main panel
    if self.x == 0 and self.y == 0 then
        self:setSize(width, height)
    end
end

return PowerPlantPanel 