-- GameBoard UI component for Power Grid Digital
-- Displays the game board with cities, connections, and power plants

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"

local GameBoard = class('GameBoard')

-- Create a new game board
function GameBoard.new(x, y, width, height, options)
    local board = GameBoard()
    board:initialize(x, y, width, height, options)
    return board
end

-- Initialize the game board
function GameBoard:initialize(x, y, width, height, options)
    -- Set default options
    self.options = options or {}
    self.options.backgroundColor = self.options.backgroundColor or {0.1, 0.1, 0.2, 0.8}
    self.options.borderColor = self.options.borderColor or {0.2, 0.2, 0.3, 1}
    self.options.textColor = self.options.textColor or {1, 1, 1, 1}
    self.options.fontSize = self.options.fontSize or 14
    self.options.padding = self.options.padding or 10
    self.options.cornerRadius = self.options.cornerRadius or 5
    self.options.cityRadius = self.options.cityRadius or 10
    self.options.cityColor = self.options.cityColor or {0.8, 0.8, 0.8, 1}
    self.options.cityBorderColor = self.options.cityBorderColor or {0.6, 0.6, 0.6, 1}
    self.options.cityTextColor = self.options.cityTextColor or {0, 0, 0, 1}
    self.options.connectionColor = self.options.connectionColor or {0.4, 0.4, 0.4, 1}
    self.options.connectionWidth = self.options.connectionWidth or 2
    self.options.powerPlantColor = self.options.powerPlantColor or {0.3, 0.3, 0.3, 1}
    self.options.powerPlantBorderColor = self.options.powerPlantBorderColor or {0.2, 0.2, 0.2, 1}
    self.options.powerPlantTextColor = self.options.powerPlantTextColor or {1, 1, 1, 1}
    self.options.selectedColor = self.options.selectedColor or {0.2, 0.6, 0.2, 1}
    self.options.hoverColor = self.options.hoverColor or {0.4, 0.8, 0.4, 1}
    
    -- Set position and size
    self.x = x or 0
    self.y = y or 0
    self.width = width or 800
    self.height = height or 600
    
    -- Create panel
    self.panel = Panel.new(x, y, width, height, {
        backgroundColor = self.options.backgroundColor,
        borderColor = self.options.borderColor,
        cornerRadius = self.options.cornerRadius
    })
    
    -- Create title label
    self.titleLabel = Label.new("Game Board", x + self.options.padding, y + self.options.padding, 
        width - (2 * self.options.padding), 30, {
            fontSize = self.options.fontSize + 4,
            textColor = self.options.textColor,
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0}
        })
    
    -- Game board state
    self.visible = true
    self.cities = {}
    self.connections = {}
    self.powerPlants = {}
    self.selectedCity = nil
    self.selectedPowerPlant = nil
    self.hoveredCity = nil
    self.hoveredPowerPlant = nil
    self.onCitySelected = nil
    self.onPowerPlantSelected = nil
    
    return self
end

-- Set game board position
function GameBoard:setPosition(x, y)
    self.x = x
    self.y = y
    self.panel:setPosition(x, y)
    self.titleLabel:setPosition(x + self.options.padding, y + self.options.padding)
end

-- Set game board size
function GameBoard:setSize(width, height)
    self.width = width
    self.height = height
    self.panel:setSize(width, height)
    self.titleLabel:setSize(width - (2 * self.options.padding), 30)
end

-- Set game board visibility
function GameBoard:setVisible(visible)
    self.visible = visible
    self.panel:setVisible(visible)
    self.titleLabel:setVisible(visible)
end

-- Get game board visibility
function GameBoard:isVisible()
    return self.visible
end

-- Set cities
function GameBoard:setCities(cities)
    self.cities = cities
end

-- Set connections
function GameBoard:setConnections(connections)
    self.connections = connections
end

-- Set power plants
function GameBoard:setPowerPlants(powerPlants)
    self.powerPlants = powerPlants
end

-- Set city selection handler
function GameBoard:setOnCitySelected(handler)
    self.onCitySelected = handler
end

-- Set power plant selection handler
function GameBoard:setOnPowerPlantSelected(handler)
    self.onPowerPlantSelected = handler
end

-- Get city at position
function GameBoard:getCityAt(x, y)
    for _, city in ipairs(self.cities) do
        local dx = x - city.x
        local dy = y - city.y
        if dx * dx + dy * dy <= self.options.cityRadius * self.options.cityRadius then
            return city
        end
    end
    return nil
end

