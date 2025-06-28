-- UIManager for Power Grid Digital
-- Manages all UI components and their interactions

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"
local Button = require "src.ui.button"
local CityPanel = require "src.ui.cityPanel"
local GameBoard = require "src.ui.gameBoard"
local MarketPanel = require "src.ui.marketPanel"
local PhasePanel = require "src.ui.phasePanel"
local PlayerPanel = require "src.ui.playerPanel"
local PowerPlantPanel = require "src.ui.powerPlantPanel"
local ResourcePanel = require "src.ui.resourcePanel"
local ErrorPanel = require "src.ui.errorPanel"
local TransitionOverlay = require "src.ui.transitionOverlay"

local UIManager = class('UIManager')

-- Create a new UI manager
function UIManager.new(options)
    local manager = UIManager()
    manager:initialize(options)
    return manager
end

-- Initialize the UI manager
function UIManager:initialize(options)
    -- Set default options
    self.options = options or {}
    self.options.backgroundColor = self.options.backgroundColor or {0.1, 0.1, 0.2, 0.8}
    self.options.borderColor = self.options.borderColor or {0.2, 0.2, 0.3, 1}
    self.options.textColor = self.options.textColor or {1, 1, 1, 1}
    self.options.fontSize = self.options.fontSize or 14
    self.options.padding = self.options.padding or 10
    self.options.cornerRadius = self.options.cornerRadius or 5
    
    -- Get window dimensions
    self.width = love.graphics.getWidth()
    self.height = love.graphics.getHeight()
    
    -- Create main panel
    self.mainPanel = Panel.new(0, 0, self.width, self.height, {
        backgroundColor = {0, 0, 0, 0},
        borderColor = {0, 0, 0, 0},
        cornerRadius = 0
    })
    
    -- Create game board
    self.gameBoard = GameBoard.new(0, 0, self.width * 0.7, self.height * 0.7, {
        backgroundColor = {0.2, 0.2, 0.3, 0.8},
        borderColor = {0.3, 0.3, 0.4, 1},
        textColor = self.options.textColor,
        fontSize = self.options.fontSize,
        padding = self.options.padding,
        cornerRadius = self.options.cornerRadius
    })
    
    -- Create side panels
    local sidePanelWidth = self.width * 0.3
    local sidePanelHeight = self.height / 3
    
    -- Create phase panel
    self.phasePanel = PhasePanel.new(self.width * 0.7 + self.options.padding, self.options.padding,
        sidePanelWidth - (2 * self.options.padding), sidePanelHeight, {
            backgroundColor = self.options.backgroundColor,
            borderColor = self.options.borderColor,
            textColor = self.options.textColor,
            fontSize = self.options.fontSize,
            padding = self.options.padding,
            cornerRadius = self.options.cornerRadius
        })
    
    -- Create market panel
    self.marketPanel = MarketPanel.new(self.width * 0.7 + self.options.padding,
        self.options.padding + 110, sidePanelWidth - (2 * self.options.padding), sidePanelHeight, {
            backgroundColor = self.options.backgroundColor,
            borderColor = self.options.borderColor,
            textColor = self.options.textColor,
            fontSize = self.options.fontSize,
            padding = self.options.padding,
            cornerRadius = self.options.cornerRadius
        })
    
    -- Create player panel
    self.playerPanel = PlayerPanel.new(self.width * 0.7 + self.options.padding,
        self.options.padding + 270, sidePanelWidth - (2 * self.options.padding), sidePanelHeight, {
            backgroundColor = self.options.backgroundColor,
            borderColor = self.options.borderColor,
            textColor = self.options.textColor,
            fontSize = self.options.fontSize,
            padding = self.options.padding,
            cornerRadius = self.options.cornerRadius
        })
    
    -- Create power plant panel
    self.powerPlantPanel = PowerPlantPanel.new(self.width * 0.7 + self.options.padding,
        self.options.padding + 480, sidePanelWidth - (2 * self.options.padding), sidePanelHeight, {
            backgroundColor = self.options.backgroundColor,
            borderColor = self.options.borderColor,
            textColor = self.options.textColor,
            fontSize = self.options.fontSize,
            padding = self.options.padding,
            cornerRadius = self.options.cornerRadius
        })
    
    -- Create resource panel
    self.resourcePanel = ResourcePanel.new(self.width * 0.7 + self.options.padding,
        self.options.padding + 690, sidePanelWidth - (2 * self.options.padding), sidePanelHeight, {
            backgroundColor = self.options.backgroundColor,
            borderColor = self.options.borderColor,
            textColor = self.options.textColor,
            fontSize = self.options.fontSize,
            padding = self.options.padding,
            cornerRadius = self.options.cornerRadius
        })
    
    -- Create city panel
    self.cityPanel = CityPanel.new(self.width * 0.7 + self.options.padding,
        self.options.padding + 850, sidePanelWidth - (2 * self.options.padding), sidePanelHeight, {
            backgroundColor = self.options.backgroundColor,
            borderColor = self.options.borderColor,
            textColor = self.options.textColor,
            fontSize = self.options.fontSize,
            padding = self.options.padding,
            cornerRadius = self.options.cornerRadius
        })
    
    -- Create error panel
    self.errorPanel = ErrorPanel.new(self.width/2 - 150, self.height/2 - 75, 300, 150, {
        backgroundColor = {0.3, 0.1, 0.1, 0.9},
        borderColor = {0.4, 0.2, 0.2, 1},
        textColor = self.options.textColor,
        fontSize = self.options.fontSize,
        padding = self.options.padding,
        cornerRadius = self.options.cornerRadius
    })
    
    -- Create transition overlay
    self.transitionOverlay = TransitionOverlay.new(0, 0, self.width, self.height, {
        backgroundColor = {0, 0, 0, 0},
        textColor = self.options.textColor,
        fontSize = self.options.fontSize * 2,
        padding = self.options.padding,
        cornerRadius = 0,
        transitionDuration = 0.5,
        fadeInDuration = 0.3,
        fadeOutDuration = 0.3
    })
    
    -- UI manager state
    self.visible = true
    self.activePanel = nil
    self.onCitySelected = nil
    self.onPowerPlantSelected = nil
    self.onResourceSelected = nil
    self.onBuildConnection = nil
    self.onPurchasePowerPlant = nil
    self.onPurchaseResource = nil
    
    -- Set up event handlers
    self:setupEventHandlers()
    
    return self
