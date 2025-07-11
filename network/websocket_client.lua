-- WebSocket client for multiplayer functionality
-- Falls back to HTTP polling when WebSocket library is not available

local json = require("lib.json")

local WebSocketClient = {}
WebSocketClient.__index = WebSocketClient

-- Message types matching the Go server protocol
local MessageType = {
    -- Connection messages
    CONNECT = "CONNECT",
    DISCONNECT = "DISCONNECT",
    PING = "PING",
    PONG = "PONG",
    
    -- Lobby messages
    CREATE_GAME = "CREATE_GAME",
    JOIN_GAME = "JOIN_GAME",
    LEAVE_GAME = "LEAVE_GAME",
    LIST_GAMES = "LIST_GAMES",
    START_GAME = "START_GAME",
    
    -- Game action messages
    GAME_STATE = "GAME_STATE",
    BID_PLANT = "BID_PLANT",
    BUY_RESOURCES = "BUY_RESOURCES",
    BUILD_CITY = "BUILD_CITY",
    POWER_CITIES = "POWER_CITIES",
    END_TURN = "END_TURN",
    
    -- Notification messages
    ERROR = "ERROR",
    PHASE_CHANGE = "PHASE_CHANGE",
    TURN_CHANGE = "TURN_CHANGE"
}

function WebSocketClient:new(url)
    local self = setmetatable({}, WebSocketClient)
    self.url = url
    self.connected = false
    self.ws = nil
    self.callbacks = {}
    self.messageQueue = {}
    self.sessionId = nil
    self.gameId = nil
    self.playerId = nil
    
    -- Try to load websocket library first
    local success, ws_lib = pcall(require, "websocket")
    if success then
        self.ws_client = ws_lib.client
        self.mode = "websocket"
        print("Using WebSocket library")
    else
        -- Fall back to HTTP polling implementation
        local HttpClient = require("network.http_websocket_client")
        self.httpClient = HttpClient:new(url)
        self.mode = "http"
        print("WebSocket library not available, using HTTP polling")
    end
    
    return self
end

function WebSocketClient:connect()
    if self.mode == "http" then
        return self.httpClient:connect()
    elseif self.mode == "websocket" then
        local ws = self.ws_client.new()
        local success, err = ws:connect(self.url)
        
        if success then
            self.ws = ws
            self.connected = true
            print("Connected to WebSocket server: " .. self.url)
            return true
        else
            print("Failed to connect: " .. tostring(err))
            return false
        end
    end
    
    return false
end

function WebSocketClient:disconnect()
    if self.mode == "http" then
        self.httpClient:disconnect()
        self.connected = self.httpClient.connected
    elseif self.connected then
        self:send(MessageType.DISCONNECT, {})
        if self.ws then
            self.ws:close()
        end
        self.connected = false
        print("Disconnected from WebSocket server")
    end
end

function WebSocketClient:send(messageType, payload)
    if self.mode == "http" then
        return self.httpClient:send(messageType, payload)
    end
    
    if not self.connected then
        print("Not connected to server")
        return false
    end
    
    local message = {
        type = messageType,
        timestamp = os.time(),
        session_id = self.sessionId,
        game_id = self.gameId,
        payload = payload or {}
    }
    
    local jsonStr = json.encode(message)
    
    local success, err = self.ws:send(jsonStr)
    if not success then
        print("Failed to send message: " .. tostring(err))
        return false
    end
    
    return true
end

function WebSocketClient:receive()
    if self.mode == "http" then
        return self.httpClient:receive()
    end
    
    if not self.connected then
        return nil
    end
    
    local message, err = self.ws:receive()
    if message then
        local success, data = pcall(json.decode, message)
        if success then
            return data
        else
            print("Failed to parse message: " .. tostring(data))
        end
    elseif err ~= "timeout" then
        print("Receive error: " .. tostring(err))
        self.connected = false
    end
    
    return nil
end

function WebSocketClient:update(dt)
    if self.mode == "http" then
        self.httpClient:update(dt)
        self.connected = self.httpClient.connected
        self.sessionId = self.httpClient.sessionId
        self.gameId = self.httpClient.gameId
        
        -- Forward callbacks from HTTP client
        for msgType, callback in pairs(self.callbacks) do
            self.httpClient:on(msgType, callback)
        end
        return
    end
    
    if not self.connected then
        return
    end
    
    -- Process incoming messages
    local message = self:receive()
    while message do
        self:handleMessage(message)
        message = self:receive()
    end
    
    -- Send ping every 30 seconds to keep connection alive
    self.pingTimer = (self.pingTimer or 0) + dt
    if self.pingTimer > 30 then
        self:send(MessageType.PING, {})
        self.pingTimer = 0
    end
end

function WebSocketClient:handleMessage(message)
    print("Received message: " .. message.type)
    
    -- Update session/game IDs if provided
    if message.session_id then
        self.sessionId = message.session_id
    end
    
    -- Handle specific message types
    if message.type == MessageType.PONG then
        -- Ping response, connection is alive
        return
    elseif message.type == MessageType.GAME_STATE then
        if message.payload.game_id then
            self.gameId = message.payload.game_id
        end
    elseif message.type == MessageType.ERROR then
        print("Server error: " .. (message.payload.message or "Unknown error"))
    end
    
    -- Call registered callbacks
    local callback = self.callbacks[message.type]
    if callback then
        callback(message.payload)
    end
end

function WebSocketClient:on(messageType, callback)
    self.callbacks[messageType] = callback
end

-- Game-specific methods

function WebSocketClient:createGame(name, map, maxPlayers)
    return self:send(MessageType.CREATE_GAME, {
        name = name,
        map = map,
        max_players = maxPlayers or 6
    })
end

function WebSocketClient:joinGame(gameId, playerName, color)
    self.gameId = gameId
    return self:send(MessageType.JOIN_GAME, {
        game_id = gameId,
        player_name = playerName,
        color = color
    })
end

function WebSocketClient:startGame()
    return self:send(MessageType.START_GAME, {})
end

function WebSocketClient:listGames()
    return self:send(MessageType.LIST_GAMES, {})
end

function WebSocketClient:bidOnPlant(plantId, bid)
    return self:send(MessageType.BID_PLANT, {
        plant_id = plantId,
        bid = bid
    })
end

function WebSocketClient:buyResources(resources)
    return self:send(MessageType.BUY_RESOURCES, {
        resources = resources
    })
end

function WebSocketClient:buildCity(cityId)
    return self:send(MessageType.BUILD_CITY, {
        city_id = cityId
    })
end

function WebSocketClient:powerCities(plantIds)
    return self:send(MessageType.POWER_CITIES, {
        power_plants = plantIds
    })
end

function WebSocketClient:endTurn()
    return self:send(MessageType.END_TURN, {})
end

-- Export message types for external use
WebSocketClient.MessageType = MessageType

return WebSocketClient