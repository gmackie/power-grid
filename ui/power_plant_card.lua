-- Enhanced Power Plant Card Component
local PowerPlantCard = {}
PowerPlantCard.__index = PowerPlantCard

local Theme = require("ui.theme")
local AssetLoader = require("assets.asset_loader")

function PowerPlantCard.new(x, y, powerPlant, options)
    local self = setmetatable({}, PowerPlantCard)
    
    options = options or {}
    
    -- Basic properties
    self.x = x
    self.y = y
    self.width = options.width or 180
    self.height = options.height or 120
    self.powerPlant = powerPlant
    
    -- Visual state
    self.hovered = false
    self.selected = false
    self.enabled = true
    self.visible = true
    
    -- Animation
    self.scale = 1.0
    self.targetScale = 1.0
    self.rotation = 0
    self.targetRotation = 0
    self.alpha = 1.0
    self.targetAlpha = 1.0
    self.glowAlpha = 0
    
    -- Animation speeds
    self.scaleSpeed = 8.0
    self.rotationSpeed = 5.0
    self.alphaSpeed = 6.0
    
    -- Interaction
    self.clickable = options.clickable ~= false
    self.onTap = options.onTap
    self.onLongPress = options.onLongPress
    
    -- Visual effects
    self.sparkles = {}
    self.energyParticles = {}
    
    -- Load assets
    if powerPlant then
        local plantType = string.lower(powerPlant.resourceType or "coal")
        self.cardAsset = AssetLoader.getPowerPlantCard(plantType)
        self.resourceAsset = AssetLoader.getResource(plantType)
    end
    
    -- Fonts
    self.titleFont = love.graphics.newFont(Theme.fonts.medium)
    self.numberFont = love.graphics.newFont(Theme.fonts.large)
    self.detailFont = love.graphics.newFont(Theme.fonts.small)
    
    return self
end

function PowerPlantCard:update(dt)
    if not self.visible then return end
    
    -- Update animations
    self.scale = self.scale + (self.targetScale - self.scale) * self.scaleSpeed * dt
    self.rotation = self.rotation + (self.targetRotation - self.rotation) * self.rotationSpeed * dt
    self.alpha = self.alpha + (self.targetAlpha - self.alpha) * self.alphaSpeed * dt
    
    -- Update glow
    if self.glowAlpha > 0 then
        self.glowAlpha = math.max(0, self.glowAlpha - dt * 2)
    end
    
    -- Update visual state
    if self.enabled then
        if self.selected then
            self.targetScale = 1.1
            self.targetRotation = 0
        elseif self.hovered then
            self.targetScale = 1.05
            self.targetRotation = 0
        else
            self.targetScale = 1.0
            self.targetRotation = 0
        end
        self.targetAlpha = 1.0
    else
        self.targetScale = 0.95
        self.targetRotation = 0
        self.targetAlpha = 0.6
    end
    
    -- Update sparkles
    for i = #self.sparkles, 1, -1 do
        local sparkle = self.sparkles[i]
        sparkle.life = sparkle.life - dt
        sparkle.y = sparkle.y - 30 * dt
        sparkle.alpha = sparkle.alpha * 0.98
        if sparkle.life <= 0 then
            table.remove(self.sparkles, i)
        end
    end
    
    -- Update energy particles
    for i = #self.energyParticles, 1, -1 do
        local particle = self.energyParticles[i]
        particle.life = particle.life - dt
        particle.x = particle.x + particle.vx * dt
        particle.y = particle.y + particle.vy * dt
        particle.alpha = particle.alpha * 0.99
        if particle.life <= 0 then
            table.remove(self.energyParticles, i)
        end
    end
end

