local PlayerPanel = {}
PlayerPanel.__index = PlayerPanel

local State = require("state")
local enums = require("models.enums") -- Assuming enums.ResourceType is used for player resources

function PlayerPanel.new()
    local self = setmetatable({}, PlayerPanel)
    
    self.x = 0
    self.y = 0
    self.panelHeight = 150 -- Increased height to accommodate more info per player
    self.panelWidth = love.graphics.getWidth()
    
    self.backgroundColor = {0.15, 0.15, 0.18, 0.95}
    self.borderColor = {0.4, 0.4, 0.4, 1}
    self.defaultTextColor = {1, 1, 1, 1}
    self.font = love.graphics.newFont(16)
    self.smallFont = love.graphics.newFont(12)
    
    return self
end

function PlayerPanel:update(dt)
    self.panelWidth = love.graphics.getWidth() -- Update width if window resizes
end

function PlayerPanel:draw()
    love.graphics.setFont(self.font)
    
    -- Draw panel background
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.panelWidth, self.panelHeight)
    love.graphics.setColor(self.borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x, self.y, self.panelWidth, self.panelHeight)
    love.graphics.setLineWidth(1)

    local players = State.players
    local playerCount = #players
    if playerCount == 0 then return end

    local sectionWidth = self.panelWidth / playerCount
    local padding = 10

    for i, player in ipairs(players) do
        local startX = self.x + (i-1) * sectionWidth
        
        -- Player Name and Color indicator
        love.graphics.setColor(player.color or self.defaultTextColor)
        love.graphics.rectangle("fill", startX + padding, self.y + padding, sectionWidth - 2 * padding, 5) -- Color bar
        love.graphics.setColor(self.defaultTextColor)
        love.graphics.printf(player.name, startX + padding, self.y + padding + 10, sectionWidth - 2 * padding, "left")

        -- Money
        love.graphics.printf("Money: $" .. player.money, startX + padding, self.y + padding + 30, sectionWidth - 2 * padding, "left")

        -- Resources (Summary)
        love.graphics.setFont(self.smallFont)
        local resourceTextY = self.y + padding + 50
        local resourceIconSize = 8
        local resourceSpacingX = 70
        local currentResourceX = startX + padding

        love.graphics.setColor(self.defaultTextColor)
        love.graphics.print("Resources:", currentResourceX, resourceTextY)
        resourceTextY = resourceTextY + 15

        for resourceType, count in pairs(player.resources) do
            if count > 0 then -- Only show resources player has
                local resourceColor = player:getResourceColor(resourceType) -- Assuming Player model has this
                love.graphics.setColor(resourceColor or self.defaultTextColor)
                love.graphics.circle("fill", currentResourceX + resourceIconSize, resourceTextY + resourceIconSize/2, resourceIconSize)
                love.graphics.setColor(self.defaultTextColor)
                love.graphics.print(string.format("%s: %d", resourceType, count), currentResourceX + resourceIconSize*2 + 5, resourceTextY)
                currentResourceX = currentResourceX + resourceSpacingX
                if currentResourceX > startX + sectionWidth - padding - resourceSpacingX then -- new row if needed
                    currentResourceX = startX + padding
                    resourceTextY = resourceTextY + 15
                end
            end
        end
        
        -- Power Plants
        love.graphics.setFont(self.smallFont)
        local plantTextY = self.y + padding + 95
        love.graphics.setColor(self.defaultTextColor)
        love.graphics.print("Power Plants:", startX + padding, plantTextY)
        plantTextY = plantTextY + 15

        if player.powerPlants and #player.powerPlants > 0 then
            local plantInfoFont = love.graphics.newFont(10) -- Smaller font for details
            local oldFont = love.graphics.getFont()
            love.graphics.setFont(plantInfoFont)
            
            local plantStartX = startX + padding
            local plantBoxWidth = (sectionWidth - 2 * padding) / math.max(1, #player.powerPlants) - 5
            plantBoxWidth = math.max(50, plantBoxWidth) -- Minimum width
            local plantBoxHeight = self.panelHeight - (plantTextY - self.y) - padding - 5

            for pp_idx, p_plant in ipairs(player.powerPlants) do
                local currentPlantX = plantStartX + (pp_idx - 1) * (plantBoxWidth + 5)
                if currentPlantX + plantBoxWidth > startX + sectionWidth - padding then break end -- Avoid overflow

                local p_color = p_plant:getResourceColor() or {0.3,0.3,0.3,1}
                love.graphics.setColor(p_color[1]*0.7, p_color[2]*0.7, p_color[3]*0.7, p_color[4])
                love.graphics.rectangle("fill", currentPlantX, plantTextY, plantBoxWidth, plantBoxHeight)
                love.graphics.setColor(self.defaultTextColor)
                love.graphics.setLineWidth(1)
                love.graphics.rectangle("line", currentPlantX, plantTextY, plantBoxWidth, plantBoxHeight)

                local textX = currentPlantX + 3
                local textY = plantTextY + 3
                local lineH = 11

                love.graphics.print(string.format("#%d (%dc)", p_plant.id, p_plant.capacity), textX, textY)
                textY = textY + lineH
                love.graphics.print(string.format("%s", p_plant.resourceType), textX, textY)
                textY = textY + lineH
                love.graphics.print(string.format("Cost: %d", p_plant.resourceCost), textX, textY)
                textY = textY + lineH
                love.graphics.print(string.format("Stored: %d", p_plant:getResourceStoredCount()), textX, textY)
            end
            love.graphics.setFont(oldFont)
        else
            love.graphics.print("None", startX + padding, plantTextY)
        end
        love.graphics.setFont(self.font) -- Reset font to panel's default if changed
    end
end

-- Ensure setPlayer is removed if not used, or adapted if a single player focus is needed elsewhere
-- For now, this panel shows all players, so setPlayer is not directly used for its main draw loop.
function PlayerPanel:setPlayer(player)
    -- This function might become obsolete or be repurposed if the panel always shows all players.
    -- self.player = player 
end

function PlayerPanel:mousepressed(x, y, button)
    -- No-op for now
end

function PlayerPanel:mousemoved(x, y, dx, dy)
    -- No-op for now
end

return PlayerPanel 