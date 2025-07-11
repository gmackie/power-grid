local gameLobby = {}
local NetworkManager = require("network.network_manager")

function gameLobby:enter(gameState)
    print("Game lobby entered")
    self.network = NetworkManager.getInstance()
    self.gameState = gameState or {}
    self.isHost = false -- Will be determined by checking who created the game
    
    -- Set up network callbacks
    self.network.onGameStateUpdate = function(state)
        self.gameState = state
        -- Check if game has started
        if state.status == "PLAYING" then
            -- Convert network game state to local game state and start
            self:startGame(state)
        end
    end
    
    self.network.onError = function(code, message)
        print("Error: " .. code .. " - " .. message)
        self.errorMessage = message
        self.errorTimer = 3
    end
    
    -- Determine if we're the host (simplified - first player is host)
    if self.gameState.players then
        local playerCount = 0
        for _ in pairs(self.gameState.players) do
            playerCount = playerCount + 1
        end
        self.isHost = playerCount == 1
    end
end

function gameLobby:update(dt)
    self.network:update(dt)
    
    -- Error message timer
    if self.errorTimer then
        self.errorTimer = self.errorTimer - dt
        if self.errorTimer <= 0 then
            self.errorMessage = nil
            self.errorTimer = nil
        end
    end
end

function gameLobby:draw()
    love.graphics.clear(0.1, 0.1, 0.12)
    
    -- Header
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.printf("Game Lobby", 0, 30, love.graphics.getWidth(), "center")
    
    -- Game info
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.print("Game: " .. (self.gameState.name or "Unknown"), 50, 100)
    love.graphics.print("Map: " .. (self.gameState.map and self.gameState.map.name or "Unknown"), 50, 130)
    
    -- Players list
    love.graphics.print("Players:", 50, 180)
    
    love.graphics.setFont(love.graphics.newFont(16))
    local y = 210
    if self.gameState.players then
        for playerId, player in pairs(self.gameState.players) do
            -- Player color box
            local r, g, b = self:getColorRGB(player.color)
            love.graphics.setColor(r, g, b, 1)
            love.graphics.rectangle("fill", 50, y, 20, 20)
            
            -- Player name
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(player.name, 80, y)
            
            -- Ready status (if implemented)
            if player.is_ready then
                love.graphics.setColor(0.2, 1, 0.2, 1)
                love.graphics.print("Ready", 300, y)
            else
                love.graphics.setColor(0.7, 0.7, 0.7, 1)
                love.graphics.print("Not Ready", 300, y)
            end
            
            y = y + 30
        end
    end
    
    -- Waiting for players message
    local playerCount = 0
    if self.gameState.players then
        for _ in pairs(self.gameState.players) do
            playerCount = playerCount + 1
        end
    end
    
    if playerCount < 2 then
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.printf("Waiting for more players...", 0, 350, love.graphics.getWidth(), "center")
    end
    
    -- Buttons
    if self.isHost and playerCount >= 2 then
        self:drawButton("Start Game", 300, 450, 200, 50, function()
            self.network:startGame()
        end)
    elseif not self.isHost then
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.printf("Waiting for host to start the game...", 0, 465, love.graphics.getWidth(), "center")
    end
    
    self:drawButton("Leave Game", 50, 530, 150, 40, function()
        -- TODO: Implement leave game
        self.network:disconnect()
        changeState("menu")
    end)
    
    -- Error message
    if self.errorMessage then
        love.graphics.setColor(1, 0.3, 0.3, 1)
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.printf(self.errorMessage, 0, 400, love.graphics.getWidth(), "center")
    end
end

function gameLobby:drawButton(text, x, y, w, h, onClick)
    local mx, my = love.mouse.getPosition()
    local isHovered = mx >= x and mx <= x + w and my >= y and my <= y + h
    
    if isHovered then
        love.graphics.setColor(0.4, 0.8, 0.4, 1)
    else
        love.graphics.setColor(0.3, 0.7, 0.3, 1)
    end
    
    love.graphics.rectangle("fill", x, y, w, h, 5)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf(text, x, y + h/2 - 10, w, "center")
    
    -- Store button for click handling
    self.buttons = self.buttons or {}
    table.insert(self.buttons, {x = x, y = y, w = w, h = h, onClick = onClick})
end

function gameLobby:mousepressed(x, y, button)
    if button == 1 and self.buttons then
        for _, btn in ipairs(self.buttons) do
            if x >= btn.x and x <= btn.x + btn.w and
               y >= btn.y and y <= btn.y + btn.h then
                btn.onClick()
                break
            end
        end
    end
    
    -- Clear buttons after handling
    self.buttons = {}
end

function gameLobby:startGame(networkGameState)
    -- Convert network game state to local game format
    local players = {}
    for playerId, playerData in pairs(networkGameState.players) do
        table.insert(players, {
            id = playerId,
            name = playerData.name,
            color = playerData.color,
            money = playerData.money,
            powerPlants = playerData.power_plants or {},
            cities = playerData.cities or {},
            resources = playerData.resources or {}
        })
    end
    
    -- Store network game info in state
    local State = require("state")
    State.networkGame = {
        gameId = networkGameState.game_id,
        isOnline = true,
        localPlayerId = self.network.localPlayerId
    }
    
    -- Switch to game state with players
    changeState("game", players)
end

function gameLobby:getColorRGB(colorName)
    local colors = {
        red = {1, 0.2, 0.2},
        blue = {0.2, 0.2, 1},
        green = {0.2, 0.8, 0.2},
        yellow = {1, 1, 0.2},
        purple = {0.8, 0.2, 0.8},
        black = {0.2, 0.2, 0.2}
    }
    return unpack(colors[colorName] or {1, 1, 1})
end

function gameLobby:leave()
    -- Clean up callbacks
    self.network.onGameStateUpdate = nil
    self.network.onError = nil
end

return gameLobby