function PowerPlantCard:draw()
    if not self.visible or self.alpha <= 0 then return end
    
    love.graphics.push()
    
    -- Apply transform
    local centerX = self.x + self.width / 2
    local centerY = self.y + self.height / 2
    love.graphics.translate(centerX, centerY)
    love.graphics.scale(self.scale)
    love.graphics.rotate(self.rotation)
    love.graphics.translate(-centerX, -centerY)
    
    -- Draw glow effect
    if self.glowAlpha > 0 or self.selected then
        local glowAlpha = math.max(self.glowAlpha, self.selected and 0.5 or 0)
        love.graphics.setColor(Theme.colors.primary[1], Theme.colors.primary[2], 
                              Theme.colors.primary[3], glowAlpha * self.alpha)
        for i = 1, 3 do
            love.graphics.rectangle("line", self.x - i*2, self.y - i*2, 
                                  self.width + i*4, self.height + i*4, 
                                  Theme.layout.radiusSmall + i)
        end
    end
    
    -- Draw card background
    if self.cardAsset then
        love.graphics.setColor(1, 1, 1, self.alpha)
        love.graphics.draw(self.cardAsset, self.x, self.y, 0,
                          self.width / self.cardAsset:getWidth(),
                          self.height / self.cardAsset:getHeight())
    else
        -- Fallback drawing
        self:drawFallbackCard()
    end
    
    -- Draw card content
    if self.powerPlant then
        self:drawCardContent()
    end
    
    -- Draw sparkles
    self:drawSparkles()
    
    -- Draw energy particles
    self:drawEnergyParticles()
    
    love.graphics.pop()
end

function PowerPlantCard:drawFallbackCard()
    local resourceColor = Theme.getResourceColor(self.powerPlant.resourceType)
    
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.3 * self.alpha)
    love.graphics.rectangle("fill", self.x + 2, self.y + 2, self.width, self.height, Theme.layout.radiusSmall)
    
    -- Background
    love.graphics.setColor(resourceColor[1], resourceColor[2], resourceColor[3], 0.9 * self.alpha)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, Theme.layout.radiusSmall)
    
    -- Border
    love.graphics.setColor(Theme.colors.textPrimary[1], Theme.colors.textPrimary[2], 
                          Theme.colors.textPrimary[3], 0.8 * self.alpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, Theme.layout.radiusSmall)
end

function PowerPlantCard:drawCardContent()
    local plant = self.powerPlant
    
    -- Plant number (top left)
    love.graphics.setFont(self.numberFont)
    love.graphics.setColor(Theme.colors.textPrimary[1], Theme.colors.textPrimary[2], 
                          Theme.colors.textPrimary[3], self.alpha)
    love.graphics.print(tostring(plant.id or plant.cost), self.x + 8, self.y + 5)
    
    -- Resource icon and cost (bottom left)
    if self.resourceAsset then
        local iconSize = 24
        love.graphics.setColor(1, 1, 1, self.alpha)
        love.graphics.draw(self.resourceAsset, self.x + 8, self.y + self.height - iconSize - 8, 0,
                          iconSize / self.resourceAsset:getWidth(),
                          iconSize / self.resourceAsset:getHeight())
        
        -- Resource cost
        love.graphics.setFont(self.detailFont)
        love.graphics.setColor(Theme.colors.textPrimary[1], Theme.colors.textPrimary[2], 
                              Theme.colors.textPrimary[3], self.alpha)
        love.graphics.print("×" .. (plant.resourceCost or 1), self.x + 8 + iconSize + 4, 
                           self.y + self.height - iconSize - 4)
    end
    
    -- Power capacity (bottom right)
    love.graphics.setFont(self.numberFont)
    love.graphics.setColor(Theme.colors.warning[1], Theme.colors.warning[2], 
                          Theme.colors.warning[3], self.alpha)
    local capacityText = tostring(plant.capacity or 1)
    local textWidth = self.numberFont:getWidth(capacityText)
    love.graphics.print(capacityText, self.x + self.width - textWidth - 8, 
                       self.y + self.height - self.numberFont:getHeight() - 5)
    
    -- Power symbol
    love.graphics.setColor(Theme.colors.warning[1], Theme.colors.warning[2], 
                          Theme.colors.warning[3], self.alpha * 0.7)
    love.graphics.circle("fill", self.x + self.width - textWidth - 20, 
                        self.y + self.height - self.numberFont:getHeight()/2 - 5, 6)
    
    -- Plant type label (center)
    if plant.resourceType then
        love.graphics.setFont(self.detailFont)
        love.graphics.setColor(Theme.colors.textSecondary[1], Theme.colors.textSecondary[2], 
                              Theme.colors.textSecondary[3], self.alpha)
        local typeText = plant.resourceType:upper()
        local typeWidth = self.detailFont:getWidth(typeText)
        love.graphics.print(typeText, self.x + (self.width - typeWidth) / 2, self.y + 40)
    end
    
    -- Auction price (if in auction)
    if plant.currentBid and plant.currentBid > 0 then
        love.graphics.setFont(self.titleFont)
        love.graphics.setColor(Theme.colors.success[1], Theme.colors.success[2], 
                              Theme.colors.success[3], self.alpha)
        local bidText = "$" .. plant.currentBid
        local bidWidth = self.titleFont:getWidth(bidText)
        love.graphics.print(bidText, self.x + (self.width - bidWidth) / 2, self.y + 60)
    end
