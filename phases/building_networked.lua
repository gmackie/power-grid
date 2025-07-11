-- Building Phase with network support
local BuildingPhase = {}
BuildingPhase.__index = BuildingPhase

local State = require("state")
local enums = require("models.enums")
local UI = require("ui")
local NetworkActions = require("network.network_actions")

function BuildingPhase.new()
    local self = setmetatable({}, BuildingPhase)
    self.selectedCity = nil
    self.phaseComplete = false
    self.buildingOrder = {}
    self.currentBuilderIndex = 1
    self.playersWhoPassedBuilding = {}
    self.waitingForServer = false
    self.passButton = UI.Button.new("Pass Turn", 0, 0, 120, 40)
    self.buildButton = UI.Button.new("Build Here", 0, 0, 150, 40)
    return self
end

function BuildingPhase:enter()
    print("Entering Building Phase")
    self.phaseComplete = false
    self.selectedCity = nil
    self.playersWhoPassedBuilding = {}
    self.waitingForServer = false
    
    -- Set up building order (reverse player order)
    self.buildingOrder = {}
    if State.turnOrder and #State.turnOrder > 0 then
        -- Use turn order from server if available
        for i = #State.turnOrder, 1, -1 do
            -- Find player index for this player ID
            for j, player in ipairs(State.players) do
                if player.id == State.turnOrder[i] then
                    table.insert(self.buildingOrder, j)
                    break
                end
            end
        end
    else
        -- Fallback to local order
        for i = #State.players, 1, -1 do
            table.insert(self.buildingOrder, i)
        end
    end
    self.currentBuilderIndex = 1
end

function BuildingPhase:exit()
    print("Exiting Building Phase")
end

function BuildingPhase:update(dt)
    if self.phaseComplete then
        State.currentPhase = enums.GamePhase.BUREAUCRACY
        self.phaseComplete = false
        return
    end
    
    local mx, my = love.mouse.getPosition()
    
    -- Check if waiting for other players
    if NetworkActions.isWaitingForOthers() then
        self.waitingForServer = true
        return
    else
        self.waitingForServer = false
    end
    
    -- Update buttons
    self.passButton.x = love.graphics.getWidth() - 140
    self.passButton.y = love.graphics.getHeight() - 50
    self.passButton:update(mx, my)
    
    if self.selectedCity then
        self.buildButton.x = love.graphics.getWidth()/2 - 75
        self.buildButton.y = love.graphics.getHeight() - 100
        self.buildButton:update(mx, my)
    end
end

function BuildingPhase:draw()
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Building Phase", 0, 20, windowWidth, "center")
    
    -- Draw waiting message if not our turn
    if self.waitingForServer or NetworkActions.isWaitingForOthers() then
        love.graphics.setColor(1, 1, 0.5, 1)
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.printf("Waiting for other players...", 0, windowHeight/2 - 50, windowWidth, "center")
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.setColor(1, 1, 1, 1)
        return
    end
    
    -- Get current builder
    local currentBuilderPlayerIndex = self.buildingOrder[self.currentBuilderIndex]
    local currentPlayer = State.players[currentBuilderPlayerIndex]
    
    if currentPlayer then
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.printf(currentPlayer.name .. "'s Turn to Build (Money: $" .. currentPlayer.money .. ")", 0, 60, windowWidth, "center")
        
        -- Draw map
        if State.map and State.map.cities then
            self:drawMap()
        end
        
        -- Draw selected city info
        if self.selectedCity then
            local cost = self:calculateBuildingCost(self.selectedCity, currentPlayer)
            love.graphics.setFont(love.graphics.newFont(16))
            love.graphics.setColor(1, 1, 0.8, 1)
            love.graphics.printf("Selected: " .. self.selectedCity.name .. " - Cost: $" .. cost, 0, windowHeight - 150, windowWidth, "center")
            love.graphics.setColor(1, 1, 1, 1)
            self.buildButton:draw()
        end
        
        -- Draw pass button
        if not self.playersWhoPassedBuilding[currentBuilderPlayerIndex] then
            self.passButton:draw()
        end
        
        -- Display player's cities
        if #currentPlayer.cities > 0 then
            love.graphics.setFont(love.graphics.newFont(12))
            love.graphics.print("Your cities: " .. table.concat(currentPlayer.cities, ", "), 10, windowHeight - 20)
        end
    end
end

