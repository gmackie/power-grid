local game = {}

-- Import models
local Player = require("models.player")
local PowerPlant = require("models.power_plant")
local ResourceMarket = require("models.resource_market")
local PhaseManager = require("phases.phase_manager_networked")
local UI = require("ui")
local State = require("state")
local json = require("lib.json")
local enums = require("models.enums")
local NetworkManager = require("network.network_manager")
local ConnectionStatus = require("ui.connection_status")

-- Game state
game.players = {}
game.currentPlayerIndex = 1
game.market = {}
game.resourceMarket = nil
game.phaseManager = nil
game.playerPanel = nil
game.isOnline = false
game.network = nil
game.connectionStatus = nil

function game:enter(playersFromSetup)
    print("Game state entered")
    print("Current state:", State.currentState)
    print("Current phase:", State.currentPhase)
    
    -- Check if this is an online game
    if State.networkGame and State.networkGame.isOnline then
        self.isOnline = true
        self.network = NetworkManager.getInstance()
        self:setupNetworkCallbacks()
        print("Online game mode activated")
    else
        self.isOnline = false
        print("Offline/pass-and-play mode")
    end
    
    -- If players are passed from playerSetup, initialize them
    if playersFromSetup and #playersFromSetup > 0 then
        print("Received " .. #playersFromSetup .. " players from setup")
        State.players = {}
        for i, playerData in ipairs(playersFromSetup) do
            local player = Player.new(playerData.name, playerData.color)
            player.money = 50  -- Standard Power Grid starting money
            player.powerPlants = {}
            player.cities = {}
            -- Set player ID for online games
            if playerData.id then
                player.id = playerData.id
            end
            table.insert(State.players, player)
        end
        State.currentPlayerIndex = 1
        -- Initialize game phase for pass-and-play
        State.currentPhase = enums.GamePhase.PLAYER_ORDER
        State.currentState = "game"
        
        -- Initialize resource market
        State.setResourceMarket(ResourceMarket.new(#State.players))
        print("Initialized resource market for " .. #State.players .. " players")
        
        -- Load power plants for the market
        local powerPlantsFile = love.filesystem.read("data/power_plants.json")
        if powerPlantsFile then
            local success, powerPlantsData = pcall(json.decode, powerPlantsFile)
            if success and powerPlantsData then
                print("Loaded " .. #powerPlantsData .. " power plants")
                State.powerPlantDeck = {}
                for _, plantData in ipairs(powerPlantsData) do
                    local plant = PowerPlant.new(
                        plantData.id,
                        plantData.cost,
                        plantData.resourceType,
                        plantData.resourcesRequired,
                        plantData.citiesPowered
                    )
                    table.insert(State.powerPlantDeck, plant)
                end
                -- Sort deck by cost
                table.sort(State.powerPlantDeck, function(a, b) return a.cost < b.cost end)
                
                -- Initialize the power plant market (first 8 plants)
                State.powerPlantMarket = {}
                for i = 1, math.min(8, #State.powerPlantDeck) do
                    table.insert(State.powerPlantMarket, State.powerPlantDeck[i])
                end
            else
                print("Error parsing power plants:", powerPlantsData)
            end
        else
            print("Could not read power plants file")
        end
        
        -- Load test map
        local mapFile = love.filesystem.read("data/test_map.json")
        if mapFile then
            local success, mapData = pcall(json.decode, mapFile)
            if success and mapData then
                State.map = mapData
                print("Loaded map with " .. #mapData.cities .. " cities")
            else
                print("Error parsing map:", mapData)
            end
        else
            print("Could not read map file")
        end
    end
    
    -- Initialize phase manager
    self.phaseManager = PhaseManager.new()
    
    -- Initialize UI
    self.playerPanel = UI.PlayerPanel.new(10, 10, 200, 150)
    
    -- Initialize connection status indicator if online
    if self.isOnline then
        self.connectionStatus = ConnectionStatus.new()
    end
    
    -- Game state
    State.currentState = "game"
    State.gameStarted = true
end

function game:setupNetworkCallbacks()
    -- Handle game state updates from server
    self.network.onGameStateUpdate = function(gameState)
        self:updateFromNetworkState(gameState)
    end
    
    -- Handle phase changes
    self.network.onPhaseChange = function(phase, round)
        State.currentPhase = self:convertPhaseFromNetwork(phase)
        State.currentRound = round
        print("Phase changed to: " .. phase)
    end
    
    -- Handle turn changes
    self.network.onTurnChange = function(currentPlayerId, turn)
        -- Find the player index for this ID
        for i, player in ipairs(State.players) do
            if player.id == currentPlayerId then
                State.currentPlayerIndex = i
                break
            end
        end
    end
    
    -- Handle errors
    self.network.onError = function(code, message)
        print("Network error: " .. code .. " - " .. message)
        -- TODO: Show error dialog to player
    end
    
    -- Handle connection lost
    self.network.onConnectionLost = function()
        print("Connection lost! Attempting to reconnect...")
        -- TODO: Show notification to player
    end
    
    -- Handle reconnection
    self.network.onReconnected = function()
        print("Successfully reconnected!")
        -- TODO: Show notification to player
    end
end

function game:updateFromNetworkState(networkState)
    -- Update players
    if networkState.players then
        for playerId, playerData in pairs(networkState.players) do
            -- Find local player object
            local localPlayer = nil
            for _, player in ipairs(State.players) do
                if player.id == playerId then
                    localPlayer = player
                    break
                end
            end
            
            if localPlayer then
                -- Update player data
                localPlayer.money = playerData.money
                localPlayer.cities = playerData.cities or {}
                localPlayer.powerPlants = {}
                
                -- Convert power plants
                if playerData.power_plants then
                    for _, plantData in ipairs(playerData.power_plants) do
                        local plant = PowerPlant.new(
                            plantData.id,
                            plantData.cost,
                            plantData.resource_type,
                            plantData.resource_cost,
                            plantData.capacity
                        )
                        table.insert(localPlayer.powerPlants, plant)
                    end
                end
                
                -- Update resources
                if playerData.resources then
                    localPlayer.resources = playerData.resources
                end
            end
        end
    end
    
    -- Update market
    if networkState.market and networkState.market.resources then
        -- TODO: Update resource market from network state
    end
    
    -- Update power plant market
    if networkState.power_plants then
        State.powerPlantMarket = {}
        for _, plantData in ipairs(networkState.power_plants) do
            local plant = PowerPlant.new(
                plantData.id,
                plantData.cost,
                plantData.resource_type,
                plantData.resource_cost,
                plantData.capacity
            )
            table.insert(State.powerPlantMarket, plant)
        end
    end
    
    -- Update turn order
    if networkState.turn_order then
        State.turnOrder = networkState.turn_order
    end
end

function game:convertPhaseFromNetwork(networkPhase)
    local phaseMap = {
        ["PLAYER_ORDER"] = enums.GamePhase.PLAYER_ORDER,
        ["AUCTION"] = enums.GamePhase.AUCTION,
        ["BUY_RESOURCES"] = enums.GamePhase.BUY_RESOURCES,
        ["BUILD_CITIES"] = enums.GamePhase.BUILD_CITIES,
        ["BUREAUCRACY"] = enums.GamePhase.BUREAUCRACY,
        ["GAME_END"] = enums.GamePhase.GAME_END
    }
    return phaseMap[networkPhase] or enums.GamePhase.PLAYER_ORDER
end

function game:update(dt)
    -- Update network if online
    if self.isOnline and self.network then
        self.network:update(dt)
    end
    
    -- Update connection status
    if self.connectionStatus then
        self.connectionStatus:update(dt)
    end
    
    -- Update phase manager
    if self.phaseManager then
        self.phaseManager:update(dt)
    end
    
    -- Update player panel
    if self.playerPanel and State.players and State.currentPlayerIndex then
        local currentPlayer = State.players[State.currentPlayerIndex]
        if currentPlayer then
            self.playerPanel:setPlayer(currentPlayer)
        end
    end
end

function game:draw()
    -- Clear background
    love.graphics.clear(0.15, 0.15, 0.18, 1)
    
    -- Draw phase manager
    if self.phaseManager then
        self.phaseManager:draw()
    end
    
    -- Draw player panel
    if self.playerPanel then
        self.playerPanel:draw()
    end
    
    -- Draw connection status
    if self.connectionStatus then
        self.connectionStatus:draw()
    end
end

function game:mousepressed(x, y, button)
    -- Check connection status clicks first
    if self.connectionStatus then
        self.connectionStatus:mousepressed(x, y, button)
    end
    
    if self.phaseManager then
        self.phaseManager:mousepressed(x, y, button)
    end
end

function game:mousereleased(x, y, button)
    if self.phaseManager then
        self.phaseManager:mousereleased(x, y, button)
    end
end

function game:keypressed(key)
    if key == "escape" then
        if self.isOnline then
            -- TODO: Show confirmation dialog before leaving online game
            self.network:disconnect()
        end
        changeState("menu")
    elseif self.phaseManager then
        self.phaseManager:keypressed(key)
    end
end

function game:leave()
    -- Clean up network callbacks if online
    if self.isOnline and self.network then
        self.network.onGameStateUpdate = nil
        self.network.onPhaseChange = nil
        self.network.onTurnChange = nil
        self.network.onError = nil
    end
end

return game