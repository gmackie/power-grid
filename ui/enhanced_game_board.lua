-- Enhanced Game Board with visual polish
local EnhancedGameBoard = {}
EnhancedGameBoard.__index = EnhancedGameBoard

local Theme = require("ui.theme")
local AssetLoader = require("assets.asset_loader")
local StyledPanel = require("ui.styled_panel")

function EnhancedGameBoard.new(x, y, width, height, options)
    local self = setmetatable({}, EnhancedGameBoard)
    
    options = options or {}
    
    -- Basic properties
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    
    -- Map data
    self.cities = {}
    self.connections = {}
    self.players = {}
    
    -- Visual settings
    self.scale = 1.0
    self.offsetX = 0
    self.offsetY = 0
    self.targetScale = 1.0
    self.targetOffsetX = 0
    self.targetOffsetY = 0
    
    -- Animation
    self.animationSpeed = 5.0
    
    -- Interaction
    self.selectedCity = nil
    self.hoveredCity = nil
    self.buildableConnections = {}
    
    -- Visual effects
    self.cityPulses = {}
    self.connectionAnimations = {}
    self.sparkles = {}
    
    -- Load assets
    self.cityAssets = {}
    local regions = {"yellow", "purple", "blue", "brown", "red", "green"}
    for _, region in ipairs(regions) do
        self.cityAssets[region] = AssetLoader.getCity(region)
    end
    
    -- Fonts
    self.cityFont = love.graphics.newFont(Theme.fonts.small)
    self.costFont = love.graphics.newFont(Theme.fonts.tiny)
    
    return self
end

function EnhancedGameBoard:update(dt)
    -- Update animations
    self.scale = self.scale + (self.targetScale - self.scale) * self.animationSpeed * dt
    self.offsetX = self.offsetX + (self.targetOffsetX - self.offsetX) * self.animationSpeed * dt
    self.offsetY = self.offsetY + (self.targetOffsetY - self.offsetY) * self.animationSpeed * dt
    
    -- Update city pulses
    for cityId, pulse in pairs(self.cityPulses) do
        pulse.phase = pulse.phase + dt * 4
        pulse.alpha = math.max(0, pulse.alpha - dt * 2)
        if pulse.alpha <= 0 then
            self.cityPulses[cityId] = nil
        end
    end
    
    -- Update connection animations
    for i = #self.connectionAnimations, 1, -1 do
        local anim = self.connectionAnimations[i]
        anim.progress = anim.progress + dt * 2
        if anim.progress >= 1 then
            table.remove(self.connectionAnimations, i)
        end
    end
    
    -- Update sparkles
    for i = #self.sparkles, 1, -1 do
        local sparkle = self.sparkles[i]
        sparkle.life = sparkle.life - dt
        sparkle.y = sparkle.y - 20 * dt
        sparkle.alpha = sparkle.alpha * 0.98
        if sparkle.life <= 0 then
            table.remove(self.sparkles, i)
        end
    end
end

function EnhancedGameBoard:draw()
    love.graphics.push()
    
    -- Apply transform
    love.graphics.translate(self.offsetX, self.offsetY)
    love.graphics.scale(self.scale)
    
    -- Set clipping
    love.graphics.setScissor(self.x, self.y, self.width, self.height)
    
    -- Draw background grid
    self:drawGrid()
    
    -- Draw connections
    self:drawConnections()
    
    -- Draw cities
    self:drawCities()
    
    -- Draw sparkles
    self:drawSparkles()
    
    love.graphics.setScissor()
    love.graphics.pop()
end

function EnhancedGameBoard:drawGrid()
    love.graphics.setColor(Theme.colors.backgroundLight[1], Theme.colors.backgroundLight[2], 
                          Theme.colors.backgroundLight[3], 0.3)
    love.graphics.setLineWidth(1)
    
    local gridSize = 40
    for x = self.x, self.x + self.width, gridSize do
        love.graphics.line(x, self.y, x, self.y + self.height)
    end
    for y = self.y, self.y + self.height, gridSize do
        love.graphics.line(self.x, y, self.x + self.width, y)
    end
end

