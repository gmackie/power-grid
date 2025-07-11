-- Bureaucracy Phase with network support
local BureaucracyPhase = {}
BureaucracyPhase.__index = BureaucracyPhase

local State = require("state")
local enums = require("models.enums")
local UI = require("ui")
local NetworkActions = require("network.network_actions")

function BureaucracyPhase.new()
    local self = setmetatable({}, BureaucracyPhase)
    self.phaseComplete = false
    self.currentPlayerIndex = 1
    self.selectedPlants = {}
    self.waitingForServer = false
    self.powerButton = UI.Button.new("Power Cities", 0, 0, 150, 40)
    self.skipButton = UI.Button.new("Skip", 0, 0, 100, 40)
    return self
end

function BureaucracyPhase:enter()
    print("Entering Bureaucracy Phase")
    self.phaseComplete = false
    self.currentPlayerIndex = 1
    self.selectedPlants = {}
    self.waitingForServer = false
    
    -- All players act simultaneously in bureaucracy phase
    State.bureaucracyComplete = {}
    for i = 1, #State.players do
        State.bureaucracyComplete[i] = false
    end
end

function BureaucracyPhase:exit()
    print("Exiting Bureaucracy Phase")
end

function BureaucracyPhase:update(dt)
    if self.phaseComplete then
        -- End of round - go back to player order
        State.currentPhase = enums.GamePhase.PLAYER_ORDER
        State.currentRound = (State.currentRound or 1) + 1
        self.phaseComplete = false
        return
    end
    
    local mx, my = love.mouse.getPosition()
    
    -- In online mode, check if we're done
    if NetworkActions.shouldWaitForServer() then
        -- Check if all players have completed bureaucracy
        local allComplete = true
        for i = 1, #State.players do
            if not State.bureaucracyComplete[i] then
                allComplete = false
                break
            end
        end
        if allComplete then
            self.phaseComplete = true
        end
    end
    
    -- Update buttons
    self.powerButton.x = love.graphics.getWidth()/2 - 75
    self.powerButton.y = love.graphics.getHeight() - 100
    self.skipButton.x = love.graphics.getWidth()/2 - 50
    self.skipButton.y = love.graphics.getHeight() - 50
    
    self.powerButton:update(mx, my)
    self.skipButton:update(mx, my)
end

