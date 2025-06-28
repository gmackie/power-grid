local game = {}

-- Import models
local Player = require("models.player")
local PowerPlant = require("models.power_plant")
local ResourceMarket = require("models.resource_market")
local PhaseManager = require("phases.phase_manager")
local UI = require("ui")
local State = require("state")
local json = require("lib.json")
local enums = require("models.enums")

-- Game state
game.players = {}
game.currentPlayerIndex = 1
game.market = {}
game.resourceMarket = nil
game.phaseManager = nil
game.playerPanel = nil

function game:enter(playersFromSetup)
    print("Game state entered")
    print("Current state:", State.currentState)
    print("Current phase:", State.currentPhase)
    
    -- If players are passed from playerSetup, initialize them
    if playersFromSetup and #playersFromSetup > 0 then
        print("Received " .. #playersFromSetup .. " players from setup")
        State.players = {}
        for i, playerData in ipairs(playersFromSetup) do
            local player = Player.new(playerData.name, playerData.color)
            player.money = 50  -- Standard Power Grid starting money
            player.powerPlants = {}
            player.cities = {}
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
                State.powerPlantMarket = {}
                for _, plantData in ipairs(powerPlantsData) do
                    local plant = PowerPlant.new(
                        plantData.id,
                        plantData.cost,
                        plantData.capacity,
                        plantData.resourceType,
                        plantData.resourceCost
                    )
                    table.insert(State.powerPlantMarket, plant)
                end
                print("Loaded " .. #State.powerPlantMarket .. " power plants into market")
            else
                print("ERROR: Failed to decode power_plants.json")
            end
        else
            print("ERROR: Could not load power_plants.json")
        end
        
        -- Load map data
        local mapFile = love.filesystem.read("data/test_map.json")
        if mapFile then
            local success, mapData = pcall(json.decode, mapFile)
            if success and mapData then
                State.cities = {}
                State.connections = {}
                
                -- Load cities
                for _, cityData in ipairs(mapData.cities) do
                    local city = {
                        id = cityData.id,
                        name = cityData.name,
                        x = cityData.x,
                        y = cityData.y,
                        region = cityData.region,
                        houses = {} -- Will store player houses
                    }
                    table.insert(State.cities, city)
                end
                
                -- Load connections
                for _, connData in ipairs(mapData.connections) do
                    local connection = {
                        from = connData.from,
                        to = connData.to,
                        cost = connData.cost
                    }
                    table.insert(State.connections, connection)
                end
                
                print("Loaded " .. #State.cities .. " cities and " .. #State.connections .. " connections")
            else
                print("ERROR: Failed to decode test_map.json")
            end
        else
            print("ERROR: Could not load test_map.json")
        end
    end

    print("--- Verifying player power plants in State AT START of game:enter ---")
    if State.players and type(State.players) == "table" then
        print("game:enter sees " .. #State.players .. " players in State.players.")
        for P_idx, P_player in ipairs(State.players) do
            if P_player and P_player.powerPlants and type(P_player.powerPlants) == "table" then
                print("GAME-ENTER Player " .. P_player.name .. " has " .. #P_player.powerPlants .. " power plant(s):")
                for pp_idx, pp_plant in ipairs(P_player.powerPlants) do
                    print("  GAME-ENTER Plant ID: " .. pp_plant.id)
                end
            elseif P_player then
                print("GAME-ENTER Player " .. P_player.name .. " has no powerPlants table or it's not a table.")
            else
                print("GAME-ENTER Player at index " .. P_idx .. " is nil.")
            end
        end
    else
        print("GAME-ENTER State.players is nil or not a table.")
    end
    print("-------------------------------------------------------------------")
    
    -- Initialize phase manager and UI
    self.phaseManager = PhaseManager.new()
    self.playerPanel = UI.PlayerPanel.new()
    
    -- Set the current player for the player panel
    if State.getCurrentPlayer() then
        self.playerPanel:setPlayer(State.getCurrentPlayer())
    end
    
    -- If no phase is set, default to AUCTION
    if not State.currentPhase then
        print("No phase set, defaulting to AUCTION")
        State.setCurrentPhase(enums.GamePhase.AUCTION)
    end

    -- Load power plants if not already loaded (REMOVED - main.lua handles this for flag-based starts)
    --[[ 
    if #State.powerPlantMarket == 0 then
        print("Loading power plants from JSON for game:enter - THIS SHOULD LIKELY BE HANDLED DIFFERENTLY OR EARLIER")
        local paths = {
            "data/power_plants.json",
            "love_client2/data/power_plants.json"
        }
        
        local powerPlantsFile = nil
        local usedPath = nil
        
        for _, path in ipairs(paths) do
            powerPlantsFile = love.filesystem.read(path)
            if powerPlantsFile then
                usedPath = path
                break
            end
        end
        
        if powerPlantsFile then
            print("Successfully loaded power plants from:", usedPath, "(in game:enter)")
            local success, powerPlants = pcall(json.decode, powerPlantsFile)
            if success then
                print("Successfully decoded JSON (in game:enter)")
                State.powerPlantMarket = {} -- Clear it first to avoid duplicates if called unexpectedly
                for _, plantData in ipairs(powerPlants) do
                    local plant = PowerPlant.new(
                        plantData.id,
                        plantData.cost,
                        plantData.capacity,
                        plantData.resourceType,
                        plantData.resourceCost
                    )
                    table.insert(State.powerPlantMarket, plant)
                end
                print("Loaded " .. #State.powerPlantMarket .. " power plants (in game:enter)")
            else
                print("ERROR: Failed to decode JSON (in game:enter):", powerPlants)
            end
        else
            print("WARNING: Could not load power plants JSON file from any path (in game:enter)")
        end
    end
    ]]
end

function game:update(dt)
    -- Update phase manager if it exists
    if self.phaseManager and self.phaseManager.update then
        self.phaseManager:update(dt)
    end
    
    -- Update player panel if it exists
    if self.playerPanel and self.playerPanel.update then
        self.playerPanel:update(dt)
    end
end

function game:draw()
    local windowWidth, windowHeight = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Draw background
    love.graphics.setColor(0.12, 0.12, 0.15)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    
    -- Draw title and phase
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.printf("Power Grid", 0, 40, windowWidth, "center")
    love.graphics.setFont(love.graphics.newFont(24))
    
    -- Draw phase with nil check
    local phaseText = State.currentPhase or "No Phase"
    love.graphics.printf("Phase: " .. phaseText, 0, 80, windowWidth, "center")
    
    -- Draw current phase
    if self.phaseManager and self.phaseManager.draw then
        self.phaseManager:draw()
    end
    
    -- Draw player panel
    if self.playerPanel and self.playerPanel.draw then
        self.playerPanel:draw()
    end
end

function game:mousepressed(x, y, button)
    if self.phaseManager and self.phaseManager.mousepressed then
        self.phaseManager:mousepressed(x, y, button)
    end
end

function game:mousereleased(x, y, button)
    if self.phaseManager and self.phaseManager.mousereleased then
        self.phaseManager:mousereleased(x, y, button)
    end
end

function game:mousemoved(x, y)
    if self.phaseManager and self.phaseManager.mousemoved then
        self.phaseManager:mousemoved(x, y)
    end
end

function game:keypressed(key)
    if self.phaseManager and self.phaseManager.keypressed then
        self.phaseManager:keypressed(key)
    end
end

function game:textinput(t)
    if self.phaseManager and self.phaseManager.textinput then
        self.phaseManager:textinput(t)
    end
end

return game 