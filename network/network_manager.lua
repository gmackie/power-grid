-- Network Manager for handling multiplayer connections and game state

local WebSocketClient = require("network.websocket_client")

local NetworkManager = {}
NetworkManager.__index = NetworkManager

function NetworkManager:new()
    local self = setmetatable({}, NetworkManager)
    
    self.client = nil
    self.serverUrl = "ws://localhost:4080/game"
    self.isOnline = false
    self.currentGame = nil
    self.localPlayerId = nil
    self.localPlayerName = nil
    self.localPlayerColor = nil
    
    -- Reconnection settings
    self.autoReconnect = true
    self.reconnectDelay = 2 -- seconds
    self.reconnectTimer = 0
    self.maxReconnectAttempts = 5
    self.reconnectAttempts = 0
    self.wasConnected = false
    
    -- Callbacks for game events
    self.onGameStateUpdate = nil
    self.onPhaseChange = nil
    self.onTurnChange = nil
    self.onError = nil
    self.onGameList = nil
    self.onConnectionLost = nil
    self.onReconnected = nil
    
    return self
end

function NetworkManager:connect(serverUrl)
    if serverUrl then
        self.serverUrl = serverUrl
    end
    
    self.client = WebSocketClient:new(self.serverUrl)
    
    if self.client:connect() then
        self.isOnline = true
        self:setupCallbacks()
        return true
    else
        self.isOnline = false
        return false
    end
end

function NetworkManager:disconnect()
    if self.client then
        self.client:disconnect()
        self.client = nil
    end
    self.isOnline = false
    self.currentGame = nil
    self.autoReconnect = false -- Don't auto-reconnect after manual disconnect
    self.wasConnected = false
end

function NetworkManager:reconnect()
    -- Try to create a new connection with the same settings
    self.client = WebSocketClient:new(self.serverUrl)
    
    if self.client:connect() then
        self.isOnline = true
        self:setupCallbacks()
        return true
    else
        self.isOnline = false
        return false
    end
end

function NetworkManager:rejoinGame()
    -- Attempt to rejoin the game we were in
    if self.currentGame and self.currentGame.game_id and self.localPlayerName and self.localPlayerColor then
        print("Attempting to rejoin game: " .. self.currentGame.game_id)
        return self.client:joinGame(self.currentGame.game_id, self.localPlayerName, self.localPlayerColor)
    end
    return false
end

function NetworkManager:setupCallbacks()
    local MessageType = WebSocketClient.MessageType
    
    -- Game state updates
    self.client:on(MessageType.GAME_STATE, function(payload)
        self.currentGame = payload
        if self.onGameStateUpdate then
            self.onGameStateUpdate(payload)
        end
    end)
    
    -- Phase changes
    self.client:on(MessageType.PHASE_CHANGE, function(payload)
        if self.onPhaseChange then
            self.onPhaseChange(payload.phase, payload.round)
        end
    end)
    
    -- Turn changes
    self.client:on(MessageType.TURN_CHANGE, function(payload)
        if self.onTurnChange then
            self.onTurnChange(payload.current_player_id, payload.turn)
        end
    end)
    
    -- Error handling
    self.client:on(MessageType.ERROR, function(payload)
        if self.onError then
            self.onError(payload.code, payload.message)
        end
    end)
    
    -- Game list for lobby
    self.client:on(MessageType.LIST_GAMES, function(payload)
        if self.onGameList then
            self.onGameList(payload.games)
        end
    end)
end

function NetworkManager:update(dt)
    if self.client and self.isOnline then
        self.client:update(dt)
        
        -- Check if still connected
        if not self.client.connected then
            self.isOnline = false
            self.wasConnected = true
            
            if self.onConnectionLost then
                self.onConnectionLost()
            end
            
            if self.onError then
                self.onError("CONNECTION_LOST", "Lost connection to server")
            end
        end
    elseif self.autoReconnect and self.wasConnected and self.reconnectAttempts < self.maxReconnectAttempts then
        -- Handle reconnection
        self.reconnectTimer = self.reconnectTimer + dt
        
        if self.reconnectTimer >= self.reconnectDelay then
            self.reconnectTimer = 0
            self.reconnectAttempts = self.reconnectAttempts + 1
            
            print("Attempting to reconnect... (attempt " .. self.reconnectAttempts .. "/" .. self.maxReconnectAttempts .. ")")
            
            if self:reconnect() then
                self.reconnectAttempts = 0
                self.wasConnected = false
                
                if self.onReconnected then
                    self.onReconnected()
                end
                
                -- Rejoin game if we were in one
                if self.currentGame and self.currentGame.game_id then
                    self:rejoinGame()
                end
            end
        end
    end
end

-- Game actions

function NetworkManager:createGame(gameName, mapName)
    if not self.isOnline then return false end
    return self.client:createGame(gameName, mapName)
end

function NetworkManager:joinGame(gameId, playerName, color)
    if not self.isOnline then return false end
    
    self.localPlayerName = playerName
    self.localPlayerColor = color
    
    return self.client:joinGame(gameId, playerName, color)
end

function NetworkManager:startGame()
    if not self.isOnline then return false end
    return self.client:startGame()
end

function NetworkManager:requestGameList()
    if not self.isOnline then return false end
    return self.client:listGames()
end

-- Game actions that match the phase actions

function NetworkManager:bidOnPlant(plantId, bid)
    if not self.isOnline then return false end
    return self.client:bidOnPlant(plantId, bid)
end

function NetworkManager:buyResources(resources)
    if not self.isOnline then return false end
    return self.client:buyResources(resources)
end

function NetworkManager:buildCity(cityId)
    if not self.isOnline then return false end
    return self.client:buildCity(cityId)
end

function NetworkManager:powerCities(plantIds)
    if not self.isOnline then return false end
    return self.client:powerCities(plantIds)
end

function NetworkManager:endTurn()
    if not self.isOnline then return false end
    return self.client:endTurn()
end

-- Helper methods

function NetworkManager:isMyTurn()
    if not self.currentGame then return false end
    return self.currentGame.current_turn == self.localPlayerId
end

function NetworkManager:getCurrentPhase()
    if not self.currentGame then return nil end
    return self.currentGame.current_phase
end

function NetworkManager:getPlayers()
    if not self.currentGame then return {} end
    return self.currentGame.players or {}
end

function NetworkManager:getLocalPlayer()
    if not self.currentGame or not self.localPlayerId then return nil end
    return self.currentGame.players[self.localPlayerId]
end

-- Singleton instance
local instance = nil

function NetworkManager.getInstance()
    if not instance then
        instance = NetworkManager:new()
    end
    return instance
end

return NetworkManager