end

-- Set up event handlers
function UIManager:setupEventHandlers()
    -- Game board handlers
    self.gameBoard:setOnCitySelected(function(city)
        if self.onCitySelected then
            self.onCitySelected(city)
        end
    end)
    
    self.gameBoard:setOnPowerPlantSelected(function(powerPlant)
        if self.onPowerPlantSelected then
            self.onPowerPlantSelected(powerPlant)
        end
    end)
    
    -- City panel handlers
    self.cityPanel:setOnBuildConnection(function(city1, city2)
        if self.onBuildConnection then
            self.onBuildConnection(city1, city2)
        end
    end)
    
    -- Power plant panel handlers
    self.powerPlantPanel:setOnPurchase(function(powerPlant)
        if self.onPurchasePowerPlant then
            self.onPurchasePowerPlant(powerPlant)
        end
    end)
    
    -- Resource panel handlers
    self.resourcePanel:setOnPurchase(function(resource, amount)
        if self.onPurchaseResource then
            self.onPurchaseResource(resource, amount)
        end
    end)
    
    -- Error panel handlers
    self.errorPanel:setOnDismiss(function()
        self.activePanel = nil
    end)
end

-- Set UI manager visibility
function UIManager:setVisible(visible)
    self.visible = visible
    self.mainPanel:setVisible(visible)
    self.gameBoard:setVisible(visible)
    self.phasePanel:setVisible(visible)
    self.marketPanel:setVisible(visible)
    self.playerPanel:setVisible(visible)
    self.powerPlantPanel:setVisible(visible)
    self.resourcePanel:setVisible(visible)
    self.cityPanel:setVisible(visible)
    self.errorPanel:setVisible(visible)
    self.transitionOverlay:setVisible(visible)
end

-- Get UI manager visibility
function UIManager:isVisible()
    return self.visible
end

-- Set active panel
function UIManager:setActivePanel(panel)
    self.activePanel = panel
    
    -- Hide all panels
    self.cityPanel:setVisible(false)
    self.powerPlantPanel:setVisible(false)
    self.resourcePanel:setVisible(false)
    
    -- Show active panel
    if panel then
        panel:setVisible(true)
    end
end

-- Set city selection handler
function UIManager:setOnCitySelected(handler)
    self.onCitySelected = handler
end

-- Set power plant selection handler
function UIManager:setOnPowerPlantSelected(handler)
    self.onPowerPlantSelected = handler
end

-- Set resource selection handler
function UIManager:setOnResourceSelected(handler)
    self.onResourceSelected = handler
    self.resourcePanel:setOnResourceSelected(handler)
