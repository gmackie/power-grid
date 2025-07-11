local lobbyBrowser = {}
local NetworkManager = require("network.network_manager")

function lobbyBrowser:enter()
    print("Lobby browser entered")
    self.network = NetworkManager.getInstance()
    
    -- UI state
    self.games = {}
    self.selectedGame = nil
    self.playerName = "Player" .. love.math.random(1000, 9999)
    self.playerColor = "red"
    self.refreshTimer = 0
    self.showCreateDialog = false
    
    -- Create game dialog
    self.newGameName = "Game " .. love.math.random(100, 999)
    self.newGameMap = "usa"
    
    -- Available colors
    self.colors = {"red", "blue", "green", "yellow", "purple", "black"}
    
    -- Set up network callbacks
    self.network.onGameList = function(games)
        self.games = games or {}
    end
    
    self.network.onGameStateUpdate = function(gameState)
        -- Game joined successfully, switch to game lobby
        changeState("gameLobby", gameState)
    end
    
    self.network.onError = function(code, message)
        print("Error: " .. code .. " - " .. message)
        self.errorMessage = message
        self.errorTimer = 3
    end
    
    -- Request initial game list
    self:refreshGameList()
end

function lobbyBrowser:refreshGameList()
    self.network:requestGameList()
    self.refreshTimer = 5 -- Refresh every 5 seconds
end

function lobbyBrowser:update(dt)
    self.network:update(dt)
    
    -- Auto-refresh game list
    self.refreshTimer = self.refreshTimer - dt
    if self.refreshTimer <= 0 then
        self:refreshGameList()
    end
    
    -- Error message timer
    if self.errorTimer then
        self.errorTimer = self.errorTimer - dt
        if self.errorTimer <= 0 then
            self.errorMessage = nil
            self.errorTimer = nil
        end
    end
end

function lobbyBrowser:draw()
    love.graphics.clear(0.1, 0.1, 0.12)
    
    -- Header
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.printf("Online Games", 0, 30, love.graphics.getWidth(), "center")
    
    -- Player info section
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.print("Your Name: " .. self.playerName, 50, 100)
    love.graphics.print("Your Color: ", 350, 100)
    
    -- Color indicator
    local r, g, b = self:getColorRGB(self.playerColor)
    love.graphics.setColor(r, g, b, 1)
    love.graphics.rectangle("fill", 450, 95, 30, 30)
    
    -- Game list
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.print("Available Games:", 50, 150)
    
    -- Draw game list
    love.graphics.setFont(love.graphics.newFont(16))
    local y = 180
    for i, game in ipairs(self.games) do
        local isSelected = self.selectedGame == game.id
        
        if isSelected then
            love.graphics.setColor(0.3, 0.5, 0.7, 0.5)
            love.graphics.rectangle("fill", 45, y - 5, 710, 30)
        end
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(game.name, 50, y)
        love.graphics.print(game.status, 300, y)
        love.graphics.print(game.players .. "/" .. game.max_players .. " players", 450, y)
        love.graphics.print("Map: " .. game.map, 600, y)
        
        y = y + 35
    end
    
    -- No games message
    if #self.games == 0 then
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print("No games available. Create one!", 50, y)
    end
    
    -- Buttons
    self:drawButton("Create Game", 50, 500, 150, 40, function()
        self.showCreateDialog = true
    end)
    
    self:drawButton("Join Game", 220, 500, 150, 40, function()
        if self.selectedGame then
            self.network:joinGame(self.selectedGame, self.playerName, self.playerColor)
        end
    end, self.selectedGame ~= nil)
    
    self:drawButton("Refresh", 390, 500, 100, 40, function()
        self:refreshGameList()
    end)
    
    self:drawButton("Back", 650, 500, 100, 40, function()
        self.network:disconnect()
        changeState("menu")
    end)
    
    -- Create game dialog
    if self.showCreateDialog then
        self:drawCreateGameDialog()
    end
    
    -- Error message
    if self.errorMessage then
        love.graphics.setColor(1, 0.3, 0.3, 1)
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.printf(self.errorMessage, 0, 560, love.graphics.getWidth(), "center")
    end
end

function lobbyBrowser:drawButton(text, x, y, w, h, onClick, enabled)
    if enabled == nil then enabled = true end
    
    local mx, my = love.mouse.getPosition()
    local isHovered = mx >= x and mx <= x + w and my >= y and my <= y + h
    
    if not enabled then
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
    elseif isHovered then
        love.graphics.setColor(0.4, 0.8, 0.4, 1)
    else
        love.graphics.setColor(0.3, 0.7, 0.3, 1)
    end
    
    love.graphics.rectangle("fill", x, y, w, h, 5)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(text, x, y + h/2 - 8, w, "center")
    
    -- Store button for click handling
    self.buttons = self.buttons or {}
    table.insert(self.buttons, {x = x, y = y, w = w, h = h, onClick = onClick, enabled = enabled})
end

function lobbyBrowser:drawCreateGameDialog()
    -- Dialog background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Dialog box
    love.graphics.setColor(0.2, 0.2, 0.25, 1)
    love.graphics.rectangle("fill", 200, 150, 400, 300, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", 200, 150, 400, 300, 10)
    
    -- Title
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Create New Game", 200, 170, 400, "center")
    
    -- Game name input
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.print("Game Name:", 220, 220)
    love.graphics.setColor(0.3, 0.3, 0.35, 1)
    love.graphics.rectangle("fill", 220, 245, 360, 30)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(self.newGameName, 225, 250)
    
    -- Map selection
    love.graphics.print("Map:", 220, 290)
    love.graphics.print(self.newGameMap, 260, 290)
    
    -- Buttons
    self:drawButton("Create", 220, 380, 100, 40, function()
        self.network:createGame(self.newGameName, self.newGameMap)
        self.showCreateDialog = false
    end)
    
    self:drawButton("Cancel", 480, 380, 100, 40, function()
        self.showCreateDialog = false
    end)
end

function lobbyBrowser:mousepressed(x, y, button)
    if button == 1 then
        -- Handle button clicks
        if self.buttons then
            for _, btn in ipairs(self.buttons) do
                if btn.enabled and x >= btn.x and x <= btn.x + btn.w and
                   y >= btn.y and y <= btn.y + btn.h then
                    btn.onClick()
                    break
                end
            end
        end
        
        -- Select game from list
        if not self.showCreateDialog then
            local listY = 180
            for i, game in ipairs(self.games) do
                if x >= 45 and x <= 755 and y >= listY - 5 and y <= listY + 25 then
                    self.selectedGame = game.id
                    break
                end
                listY = listY + 35
            end
        end
    end
    
    -- Clear buttons after handling
    self.buttons = {}
end

function lobbyBrowser:textinput(text)
    if self.showCreateDialog then
        self.newGameName = self.newGameName .. text
    end
end

function lobbyBrowser:keypressed(key)
    if self.showCreateDialog then
        if key == "backspace" and #self.newGameName > 0 then
            self.newGameName = self.newGameName:sub(1, -2)
        elseif key == "escape" then
            self.showCreateDialog = false
        end
    elseif key == "escape" then
        self.network:disconnect()
        changeState("menu")
    end
end

function lobbyBrowser:getColorRGB(colorName)
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

function lobbyBrowser:leave()
    -- Clean up callbacks
    self.network.onGameList = nil
    self.network.onGameStateUpdate = nil
    self.network.onError = nil
end

return lobbyBrowser