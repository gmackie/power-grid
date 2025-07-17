-- Enhanced Menu State with improved visuals
local menu = {}
local State = require("state")
local NetworkManager = require("network.network_manager")
local StyledButton = require("ui.styled_button")
local Theme = require("ui.theme")
local AssetLoader = require("assets.asset_loader")
local MobileConfig = require("mobile.mobile_config")

-- Visual elements
local particles = {}
local backgroundGradient = nil
local logoScale = 0
local logoTargetScale = 1
local titleAlpha = 0
local buttonStagger = 0

function menu:enter()
    print("Enhanced menu state entered")
    self.network = NetworkManager.getInstance()
    
    -- Load assets
    AssetLoader.loadAll()
    
    -- Get responsive layout configuration
    local screenConfig = MobileConfig.getScreenConfig()
    local layout = MobileConfig.getLayout()
    
    -- Create background gradient
    self:createBackgroundGradient()
    
    -- Initialize animations
    logoScale = 0
    logoTargetScale = 1
    titleAlpha = 0
    buttonStagger = 0
    
    -- Create particle system for background
    self:initParticles()
    
    -- Calculate responsive button positioning
    local centerX = screenConfig.width / 2
    local startY = screenConfig.height * 0.45
    local buttonWidth = math.min(300, screenConfig.width - layout.margin * 4)
    local buttonHeight = Theme.layout.buttonHeightLarge
    local spacing = Theme.layout.spacing * 2
    
    -- Create styled buttons with staggered animation
    self.buttons = {}
    
    -- Play Online button
    self.playOnlineButton = StyledButton.new("Play Online", 
        centerX - buttonWidth/2, startY, buttonWidth, buttonHeight, {
            type = "primary",
            icon = "online",
            onTap = function() self:connectOnline() end
        })
    self.playOnlineButton.targetAlpha = 0
    table.insert(self.buttons, self.playOnlineButton)
    
    -- Pass and Play button
    self.passPlayButton = StyledButton.new("Pass and Play", 
        centerX - buttonWidth/2, startY + (buttonHeight + spacing), buttonWidth, buttonHeight, {
            type = "primary",
            icon = "players",
            onTap = function() changeState("playerSetup") end
        })
    self.passPlayButton.targetAlpha = 0
    table.insert(self.buttons, self.passPlayButton)
    
    -- Settings button
    self.settingsButton = StyledButton.new("Settings", 
        centerX - buttonWidth/2, startY + 2*(buttonHeight + spacing), buttonWidth, buttonHeight, {
            type = "secondary",
            icon = "settings",
            onTap = function() print("Settings not implemented yet") end
        })
    self.settingsButton.targetAlpha = 0
    table.insert(self.buttons, self.settingsButton)
    
    -- Exit button (desktop only)
    if not screenConfig.isMobile then
        self.exitButton = StyledButton.new("Exit", 
            centerX - buttonWidth/2, startY + 3*(buttonHeight + spacing), buttonWidth, buttonHeight, {
                type = "secondary",
                icon = "close",
                onTap = function() love.event.quit() end
            })
        self.exitButton.targetAlpha = 0
        table.insert(self.buttons, self.exitButton)
    end
    
    -- Connection status
    self.connectionStatus = ""
    self.statusAlpha = 0
    
    -- Create fonts
    self.titleFont = love.graphics.newFont(Theme.fonts.title)
    self.subtitleFont = love.graphics.newFont(Theme.fonts.large)
    self.versionFont = love.graphics.newFont(Theme.fonts.small)
end

