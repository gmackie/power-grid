local BuildingPhase = {}
BuildingPhase.__index = BuildingPhase

local State = require("state") -- Ensure State is required

function BuildingPhase.new()
    local self = setmetatable({}, BuildingPhase)
    self.selectedCity = nil
    self.phaseComplete = false -- Add phase complete flag
    return self
end

function BuildingPhase:enter()
    print("Entering Building Phase")
    self.phaseComplete = false
    -- TODO: Implement logic for player turns in reverse order
end

function BuildingPhase:update(dt)
    -- No-op for now
end

function BuildingPhase:draw()
    local windowWidth = love.graphics.getWidth()
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Building Phase", 0, 200, windowWidth, "center")
    
    local currentPlayer = State.players[State.currentPlayerIndex]
    if currentPlayer then
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.printf(currentPlayer.name .. "'s Turn to Build", 0, 250, windowWidth, "center")
        
        -- Display player's current cities (if any)
        if #currentPlayer.cities > 0 then
            local cityY = 300
            love.graphics.print("Current cities: ", windowWidth/2 - 200, cityY)
            for i, city in ipairs(currentPlayer.cities) do
                -- Assuming city object has name, x, y properties for drawing if needed
                love.graphics.print(city.name, windowWidth/2 - 100, cityY + i * 20)
            end
        else
            love.graphics.printf("No cities yet.", 0, 300, windowWidth, "center")
        end
        -- TODO: Draw map, available cities, costs etc.
    else
        love.graphics.printf("No current player for Building Phase.", 0, 250, windowWidth, "center")
    end
    love.graphics.printf("Press 'C' to complete Building Phase (Dev)", 0, love.graphics.getHeight() - 50, windowWidth, "center")
end

function BuildingPhase:mousepressed(x, y, button)
    -- No-op for now, will handle city selection/building
end

function BuildingPhase:keypressed(key)
    if key == "c" then -- Dev key to complete phase
        self.phaseComplete = true
    end
end

function BuildingPhase:isPhaseComplete()
    if self.phaseComplete then
        self.phaseComplete = false -- Reset for next time
        return true
    end
    return false
end

return BuildingPhase 