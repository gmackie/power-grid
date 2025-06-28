-- MapUI.lua - Map visualization for Power Grid Digital

local class = require "lib.middleclass"
local flux = require "lib.flux"

local MapUI = class('MapUI')

function MapUI:initialize(game)
    self.game = game
    
    -- Rendering properties
    self.scale = 1.0
    self.offsetX = 0
    self.offsetY = 0
    self.dragging = false
    self.dragStartX = 0
    self.dragStartY = 0
    self.cityRadius = 15
    self.selectedCityRadius = 18
    self.connectionWidth = 5
    
    -- Animation tweens
    self.animations = {
        cities = {},
        connections = {}
    }
    
    -- City colors by region
    self.regionColors = {
        YELLOW = {1, 0.9, 0.2},
        PURPLE = {0.8, 0.2, 0.8},
        BLUE = {0.2, 0.5, 0.9},
        BROWN = {0.6, 0.4, 0.2},
        RED = {0.9, 0.2, 0.2},
        GREEN = {0.2, 0.8, 0.2}
    }
    
    -- Player colors
    self.playerColors = {
        RED = {0.9, 0.2, 0.2},
        GREEN = {0.2, 0.8, 0.2},
        BLUE = {0.2, 0.5, 0.9},
        YELLOW = {1, 0.9, 0.2},
        BLACK = {0.2, 0.2, 0.2},
        PURPLE = {0.8, 0.2, 0.8}
    }
    
    -- Connection cost colors
    self.costColors = {
        [0] = {0.8, 0.8, 0.8},
        [1] = {0.2, 0.8, 0.2},
        [2] = {0.9, 0.6, 0.1},
        [3] = {0.9, 0.2, 0.2}
    }
    
    -- Font sizes
    self.fonts = {
        city = love.graphics.newFont(12),
        cost = love.graphics.newFont(10),
        region = love.graphics.newFont(14)
    }
    
    -- Touch/mouse state
    self.touch = {
        x = 0,
        y = 0,
        pressed = false
    }
end

function MapUI:update(dt)
    -- Update animations
    flux.update(dt)
    
    -- Check if a city is being hovered/selected
    if self.touch.pressed then
        self:checkCitySelection()
    end
end

function MapUI:draw()
    local map = self.game.map
    if not map then return end
    
    love.graphics.push()
    
    -- Apply transformations
    love.graphics.translate(self.offsetX, self.offsetY)
    love.graphics.scale(self.scale, self.scale)
    
    -- Draw connections
    self:drawConnections()
    
    -- Draw cities
    self:drawCities()
    
    -- Draw player buildings
    self:drawBuildings()
    
    -- Draw region labels
    self:drawRegionLabels()
    
    love.graphics.pop()
end

function MapUI:drawConnections()
    local map = self.game.map
    if not map or not map.connections then return end
    
    for fromCityId, connections in pairs(map.connections) do
        local fromCity = map.cities[fromCityId]
        
        for _, connection in ipairs(connections) do
            local toCity = map.cities[connection.to_city]
            
            -- Determine connection color based on cost
            local costLevel = math.min(connection.cost / 5, 3)
            local color = self.costColors[math.floor(costLevel)]
            
            -- Draw connection line
            love.graphics.setLineWidth(self.connectionWidth)
            love.graphics.setColor(color)
            love.graphics.line(
                fromCity.position.x, 
                fromCity.position.y, 
                toCity.position.x, 
                toCity.position.y
            )
            
            -- Draw cost label
            local midX = (fromCity.position.x + toCity.position.x) / 2
            local midY = (fromCity.position.y + toCity.position.y) / 2
            
            love.graphics.setFont(self.fonts.cost)
            love.graphics.setColor(1, 1, 1)
            love.graphics.circle("fill", midX, midY, 10)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(
                tostring(connection.cost), 
                midX - 10, 
                midY - 5, 
                20, 
                "center"
            )
        end
    end
end

function MapUI:drawCities()
    local map = self.game.map
    if not map or not map.cities then return end
    
    for cityId, city in pairs(map.cities) do
        local isSelected = (self.game.selectedCity == cityId)
        local radius = isSelected and self.selectedCityRadius or self.cityRadius
        
        -- Get region color
        local color = self.regionColors[city.region] or {0.5, 0.5, 0.5}
        
        -- Draw city circle
        love.graphics.setColor(color)
        love.graphics.circle("fill", city.position.x, city.position.y, radius)
        
        -- Draw outline for selected city
        if isSelected then
            love.graphics.setColor(1, 1, 1)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", city.position.x, city.position.y, radius + 2)
        end
        
        -- Draw city name
        love.graphics.setFont(self.fonts.city)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(
            city.name, 
            city.position.x - 50, 
            city.position.y + radius + 5, 
            100, 
            "center"
        )
        
        -- Animation for new cities (grow effect)
        if self.animations.cities[cityId] then
            local anim = self.animations.cities[cityId]
            love.graphics.setColor(1, 1, 1, anim.alpha)
            love.graphics.circle("line", city.position.x, city.position.y, anim.radius)
        end
    end
end