end

-- Set build connection handler
function UIManager:setOnBuildConnection(handler)
    self.onBuildConnection = handler
end

-- Set purchase power plant handler
function UIManager:setOnPurchasePowerPlant(handler)
    self.onPurchasePowerPlant = handler
end

-- Set purchase resource handler
function UIManager:setOnPurchaseResource(handler)
    self.onPurchaseResource = handler
end

-- Show error message
function UIManager:showError(message)
    self.errorPanel:show(message)
    self.activePanel = self.errorPanel
end

-- Start transition
function UIManager:startTransition(message, onComplete)
    self.transitionOverlay:setOnTransitionComplete(onComplete)
    self.transitionOverlay:start(message)
end

-- Update UI manager
function UIManager:update(dt)
    if not self.visible then return end
    
    -- Update error panel
    self.errorPanel:update(dt)
    
    -- Update transition overlay
    self.transitionOverlay:update(dt)
    
    -- Update game board
    self.gameBoard:update(dt)
    
    -- Update phase panel
    self.phasePanel:update(dt)
    
    -- Update market panel
    self.marketPanel:update(dt)
    
    -- Update player panel
    self.playerPanel:update(dt)
    
    -- Update power plant panel
    self.powerPlantPanel:update(dt)
    
    -- Update resource panel
    self.resourcePanel:update(dt)
    
    -- Update city panel
    self.cityPanel:update(dt)
end

-- Draw UI manager
function UIManager:draw()
    if not self.visible then return end
    
    -- Draw main panel
    self.mainPanel:draw()
    
    -- Draw game board
    self.gameBoard:draw()
    
    -- Draw phase panel
    self.phasePanel:draw()
    
    -- Draw market panel
    self.marketPanel:draw()
    
    -- Draw player panel
    self.playerPanel:draw()
    
    -- Draw active panel
    if self.activePanel then
        self.activePanel:draw()
    end
    
    -- Draw error panel
    self.errorPanel:draw()
    
    -- Draw transition overlay
    self.transitionOverlay:draw()
end

-- Handle mouse press
function UIManager:mousepressed(x, y, button)
    if not self.visible then return false end
    
    -- Check if click is inside game board
    if self.gameBoard:mousepressed(x, y, button) then
        return true
    end
    
    -- Check if click is inside phase panel
    if self.phasePanel:mousepressed(x, y, button) then
        return true
    end
    
    -- Check if click is inside market panel
    if self.marketPanel:mousepressed(x, y, button) then
        return true
    end
    
    -- Check if click is inside player panel
    if self.playerPanel:mousepressed(x, y, button) then
        return true
    end
    
    -- Check if click is inside active panel
    if self.activePanel and self.activePanel:mousepressed(x, y, button) then
        return true
    end
    
    -- Check if click is inside error panel
    if self.errorPanel:mousepressed(x, y, button) then
        return true
    end
    
    -- Check if click is inside transition overlay
    if self.transitionOverlay:mousepressed(x, y, button) then
        return true
    end
    
    return false
end

-- Handle mouse move
function UIManager:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    
    -- Check if mouse is inside game board
    if self.gameBoard:mousemoved(x, y, dx, dy) then
        return true
    end
    
    -- Check if mouse is inside phase panel
    if self.phasePanel:mousemoved(x, y, dx, dy) then
        return true
    end
    
    -- Check if mouse is inside market panel
    if self.marketPanel:mousemoved(x, y, dx, dy) then
        return true
    end
    
    -- Check if mouse is inside player panel
    if self.playerPanel:mousemoved(x, y, dx, dy) then
        return true
    end
    
    -- Check if mouse is inside active panel
    if self.activePanel and self.activePanel:mousemoved(x, y, dx, dy) then
        return true
    end
    
    -- Check if mouse is inside error panel
    if self.errorPanel:mousemoved(x, y, dx, dy) then
        return true
    end
    
    -- Check if mouse is inside transition overlay
    if self.transitionOverlay:mousemoved(x, y, dx, dy) then
        return true
    end
    
    return false
end