function menu:createBackgroundGradient()
    local screenConfig = MobileConfig.getScreenConfig()
    local canvas = love.graphics.newCanvas(screenConfig.width, screenConfig.height)
    
    love.graphics.setCanvas(canvas)
    
    -- Draw gradient background
    local gradientMesh = love.graphics.newMesh({
        {0, 0, 0, 0, Theme.colors.backgroundDark[1], Theme.colors.backgroundDark[2], Theme.colors.backgroundDark[3], 1},
        {screenConfig.width, 0, 1, 0, Theme.colors.backgroundDark[1], Theme.colors.backgroundDark[2], Theme.colors.backgroundDark[3], 1},
        {screenConfig.width, screenConfig.height, 1, 1, Theme.colors.background[1], Theme.colors.background[2], Theme.colors.background[3], 1},
        {0, screenConfig.height, 0, 1, Theme.colors.background[1], Theme.colors.background[2], Theme.colors.background[3], 1}
    }, "fan")
    
    love.graphics.draw(gradientMesh)
    love.graphics.setCanvas()
    
    backgroundGradient = canvas
end

function menu:initParticles()
    local screenConfig = MobileConfig.getScreenConfig()
    
    -- Create floating energy particles
    for i = 1, 20 do
        table.insert(particles, {
            x = math.random(0, screenConfig.width),
            y = math.random(0, screenConfig.height),
            vx = math.random(-20, 20),
            vy = math.random(-30, -10),
            size = math.random(2, 5),
            alpha = math.random(0.3, 0.7),
            color = math.random() > 0.5 and Theme.colors.primary or Theme.colors.secondary
        })
    end
end

function menu:updateParticles(dt)
    local screenConfig = MobileConfig.getScreenConfig()
    
    for _, particle in ipairs(particles) do
        particle.x = particle.x + particle.vx * dt
        particle.y = particle.y + particle.vy * dt
        
        -- Wrap around screen
        if particle.y < -10 then
            particle.y = screenConfig.height + 10
            particle.x = math.random(0, screenConfig.width)
        end
        
        if particle.x < -10 then
            particle.x = screenConfig.width + 10
        elseif particle.x > screenConfig.width + 10 then
            particle.x = -10
        end
        
        -- Gentle floating motion
        particle.vx = particle.vx + math.sin(love.timer.getTime() * 2 + particle.y * 0.01) * 10 * dt
    end
end

function menu:connectOnline()
    self.connectionStatus = "Connecting to server..."
    self.statusAlpha = 1
    
    self.network:connect("localhost", 4080, 
        function() 
            changeState("lobbyBrowser")
        end,
        function(err) 
            self.connectionStatus = "Connection failed: " .. (err or "Unknown error")
            self.statusAlpha = 1
        end
    )
end

function menu:update(dt)
    -- Update animations
    logoScale = logoScale + (logoTargetScale - logoScale) * 5 * dt
    titleAlpha = math.min(1, titleAlpha + dt * 2)
    
    -- Stagger button appearance
    buttonStagger = math.min(1, buttonStagger + dt * 1.5)
    
    for i, button in ipairs(self.buttons) do
        local staggerDelay = (i - 1) * 0.1
        local progress = math.max(0, buttonStagger - staggerDelay)
        button.targetAlpha = math.min(1, progress * 3)
        button:update(dt)
    end
    
    -- Update particles
    self:updateParticles(dt)
    
    -- Fade out connection status
    if self.statusAlpha > 0 then
        self.statusAlpha = math.max(0, self.statusAlpha - dt * 0.5)
    end
    
    -- Update network manager if connected
    if self.network.isOnline then
        self.network:update(dt)
    end
end

