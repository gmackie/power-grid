local BureaucracyPhase = {}
BureaucracyPhase.__index = BureaucracyPhase

local State = require("state") -- Ensure State is required

function BureaucracyPhase.new()
    local self = setmetatable({}, BureaucracyPhase)
    self.phaseComplete = false -- Add phase complete flag
    self.incomeCalculated = false
    self.showingResults = false
    self.resultsDisplayTime = 0
    return self
end

function BureaucracyPhase:enter()
    print("Entering Bureaucracy Phase")
    self.phaseComplete = false
    self.incomeCalculated = false
    self.showingResults = false
    self.resultsDisplayTime = 0
    
    -- Automatically calculate income and refresh market
    self:calculateIncome()
    self:refreshResourceMarket()
    self:refreshPowerPlantMarket()
    
    self.incomeCalculated = true
    self.showingResults = true
end

function BureaucracyPhase:update(dt)
    if self.showingResults then
        self.resultsDisplayTime = self.resultsDisplayTime + dt
        -- Auto-advance after 3 seconds
        if self.resultsDisplayTime > 3.0 then
            self.phaseComplete = true
        end
    end
end

function BureaucracyPhase:draw()
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Bureaucracy Phase", 0, 30, windowWidth, "center")
    
    if self.incomeCalculated then
        -- Show income results
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.printf("Round Complete - Income Earned", 0, 80, windowWidth, "center")
        
        if State.players and #State.players > 0 then
            local yPos = 130
            love.graphics.setFont(love.graphics.newFont(16))
            
            for i, player in ipairs(State.players) do
                local citiesPowered = player.citiesPowered or 0
                local income = player.lastIncome or 0
                local powerUsed = player.lastPowerUsed or 0
                
                love.graphics.printf(
                    player.name .. ": " .. citiesPowered .. " cities powered, earned $" .. income,
                    0, yPos + (i-1)*30, windowWidth, "center"
                )
                
                -- Show resources consumed
                if powerUsed > 0 then
                    love.graphics.setFont(love.graphics.newFont(12))
                    love.graphics.printf(
                        "Consumed " .. powerUsed .. " resources",
                        0, yPos + (i-1)*30 + 18, windowWidth, "center"
                    )
                    love.graphics.setFont(love.graphics.newFont(16))
                end
            end
        end
        
        -- Show market refresh status
        local yPos = 130 + (#State.players * 35) + 30
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.printf("✓ Resource market restocked", 0, yPos, windowWidth, "center")
        love.graphics.printf("✓ Power plant market updated", 0, yPos + 20, windowWidth, "center")
        
        -- Auto-advance timer
        local remainingTime = math.max(0, 3.0 - self.resultsDisplayTime)
        love.graphics.printf("Advancing in " .. math.ceil(remainingTime) .. " seconds (or press C)", 0, windowHeight - 50, windowWidth, "center")
    else
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.printf("Calculating income and updating markets...", 0, windowHeight/2, windowWidth, "center")
    end
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

-- Helper functions
function BureaucracyPhase:calculateIncome()
    print("Calculating player income...")
    
    for _, player in ipairs(State.players) do
        -- Calculate how many cities can be powered
        local totalPower = self:calculatePlayerPower(player)
        local citiesOwned = #player.cities
        local citiesPowered = math.min(totalPower, citiesOwned)
        
        -- Calculate income based on cities powered
        local income = self:getIncomeForCities(citiesPowered)
        
        -- Update player data
        player.citiesPowered = citiesPowered
        player.lastIncome = income
        player.lastPowerUsed = math.min(totalPower, citiesOwned) -- Resources consumed
        player.money = player.money + income
        
        print(player.name .. " powered " .. citiesPowered .. " cities, earned $" .. income)
    end
end

function BureaucracyPhase:calculatePlayerPower(player)
    local totalPower = 0
    
    -- For each power plant, check if it has enough resources to operate
    for _, plant in ipairs(player.powerPlants) do
        if plant.resourceCost == 0 then
            -- Free power plants (wind, solar, etc.) always produce power
            totalPower = totalPower + plant.capacity
        else
            -- Check if plant has enough resources stored
            local availableResources = plant.storedResources or 0
            local operatingCapacity = math.floor(availableResources / plant.resourceCost)
            local actualPower = math.min(operatingCapacity, plant.capacity)
            totalPower = totalPower + actualPower
            
            -- Consume resources (simplified - just subtract what was used)
            plant.storedResources = (plant.storedResources or 0) - (actualPower * plant.resourceCost)
            plant.storedResources = math.max(0, plant.storedResources)
        end
    end
    
    return totalPower
end

function BureaucracyPhase:getIncomeForCities(citiesPowered)
    -- Standard Power Grid income table
    local incomeTable = {
        [0] = 10,   -- 0 cities
        [1] = 22,   -- 1 city
        [2] = 33,   -- 2 cities
        [3] = 44,   -- 3 cities
        [4] = 54,   -- 4 cities
        [5] = 64,   -- 5 cities
        [6] = 73,   -- 6 cities
        [7] = 82,   -- 7 cities
        [8] = 90,   -- 8 cities
        [9] = 98,   -- 9 cities
        [10] = 105, -- 10 cities
        [11] = 112, -- 11 cities
        [12] = 118, -- 12 cities
        [13] = 124, -- 13 cities
        [14] = 129, -- 14 cities
        [15] = 134, -- 15 cities
        [16] = 138, -- 16 cities
        [17] = 142, -- 17 cities
        [18] = 145, -- 18 cities
        [19] = 148, -- 19 cities
        [20] = 150  -- 20 cities
    }
    
    return incomeTable[citiesPowered] or (citiesPowered > 20 and 150 or 10)
end

function BureaucracyPhase:refreshResourceMarket()
    if not State.resourceMarket then
        print("No resource market to refresh")
        return
    end
    
    -- Simplified resource market refresh
    -- In a full implementation, this would follow complex rules based on player count and consumption
    local resourceTypes = {"coal", "oil", "garbage", "uranium"}
    
    for _, resourceType in ipairs(resourceTypes) do
        if State.resourceMarket[resourceType] then
            -- Add some resources back to the market (simplified)
            local replenishAmount = #State.players -- Rough approximation
            if resourceType == "uranium" then
                replenishAmount = math.ceil(replenishAmount / 2) -- Uranium restocks less
            end
            
            -- Add to the lowest cost space available
            for step = 1, 8 do -- 8 price steps in Power Grid
                if State.resourceMarket[resourceType][step] then
                    local currentAmount = State.resourceMarket[resourceType][step]
                    local maxCapacity = (step <= 3) and 3 or 1 -- First 3 spaces hold 3, others hold 1
                    local canAdd = math.min(replenishAmount, maxCapacity - currentAmount)
                    
                    if canAdd > 0 then
                        State.resourceMarket[resourceType][step] = currentAmount + canAdd
                        replenishAmount = replenishAmount - canAdd
                        
                        if replenishAmount <= 0 then
                            break
                        end
                    end
                end
            end
        end
    end
    
    print("Resource market restocked")
end

function BureaucracyPhase:refreshPowerPlantMarket()
    -- Simplified power plant market refresh
    -- In a full implementation, this would handle the current/future market, 
    -- removing lowest plant if someone bought one, adding from deck, etc.
    
    if not State.powerPlantMarket or #State.powerPlantMarket == 0 then
        print("No power plant market to refresh")
        return
    end
    
    -- For now, just shuffle the market (very simplified)
    -- In a real game, you'd remove the lowest numbered plant and add a new one from the deck
    print("Power plant market updated (simplified)")
    
    -- TODO: Implement proper power plant market management:
    -- - Remove lowest numbered plant if any plants were bought
    -- - Add new plants from deck to replace bought plants
    -- - Handle Step 2 and Step 3 transitions
    -- - Manage current/future market split
end

return BureaucracyPhase 