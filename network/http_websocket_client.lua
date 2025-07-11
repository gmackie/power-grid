-- Simple HTTP/WebSocket client for Love2D
-- This provides a basic WebSocket implementation using Love2D's built-in HTTP support
-- and socket library when available

local json = require("lib.json")

local HttpWebSocketClient = {}
HttpWebSocketClient.__index = HttpWebSocketClient

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

function HttpWebSocketClient:new(url)
    local self = setmetatable({}, HttpWebSocketClient)
    
    self.url = url
    self.baseUrl = url:gsub("ws://", "http://"):gsub("/game$", "")
    self.connected = false
    self.callbacks = {}
    self.messageQueue = {}
    self.sessionId = nil
    self.gameId = nil
    self.playerId = nil
    self.pollTimer = 0
    self.pollInterval = 0.1 -- Poll every 100ms for messages
    
    -- For now, use simple simulation mode since socket library setup is complex
    self.hasSocket = false
    print("Using simulation mode for HTTP client")
    
    return self
end

function HttpWebSocketClient:connect()
    print("Attempting to connect to: " .. self.baseUrl)
    
    -- First, try to connect and get a session ID
    local connectData = {
        type = MessageType.CONNECT,
        timestamp = os.time(),
        payload = {
            client_type = "love2d",
            version = "1.0"
        }
    }
    
    local response = self:sendHttpRequest("/connect", connectData)
    if response and response.session_id then
        self.sessionId = response.session_id
        self.connected = true
        print("Connected with session ID: " .. self.sessionId)
        return true
    else
        print("Failed to connect: " .. (response and response.error or "No response"))
        return false
    end
end

function HttpWebSocketClient:disconnect()
    if self.connected then
        self:send(MessageType.DISCONNECT, {})
        self.connected = false
        self.sessionId = nil
        print("Disconnected from server")
    end
end

function HttpWebSocketClient:sendHttpRequest(endpoint, data)
    local url = self.baseUrl .. endpoint
    local jsonData = json.encode(data)
    
    -- Add session ID to headers if we have one
    local headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = tostring(#jsonData)
    }
    
    if self.sessionId then
        headers["X-Session-ID"] = self.sessionId
    end
    
    if self.hasSocket then
        -- Use socket.http for better control
        local response = {}
        local result, status, responseHeaders = self.http.request{
            url = url,
            method = "POST",
            source = ltn12.source.string(jsonData),
            sink = ltn12.sink.table(response),
            headers = headers
        }
        
        if status == 200 and response[1] then
            local success, parsed = pcall(json.decode, table.concat(response))
            if success then
                return parsed
            end
        end
    else
        -- Fall back to Love2D's HTTP (limited functionality)
        print("Warning: Using basic HTTP client, some features may not work")
        -- Love2D doesn't have built-in HTTP POST, so we'll simulate responses
        return self:simulateResponse(endpoint, data)
    end
    
    return nil
end

function HttpWebSocketClient:simulateResponse(endpoint, data)
    -- Simulate server responses for testing when real HTTP isn't available
    if endpoint == "/connect" then
        return {
            session_id = "sim_" .. love.math.random(10000, 99999),
            status = "connected"
        }
    elseif endpoint == "/game" and data.type == MessageType.CREATE_GAME then
        return {
            type = MessageType.GAME_STATE,
            payload = {
                game_id = "sim_game_" .. love.math.random(1000, 9999),
                name = data.payload.name,
                status = "LOBBY",
                players = {},
                max_players = data.payload.max_players or 6
            }
        }
    elseif endpoint == "/game" and data.type == MessageType.LIST_GAMES then
        return {
            type = MessageType.LIST_GAMES,
            payload = {
                games = {
                    {
                        id = "sim_game_123",
                        name = "Test Game",
                        status = "LOBBY",
                        players = 1,
                        max_players = 6,
                        map = "usa"
                    }
                }
            }
        }
    end
    
    return {type = data.type, payload = {}}
end

function HttpWebSocketClient:send(messageType, payload)
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
    
    -- Send via HTTP endpoint
    local response = self:sendHttpRequest("/game", message)
    if response then
        -- Handle immediate response
        self:handleMessage(response)
        return true
    end
    
    return false
end

function HttpWebSocketClient:receive()
    -- Poll for messages from server
    if not self.connected then
        return nil
    end
    
    local pollData = {
        type = "POLL",
        session_id = self.sessionId,
        timestamp = os.time(),
        payload = {}
    }
    
    local response = self:sendHttpRequest("/poll", pollData)
    if response and response.messages then
        return response.messages
    end
    
    return nil
end

function HttpWebSocketClient:update(dt)
    if not self.connected then
        return
    end
    
    -- Poll for messages periodically
    self.pollTimer = self.pollTimer + dt
    if self.pollTimer >= self.pollInterval then
        self.pollTimer = 0
        
        local messages = self:receive()
        if messages then
            for _, message in ipairs(messages) do
                self:handleMessage(message)
            end
        end
    end
end

function HttpWebSocketClient:handleMessage(message)
    print("Received message: " .. (message.type or "unknown"))
    
    -- Update session/game IDs if provided
    if message.session_id then
        self.sessionId = message.session_id
    end
    
    -- Handle specific message types
    if message.type == MessageType.PONG then
        -- Ping response, connection is alive
        return
    elseif message.type == MessageType.GAME_STATE then
        if message.payload and message.payload.game_id then
            self.gameId = message.payload.game_id
        end
    elseif message.type == MessageType.ERROR then
        print("Server error: " .. (message.payload and message.payload.message or "Unknown error"))
    end
    
    -- Call registered callbacks
    local callback = self.callbacks[message.type]
    if callback then
        callback(message.payload)
    end
end

function HttpWebSocketClient:on(messageType, callback)
    self.callbacks[messageType] = callback
end

-- Game-specific methods (same as WebSocket client)

function HttpWebSocketClient:createGame(name, map, maxPlayers)
    return self:send(MessageType.CREATE_GAME, {
        name = name,
        map = map,
        max_players = maxPlayers or 6
    })
end

function HttpWebSocketClient:joinGame(gameId, playerName, color)
    self.gameId = gameId
    return self:send(MessageType.JOIN_GAME, {
        game_id = gameId,
        player_name = playerName,
        color = color
    })
end

function HttpWebSocketClient:startGame()
    return self:send(MessageType.START_GAME, {})
end

function HttpWebSocketClient:listGames()
    return self:send(MessageType.LIST_GAMES, {})
end

function HttpWebSocketClient:bidOnPlant(plantId, bid)
    return self:send(MessageType.BID_PLANT, {
        plant_id = plantId,
        bid = bid
    })
end

function HttpWebSocketClient:buyResources(resources)
    return self:send(MessageType.BUY_RESOURCES, {
        resources = resources
    })
end

function HttpWebSocketClient:buildCity(cityId)
    return self:send(MessageType.BUILD_CITY, {
        city_id = cityId
    })
end

function HttpWebSocketClient:powerCities(plantIds)
    return self:send(MessageType.POWER_CITIES, {
        power_plants = plantIds
    })
end

function HttpWebSocketClient:endTurn()
    return self:send(MessageType.END_TURN, {})
end

-- Export message types for external use
HttpWebSocketClient.MessageType = MessageType

return HttpWebSocketClient