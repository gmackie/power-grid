local BuildingPhase = {}
BuildingPhase.__index = BuildingPhase

local State = require("state") -- Ensure State is required

function BuildingPhase.new()
    local self = setmetatable({}, BuildingPhase)
    self.selectedCity = nil
    self.phaseComplete = false -- Add phase complete flag
    self.buildingOrder = {} -- Player order for building (reverse of player order)
    self.currentBuilderIndex = 1 -- Index into buildingOrder
    self.playersWhoPassedBuilding = {} -- Track who has passed
    return self
end

function BuildingPhase:enter()
    print("Entering Building Phase")
    self.phaseComplete = false
    self.selectedCity = nil
    self.playersWhoPassedBuilding = {}
    
    -- Set up building order (reverse player order)
    self.buildingOrder = {}
    for i = #State.players, 1, -1 do
        table.insert(self.buildingOrder, i)
    end
    self.currentBuilderIndex = 1
    
    print("Building order:", table.concat(self.buildingOrder, ", "))
end

function BuildingPhase:update(dt)
    -- No-op for now
end

function BuildingPhase:draw()
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Building Phase", 0, 20, windowWidth, "center")
    
    -- Get current builder
    local currentBuilderPlayerIndex = self.buildingOrder[self.currentBuilderIndex]
    local currentPlayer = State.players[currentBuilderPlayerIndex]
    
    if currentPlayer then
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.printf(currentPlayer.name .. "'s Turn to Build (Money: $" .. currentPlayer.money .. ")", 0, 60, windowWidth, "center")
        
        -- Draw map if cities exist
        if State.cities and #State.cities > 0 then
            self:drawMap()
        end
        
        -- Display instructions
        love.graphics.setFont(love.graphics.newFont(14))
        local instructions = "Click a city to build there. Press P to pass turn."
        if self.selectedCity then
            local cost = self:calculateBuildingCost(self.selectedCity, currentPlayer)
            instructions = "Selected: " .. self.selectedCity.name .. " (Cost: $" .. cost .. ") - Click again to confirm"
        end
        love.graphics.printf(instructions, 0, windowHeight - 80, windowWidth, "center")
        
        -- Display player's current cities
        if #currentPlayer.cities > 0 then
            love.graphics.setFont(love.graphics.newFont(12))
            love.graphics.print("Your cities: ", 10, windowHeight - 60)
            local cityText = ""
            for i, cityId in ipairs(currentPlayer.cities) do
                local city = self:findCityById(cityId)
                if city then
                    cityText = cityText .. city.name
                    if i < #currentPlayer.cities then cityText = cityText .. ", " end
                end
            end
            love.graphics.print(cityText, 10, windowHeight - 40)
        end
    else
        love.graphics.printf("No current player for Building Phase.", 0, 100, windowWidth, "center")
    end
    
    love.graphics.printf("Press 'C' to complete Building Phase (Dev)", 0, love.graphics.getHeight() - 20, windowWidth, "center")
end

function BuildingPhase:mousepressed(x, y, button)
    if button == 1 and State.cities then
        -- Check if clicking on a city
        for _, city in ipairs(State.cities) do
            local distance = math.sqrt((x - (city.x + 200))^2 + (y - (city.y + 100))^2) -- Offset for map position
            if distance <= 20 then -- City radius
                if self.selectedCity == city then
                    -- Clicking same city again - try to build
                    self:attemptBuild(city)
                else
                    -- Select new city
                    self.selectedCity = city
                end
                break
            end
        end
    end
end

function BuildingPhase:keypressed(key)
    if key == "c" then -- Dev key to complete phase
        self.phaseComplete = true
    elseif key == "p" then -- Pass turn
        self:passTurn()
    end
end

function BuildingPhase:isPhaseComplete()
    if self.phaseComplete then
        self.phaseComplete = false -- Reset for next time
        return true
    end
    -- Check if all players have passed
    if #self.playersWhoPassedBuilding >= #State.players then
        return true
    end
    return false
end

