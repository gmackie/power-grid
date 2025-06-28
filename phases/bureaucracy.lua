local BureaucracyPhase = {}
BureaucracyPhase.__index = BureaucracyPhase

local State = require("state") -- Ensure State is required

function BureaucracyPhase.new()
    local self = setmetatable({}, BureaucracyPhase)
    self.phaseComplete = false -- Add phase complete flag
    return self
end

function BureaucracyPhase:enter()
    print("Entering Bureaucracy Phase")
    self.phaseComplete = false
    -- TODO: Implement logic: players earn money, replenish resources, update market
end

function BureaucracyPhase:update(dt)
    -- No-op for now
end

function BureaucracyPhase:draw()
    local windowWidth = love.graphics.getWidth()
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Bureaucracy Phase", 0, 200, windowWidth, "center")
    
    -- Display summary or actions for bureaucracy
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf("Players earn income based on cities powered.", 0, 250, windowWidth, "center")
    love.graphics.printf("Resource market restocks.", 0, 280, windowWidth, "center")
    love.graphics.printf("Power plant market updates.", 0, 310, windowWidth, "center")

    -- Example: Show player money after income (conceptual)
    if State.players and #State.players > 0 then
        local yPos = 350
        love.graphics.printf("Player Income (Example):", 0, yPos, windowWidth, "center")
        yPos = yPos + 30
        for i, player in ipairs(State.players) do
            love.graphics.printf(player.name .. ": $" .. player.money .. " (+" .. (player.lastIncome or 0) .. ")", 0, yPos + (i-1)*25, windowWidth, "center")
        end
    end
    love.graphics.printf("Press 'C' to complete Bureaucracy Phase (Dev)", 0, love.graphics.getHeight() - 50, windowWidth, "center")
end

function BureaucracyPhase:mousepressed(x, y, button)
    -- No-op for now
end

function BureaucracyPhase:keypressed(key)
    if key == "c" then -- Dev key to complete phase
        self.phaseComplete = true
    end
end

function BureaucracyPhase:isPhaseComplete()
    if self.phaseComplete then
        self.phaseComplete = false -- Reset for next time
        return true
    end
    return false
end

return BureaucracyPhase 