function BureaucracyPhase:draw()
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Bureaucracy Phase", 0, 20, windowWidth, "center")
    
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf("Power your cities and earn income", 0, 60, windowWidth, "center")
    
    -- In online mode, show all players' status
    if NetworkActions.shouldWaitForServer() then
        self:drawAllPlayersStatus()
    else
        -- Offline mode - show current player
        self:drawCurrentPlayerStatus()
    end
    
    -- Draw waiting message if processing
    if self.waitingForServer then
        love.graphics.setColor(1, 1, 0.5, 1)
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.printf("Processing...", 0, windowHeight/2, windowWidth, "center")
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function BureaucracyPhase:drawAllPlayersStatus()
    local y = 120
    love.graphics.setFont(love.graphics.newFont(14))
    
    for i, player in ipairs(State.players) do
        local isLocalPlayer = false
        if State.networkGame and State.networkGame.localPlayerId then
            isLocalPlayer = player.id == State.networkGame.localPlayerId
        end
        
        -- Player name and status
        if State.bureaucracyComplete[i] then
            love.graphics.setColor(0.5, 0.8, 0.5, 1)
            love.graphics.print(player.name .. " - Complete", 50, y)
        else
            if isLocalPlayer then
                love.graphics.setColor(1, 1, 0.8, 1)
            else
                love.graphics.setColor(0.8, 0.8, 0.8, 1)
            end
            love.graphics.print(player.name .. " - Deciding...", 50, y)
        end
        
        -- Show player's power plants and cities
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print("Cities: " .. #player.cities, 250, y)
        love.graphics.print("Plants: " .. #player.powerPlants, 350, y)
        
        -- If local player and not complete, show controls
        if isLocalPlayer and not State.bureaucracyComplete[i] then
            self:drawPlayerControls(player, y + 30)
            y = y + 100
        else
            y = y + 25
        end
    end
end

function BureaucracyPhase:drawCurrentPlayerStatus()
    local currentPlayer = State.players[self.currentPlayerIndex]
    if not currentPlayer then return end
    
    local y = 120
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.print(currentPlayer.name .. "'s Turn", 50, y)
    
    y = y + 40
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("Cities owned: " .. #currentPlayer.cities, 50, y)
    
    -- Show power plants
    y = y + 30
    love.graphics.print("Power Plants:", 50, y)
    y = y + 25
    
    for i, plant in ipairs(currentPlayer.powerPlants) do
        local isSelected = self.selectedPlants[plant.id] ~= nil
        
        if isSelected then
            love.graphics.setColor(0.3, 0.8, 0.3, 1)
        else
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
        end
        
        local plantText = string.format("Plant #%d - Powers %d cities (%s)", 
            plant.id, plant.citiesPowered, plant.resourceType)
        love.graphics.print(plantText, 70, y)
        
        -- Show resource cost and availability
        if plant.resourcesRequired > 0 then
            local hasResources = self:playerHasResourcesForPlant(currentPlayer, plant)
            if hasResources then
                love.graphics.setColor(0.5, 0.8, 0.5, 1)
                love.graphics.print("Resources available", 400, y)
            else
                love.graphics.setColor(0.8, 0.5, 0.5, 1)
                love.graphics.print("Not enough resources", 400, y)
            end
        end
        
        y = y + 25
    end
    
    -- Show potential income
    y = y + 20
    love.graphics.setColor(1, 1, 0.8, 1)
    local citiesPowered = self:calculateCitiesPowered(currentPlayer)
    local income = self:calculateIncome(citiesPowered)
    love.graphics.print(string.format("Cities powered: %d/%d - Income: $%d", 
        citiesPowered, #currentPlayer.cities, income), 50, y)
    
    -- Draw buttons
    love.graphics.setColor(1, 1, 1, 1)
    if not State.bureaucracyComplete[self.currentPlayerIndex] then
        self.powerButton:draw()
        self.skipButton:draw()
    end
end

function BureaucracyPhase:drawPlayerControls(player, y)
    -- This would show the controls for the local player in online mode
    -- Similar to drawCurrentPlayerStatus but positioned differently
end

function BureaucracyPhase:mousepressed(x, y, button)
    if button == 1 then
        if self.waitingForServer then
            return
        end
        
        -- Check plant selection (offline mode)
        if not NetworkActions.shouldWaitForServer() then
            local currentPlayer = State.players[self.currentPlayerIndex]
            if currentPlayer then
                local plantY = 215
                for i, plant in ipairs(currentPlayer.powerPlants) do
                    if x >= 70 and x <= 600 and y >= plantY and y <= plantY + 25 then
                        -- Toggle plant selection
                        if self.selectedPlants[plant.id] then
                            self.selectedPlants[plant.id] = nil
                        else
                            if self:playerHasResourcesForPlant(currentPlayer, plant) then
                                self.selectedPlants[plant.id] = true
                            end
                        end
                        return
                    end
                    plantY = plantY + 25
                end
            end
        end
        
        -- Check power button
        if self.powerButton:isHovered(x, y) then
            local plantIds = {}
            for plantId, _ in pairs(self.selectedPlants) do
                table.insert(plantIds, plantId)
            end
            
            if NetworkActions.shouldWaitForServer() then
                self.waitingForServer = true
                NetworkActions.powerCities(plantIds)
            else
                -- Offline mode
                self:powerCities(plantIds)
            end
            return
        end
        
        -- Check skip button
        if self.skipButton:isHovered(x, y) then
            if NetworkActions.shouldWaitForServer() then
                self.waitingForServer = true
                NetworkActions.powerCities({}) -- Empty array means no plants used
            else
                -- Offline mode
                self:skipPowerGeneration()
            end
            return
        end
    end
end

function BureaucracyPhase:powerCities(plantIds)
    local currentPlayer = State.players[self.currentPlayerIndex]
    if not currentPlayer then return end
    
    -- Calculate cities powered and income
    local citiesPowered = 0
    for _, plantId in ipairs(plantIds) do
        for _, plant in ipairs(currentPlayer.powerPlants) do
            if plant.id == plantId then
                citiesPowered = citiesPowered + plant.citiesPowered
                -- Consume resources (in offline mode)
                if not NetworkActions.shouldWaitForServer() then
                    self:consumeResourcesForPlant(currentPlayer, plant)
                end
                break
            end
        end
    end
    
    -- Cap at actual cities owned
    citiesPowered = math.min(citiesPowered, #currentPlayer.cities)
    
    -- Calculate and award income (offline mode)
    if not NetworkActions.shouldWaitForServer() then
        local income = self:calculateIncome(citiesPowered)
        currentPlayer.money = currentPlayer.money + income
        print(currentPlayer.name .. " powered " .. citiesPowered .. " cities and earned $" .. income)
        
        -- Move to next player
        self:advanceToNextPlayer()
    else
        -- Mark this player as complete
        State.bureaucracyComplete[self.currentPlayerIndex] = true
        self.waitingForServer = false
    end
    
    self.selectedPlants = {}
end

function BureaucracyPhase:skipPowerGeneration()
    local currentPlayer = State.players[self.currentPlayerIndex]
    if currentPlayer then
        print(currentPlayer.name .. " skipped power generation")
        
        if NetworkActions.shouldWaitForServer() then
            State.bureaucracyComplete[self.currentPlayerIndex] = true
            self.waitingForServer = false
        else
            -- Still get base income
            currentPlayer.money = currentPlayer.money + 10
            self:advanceToNextPlayer()
        end
    end
end

function BureaucracyPhase:advanceToNextPlayer()
    self.currentPlayerIndex = self.currentPlayerIndex + 1
    if self.currentPlayerIndex > #State.players then
        -- All players done - refresh markets
        self:refreshMarkets()
        self.phaseComplete = true
    end
end

function BureaucracyPhase:refreshMarkets()
    -- In online mode, server handles this
    if not NetworkActions.shouldWaitForServer() then
        print("Refreshing markets...")
        -- TODO: Implement market refresh logic
    end
end

function BureaucracyPhase:playerHasResourcesForPlant(player, plant)
    if plant.resourcesRequired == 0 then
        return true -- Wind/renewable
    end
    
    local resources = player.resources or {}
    local required = plant.resourcesRequired
    
    if plant.resourceType == "Coal" then
        return (resources.coal or 0) >= required
    elseif plant.resourceType == "Oil" then
        return (resources.oil or 0) >= required
    elseif plant.resourceType == "Garbage" then
        return (resources.garbage or 0) >= required
    elseif plant.resourceType == "Uranium" then
        return (resources.uranium or 0) >= required
    elseif plant.resourceType == "Hybrid" then
        -- Can use coal or oil
        return ((resources.coal or 0) >= required) or ((resources.oil or 0) >= required)
    end
    
    return false
end

function BureaucracyPhase:consumeResourcesForPlant(player, plant)
    if plant.resourcesRequired == 0 then return end
    
    local resources = player.resources or {}
    local required = plant.resourcesRequired
    
    if plant.resourceType == "Coal" and resources.coal >= required then
        resources.coal = resources.coal - required
    elseif plant.resourceType == "Oil" and resources.oil >= required then
        resources.oil = resources.oil - required
    elseif plant.resourceType == "Garbage" and resources.garbage >= required then
        resources.garbage = resources.garbage - required
    elseif plant.resourceType == "Uranium" and resources.uranium >= required then
        resources.uranium = resources.uranium - required
    elseif plant.resourceType == "Hybrid" then
        -- Prefer coal over oil
        if resources.coal >= required then
            resources.coal = resources.coal - required
        elseif resources.oil >= required then
            resources.oil = resources.oil - required
        end
    end
    
    player.resources = resources
end

function BureaucracyPhase:calculateCitiesPowered(player)
    local total = 0
    for plantId, _ in pairs(self.selectedPlants) do
        for _, plant in ipairs(player.powerPlants) do
            if plant.id == plantId then
                total = total + plant.citiesPowered
                break
            end
        end
    end
    return math.min(total, #player.cities)
end

function BureaucracyPhase:calculateIncome(citiesPowered)
    -- Power Grid income table
    local incomeTable = {
        [0] = 10,
        [1] = 22,
        [2] = 33,
        [3] = 44,
        [4] = 54,
        [5] = 64,
        [6] = 73,
        [7] = 82,
        [8] = 90,
        [9] = 98,
        [10] = 105,
        [11] = 112,
        [12] = 118,
        [13] = 124,
        [14] = 129,
        [15] = 134,
        [16] = 138,
        [17] = 142,
        [18] = 145,
        [19] = 148,
        [20] = 150
    }
    
    if citiesPowered > 20 then
        return 150
    end
    
    return incomeTable[citiesPowered] or 10
end

return BureaucracyPhase