-- AI Player for automated testing
-- Provides simple decision-making logic for different game phases

local AIPlayer = {}
AIPlayer.__index = AIPlayer

function AIPlayer.new(name, difficulty)
    local self = setmetatable({}, AIPlayer)
    self.name = name or "AI Player"
    self.difficulty = difficulty or "easy" -- easy, medium, hard
    self.behaviorStyle = "balanced" -- aggressive, conservative, balanced
    return self
end

-- Make a decision for the auction phase
function AIPlayer:makeAuctionDecision(gameState, availablePlants, currentBid)
    local decision = {
        action = "pass", -- bid, nominate, pass
        plant = nil,
        bidAmount = 0
    }
    
    if self.difficulty == "easy" then
        -- Easy AI: Very simple logic
        if currentBid == 0 and availablePlants and #availablePlants > 0 then
            -- Nominate the cheapest plant
            local cheapestPlant = availablePlants[1]
            for _, plant in ipairs(availablePlants) do
                if plant.cost < cheapestPlant.cost then
                    cheapestPlant = plant
                end
            end
            decision.action = "nominate"
            decision.plant = cheapestPlant
            decision.bidAmount = cheapestPlant.cost
        elseif currentBid > 0 and currentBid < 30 then
            -- Bid a little higher if it's cheap
            decision.action = "bid"
            decision.bidAmount = currentBid + math.random(1, 3)
        else
            decision.action = "pass"
        end
    else
        -- More sophisticated logic for medium/hard AI
        decision.action = "pass" -- Default to pass for now
    end
    
    return decision
end

-- Make a decision for the resource buying phase
function AIPlayer:makeResourceDecision(gameState, player, resourceMarket)
    local decision = {
        action = "pass", -- buy, pass
        resourceType = nil,
        amount = 1,
        targetPlant = nil
    }
    
    -- Simple logic: buy cheapest available resource if we have power plants that need it
    if player.powerPlants and #player.powerPlants > 0 then
        for _, plant in ipairs(player.powerPlants) do
            if plant.resourceType and plant.resourceType ~= "none" then
                local currentStored = plant.storedResources or 0
                local capacity = plant.capacity * 2 -- Assume 2x capacity for storage
                
                if currentStored < capacity and player.money > 5 then
                    decision.action = "buy"
                    decision.resourceType = plant.resourceType
                    decision.targetPlant = plant
                    break
                end
            end
        end
    end
    
    return decision
end

-- Make a decision for the building phase
function AIPlayer:makeBuildingDecision(gameState, player, availableCities)
    local decision = {
        action = "pass", -- build, pass
        city = nil
    }
    
    -- Simple logic: build in the cheapest available city if we have money
    if player.money > 15 and availableCities and #availableCities > 0 then
        local cheapestCity = nil
        local cheapestCost = 999
        
        for _, city in ipairs(availableCities) do
            -- Calculate rough building cost (simplified)
            local houseCost = 10 + (#city.houses * 5)
            local connectionCost = (#player.cities == 0) and 0 or 5 -- Simplified
            local totalCost = houseCost + connectionCost
            
            if totalCost < cheapestCost and totalCost <= player.money then
                cheapestCity = city
                cheapestCost = totalCost
            end
        end
        
        if cheapestCity then
            decision.action = "build"
            decision.city = cheapestCity
        end
    end
    
    return decision
end

-- Get coordinates for clicking on a city (for simulator)
function AIPlayer:getCityClickCoords(city)
    -- Map offset from building phase drawing
    local mapOffsetX, mapOffsetY = 200, 100
    return city.x + mapOffsetX, city.y + mapOffsetY
end

-- Get UI element coordinates (approximate)
function AIPlayer:getUICoords(element)
    local coords = {
        passAndPlay = {800, 400},
        nameInput = {400, 300},
        addPlayerButton = {600, 350},
        startGameButton = {800, 500},
        passButton = "p", -- Keyboard shortcut
        colors = {
            {450, 400}, -- First color
            {500, 400}, -- Second color
            {550, 400}, -- Third color
            {600, 400}, -- Fourth color
        }
    }
    
    return coords[element]
end

-- Generate a random AI name
function AIPlayer.generateName()
    local firstNames = {"Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry"}
    local lastNames = {"Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis"}
    
    local firstName = firstNames[math.random(#firstNames)]
    local lastName = lastNames[math.random(#lastNames)]
    
    return firstName .. " " .. lastName
end

-- Create multiple AI players
function AIPlayer.createTeam(count, difficulty)
    local team = {}
    local usedNames = {}
    
    for i = 1, count do
        local name = AIPlayer.generateName()
        
        -- Ensure unique names
        while usedNames[name] do
            name = AIPlayer.generateName()
        end
        usedNames[name] = true
        
        local ai = AIPlayer.new(name, difficulty)
        table.insert(team, ai)
    end
    
    return team
end

return AIPlayer