function EnhancedGameBoard:drawConnections()
    love.graphics.setLineWidth(3)
    
    for _, connection in ipairs(self.connections) do
        local city1 = self.cities[connection.city1]
        local city2 = self.cities[connection.city2]
        
        if city1 and city2 then
            local x1, y1 = city1.x, city1.y
            local x2, y2 = city2.x, city2.y
            
            -- Connection color based on ownership or buildability
            local color = Theme.colors.textDisabled
            local alpha = 0.5
            
            if connection.owner then
                color = Theme.getPlayerColor(connection.owner)
                alpha = 1.0
            elseif self:isConnectionBuildable(connection) then
                color = Theme.colors.warning
                alpha = 0.8
            end
            
            love.graphics.setColor(color[1], color[2], color[3], alpha)
            love.graphics.line(x1, y1, x2, y2)
            
            -- Draw cost indicator
            local midX, midY = (x1 + x2) / 2, (y1 + y2) / 2
            self:drawConnectionCost(midX, midY, connection.cost, color, alpha)
            
            -- Draw connection animation if active
            for _, anim in ipairs(self.connectionAnimations) do
                if anim.connection == connection then
                    self:drawConnectionAnimation(x1, y1, x2, y2, anim.progress)
                end
            end
        end
    end
end

function EnhancedGameBoard:drawConnectionCost(x, y, cost, color, alpha)
    local radius = 12
    
    -- Background circle
    love.graphics.setColor(Theme.colors.surface[1], Theme.colors.surface[2], 
                          Theme.colors.surface[3], alpha)
    love.graphics.circle("fill", x, y, radius)
    
    -- Border
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", x, y, radius)
    
    -- Cost text
    love.graphics.setFont(self.costFont)
    love.graphics.setColor(Theme.colors.textPrimary[1], Theme.colors.textPrimary[2], 
                          Theme.colors.textPrimary[3], alpha)
    local text = tostring(cost)
    local textWidth = self.costFont:getWidth(text)
    local textHeight = self.costFont:getHeight()
    love.graphics.print(text, x - textWidth/2, y - textHeight/2)
end

function EnhancedGameBoard:drawConnectionAnimation(x1, y1, x2, y2, progress)
    -- Draw energy flowing along the connection
    love.graphics.setColor(Theme.colors.primary[1], Theme.colors.primary[2], 
                          Theme.colors.primary[3], 0.8)
    
    for i = 0, 3 do
        local t = (progress + i * 0.25) % 1
        local x = x1 + (x2 - x1) * t
        local y = y1 + (y2 - y1) * t
        local size = 5 - i
        love.graphics.circle("fill", x, y, size)
    end
end

function EnhancedGameBoard:drawCities()
    for _, city in ipairs(self.cities) do
        local asset = self.cityAssets[city.region]
        local scale = 1.0
        local alpha = 1.0
        
        -- Hover effect
        if self.hoveredCity == city then
            scale = 1.2
        end
        
        -- Selection effect
        if self.selectedCity == city then
            scale = 1.3
            -- Draw selection ring
            love.graphics.setColor(Theme.colors.primary[1], Theme.colors.primary[2], 
                                  Theme.colors.primary[3], 0.8)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", city.x, city.y, 20)
        end
        
        -- Pulse effect
        local pulse = self.cityPulses[city.id]
        if pulse then
            local pulseScale = 1 + math.sin(pulse.phase) * 0.3
            love.graphics.setColor(pulse.color[1], pulse.color[2], pulse.color[3], pulse.alpha)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", city.x, city.y, 25 * pulseScale)
        end
        
        -- Draw city
        if asset then
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.draw(asset, city.x - 15 * scale, city.y - 15 * scale, 0, scale, scale)
        else
            -- Fallback drawing
            local regionColor = Theme.getRegionColor(city.region)
            love.graphics.setColor(regionColor[1], regionColor[2], regionColor[3], alpha)
            love.graphics.circle("fill", city.x, city.y, 15 * scale)
            
            love.graphics.setColor(Theme.colors.textPrimary[1], Theme.colors.textPrimary[2], 
                                  Theme.colors.textPrimary[3], alpha)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", city.x, city.y, 15 * scale)
        end
        
        -- Draw ownership indicators
        if city.owners and #city.owners > 0 then
            self:drawCityOwnership(city)
        end
        
        -- Draw city name
        love.graphics.setFont(self.cityFont)
        love.graphics.setColor(Theme.colors.textPrimary[1], Theme.colors.textPrimary[2], 
                              Theme.colors.textPrimary[3], alpha)
        local textWidth = self.cityFont:getWidth(city.name)
        love.graphics.print(city.name, city.x - textWidth/2, city.y + 25)
    end