end

function PowerPlantCard:drawSparkles()
    for _, sparkle in ipairs(self.sparkles) do
        love.graphics.setColor(sparkle.color[1], sparkle.color[2], sparkle.color[3], sparkle.alpha * self.alpha)
        love.graphics.circle("fill", sparkle.x, sparkle.y, sparkle.size)
    end
end

function PowerPlantCard:drawEnergyParticles()
    for _, particle in ipairs(self.energyParticles) do
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], particle.alpha * self.alpha)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
    end
end

function PowerPlantCard:addSparkle(color)
    table.insert(self.sparkles, {
        x = self.x + math.random(0, self.width),
        y = self.y + self.height,
        size = math.random(2, 4),
        color = color or Theme.colors.warning,
        alpha = 1.0,
        life = 0.8
    })
end

function PowerPlantCard:addEnergyParticle()
    table.insert(self.energyParticles, {
        x = self.x + self.width / 2,
        y = self.y + self.height / 2,
        vx = math.random(-50, 50),
        vy = math.random(-50, 50),
        size = math.random(1, 3),
        color = Theme.getResourceColor(self.powerPlant.resourceType),
        alpha = 1.0,
        life = 0.5
    })
end

function PowerPlantCard:flash(color)
    self.glowAlpha = 1.0
    
    -- Add sparkles
    for i = 1, 3 do
        self:addSparkle(color)
    end
end

function PowerPlantCard:animate()
    -- Create energy particles
    for i = 1, 5 do
        self:addEnergyParticle()
    end
end

function PowerPlantCard:mousepressed(x, y, button)
    if not self.visible or not self.enabled or not self.clickable then return false end
    if button ~= 1 then return false end
    
    if self:contains(x, y) then
        self:flash(Theme.colors.primary)
        if self.onTap then
            self.onTap(self.powerPlant)
        end
        return true
    end
    return false
end

function PowerPlantCard:mousemoved(x, y)
    if not self.visible or not self.enabled then return end
    self.hovered = self:contains(x, y)
end

function PowerPlantCard:contains(x, y)
    return x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + self.height
end

function PowerPlantCard:setSelected(selected)
    self.selected = selected
    if selected then
        self:flash(Theme.colors.primary)
    end
end

function PowerPlantCard:setEnabled(enabled)
    self.enabled = enabled
end

function PowerPlantCard:setPowerPlant(powerPlant)
    self.powerPlant = powerPlant
    
    -- Reload assets if resource type changed
    if powerPlant then
        local plantType = string.lower(powerPlant.resourceType or "coal")
        self.cardAsset = AssetLoader.getPowerPlantCard(plantType)
        self.resourceAsset = AssetLoader.getResource(plantType)
    end
end

return PowerPlantCard