function MapUI:drawBuildings()
    local map = self.game.map
    if not map or not map.cities then return end
    
    for cityId, city in pairs(map.cities) do
        if city.players and #city.players > 0 then
            -- Calculate positions for buildings (arranged in a circle)
            local numBuildings = #city.players
            local radius = self.cityRadius + 5
            local angle = 0
            local angleStep = (2 * math.pi) / numBuildings
            
            for i, playerId in ipairs(city.players) do
                local player = self.game.players[playerId]
                if player then
                    local color = self.playerColors[player.color] or {0.5, 0.5, 0.5}
                    
                    -- Calculate building position
                    local bx = city.position.x + math.cos(angle) * radius
                    local by = city.position.y + math.sin(angle) * radius
                    
                    -- Draw building
                    love.graphics.setColor(color)
                    love.graphics.rectangle("fill", bx - 5, by - 5, 10, 10)
                    
                    -- Move to next position
                    angle = angle + angleStep
                end
            end
        end
    end
end

function MapUI:drawRegionLabels()
    local map = self.game.map
    if not map then return end
    
    -- Group cities by region
    local regions = {}
    for _, city in pairs(map.cities) do
        if not regions[city.region] then
            regions[city.region] = {}
        end
        table.insert(regions[city.region], city)
    end
    
    -- Draw region labels at center of each region
    love.graphics.setFont(self.fonts.region)
    
    for region, cities in pairs(regions) do
        -- Calculate region center
        local centerX, centerY = 0, 0
        for _, city in ipairs(cities) do
            centerX = centerX + city.position.x
            centerY = centerY + city.position.y
        end
        centerX = centerX / #cities
        centerY = centerY / #cities
        
        -- Draw region name
        local color = self.regionColors[region] or {0.5, 0.5, 0.5}
        love.graphics.setColor(color)
        love.graphics.printf(
            region, 
            centerX - 100, 
            centerY - 50, 
            200, 
            "center"
        )
    end
end

-- Input handling

function MapUI:mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
        self.dragging = true
        self.dragStartX = x - self.offsetX
        self.dragStartY = y - self.offsetY
        
        self.touch.x = (x - self.offsetX) / self.scale
        self.touch.y = (y - self.offsetY) / self.scale
        self.touch.pressed = true
    end
end

function MapUI:mousereleased(x, y, button)
    if button == 1 then  -- Left mouse button
        self.dragging = false
        self.touch.pressed = false
    end
end

function MapUI:mousemoved(x, y)
    if self.dragging then
        self.offsetX = x - self.dragStartX
        self.offsetY = y - self.dragStartY
    end
    
    self.touch.x = (x - self.offsetX) / self.scale
    self.touch.y = (y - self.offsetY) / self.scale
end

function MapUI:wheelmoved(x, y)
    -- Zoom in/out
    local oldScale = self.scale
    self.scale = math.max(0.5, math.min(2.0, self.scale + y * 0.1))
    
    -- Adjust offset to zoom toward mouse position
    if oldScale ~= self.scale then
        local mouseX, mouseY = love.mouse.getPosition()
        local worldX = (mouseX - self.offsetX) / oldScale
        local worldY = (mouseY - self.offsetY) / oldScale
        
        self.offsetX = mouseX - worldX * self.scale
        self.offsetY = mouseY - worldY * self.scale
    end
end

function MapUI:touchpressed(id, x, y)
    -- Similar to mousepressed but for touch controls
    if id == 0 then  -- Primary touch
        self.dragging = true
        self.dragStartX = x - self.offsetX
        self.dragStartY = y - self.offsetY
        
        self.touch.x = (x - self.offsetX) / self.scale
        self.touch.y = (y - self.offsetY) / self.scale
        self.touch.pressed = true
    end
end

function MapUI:touchreleased(id, x, y)
    if id == 0 then  -- Primary touch
        self.dragging = false
        self.touch.pressed = false
    end
end

function MapUI:touchmoved(id, x, y)
    if id == 0 and self.dragging then  -- Primary touch
        self.offsetX = x - self.dragStartX
        self.offsetY = y - self.dragStartY
        
        self.touch.x = (x - self.offsetX) / self.scale
        self.touch.y = (y - self.offsetY) / self.scale
    end
end

-- Helper functions

function MapUI:checkCitySelection()
    local map = self.game.map
    if not map or not map.cities then return end
    
    -- Check if a city is being clicked/touched
    for cityId, city in pairs(map.cities) do
        local dx = self.touch.x - city.position.x
        local dy = self.touch.y - city.position.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance <= self.cityRadius then
            -- City was selected
            self.game.selectedCity = cityId
            
            -- Create selection animation
            self:animateCitySelection(cityId)
            
            -- Handle city selection based on game phase
            if self.game.currentPhase == "BUILD_CITIES" and self.game:isCurrentPlayer() then
                if self.game:canBuildInCity(cityId) then
                    self.game:buildCity(cityId)
                end
            end
            
            return
        end
    end
    
    -- No city was selected, clear selection
    self.game.selectedCity = nil
end

function MapUI:animateCitySelection(cityId)
    -- Create a pulse animation for the selected city
    local city = self.game.map.cities[cityId]
    if not city then return end
    
    -- Clear existing animation
    self.animations.cities[cityId] = {
        radius = self.cityRadius,
        alpha = 1.0
    }
    
    -- Create new animation
    flux.to(self.animations.cities[cityId], 0.5, {
        radius = self.cityRadius * 2,
        alpha = 0
    }):ease("quadout"):oncomplete(function()
        self.animations.cities[cityId] = nil
    end)
end

function MapUI:reset()
    -- Reset view transformations
    self.scale = 1.0
    self.offsetX = 0
    self.offsetY = 0
    self.dragging = false
    
    -- Clear selections
    self.game.selectedCity = nil
    
    -- Clear animations
    self.animations.cities = {}
    self.animations.connections = {}
end

return MapUI