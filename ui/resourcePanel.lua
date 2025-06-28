-- ResourcePanel UI component for Power Grid Digital
-- Displays resource information and allows purchasing

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"
local Button = require "src.ui.button"

local ResourcePanel = class('ResourcePanel')

-- Create a new resource panel
function ResourcePanel.new(x, y, width, height, options)
    local panel = ResourcePanel()
    panel:initialize(x, y, width, height, options)
    return panel
end

-- Initialize the resource panel
function ResourcePanel:initialize(x, y, width, height, options)
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
    self.titleLabel = Label.new("Resources", x + self.options.padding, y + self.options.padding, 
        width - (2 * self.options.padding), 30, {
            fontSize = self.options.fontSize + 4,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Create resource labels
    self.resourceLabels = {}
    local resources = {"Coal", "Oil", "Garbage", "Uranium", "Hybrid"}
    for i, resource in ipairs(resources) do
        self.resourceLabels[resource] = Label.new(resource .. ": ", x + self.options.padding, y + 50 + (i - 1) * 40, 
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
    
    -- Resource panel state
    self.visible = true
    self.resources = {
        Coal = {price = 0, available = 0, selected = 0},
        Oil = {price = 0, available = 0, selected = 0},
        Garbage = {price = 0, available = 0, selected = 0},
        Uranium = {price = 0, available = 0, selected = 0},
        Hybrid = {price = 0, available = 0, selected = 0}
    }
    self.onPurchase = nil
    
    return self
end

-- Set resource panel position
function ResourcePanel:setPosition(x, y)
    self.x = x
    self.y = y
    self.panel:setPosition(x, y)
    self.titleLabel:setPosition(x + self.options.padding, y + self.options.padding)
    for i, resource in ipairs({"Coal", "Oil", "Garbage", "Uranium", "Hybrid"}) do
        self.resourceLabels[resource]:setPosition(x + self.options.padding, y + 50 + (i - 1) * 40)
    end
    self.purchaseButton:setPosition(x + self.options.padding, y + self.height - 50)
end

-- Set resource panel size
function ResourcePanel:setSize(width, height)
    self.width = width
    self.height = height
    self.panel:setSize(width, height)
    self.titleLabel:setSize(width - (2 * self.options.padding), 30)
    for _, label in pairs(self.resourceLabels) do
        label:setSize(width - (2 * self.options.padding), 30)
    end
    self.purchaseButton:setSize(width - (2 * self.options.padding), 30)
end

-- Set resource panel visibility
function ResourcePanel:setVisible(visible)
    self.visible = visible
    self.panel:setVisible(visible)
    self.titleLabel:setVisible(visible)
    for _, label in pairs(self.resourceLabels) do
        label:setVisible(visible)
    end
    self.purchaseButton:setVisible(visible)
end

-- Get resource panel visibility
function ResourcePanel:isVisible()
    return self.visible
end

-- Set resource information
function ResourcePanel:setResourceInfo(resource, price, available)
    if self.resources[resource] then
        self.resources[resource].price = price
        self.resources[resource].available = available
        self:updateResourceLabel(resource)
    end
end

-- Set selected resource amount
function ResourcePanel:setSelectedAmount(resource, amount)
    if self.resources[resource] then
        self.resources[resource].selected = amount
        self:updateResourceLabel(resource)
    end
end

-- Set purchase handler
function ResourcePanel:setOnPurchase(handler)
    self.onPurchase = handler
end

-- Update resource label
function ResourcePanel:updateResourceLabel(resource)
    local info = self.resources[resource]
    local text = string.format("%s: %d (Available: %d)", resource, info.price, info.available)
    if info.selected > 0 then
        text = text .. string.format(" (Selected: %d)", info.selected)
    end
    self.resourceLabels[resource]:setText(text)
end

-- Draw the resource panel
function ResourcePanel:draw()
    if not self.visible then return end
    
    -- Draw panel
    self.panel:draw()
    
    -- Draw labels
    self.titleLabel:draw()
    for _, label in pairs(self.resourceLabels) do
        label:draw()
    end
    
    -- Draw purchase button
    self.purchaseButton:draw()
end

-- Handle mouse press
function ResourcePanel:mousepressed(x, y, button)
    if not self.visible then return false end
    
    -- Check if click is inside panel
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        -- Check if click is on a resource label
        for resource, label in pairs(self.resourceLabels) do
            if x >= label.x and x <= label.x + label.width and
               y >= label.y and y <= label.y + label.height then
                -- TODO: Implement resource selection
                return true
            end
        end
        
        -- Check if click is on purchase button
        if x >= self.purchaseButton.x and x <= self.purchaseButton.x + self.purchaseButton.width and
           y >= self.purchaseButton.y and y <= self.purchaseButton.y + self.purchaseButton.height then
            if self.onPurchase then
                self.onPurchase(self.resources)
            end
            return true
        end
    end
    
    return false
end

-- Handle mouse move
function ResourcePanel:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    return false
end

-- Handle mouse release
function ResourcePanel:mousereleased(x, y, button)
    if not self.visible then return false end
    return false
end

-- Handle key press
function ResourcePanel:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    return false
end

-- Handle text input
function ResourcePanel:textinput(text)
    if not self.visible then return false end
    return false
end

-- Handle window resize
function ResourcePanel:resize(width, height)
    -- Update panel size if it's the main panel
    if self.x == 0 and self.y == 0 then
        self:setSize(width, height)
    end
end

return ResourcePanel 