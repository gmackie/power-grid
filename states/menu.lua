local menu = {}
local State = require("state")
local UI = require("ui")
local NetworkManager = require("network.network_manager")
local MobileButton = require("ui.mobile_button")
local MobileConfig = require("mobile.mobile_config")

function menu:enter()
    print("Menu state entered")
    self.network = NetworkManager.getInstance()
    
    -- Get responsive layout configuration
    local screenConfig = MobileConfig.getScreenConfig()
    local layout = MobileConfig.getLayout()
    local buttonConfig = MobileConfig.getButtonConfig()
    
    -- Calculate responsive button positioning
    local centerX = screenConfig.width / 2
    local startY = screenConfig.height * 0.4  -- Start at 40% down the screen
    local buttonWidth = math.min(buttonConfig.minWidth * 2, screenConfig.width - layout.margin * 2)
    local buttonHeight = buttonConfig.minHeight
    local spacing = layout.spacing * 2
    
    -- Create mobile-friendly buttons
    self.buttons = {}
    
    self.playOnlineButton = MobileButton.new("Play Online", 
        centerX - buttonWidth/2, startY, buttonWidth, buttonHeight)
    self.playOnlineButton.onTap = function() self:connectOnline() end
    table.insert(self.buttons, self.playOnlineButton)
    
    self.passPlayButton = MobileButton.new("Pass and Play", 
        centerX - buttonWidth/2, startY + (buttonHeight + spacing), buttonWidth, buttonHeight)
    self.passPlayButton.onTap = function() changeState("playerSetup") end
    table.insert(self.buttons, self.passPlayButton)
    
    self.settingsButton = MobileButton.new("Settings", 
        centerX - buttonWidth/2, startY + 2*(buttonHeight + spacing), buttonWidth, buttonHeight)
    self.settingsButton.onTap = function() print("Settings not implemented yet") end
    table.insert(self.buttons, self.settingsButton)
    
    -- Only show exit button on desktop
    if not screenConfig.isMobile then
        self.exitButton = MobileButton.new("Exit", 
            centerX - buttonWidth/2, startY + 3*(buttonHeight + spacing), buttonWidth, buttonHeight)
        self.exitButton.onTap = function() love.event.quit() end
        table.insert(self.buttons, self.exitButton)
    end
    
    -- Connection status
    self.connectionStatus = ""
    self.connecting = false
end

function menu:connectOnline()
    if self.connecting then return end
    
    self.connecting = true
    self.connectionStatus = "Connecting to server..."
    
    -- Try to connect
    love.timer.sleep(0.1) -- Small delay for UI feedback
    
    if self.network:connect() then
        self.connectionStatus = "Connected!"
        -- Switch to lobby browser after a brief delay
        love.timer.sleep(0.5)
        changeState("lobbyBrowser")
    else
        self.connectionStatus = "Failed to connect. Check server is running."
        self.connecting = false
    end
end

function menu:update(dt)
    -- Update mobile buttons
    for _, button in ipairs(self.buttons) do
        button:update(dt)
    end
    
    -- Update network manager if connected
    if self.network.isOnline then
        self.network:update(dt)
    end
end

function menu:draw()
    love.graphics.clear(0.15, 0.15, 0.18)
    
    local screenConfig = MobileConfig.getScreenConfig()
    local fontSizes = MobileConfig.getFontSizes()
    
    -- Title - responsive font size
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(fontSizes.title))
    love.graphics.printf("Power Grid Digital", 0, screenConfig.height * 0.15, screenConfig.width, "center")
    
    -- Subtitle
    love.graphics.setFont(love.graphics.newFont(fontSizes.medium))
    love.graphics.printf("A digital adaptation of the board game", 0, screenConfig.height * 0.25, screenConfig.width, "center")
    
    -- Draw mobile buttons
    for _, button in ipairs(self.buttons) do
        button:draw()
    end
    
    -- Connection status - positioned responsively
    if self.connectionStatus ~= "" then
        love.graphics.setFont(love.graphics.newFont(fontSizes.medium))
        love.graphics.setColor(1, 1, 0.5, 1)
        love.graphics.printf(self.connectionStatus, 0, screenConfig.height * 0.8, screenConfig.width, "center")
    end
    
    -- Version info - only on desktop or if there's space
    if not screenConfig.isMobile or screenConfig.isTablet then
        love.graphics.setFont(love.graphics.newFont(fontSizes.small))
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.print("v0.2.0 - Mobile & PC Edition", 10, screenConfig.height - 25)
    end
end

-- Input handling - supports both mouse and touch
function menu:mousepressed(x, y, button)
    if button == 1 then
        for _, btn in ipairs(self.buttons) do
            if btn:mousepressed(x, y, button) then
                break
            end
        end
    end
end

function menu:mousereleased(x, y, button)
    if button == 1 then
        for _, btn in ipairs(self.buttons) do
            btn:mousereleased(x, y, button)
        end
    end
end

function menu:mousemoved(x, y, dx, dy)
    for _, btn in ipairs(self.buttons) do
        btn:mousemoved(x, y, dx, dy)
    end
end

-- Touch input handlers
function menu:touchpressed(id, x, y, dx, dy, pressure)
    for _, btn in ipairs(self.buttons) do
        if btn:touchpressed(id, x, y, dx, dy, pressure) then
            break
        end
    end
end

function menu:touchmoved(id, x, y, dx, dy, pressure)
    for _, btn in ipairs(self.buttons) do
        btn:touchmoved(id, x, y, dx, dy, pressure)
    end
end

function menu:touchreleased(id, x, y, dx, dy, pressure)
    for _, btn in ipairs(self.buttons) do
        btn:touchreleased(id, x, y, dx, dy, pressure)
    end
end

function menu:leave()
    -- Clean up when leaving menu
    self.connectionStatus = ""
    self.connecting = false
end

return menu