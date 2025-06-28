-- CityPanel UI component for Power Grid Digital
-- Displays city information and allows building connections

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"
local Button = require "src.ui.button"

local CityPanel = class('CityPanel')

-- Create a new city panel
function CityPanel.new(x, y, width, height, options)
    local panel = CityPanel()
    panel:initialize(x, y, width, height, options)
    return panel
end

-- Initialize the city panel
function CityPanel:initialize(x, y, width, height, options)
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
    self.titleLabel = Label.new("City Information", x + self.options.padding, y + self.options.padding, 
        width - (2 * self.options.padding), 30, {
            fontSize = self.options.fontSize + 4,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Create city name label
    self.cityNameLabel = Label.new("City: ", x + self.options.padding, y + 50, 
        width - (2 * self.options.padding), 20, {
            fontSize = self.options.fontSize,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Create connected cities label
    self.connectedCitiesLabel = Label.new("Connected Cities:", x + self.options.padding, y + 80, 
        width - (2 * self.options.padding), 20, {
            fontSize = self.options.fontSize,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Create connected cities list
    self.connectedCitiesList = Label.new("", x + self.options.padding, y + 110, 
        width - (2 * self.options.padding), 100, {
            fontSize = self.options.fontSize,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Create build connection button
    self.buildConnectionButton = Button.new("Build Connection", x + self.options.padding, y + height - 50, 
        width - (2 * self.options.padding), 30, {
            fontSize = self.options.fontSize,
            textColor = self.options.textColor,
            backgroundColor = {0.3, 0.6, 0.3, 1},
            borderColor = {0.4, 0.7, 0.4, 1},
            cornerRadius = 5
        })
    
    -- City panel state
    self.visible = true
    self.city = nil
    self.connectedCities = {}
    self.onBuildConnection = nil
    
    return self
end

-- Set city panel position
function CityPanel:setPosition(x, y)
    self.x = x
    self.y = y
    self.panel:setPosition(x, y)
    self.titleLabel:setPosition(x + self.options.padding, y + self.options.padding)
    self.cityNameLabel:setPosition(x + self.options.padding, y + 50)
    self.connectedCitiesLabel:setPosition(x + self.options.padding, y + 80)
    self.connectedCitiesList:setPosition(x + self.options.padding, y + 110)
    self.buildConnectionButton:setPosition(x + self.options.padding, y + self.height - 50)
end

-- Set city panel size
function CityPanel:setSize(width, height)
    self.width = width
    self.height = height
    self.panel:setSize(width, height)
    self.titleLabel:setSize(width - (2 * self.options.padding), 30)
    self.cityNameLabel:setSize(width - (2 * self.options.padding), 20)
    self.connectedCitiesLabel:setSize(width - (2 * self.options.padding), 20)
    self.connectedCitiesList:setSize(width - (2 * self.options.padding), 100)
    self.buildConnectionButton:setSize(width - (2 * self.options.padding), 30)
end

-- Set city panel visibility
function CityPanel:setVisible(visible)
    self.visible = visible
    self.panel:setVisible(visible)
    self.titleLabel:setVisible(visible)
    self.cityNameLabel:setVisible(visible)
    self.connectedCitiesLabel:setVisible(visible)
    self.connectedCitiesList:setVisible(visible)
    self.buildConnectionButton:setVisible(visible)
end

-- Get city panel visibility
function CityPanel:isVisible()
    return self.visible
end

-- Set city
function CityPanel:setCity(city)
    self.city = city
    if city then
        self.cityNameLabel:setText("City: " .. city.name)
        self:updateConnectedCitiesList()
    else
        self.cityNameLabel:setText("City: None")
        self.connectedCitiesList:setText("")
    end
end

-- Set connected cities
function CityPanel:setConnectedCities(cities)
    self.connectedCities = cities
    self:updateConnectedCitiesList()
end

-- Set build connection handler
function CityPanel:setOnBuildConnection(handler)
    self.onBuildConnection = handler
end

-- Update connected cities list
function CityPanel:updateConnectedCitiesList()
    if not self.city then
        self.connectedCitiesList:setText("")
        return
    end
    
    local text = ""
    for i, city in ipairs(self.connectedCities) do
        text = text .. city.name .. "\n"
    end
    self.connectedCitiesList:setText(text)
end

-- Draw the city panel
function CityPanel:draw()
    if not self.visible then return end
    
    -- Draw panel
    self.panel:draw()
    
    -- Draw labels
    self.titleLabel:draw()
    self.cityNameLabel:draw()
    self.connectedCitiesLabel:draw()
    self.connectedCitiesList:draw()
    
    -- Draw build connection button
    self.buildConnectionButton:draw()
end

-- Handle mouse press
function CityPanel:mousepressed(x, y, button)
    if not self.visible then return false end
    
    -- Check if click is inside panel
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        -- Check if click is on build connection button
        if x >= self.buildConnectionButton.x and x <= self.buildConnectionButton.x + self.buildConnectionButton.width and
           y >= self.buildConnectionButton.y and y <= self.buildConnectionButton.y + self.buildConnectionButton.height then
            if self.onBuildConnection then
                self.onBuildConnection(self.city)
            end
            return true
        end
    end
    
    return false
end

-- Handle mouse move
function CityPanel:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    return false
end

-- Handle mouse release
function CityPanel:mousereleased(x, y, button)
    if not self.visible then return false end
    return false
end

-- Handle key press
function CityPanel:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    return false
end

-- Handle text input
function CityPanel:textinput(text)
    if not self.visible then return false end
    return false
end

-- Handle window resize
function CityPanel:resize(width, height)
    -- Update panel size if it's the main panel
    if self.x == 0 and self.y == 0 then
        self:setSize(width, height)
    end
end

return CityPanel 