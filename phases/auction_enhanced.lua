-- Enhanced Auction Phase with Visual Polish
local auctionEnhanced = {}

local Theme = require("ui.theme")
local StyledButton = require("ui.styled_button")
local StyledPanel = require("ui.styled_panel")
local PowerPlantCard = require("ui.power_plant_card")
local VisualEffects = require("ui.visual_effects")
local AssetLoader = require("assets.asset_loader")
local MobileConfig = require("mobile.mobile_config")

function auctionEnhanced:enter(gameState)
    print("Enhanced auction phase entered")
    
    -- Initialize visual effects
    VisualEffects.init()
    
    local screenConfig = MobileConfig.getScreenConfig()
    
    -- Load power plants data (mock data for demo)
    self.powerPlants = {
        {id = 3, cost = 7, capacity = 1, resourceType = "oil", resourceCost = 2, currentBid = 0},
        {id = 4, cost = 9, capacity = 1, resourceType = "coal", resourceCost = 2, currentBid = 0},
        {id = 5, cost = 10, capacity = 1, resourceType = "hybrid", resourceCost = 2, currentBid = 0},
        {id = 6, cost = 11, capacity = 1, resourceType = "garbage", resourceCost = 1, currentBid = 0}
    }
    
    -- Auction state
    self.currentPlant = nil
    self.currentBidder = 1
    self.highestBid = 0
    self.biddingActive = false
    self.auctionResults = {}
    
    -- UI Elements
    self:createUI(screenConfig)
    
    -- Start the auction
    self:startAuction()
end

function auctionEnhanced:createUI(screenConfig)
    -- Main auction panel
    self.auctionPanel = StyledPanel.new(
        screenConfig.width * 0.05, 50,
        screenConfig.width * 0.9, screenConfig.height * 0.7,
        {
            title = "Power Plant Auction",
            style = "elevated"
        }
    )
    
    -- Create power plant cards
    self.plantCards = {}
    local cardWidth = 180
    local cardHeight = 120
    local startX = screenConfig.width * 0.1
    local startY = 120
    local spacing = 20
    
    for i, plant in ipairs(self.powerPlants) do
        local x = startX + (i - 1) * (cardWidth + spacing)
        local y = startY
        
        local card = PowerPlantCard.new(x, y, plant, {
            onTap = function(selectedPlant) 
                self:selectPlant(selectedPlant)
            end
        })
        
        table.insert(self.plantCards, card)
    end
    
    -- Bidding controls panel
    local controlsY = screenConfig.height * 0.75 + 20
    self.controlsPanel = StyledPanel.new(
        screenConfig.width * 0.1, controlsY,
        screenConfig.width * 0.8, 120,
        {
            title = "Bidding Controls",
            style = "default"
        }
    )
    
    -- Bid buttons
    local buttonWidth = 120
    local buttonHeight = 40
    local buttonsY = controlsY + 50
    
    self.bidButton = StyledButton.new("Bid", 
        screenConfig.width * 0.15, buttonsY, buttonWidth, buttonHeight,
        {
            type = "primary",
            onTap = function() self:placeBid() end
        }
    )
    
    self.passButton = StyledButton.new("Pass", 
        screenConfig.width * 0.15 + buttonWidth + 20, buttonsY, buttonWidth, buttonHeight,
        {
            type = "secondary", 
            onTap = function() self:passBid() end
        }
    )
    
    -- Bid amount controls
    self.bidAmount = 0
    self.bidAmountButtons = {}
    
    local amounts = {1, 5, 10}
    for i, amount in ipairs(amounts) do
        local btn = StyledButton.new("+" .. amount, 
            screenConfig.width * 0.55 + (i-1) * 80, buttonsY, 70, buttonHeight,
            {
                type = "secondary",
                onTap = function() self:increaseBid(amount) end
            }
        )
        table.insert(self.bidAmountButtons, btn)
    end
    
    -- Info panel
    self.infoPanel = StyledPanel.new(
        screenConfig.width * 0.05, screenConfig.height - 150,
        screenConfig.width * 0.9, 100,
        {
            style = "transparent"
        }
    )
    
    -- Fonts
    self.titleFont = love.graphics.newFont(Theme.fonts.large)
    self.infoFont = love.graphics.newFont(Theme.fonts.medium)
    self.bidFont = love.graphics.newFont(Theme.fonts.huge)
end