end

function EnhancedGameBoard:drawCityOwnership(city)
    local numOwners = #city.owners
    local angleStep = math.pi * 2 / numOwners
    local radius = 25
    
    for i, owner in ipairs(city.owners) do
        local angle = i * angleStep - math.pi/2
        local x = city.x + math.cos(angle) * radius
        local y = city.y + math.sin(angle) * radius
        
        local playerColor = Theme.getPlayerColor(owner)
        love.graphics.setColor(playerColor)
        love.graphics.circle("fill", x, y, 6)
        
        love.graphics.setColor(Theme.colors.textPrimary)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", x, y, 6)
    end
end

function EnhancedGameBoard:drawSparkles()
    for _, sparkle in ipairs(self.sparkles) do
        love.graphics.setColor(sparkle.color[1], sparkle.color[2], sparkle.color[3], sparkle.alpha)
        love.graphics.circle("fill", sparkle.x, sparkle.y, sparkle.size)
    end
end

function EnhancedGameBoard:addSparkle(x, y, color)
    table.insert(self.sparkles, {
        x = x + math.random(-10, 10),
        y = y + math.random(-10, 10),
        size = math.random(2, 5),
        color = color or Theme.colors.primary,
        alpha = 1.0,
        life = 1.0
    })
end

function EnhancedGameBoard:pulseCity(cityId, color)
    self.cityPulses[cityId] = {
        phase = 0,
        alpha = 1.0,
        color = color or Theme.colors.success
    }
end

function EnhancedGameBoard:animateConnection(connection)
    table.insert(self.connectionAnimations, {
        connection = connection,
        progress = 0
    })
end

function EnhancedGameBoard:mousepressed(x, y, button)
    if button ~= 1 then return false end
    
    -- Transform coordinates
    local localX = (x - self.offsetX) / self.scale
    local localY = (y - self.offsetY) / self.scale
    
    -- Check city clicks
    for _, city in ipairs(self.cities) do
        local distance = math.sqrt((localX - city.x)^2 + (localY - city.y)^2)
        if distance < 20 then
            self:selectCity(city)
            return true
        end
    end
    
    self:selectCity(nil)
    return false
end

function EnhancedGameBoard:mousemoved(x, y)
    -- Transform coordinates
    local localX = (x - self.offsetX) / self.scale
    local localY = (y - self.offsetY) / self.scale
    
    -- Check city hover
    local hoveredCity = nil
    for _, city in ipairs(self.cities) do
        local distance = math.sqrt((localX - city.x)^2 + (localY - city.y)^2)
        if distance < 20 then
            hoveredCity = city
            break
        end
    end
    
    self.hoveredCity = hoveredCity
end

function EnhancedGameBoard:selectCity(city)
    if self.selectedCity ~= city then
        self.selectedCity = city
        
        if city then
            self:pulseCity(city.id, Theme.colors.primary)
            self:addSparkle(city.x, city.y, Theme.colors.primary)
        end
        
        -- Update buildable connections
        self:updateBuildableConnections()
    end
end

function EnhancedGameBoard:updateBuildableConnections()
    self.buildableConnections = {}
    
    if self.selectedCity then
        -- Find connections from selected city
        for _, connection in ipairs(self.connections) do
            if (connection.city1 == self.selectedCity.id or connection.city2 == self.selectedCity.id) and
               not connection.owner then
                table.insert(self.buildableConnections, connection)
            end
        end
    end
end

function EnhancedGameBoard:isConnectionBuildable(connection)
    for _, buildable in ipairs(self.buildableConnections) do
        if buildable == connection then
            return true
        end
    end
    return false
end

function EnhancedGameBoard:setMapData(cities, connections)
    self.cities = cities
    self.connections = connections
end

function EnhancedGameBoard:zoomTo(targetScale, targetX, targetY)
    self.targetScale = math.max(0.5, math.min(2.0, targetScale))
    self.targetOffsetX = targetX or self.targetOffsetX
    self.targetOffsetY = targetY or self.targetOffsetY
end

return EnhancedGameBoard