function BuildingPhase:drawMap()
    if not State.map or not State.map.cities then return end
    
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2
    local mapScale = 0.8
    
    -- Draw connections first
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.setLineWidth(2)
    if State.map.connections then
        for _, connection in ipairs(State.map.connections) do
            local city1 = self:findCityById(connection.city1)
            local city2 = self:findCityById(connection.city2)
            if city1 and city2 then
                local x1 = centerX + (city1.x - 400) * mapScale
                local y1 = centerY + (city1.y - 300) * mapScale
                local x2 = centerX + (city2.x - 400) * mapScale
                local y2 = centerY + (city2.y - 300) * mapScale
                love.graphics.line(x1, y1, x2, y2)
                
                -- Draw connection cost
                local midX = (x1 + x2) / 2
                local midY = (y1 + y2) / 2
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.setFont(love.graphics.newFont(10))
                love.graphics.print("$" .. connection.cost, midX - 10, midY - 5)
                love.graphics.setColor(0.3, 0.3, 0.3, 1)
            end
        end
    end
    
    -- Draw cities
    for _, city in ipairs(State.map.cities) do
        local x = centerX + (city.x - 400) * mapScale
        local y = centerY + (city.y - 300) * mapScale
        local radius = 20
        
        -- Check if city is selected
        local isSelected = self.selectedCity and self.selectedCity.id == city.id
        
        -- Check if player can build here
        local currentBuilderIndex = self.buildingOrder[self.currentBuilderIndex]
        local currentPlayer = State.players[currentBuilderIndex]
        local canBuild = self:canPlayerBuildInCity(currentPlayer, city)
        
        -- City circle
        if isSelected then
            love.graphics.setColor(0.3, 0.8, 0.3, 1)
        elseif canBuild then
            love.graphics.setColor(0.5, 0.5, 0.8, 1)
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
        end
        love.graphics.circle("fill", x, y, radius)
        
        -- City border
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.circle("line", x, y, radius)
        
        -- City name
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.printf(city.name, x - 40, y + radius + 5, 80, "center")
        
        -- Show houses in city
        if city.houses and #city.houses > 0 then
            local houseSize = 8
            local spacing = 3
            local startX = x - (#city.houses * (houseSize + spacing)) / 2
            for i, playerId in ipairs(city.houses) do
                -- Find player color
                local houseColor = {0.5, 0.5, 0.5}
                for _, player in ipairs(State.players) do
                    if (player.id and player.id == playerId) or (i == playerId) then
                        houseColor = self:getColorForPlayer(player)
                        break
                    end
                end
                love.graphics.setColor(houseColor)
                love.graphics.rectangle("fill", startX + (i-1) * (houseSize + spacing), y - radius/2, houseSize, houseSize)
            end
        end
    end
end

function BuildingPhase:mousepressed(x, y, button)
    if button == 1 then
        -- Don't process if waiting
        if self.waitingForServer or NetworkActions.isWaitingForOthers() then
            return
        end
        
        -- Check build button
        if self.selectedCity and self.buildButton:isHovered(x, y) then
            if NetworkActions.shouldWaitForServer() then
                self.waitingForServer = true
                NetworkActions.buildCity(self.selectedCity.id)
            else
                -- Offline mode
                self:buildInCity(self.selectedCity)
            end
            return
        end
        
        -- Check pass button
        if self.passButton:isHovered(x, y) then
            if NetworkActions.shouldWaitForServer() then
                self.waitingForServer = true
                NetworkActions.endTurn()
            else
                -- Offline mode
                self:passTurn()
            end
            return
        end
        
        -- Check city clicks
        if State.map and State.map.cities then
            local centerX = love.graphics.getWidth() / 2
            local centerY = love.graphics.getHeight() / 2
            local mapScale = 0.8
            
            for _, city in ipairs(State.map.cities) do
                local cityX = centerX + (city.x - 400) * mapScale
                local cityY = centerY + (city.y - 300) * mapScale
                local radius = 20
                
                local dx = x - cityX
                local dy = y - cityY
                if dx * dx + dy * dy <= radius * radius then
                    local currentBuilderIndex = self.buildingOrder[self.currentBuilderIndex]
                    local currentPlayer = State.players[currentBuilderIndex]
                    if self:canPlayerBuildInCity(currentPlayer, city) then
                        self.selectedCity = city
                    end
                    return
                end
            end
        end
        
        -- Clicking elsewhere deselects
        self.selectedCity = nil
    end
end

function BuildingPhase:keypressed(key)
    if key == "p" and not self.waitingForServer and not NetworkActions.isWaitingForOthers() then
        if NetworkActions.shouldWaitForServer() then
            self.waitingForServer = true
            NetworkActions.endTurn()
        else
            self:passTurn()
        end
    end
end

function BuildingPhase:buildInCity(city)
    local currentBuilderIndex = self.buildingOrder[self.currentBuilderIndex]
    local currentPlayer = State.players[currentBuilderIndex]
    
    -- In offline mode, process the build
    local cost = self:calculateBuildingCost(city, currentPlayer)
    if currentPlayer.money >= cost then
        currentPlayer.money = currentPlayer.money - cost
        table.insert(currentPlayer.cities, city.id)
        
        -- Add house to city
        if not city.houses then city.houses = {} end
        table.insert(city.houses, currentBuilderIndex)
        
        print(currentPlayer.name .. " built in " .. city.name .. " for $" .. cost)
    end
    
    self.selectedCity = nil
    self:advanceToNextBuilder()
end

function BuildingPhase:passTurn()
    local currentBuilderIndex = self.buildingOrder[self.currentBuilderIndex]
    self.playersWhoPassedBuilding[currentBuilderIndex] = true
    self:advanceToNextBuilder()
end

function BuildingPhase:advanceToNextBuilder()
    self.currentBuilderIndex = self.currentBuilderIndex + 1
    if self.currentBuilderIndex > #self.buildingOrder then
        self.phaseComplete = true
    end
end

function BuildingPhase:canPlayerBuildInCity(player, city)
    -- Check if player already has a house there
    if city.houses then
        for _, housePlayerId in ipairs(city.houses) do
            if housePlayerId == player.id or 
               (type(housePlayerId) == "number" and State.players[housePlayerId] == player) then
                return false
            end
        end
    end
    
    -- Check if city is full (3 houses max)
    if city.houses and #city.houses >= 3 then
        return false
    end
    
    -- If player has no cities, they can build anywhere
    if #player.cities == 0 then
        return true
    end
    
    -- Otherwise, check if connected to player's network
    return self:isCityConnectedToPlayer(city, player)
end

function BuildingPhase:isCityConnectedToPlayer(city, player)
    -- Simple BFS to check if city is connected to any of player's cities
    if not State.map.connections then return false end
    
    local visited = {}
    local queue = {city.id}
    visited[city.id] = true
    
    while #queue > 0 do
        local currentCityId = table.remove(queue, 1)
        
        -- Check if this is one of player's cities
        for _, playerCityId in ipairs(player.cities) do
            if playerCityId == currentCityId then
                return true
            end
        end
        
        -- Add connected cities to queue
        for _, connection in ipairs(State.map.connections) do
            local connectedCityId = nil
            if connection.city1 == currentCityId then
                connectedCityId = connection.city2
            elseif connection.city2 == currentCityId then
                connectedCityId = connection.city1
            end
            
            if connectedCityId and not visited[connectedCityId] then
                visited[connectedCityId] = true
                table.insert(queue, connectedCityId)
            end
        end
    end
    
    return false
end

function BuildingPhase:calculateBuildingCost(city, player)
    local houseCost = 10
    if city.houses then
        houseCost = 10 + (#city.houses * 5) -- 10, 15, 20 for 1st, 2nd, 3rd
    end
    
    -- If player has no cities, no connection cost
    if #player.cities == 0 then
        return houseCost
    end
    
    -- Find cheapest connection cost
    local minConnectionCost = 999
    for _, playerCityId in ipairs(player.cities) do
        local cost = self:getConnectionCost(playerCityId, city.id)
        if cost < minConnectionCost then
            minConnectionCost = cost
        end
    end
    
    return houseCost + minConnectionCost
end

function BuildingPhase:getConnectionCost(cityId1, cityId2)
    if not State.map.connections then return 999 end
    
    -- Direct connection
    for _, connection in ipairs(State.map.connections) do
        if (connection.city1 == cityId1 and connection.city2 == cityId2) or
           (connection.city1 == cityId2 and connection.city2 == cityId1) then
            return connection.cost
        end
    end
    
    -- TODO: Implement pathfinding for indirect connections
    return 999
end

function BuildingPhase:findCityById(id)
    if not State.map or not State.map.cities then return nil end
    for _, city in ipairs(State.map.cities) do
        if city.id == id then
            return city
        end
    end
    return nil
end

function BuildingPhase:getColorForPlayer(player)
    local colors = {
        red = {1, 0.2, 0.2},
        blue = {0.2, 0.2, 1},
        green = {0.2, 0.8, 0.2},
        yellow = {1, 1, 0.2},
        purple = {0.8, 0.2, 0.8},
        black = {0.2, 0.2, 0.2}
    }
    return colors[player.color] or {0.5, 0.5, 0.5}
end

return BuildingPhase