-- Helper functions
function BuildingPhase:drawMap()
    -- Simple map drawing
    local mapOffsetX, mapOffsetY = 200, 100
    
    -- Draw connections first
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setLineWidth(2)
    if State.connections then
        for _, connection in ipairs(State.connections) do
            local fromCity = self:findCityById(connection.from)
            local toCity = self:findCityById(connection.to)
            if fromCity and toCity then
                love.graphics.line(
                    fromCity.x + mapOffsetX, fromCity.y + mapOffsetY,
                    toCity.x + mapOffsetX, toCity.y + mapOffsetY
                )
                -- Draw cost label
                local midX = (fromCity.x + toCity.x) / 2 + mapOffsetX
                local midY = (fromCity.y + toCity.y) / 2 + mapOffsetY
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(tostring(connection.cost), midX - 5, midY - 5)
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
            end
        end
    end
    
    -- Draw cities
    for _, city in ipairs(State.cities) do
        local x, y = city.x + mapOffsetX, city.y + mapOffsetY
        
        -- City background
        if self.selectedCity == city then
            love.graphics.setColor(1, 1, 0, 0.8) -- Yellow for selected
        else
            love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Gray default
        end
        love.graphics.circle("fill", x, y, 18)
        
        -- City border
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.circle("line", x, y, 18)
        
        -- Player houses in city
        if city.houses and #city.houses > 0 then
            for i, house in ipairs(city.houses) do
                local angle = (i - 1) * (2 * math.pi / #city.houses)
                local houseX = x + 12 * math.cos(angle)
                local houseY = y + 12 * math.sin(angle)
                
                -- Color based on player
                local player = State.players[house.playerIndex]
                if player and player.color then
                    local color = self:getPlayerColor(player.color)
                    love.graphics.setColor(color[1], color[2], color[3], 1)
                else
                    love.graphics.setColor(0.5, 0.5, 0.5, 1)
                end
                love.graphics.circle("fill", houseX, houseY, 4)
            end
        end
        
        -- City name
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.print(city.name, x - 20, y + 25)
    end
end

function BuildingPhase:findCityById(cityId)
    for _, city in ipairs(State.cities) do
        if city.id == cityId then
            return city
        end
    end
    return nil
end

function BuildingPhase:calculateBuildingCost(city, player)
    -- Base cost is 10 for first house, 15 for second, 20 for third
    local housesInCity = #city.houses
    local houseCost = 10 + (housesInCity * 5)
    
    -- Connection cost (simplified - just check if player has any cities)
    local connectionCost = 0
    if #player.cities == 0 then
        connectionCost = 0 -- First city is free to place
    else
        -- Find cheapest connection to player's existing cities
        connectionCost = self:findCheapestConnection(city, player)
    end
    
    return houseCost + connectionCost
end

function BuildingPhase:findCheapestConnection(targetCity, player)
    if #player.cities == 0 then
        return 0
    end
    
    local cheapestCost = 999
    for _, cityId in ipairs(player.cities) do
        local playerCity = self:findCityById(cityId)
        if playerCity then
            local cost = self:findConnectionCost(playerCity, targetCity)
            if cost < cheapestCost then
                cheapestCost = cost
            end
        end
    end
    
    return cheapestCost == 999 and 10 or cheapestCost -- Default cost if no connection found
end

function BuildingPhase:findConnectionCost(fromCity, toCity)
    -- Simple direct connection lookup
    for _, connection in ipairs(State.connections) do
        if (connection.from == fromCity.id and connection.to == toCity.id) or
           (connection.from == toCity.id and connection.to == fromCity.id) then
            return connection.cost
        end
    end
    return 10 -- Default cost if no direct connection
end

function BuildingPhase:attemptBuild(city)
    local currentBuilderPlayerIndex = self.buildingOrder[self.currentBuilderIndex]
    local currentPlayer = State.players[currentBuilderPlayerIndex]
    
    -- Check if city allows more houses
    if #city.houses >= 3 then
        print("City is full!")
        return
    end
    
    -- Check if player already has a house in this city
    for _, house in ipairs(city.houses) do
        if house.playerIndex == currentBuilderPlayerIndex then
            print("Player already has a house in this city!")
            return
        end
    end
    
    -- Calculate cost
    local cost = self:calculateBuildingCost(city, currentPlayer)
    
    -- Check if player can afford it
    if currentPlayer.money < cost then
        print("Not enough money! Cost: $" .. cost .. ", Available: $" .. currentPlayer.money)
        return
    end
    
    -- Build the house
    table.insert(city.houses, {playerIndex = currentBuilderPlayerIndex})
    table.insert(currentPlayer.cities, city.id)
    currentPlayer.money = currentPlayer.money - cost
    
    print(currentPlayer.name .. " built in " .. city.name .. " for $" .. cost)
    
    -- Move to next turn
    self:nextTurn()
end

function BuildingPhase:passTurn()
    local currentBuilderPlayerIndex = self.buildingOrder[self.currentBuilderIndex]
    self.playersWhoPassedBuilding[currentBuilderPlayerIndex] = true
    print("Player " .. currentBuilderPlayerIndex .. " passed building turn")
    self:nextTurn()
end

function BuildingPhase:nextTurn()
    self.selectedCity = nil
    self.currentBuilderIndex = self.currentBuilderIndex + 1
    
    if self.currentBuilderIndex > #self.buildingOrder then
        -- End of round, check if all players passed
        if #self.playersWhoPassedBuilding >= #State.players then
            self.phaseComplete = true
        else
            -- Start new round, only include players who haven't passed
            local newOrder = {}
            for _, playerIndex in ipairs(self.buildingOrder) do
                if not self.playersWhoPassedBuilding[playerIndex] then
                    table.insert(newOrder, playerIndex)
                end
            end
            self.buildingOrder = newOrder
            self.currentBuilderIndex = 1
        end
    end
end

function BuildingPhase:getPlayerColor(colorName)
    local colors = {
        RED = {0.9, 0.2, 0.2},
        GREEN = {0.2, 0.8, 0.2},
        BLUE = {0.2, 0.5, 0.9},
        YELLOW = {1, 0.9, 0.2},
        BLACK = {0.2, 0.2, 0.2},
        PURPLE = {0.8, 0.2, 0.8}
    }
    return colors[colorName] or {0.5, 0.5, 0.5}
end

return BuildingPhase 