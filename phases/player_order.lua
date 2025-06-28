local PlayerOrderPhase = {}
PlayerOrderPhase.__index = PlayerOrderPhase

local State = require("state") -- Ensure State is required

function PlayerOrderPhase.new()
    local self = setmetatable({}, PlayerOrderPhase)
    self.orderDetermined = false 
    return self
end

function PlayerOrderPhase:enter()
    print("Entering Player Order Phase")
    self.orderDetermined = false -- Reset flag
    
    -- Perform sorting immediately
    if State.players and #State.players > 0 then
        table.sort(State.players, function(a, b)
            local aCities = a:getTotalCities()
            local bCities = b:getTotalCities()
            if aCities ~= bCities then
                return aCities < bCities -- Player with fewer cities comes first in array (goes first in player order)
            end
            
            local aHighestPlant = 0
            for _, plant in ipairs(a.powerPlants) do aHighestPlant = math.max(aHighestPlant, plant.id) end
            local bHighestPlant = 0
            for _, plant in ipairs(b.powerPlants) do bHighestPlant = math.max(bHighestPlant, plant.id) end
            
            return aHighestPlant < bHighestPlant -- Player with lower highest plant comes first
        end)
        print("Player order determined.")
        for i,p in ipairs(State.players) do print(i .. ": " .. p.name) end
    else
        print("No players to sort for player order.")
    end
    
    -- Player order phase is usually instant after calculation
    self.orderDetermined = true 
end

function PlayerOrderPhase:update(dt)
    -- Sorting is done in enter(), so this phase completes quickly.
    -- No continuous update logic needed for player order determination itself.
end

function PlayerOrderPhase:draw()
    local windowWidth = love.graphics.getWidth()
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Determining Player Order...", 0, 200, windowWidth, "center")
    
    if State.players and #State.players > 0 then
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.printf("Player Order (Auction/Build Turn - Last to First):", 0, 250, windowWidth, "center")
        for i, player in ipairs(State.players) do
            local y = 280 + (i-1) * 30
            local playerColor = player.color or {0.7,0.7,0.7,1}
            love.graphics.setColor(playerColor[1], playerColor[2], playerColor[3], playerColor[4])
            love.graphics.rectangle("fill", windowWidth/2 - 150, y, 20, 20, 4)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(i .. ". " .. player.name, windowWidth/2 - 120, y)
            love.graphics.print("Cities: " .. player:getTotalCities(), windowWidth/2 + 30, y)
            local highestPlant = 0
            for _,p_plant in ipairs(player.powerPlants) do highestPlant = math.max(highestPlant, p_plant.id) end
            love.graphics.print("Highest Plant: " .. highestPlant, windowWidth/2 + 120, y)
        end
    else
        love.graphics.printf("No players to display order for.",0, 280, windowWidth, "center")
    end
end

function PlayerOrderPhase:mousepressed(x, y, button)
    -- No-op for now
end

function PlayerOrderPhase:mousemoved(x, y)
    -- No-op for now
end

function PlayerOrderPhase:mousereleased(x, y, button)
    -- No-op for now
end

function PlayerOrderPhase:keypressed(key)
    -- No-op for now
end

function PlayerOrderPhase:textinput(t)
    -- No-op for now
end

function PlayerOrderPhase:isPhaseComplete()
    if self.orderDetermined then
        self.orderDetermined = false -- Reset for next time
        print("PlayerOrderPhase complete.")
        return true
    end
    return false
end

return PlayerOrderPhase 