function auctionEnhanced:startAuction()
    if #self.powerPlants > 0 then
        self.currentPlant = self.powerPlants[1]
        self.highestBid = self.currentPlant.cost
        self.biddingActive = true
        
        -- Visual effects for auction start
        VisualEffects.textPop(love.graphics.getWidth()/2, 100, "AUCTION BEGINS!", Theme.colors.warning)
        VisualEffects.sparkles(love.graphics.getWidth()/2, 100, Theme.colors.primary, 200)
        
        -- Highlight current plant
        for i, card in ipairs(self.plantCards) do
            if card.powerPlant == self.currentPlant then
                card:setSelected(true)
                card:flash(Theme.colors.warning)
                break
            end
        end
    end
end

function auctionEnhanced:selectPlant(plant)
    if not self.biddingActive then return end
    
    -- Deselect previous
    for _, card in ipairs(self.plantCards) do
        card:setSelected(false)
    end
    
    -- Select new plant
    self.currentPlant = plant
    self.highestBid = plant.cost
    self.bidAmount = 0
    
    for _, card in ipairs(self.plantCards) do
        if card.powerPlant == plant then
            card:setSelected(true)
            card:flash(Theme.colors.primary)
            card:animate()
            break
        end
    end
    
    -- Visual effects
    VisualEffects.glow(400, 300, Theme.colors.primary, 100, 1.0)
    
    print("Selected plant:", plant.id, "Min bid:", self.highestBid)
end

function auctionEnhanced:increaseBid(amount)
    self.bidAmount = self.bidAmount + amount
    
    -- Visual feedback
    VisualEffects.textPop(love.graphics.getWidth() * 0.7, 200, "+$" .. amount, Theme.colors.success)
end

function auctionEnhanced:placeBid()
    if not self.currentPlant or not self.biddingActive then return end
    
    local totalBid = self.highestBid + self.bidAmount
    
    if self.bidAmount <= 0 then
        VisualEffects.textPop(love.graphics.getWidth()/2, 300, "Enter a bid amount!", Theme.colors.error)
        return
    end
    
    -- Place the bid
    self.highestBid = totalBid
    self.currentPlant.currentBid = totalBid
    self.bidAmount = 0
    
    -- Visual effects
    VisualEffects.explosion(love.graphics.getWidth()/2, 250, Theme.colors.success, 1.5)
    VisualEffects.textPop(love.graphics.getWidth()/2, 250, "$" .. totalBid, Theme.colors.success)
    
    -- Update card
    for _, card in ipairs(self.plantCards) do
        if card.powerPlant == self.currentPlant then
            card:flash(Theme.colors.success)
            card:animate()
            break
        end
    end
    
    print("Bid placed: $" .. totalBid .. " on plant " .. self.currentPlant.id)
    
    -- For demo, automatically end auction after a bid
    love.timer.sleep(1)
    self:endAuction()
end

function auctionEnhanced:passBid()
    if not self.biddingActive then return end
    
    VisualEffects.textPop(love.graphics.getWidth()/2, 300, "PASSED", Theme.colors.textSecondary)
    
    -- For demo, move to next player or end auction
    self:endAuction()
end

function auctionEnhanced:endAuction()
    self.biddingActive = false
    
    if self.currentPlant and self.currentPlant.currentBid > 0 then
        -- Plant sold!
        table.insert(self.auctionResults, {
            plant = self.currentPlant,
            price = self.currentPlant.currentBid,
            winner = "Player " .. self.currentBidder
        })
        
        -- Visual effects for successful sale
        for _, card in ipairs(self.plantCards) do
            if card.powerPlant == self.currentPlant then
                VisualEffects.powerPlantPurchase(card.x + card.width/2, card.y + card.height/2)
                card:flash(Theme.colors.warning)
                break
            end
        end
        
        VisualEffects.textPop(love.graphics.getWidth()/2, 200, "SOLD!", Theme.colors.warning)
        
        -- Remove sold plant
        for i = #self.powerPlants, 1, -1 do
            if self.powerPlants[i] == self.currentPlant then
                table.remove(self.powerPlants, i)
                table.remove(self.plantCards, i)
                break
            end
        end
    end
    
    -- Check if auction continues
    if #self.powerPlants > 0 then
        love.timer.sleep(2)
        self:startAuction()
    else
        self:finishPhase()
    end
end

