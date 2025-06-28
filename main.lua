-- Power Grid Digital - love_client2
-- Minimal main.lua with state management and a placeholder main menu

local currentState
local states = {}
local State = require("state")
local Player = require("models.player")
local PowerPlant = require("models.power_plant")
local ResourceMarket = require("models.resource_market")
local json = require("lib.json")
local enums = require("models.enums")
local Simulator = require("test.simulator")

function love.load()
    print("Game starting...")
    
    -- Set window properties
    love.window.setMode(1600, 900, {
        resizable = true,
        vsync = true,
        minwidth = 1200,
        minheight = 800
    })
    love.window.setTitle("Power Grid")
    
    -- Initialize state
    State.init()
    
    -- Initialize simulator
    local simulator = Simulator.new()
    _G.simulator = simulator -- Make globally accessible for debugging
    
    -- Check for command line flags
    local startAuction = false
    local startResourceBuying = false
    local runTest = nil

    for i = 1, #arg do
        print("Checking argument:", arg[i])
        if arg[i] == "--auction" then
            print("Found --auction flag")
            startAuction = true
            break
        elseif arg[i] == "--resource" then
            print("Found --resource flag")
            startResourceBuying = true
            break
        elseif arg[i] == "--test-full" then
            print("Found --test-full flag")
            runTest = "full"
            break
        elseif arg[i] == "--test-building" then
            print("Found --test-building flag")
            runTest = "building"
            break
        elseif arg[i] == "--test-phase" then
            print("Found --test-phase flag")
            runTest = "phase"
            break
        elseif arg[i] == "--test-menu" then
            print("Found --test-menu flag")
            runTest = "menu"
            break
        end
    end
    
    if startAuction then
        print("Starting game in auction phase with 4 players")
        -- Initialize game state for auction phase
        State.setCurrentState("game")
        State.setCurrentPhase(enums.GamePhase.AUCTION)
        
        -- Create four default players
        local playerColors = {
            {1, 0, 0, 1}, -- Red
            {0, 1, 0, 1}, -- Green
            {0, 0, 1, 1}, -- Blue
            {1, 1, 0, 1}  -- Yellow
        }
        for i = 1, 4 do
            local player = Player.new("Player " .. i, 50) -- Assuming Player.new takes name and money
            player.color = playerColors[i] -- Assign a distinct color
            State.addPlayer(player)
        end
        print("Created four default players with 50 money each")
        
        -- Initialize resource market
        State.setResourceMarket(ResourceMarket.new(#State.players))
        
        -- Load power plants
        local powerPlantsFile = love.filesystem.read("data/power_plants.json")
        if powerPlantsFile then
            local powerPlantsData = json.decode(powerPlantsFile)
            if powerPlantsData then
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
                print("Loaded " .. #State.powerPlantMarket .. " power plants into State.powerPlantMarket")
            else
                print("ERROR: Failed to decode power_plants.json")
            end
        else
            print("WARNING: Could not load power_plants.json. Ensure it's at 'data/power_plants.json'")
        end
        
        -- Load and enter game state
        changeState("game")
    elseif startResourceBuying then
        print("Starting game in resource buying phase with 4 players, each with 1 power plant")
        State.setCurrentState("game")
        State.setCurrentPhase(enums.GamePhase.RESOURCE_BUYING)

        local playerColors = {
            {1, 0, 0, 1}, {0, 1, 0, 1}, {0, 0, 1, 1}, {1, 1, 0, 1}
        }
        for i = 1, 4 do
            local player = Player.new("Player " .. i, 100) -- Give a bit more money for resource buying start
            player.color = playerColors[i]
            State.addPlayer(player)
        end
        print("Created four default players.")

        State.setResourceMarket(ResourceMarket.new(#State.players))

        local allPowerPlants = {}
        local powerPlantsFile = love.filesystem.read("data/power_plants.json")
        if powerPlantsFile then
            local powerPlantsData = json.decode(powerPlantsFile)
            if powerPlantsData then
                for _, plantData in ipairs(powerPlantsData) do
                    table.insert(allPowerPlants, PowerPlant.new(
                        plantData.id, plantData.cost, plantData.capacity,
                        plantData.resourceType, plantData.resourceCost
                    ))
                end
                print("Loaded " .. #allPowerPlants .. " total power plants from JSON.")

                if #allPowerPlants >= 4 then
                    for i = 1, 4 do
                        if State.players[i] and #allPowerPlants > 0 then -- Check if player exists and plants are available
                            local plantToGive = table.remove(allPowerPlants, 1) 
                            if plantToGive then
                                State.players[i]:addPowerPlant(plantToGive)
                                State.players[i].money = State.players[i].money - plantToGive.cost 
                                print("Gave Player " .. i .. " power plant #" .. plantToGive.id .. " and deducted $"..plantToGive.cost)
                            else
                                print("Warning: table.remove returned nil, should not happen if #allPowerPlants > 0 check is correct.") 
                            end
                        else
                            if not State.players[i] then print("Warning: Player " .. i .. " does not exist for plant assignment.") end
                            if #allPowerPlants == 0 then print("Warning: No more power plants in list to assign.") end
                            break -- Stop if no more plants or players
                        end
                    end
                else
                    print("WARNING: Not enough power plants in JSON (<4) to give one to each of the 4 players.")
                end
                State.setPowerPlantMarket(allPowerPlants) -- Remaining plants go to market
                print("Populated State.powerPlantMarket with " .. #State.powerPlantMarket .. " remaining plants.")

                -- Verification print after assignment loop
                print("--- Verifying player power plants in State after assignment ---")
                for P_idx, P_player in ipairs(State.players) do
                    if P_player and P_player.powerPlants then
                        print("Player " .. P_player.name .. " has " .. #P_player.powerPlants .. " power plant(s):")
                        for pp_idx, pp_plant in ipairs(P_player.powerPlants) do
                            print("  - Plant ID: " .. pp_plant.id .. " Cost: " .. pp_plant.cost)
                        end
                    else
                        print("Player " .. (P_player and P_player.name or "Unknown") .. " has no powerPlants table or is nil.")
                    end
                end
                print("-----------------------------------------------------------")

                print("--- Verifying player power plants in State BEFORE changeState(game) ---")
                for P_idx, P_player in ipairs(State.players) do
                    if P_player and P_player.powerPlants then
                        print("PRE-CHANGE Player " .. P_player.name .. " has " .. #P_player.powerPlants .. " power plant(s):")
                        for pp_idx, pp_plant in ipairs(P_player.powerPlants) do
                            print("  PRE-CHANGE Plant ID: " .. pp_plant.id)
                        end
                    else
                        print("PRE-CHANGE Player " .. (P_player and P_player.name or ("Index " .. P_idx)) .. " has no powerPlants table or is nil.")
                    end
                end
                print("---------------------------------------------------------------------")

            else
                print("ERROR: Failed to decode power_plants.json for --resource start")
            end
        else
            print("WARNING: Could not load power_plants.json for --resource start.")
        end
        
        changeState("game")
    elseif runTest then
        print("Running automated test: " .. runTest)
        State.setCurrentState("menu")
        changeState("menu")
        
        -- Start the appropriate test
        if runTest == "full" then
            simulator:runFullGameTest()
        elseif runTest == "building" then
            simulator:runBuildingTest()
        elseif runTest == "phase" then
            simulator:runPhaseTest("auction")
        elseif runTest == "menu" then
            simulator:runMenuTest()
        end
    else
        print("Loading main menu")
        State.setCurrentState("menu")
        changeState("menu")
    end
end

function love.update(dt)
    -- Update simulator first
    if _G.simulator then
        _G.simulator:update(dt)
    end
    
    if currentState and currentState.update then
        currentState:update(dt)
    end
end

function love.draw()
    if currentState and currentState.draw then
        currentState:draw()
    end
    
    -- Draw simulator status if running
    if _G.simulator and _G.simulator:isRunning() then
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.print("SIMULATOR RUNNING: " .. (_G.simulator.currentTest or "unknown"), 10, 10)
        love.graphics.print("Timer: " .. string.format("%.1f", _G.simulator.timer or 0), 10, 30)
        love.graphics.print("Events in queue: " .. (#_G.simulator.eventQueue or 0), 10, 50)
        love.graphics.print("Current state: " .. (currentState and "loaded" or "nil"), 10, 70)
        
        -- Show recent clicks
        for i, click in ipairs(debugClicks) do
            love.graphics.setColor(1, 0, 0, 0.8)
            love.graphics.circle("fill", click.x, click.y, 8)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(tostring(i), click.x + 10, click.y - 5)
        end
        
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end
end

function love.keypressed(key, scancode, isrepeat)
    if currentState and currentState.keypressed then
        currentState:keypressed(key, scancode, isrepeat)
    end
end

function love.mousepressed(x, y, button)
    -- Track clicks for debugging
    if _G.simulator and _G.simulator:isRunning() then
        trackClick(x, y)
        print("[DEBUG] Click at (" .. x .. ", " .. y .. ") button " .. button)
    end
    
    if currentState and currentState.mousepressed then
        currentState:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    if currentState and currentState.mousereleased then
        currentState:mousereleased(x, y, button)
    end
end

function love.textinput(text)
    if currentState and currentState.textinput then
        currentState:textinput(text)
    end
end

-- Debug overlay for showing click positions
local debugClicks = {}

-- State transition helper
function changeState(newStateName, ...)
    if states[newStateName] == nil then
        states[newStateName] = require('states.' .. newStateName)
    end
    if currentState and currentState.exit then
        currentState:exit()
    end
    currentState = states[newStateName]
    if currentState and currentState.enter then
        currentState:enter(...)
    end
    
    -- Debug logging
    if _G.simulator and _G.simulator.verbose then
        print("[DEBUG] State changed to: " .. newStateName)
    end
end

-- Debug click tracking
function trackClick(x, y)
    table.insert(debugClicks, {x = x, y = y, time = love.timer.getTime()})
    -- Keep only last 5 clicks
    while #debugClicks > 5 do
        table.remove(debugClicks, 1)
    end
end