-- Handle mouse release
function UIManager:mousereleased(x, y, button)
    if not self.visible then return false end
    
    -- Check if mouse is inside game board
    if self.gameBoard:mousereleased(x, y, button) then
        return true
    end
    
    -- Check if mouse is inside phase panel
    if self.phasePanel:mousereleased(x, y, button) then
        return true
    end
    
    -- Check if mouse is inside market panel
    if self.marketPanel:mousereleased(x, y, button) then
        return true
    end
    
    -- Check if mouse is inside player panel
    if self.playerPanel:mousereleased(x, y, button) then
        return true
    end
    
    -- Check if mouse is inside active panel
    if self.activePanel and self.activePanel:mousereleased(x, y, button) then
        return true
    end
    
    -- Check if mouse is inside error panel
    if self.errorPanel:mousereleased(x, y, button) then
        return true
    end
    
    -- Check if mouse is inside transition overlay
    if self.transitionOverlay:mousereleased(x, y, button) then
        return true
    end
    
    return false
end

-- Handle key press
function UIManager:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    
    -- Check if key is pressed in game board
    if self.gameBoard:keypressed(key, scancode, isrepeat) then
        return true
    end
    
    -- Check if key is pressed in phase panel
    if self.phasePanel:keypressed(key, scancode, isrepeat) then
        return true
    end
    
    -- Check if key is pressed in market panel
    if self.marketPanel:keypressed(key, scancode, isrepeat) then
        return true
    end
    
    -- Check if key is pressed in player panel
    if self.playerPanel:keypressed(key, scancode, isrepeat) then
        return true
    end
    
    -- Check if key is pressed in active panel
    if self.activePanel and self.activePanel:keypressed(key, scancode, isrepeat) then
        return true
    end
    
    -- Check if key is pressed in error panel
    if self.errorPanel:keypressed(key, scancode, isrepeat) then
        return true
    end
    
    -- Check if key is pressed in transition overlay
    if self.transitionOverlay:keypressed(key, scancode, isrepeat) then
        return true
    end
    
    return false
end

-- Handle text input
function UIManager:textinput(text)
    if not self.visible then return false end
    
    -- Check if text is input in game board
    if self.gameBoard:textinput(text) then
        return true
    end
    
    -- Check if text is input in phase panel
    if self.phasePanel:textinput(text) then
        return true
    end
    
    -- Check if text is input in market panel
    if self.marketPanel:textinput(text) then
        return true
    end
    
    -- Check if text is input in player panel
    if self.playerPanel:textinput(text) then
        return true
    end
    
    -- Check if text is input in active panel
    if self.activePanel and self.activePanel:textinput(text) then
        return true
    end
    
    -- Check if text is input in error panel
    if self.errorPanel:textinput(text) then
        return true
    end
    
    -- Check if text is input in transition overlay
    if self.transitionOverlay:textinput(text) then
        return true
    end
    
    return false
end

-- Handle window resize
function UIManager:resize(width, height)
    -- Update dimensions
    self.width = width
    self.height = height
    
    -- Update main panel
    self.mainPanel:resize(width, height)
    
    -- Update game board
    self.gameBoard:resize(width * 0.7, height * 0.7)
    
    -- Update side panels
    local sidePanelWidth = width * 0.3
    local sidePanelHeight = height / 3
    
    -- Update phase panel
    self.phasePanel:resize(sidePanelWidth - (2 * self.options.padding), sidePanelHeight)
    self.phasePanel:setPosition(width * 0.7 + self.options.padding, self.options.padding)
    
    -- Update market panel
    self.marketPanel:resize(sidePanelWidth - (2 * self.options.padding), sidePanelHeight)
    self.marketPanel:setPosition(width * 0.7 + self.options.padding, self.options.padding + 110)
    
    -- Update player panel
    self.playerPanel:resize(sidePanelWidth - (2 * self.options.padding), sidePanelHeight)
    self.playerPanel:setPosition(width * 0.7 + self.options.padding, self.options.padding + 270)
    
    -- Update power plant panel
    self.powerPlantPanel:resize(sidePanelWidth - (2 * self.options.padding), sidePanelHeight)
    self.powerPlantPanel:setPosition(width * 0.7 + self.options.padding, self.options.padding + 480)
    
    -- Update resource panel
    self.resourcePanel:resize(sidePanelWidth - (2 * self.options.padding), sidePanelHeight)
    self.resourcePanel:setPosition(width * 0.7 + self.options.padding, self.options.padding + 690)
    
    -- Update city panel
    self.cityPanel:resize(sidePanelWidth - (2 * self.options.padding), sidePanelHeight)
    self.cityPanel:setPosition(width * 0.7 + self.options.padding, self.options.padding + 850)
    
    -- Update error panel
    self.errorPanel:resize(300, 150)
    self.errorPanel:setPosition(width/2 - 150, height/2 - 75)
    
    -- Update transition overlay
    self.transitionOverlay:resize(width, height)
end

return UIManager 