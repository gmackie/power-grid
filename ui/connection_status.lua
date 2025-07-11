-- Connection Status UI Component
local ConnectionStatus = {}
ConnectionStatus.__index = ConnectionStatus

local NetworkManager = require("network.network_manager")

function ConnectionStatus.new(x, y)
    local self = setmetatable({}, ConnectionStatus)
    self.x = x or love.graphics.getWidth() - 100
    self.y = y or 10
    self.width = 90
    self.height = 30
    return self
end

function ConnectionStatus:update(dt)
    -- Position updates if window resizes
    self.x = love.graphics.getWidth() - self.width - 10
end

function ConnectionStatus:draw()
    local network = NetworkManager.getInstance()
    
    -- Background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", self.x - 5, self.y - 5, self.width + 10, self.height + 10, 5)
    
    -- Status indicator and text
    local statusText = "Offline"
    local statusColor = {0.5, 0.5, 0.5} -- Gray
    
    if network.isOnline then
        statusText = "Online"
        statusColor = {0.2, 1, 0.2} -- Green
    elseif network.wasConnected and network.autoReconnect then
        -- Reconnecting
        statusText = "Reconnecting..."
        statusColor = {1, 1, 0.2} -- Yellow
        
        if network.reconnectAttempts > 0 then
            statusText = "Retry " .. network.reconnectAttempts .. "/" .. network.maxReconnectAttempts
        end
    elseif network.wasConnected and network.reconnectAttempts >= network.maxReconnectAttempts then
        statusText = "Disconnected"
        statusColor = {1, 0.2, 0.2} -- Red
    end
    
    -- Draw status dot
    love.graphics.setColor(statusColor)
    love.graphics.circle("fill", self.x + 10, self.y + self.height/2, 6)
    
    -- Draw status text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print(statusText, self.x + 20, self.y + self.height/2 - 6)
    
    -- Draw reconnection timer if reconnecting
    if network.wasConnected and network.autoReconnect and network.reconnectAttempts < network.maxReconnectAttempts then
        local timeLeft = math.ceil(network.reconnectDelay - network.reconnectTimer)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.print("Next try in " .. timeLeft .. "s", self.x, self.y + self.height + 2)
    end
    
    -- Draw game info if in a game
    if network.currentGame and network.currentGame.game_id then
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        local gameText = "Game: " .. string.sub(network.currentGame.game_id, 1, 8) .. "..."
        love.graphics.print(gameText, self.x, self.y - 12)
    end
end

function ConnectionStatus:mousepressed(x, y, button)
    -- Check if clicked on the status indicator
    if button == 1 and x >= self.x - 5 and x <= self.x + self.width + 5 and
       y >= self.y - 5 and y <= self.y + self.height + 5 then
        local network = NetworkManager.getInstance()
        
        if not network.isOnline and network.wasConnected then
            -- Manual reconnection attempt
            network.reconnectAttempts = 0
            network.reconnectTimer = network.reconnectDelay -- Trigger immediate reconnect
            print("Manual reconnection triggered")
        end
    end
end

return ConnectionStatus