function menu:draw()
    local screenConfig = MobileConfig.getScreenConfig()
    
    -- Draw gradient background
    if backgroundGradient then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(backgroundGradient, 0, 0)
    else
        love.graphics.clear(Theme.colors.backgroundDark)
    end
    
    -- Draw particles
    for _, particle in ipairs(particles) do
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], particle.alpha * 0.5)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
    end
    
    -- Draw grid pattern overlay
    love.graphics.setColor(Theme.colors.primary[1], Theme.colors.primary[2], Theme.colors.primary[3], 0.05)
    love.graphics.setLineWidth(1)
    local gridSize = 50
    for x = 0, screenConfig.width, gridSize do
        love.graphics.line(x, 0, x, screenConfig.height)
    end
    for y = 0, screenConfig.height, gridSize do
        love.graphics.line(0, y, screenConfig.width, y)
    end
    
    -- Draw title with glow effect
    love.graphics.push()
    love.graphics.translate(screenConfig.width / 2, screenConfig.height * 0.15)
    love.graphics.scale(logoScale, logoScale)
    love.graphics.translate(-screenConfig.width / 2, -screenConfig.height * 0.15)
    
    -- Title glow
    love.graphics.setColor(Theme.colors.primary[1], Theme.colors.primary[2], Theme.colors.primary[3], titleAlpha * 0.3)
    love.graphics.setFont(self.titleFont)
    for i = 1, 3 do
        love.graphics.printf("POWER GRID", -i, screenConfig.height * 0.15 - i, screenConfig.width, "center")
        love.graphics.printf("POWER GRID", i, screenConfig.height * 0.15 - i, screenConfig.width, "center")
        love.graphics.printf("POWER GRID", -i, screenConfig.height * 0.15 + i, screenConfig.width, "center")
        love.graphics.printf("POWER GRID", i, screenConfig.height * 0.15 + i, screenConfig.width, "center")
    end
    
    -- Main title
    Theme.setColor("textPrimary", titleAlpha)
    love.graphics.printf("POWER GRID", 0, screenConfig.height * 0.15, screenConfig.width, "center")
    
    -- Subtitle
    love.graphics.setFont(self.subtitleFont)
    Theme.setColor("primary", titleAlpha * 0.8)
    love.graphics.printf("DIGITAL", 0, screenConfig.height * 0.15 + 60, screenConfig.width, "center")
    
    love.graphics.pop()
    
    -- Tag line
    love.graphics.setFont(self.subtitleFont)
    Theme.setColor("textSecondary", titleAlpha)
    love.graphics.printf("Build • Connect • Power", 0, screenConfig.height * 0.32, screenConfig.width, "center")
    
    -- Draw buttons
    for _, button in ipairs(self.buttons) do
        button:draw()
    end
    
    -- Connection status
    if self.statusAlpha > 0 then
        love.graphics.setFont(self.subtitleFont)
        Theme.setColor("warning", self.statusAlpha)
        love.graphics.printf(self.connectionStatus, 0, screenConfig.height * 0.8, screenConfig.width, "center")
    end
    
    -- Version info
    if not screenConfig.isMobile or screenConfig.isTablet then
        love.graphics.setFont(self.versionFont)
        Theme.setColor("textDisabled")
        love.graphics.print("v0.3.0 - Enhanced Edition", Theme.layout.margin, screenConfig.height - 30)
        
        -- Network status indicator
        local statusX = screenConfig.width - 150
        local statusY = screenConfig.height - 30
        
        if self.network.isOnline then
            Theme.setColor("success")
            love.graphics.circle("fill", statusX, statusY + 10, 5)
            Theme.setColor("textSecondary")
            love.graphics.print("Online", statusX + 10, statusY)
        else
            Theme.setColor("textDisabled")
            love.graphics.circle("line", statusX, statusY + 10, 5)
            love.graphics.print("Offline", statusX + 10, statusY)
        end
    end
end

function menu:mousepressed(x, y, button)
    for _, btn in ipairs(self.buttons) do
        if btn:mousepressed(x, y, button) then
            return
        end
    end
end

function menu:mousereleased(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:mousereleased(x, y, button)
    end
end

function menu:mousemoved(x, y)
    for _, btn in ipairs(self.buttons) do
        btn:mousemoved(x, y)
    end
end

function menu:touchpressed(id, x, y)
    for _, btn in ipairs(self.buttons) do
        if btn:touchpressed(id, x, y) then
            return
        end
    end
end

function menu:touchreleased(id, x, y)
    for _, btn in ipairs(self.buttons) do
        btn:touchreleased(id, x, y)
    end
end

return menu