function auctionEnhanced:finishPhase()
    VisualEffects.textPop(love.graphics.getWidth()/2, love.graphics.getHeight()/2, 
                         "AUCTION COMPLETE!", Theme.colors.primary)
    VisualEffects.sparkles(love.graphics.getWidth()/2, love.graphics.getHeight()/2, 
                          Theme.colors.primary, 300)
    
    print("Auction phase complete")
    print("Results:", #self.auctionResults, "plants sold")
end

function auctionEnhanced:update(dt, gameState)
    -- Update visual effects
    VisualEffects.update(dt)
    
    -- Update UI components
    self.auctionPanel:update(dt)
    self.controlsPanel:update(dt)
    self.infoPanel:update(dt)
    
    for _, card in ipairs(self.plantCards) do
        card:update(dt)
    end
    
    self.bidButton:update(dt)
    self.passButton:update(dt)
    
    for _, btn in ipairs(self.bidAmountButtons) do
        btn:update(dt)
    end
end

function auctionEnhanced:draw()
    -- Background
    love.graphics.clear(Theme.colors.backgroundDark)
    
    -- Draw background pattern
    love.graphics.setColor(Theme.colors.primary[1], Theme.colors.primary[2], Theme.colors.primary[3], 0.02)
    local gridSize = 60
    love.graphics.setLineWidth(1)
    for x = 0, love.graphics.getWidth(), gridSize do
        love.graphics.line(x, 0, x, love.graphics.getHeight())
    end
    for y = 0, love.graphics.getHeight(), gridSize do
        love.graphics.line(0, y, love.graphics.getWidth(), y)
    end
    
    -- Draw panels
    self.auctionPanel:draw()
    self.controlsPanel:draw()
    self.infoPanel:draw()
    
    -- Draw power plant cards
    for _, card in ipairs(self.plantCards) do
        card:draw()
    end
    
    -- Draw controls
    self.bidButton:draw()
    self.passButton:draw()
    
    for _, btn in ipairs(self.bidAmountButtons) do
        btn:draw()
    end
    
    -- Draw auction info
    self:drawAuctionInfo()
    
    -- Draw visual effects
    VisualEffects.draw()
end

function auctionEnhanced:drawAuctionInfo()
    local x, y, w, h = self.infoPanel:getContentBounds()
    
    if self.currentPlant then
        -- Current bid info
        love.graphics.setFont(self.infoFont)
        Theme.setColor("textPrimary")
        love.graphics.print("Current Plant: #" .. self.currentPlant.id, x + 20, y + 10)
        love.graphics.print("Minimum Bid: $" .. self.highestBid, x + 200, y + 10)
        
        if self.bidAmount > 0 then
            love.graphics.print("Your Bid: $" .. (self.highestBid + self.bidAmount), x + 400, y + 10)
        end
        
        -- Current bidder
        love.graphics.print("Current Bidder: Player " .. self.currentBidder, x + 20, y + 35)
        
        -- Auction status
        if self.biddingActive then
            Theme.setColor("success")
            love.graphics.print("● BIDDING ACTIVE", x + 400, y + 35)
        else
            Theme.setColor("textDisabled")
            love.graphics.print("○ Waiting...", x + 400, y + 35)
        end
    end
    
    -- Results summary
    if #self.auctionResults > 0 then
        Theme.setColor("textSecondary")
        love.graphics.print("Plants Sold: " .. #self.auctionResults, x + 20, y + 60)
    end
end

function auctionEnhanced:mousepressed(x, y, button)
    -- Handle card clicks
    for _, card in ipairs(self.plantCards) do
        if card:mousepressed(x, y, button) then
            return
        end
    end
    
    -- Handle button clicks
    if self.bidButton:mousepressed(x, y, button) then return end
    if self.passButton:mousepressed(x, y, button) then return end
    
    for _, btn in ipairs(self.bidAmountButtons) do
        if btn:mousepressed(x, y, button) then return end
    end
end

function auctionEnhanced:mousereleased(x, y, button)
    for _, card in ipairs(self.plantCards) do
        card:mousereleased(x, y, button)
    end
    
    self.bidButton:mousereleased(x, y, button)
    self.passButton:mousereleased(x, y, button)
    
    for _, btn in ipairs(self.bidAmountButtons) do
        btn:mousereleased(x, y, button)
    end
end

function auctionEnhanced:mousemoved(x, y)
    for _, card in ipairs(self.plantCards) do
        card:mousemoved(x, y)
    end
    
    self.bidButton:mousemoved(x, y)
    self.passButton:mousemoved(x, y)
    
    for _, btn in ipairs(self.bidAmountButtons) do
        btn:mousemoved(x, y)
    end
end

return auctionEnhanced