-- Get power plant at position
function GameBoard:getPowerPlantAt(x, y)
    for _, powerPlant in ipairs(self.powerPlants) do
        local dx = x - powerPlant.x
        local dy = y - powerPlant.y
        if dx * dx + dy * dy <= self.options.cityRadius * self.options.cityRadius then
            return powerPlant
        end
    end
    return nil
end

-- Draw the game board
function GameBoard:draw()
    if not self.visible then return end
    
    -- Draw panel
    self.panel:draw()
    
    -- Draw title label
    self.titleLabel:draw()
    
    -- Draw connections
    love.graphics.setColor(self.options.connectionColor)
    love.graphics.setLineWidth(self.options.connectionWidth)
    for _, connection in ipairs(self.connections) do
        love.graphics.line(connection.city1.x, connection.city1.y, 
                          connection.city2.x, connection.city2.y)
    end
    
    -- Draw cities
    for _, city in ipairs(self.cities) do
        -- Set city color based on state
        if city == self.selectedCity then
            love.graphics.setColor(self.options.selectedColor)
        elseif city == self.hoveredCity then
            love.graphics.setColor(self.options.hoverColor)
        else
            love.graphics.setColor(self.options.cityColor)
        end
        
        -- Draw city circle
        love.graphics.circle("fill", city.x, city.y, self.options.cityRadius)
        
        -- Draw city border
        love.graphics.setColor(self.options.cityBorderColor)
        love.graphics.circle("line", city.x, city.y, self.options.cityRadius)
        
        -- Draw city name
        love.graphics.setColor(self.options.cityTextColor)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(city.name)
        love.graphics.print(city.name, city.x - textWidth / 2, 
                          city.y - self.options.cityRadius - 15)
    end
    
    -- Draw power plants
    for _, powerPlant in ipairs(self.powerPlants) do
        -- Set power plant color based on state
        if powerPlant == self.selectedPowerPlant then
            love.graphics.setColor(self.options.selectedColor)
        elseif powerPlant == self.hoveredPowerPlant then
            love.graphics.setColor(self.options.hoverColor)
        else
            love.graphics.setColor(self.options.powerPlantColor)
        end
        
        -- Draw power plant circle
        love.graphics.circle("fill", powerPlant.x, powerPlant.y, self.options.cityRadius)
        
        -- Draw power plant border
        love.graphics.setColor(self.options.powerPlantBorderColor)
        love.graphics.circle("line", powerPlant.x, powerPlant.y, self.options.cityRadius)
        
        -- Draw power plant number
        love.graphics.setColor(self.options.powerPlantTextColor)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(tostring(powerPlant.number))
        love.graphics.print(tostring(powerPlant.number), powerPlant.x - textWidth / 2, 
                          powerPlant.y - self.options.cityRadius - 15)
    end
end

-- Handle mouse press
function GameBoard:mousepressed(x, y, button)
    if not self.visible then return false end
    
    -- Check if click is inside game board
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        -- Check if click is on a city
        local city = self:getCityAt(x, y)
        if city then
            self.selectedCity = city
            if self.onCitySelected then
                self.onCitySelected(city)
            end
            return true
        end
        
        -- Check if click is on a power plant
        local powerPlant = self:getPowerPlantAt(x, y)
        if powerPlant then
            self.selectedPowerPlant = powerPlant
            if self.onPowerPlantSelected then
                self.onPowerPlantSelected(powerPlant)
            end
            return true
        end
    end
    
    return false
end

-- Handle mouse move
function GameBoard:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    
    -- Check if mouse is inside game board
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        -- Check if mouse is over a city
        local city = self:getCityAt(x, y)
        if city then
            self.hoveredCity = city
            return true
        end
        
        -- Check if mouse is over a power plant
        local powerPlant = self:getPowerPlantAt(x, y)
        if powerPlant then
            self.hoveredPowerPlant = powerPlant
            return true
        end
    end
    
    self.hoveredCity = nil
    self.hoveredPowerPlant = nil
    return false
end

-- Handle mouse release
function GameBoard:mousereleased(x, y, button)
    if not self.visible then return false end
    return false
end

-- Handle key press
function GameBoard:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    return false
end

-- Handle text input
function GameBoard:textinput(text)
    if not self.visible then return false end
    return false
end

-- Handle window resize
function GameBoard:resize(width, height)
    -- Update game board size if it's the main board
    if self.x == 0 and self.y == 0 then
        self:setSize(width, height)
    end
end

return GameBoard 