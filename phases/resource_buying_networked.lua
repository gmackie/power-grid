-- Resource Buying Phase with network support
local ResourceBuyingPhase = {}
ResourceBuyingPhase.__index = ResourceBuyingPhase

local State = require("state")
local enums = require("models.enums")
local UI = require("ui")
local NetworkActions = require("network.network_actions")

function ResourceBuyingPhase.new()
    local self = setmetatable({}, ResourceBuyingPhase)
    self.selectedResource = nil
    self.selectedAmount = 0
    self.phaseComplete = false
    self.resourceClickRegions = {}
    self.buyButton = UI.Button.new("Buy Resources", 0, 0, 180, 40)
    self.passButton = UI.Button.new("Pass Turn", 0, 0, 120, 40)
    self.waitingForServer = false
    
    -- UI for selecting quantities
    self.quantityButtons = {}
    self.selectedQuantities = {}
    
    return self
end

function ResourceBuyingPhase:enter()
    print("Entering Resource Buying Phase")
    State.resetResourceBuyingTurnState()
    self.phaseComplete = false
    self.waitingForServer = false
    self.selectedQuantities = {}
    
    -- Initialize quantity selection
    local resourceTypes = {"Coal", "Oil", "Garbage", "Uranium"}
    for _, resourceType in ipairs(resourceTypes) do
        self.selectedQuantities[resourceType] = 0
    end
    
    -- Set up player order (reverse of normal order)
    local playerIndicesToOrder = {}
    if State.playerOrder and #State.playerOrder == #State.players and #State.players > 0 then
        for i = 1, #State.playerOrder do
            table.insert(playerIndicesToOrder, State.playerOrder[i])
        end
    else
        for i = 1, #State.players do
            table.insert(playerIndicesToOrder, i)
        end
    end
    
    -- Reverse order for resource buying
    for i = #playerIndicesToOrder, 1, -1 do
        table.insert(State.resourceBuyingOrder, playerIndicesToOrder[i])
    end
    
    State.currentResourceBuyerOrderIndex = 1
    State.playersWhoPassedResourceBuying = {}
    for i = 1, #State.players do
        State.playersWhoPassedResourceBuying[i] = false
    end
end

function ResourceBuyingPhase:exit()
    print("Exiting Resource Buying Phase")
end

function ResourceBuyingPhase:update(dt)
    if self.phaseComplete then
        State.currentPhase = enums.GamePhase.BUILDING
        self.phaseComplete = false
        return
    end
    
    local mx, my = love.mouse.getPosition()
    
    -- Check if waiting for other players in online mode
    if NetworkActions.isWaitingForOthers() then
        self.waitingForServer = true
        return
    else
        self.waitingForServer = false
    end
    
    -- Update buttons
    self.buyButton.x = love.graphics.getWidth() - 200
    self.buyButton.y = love.graphics.getHeight() - 100
    self.passButton.x = love.graphics.getWidth() - 200
    self.passButton.y = love.graphics.getHeight() - 50
    
    self.buyButton:update(mx, my)
    self.passButton:update(mx, my)
end

function ResourceBuyingPhase:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf("Resource Buying Phase", 0, 20, love.graphics.getWidth(), "center")
    
    -- Draw waiting message if not our turn
    if self.waitingForServer or NetworkActions.isWaitingForOthers() then
        love.graphics.setColor(1, 1, 0.5, 1)
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.printf("Waiting for other players...", 0, love.graphics.getHeight()/2 - 50, love.graphics.getWidth(), "center")
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.setColor(1, 1, 1, 1)
        return
    end
    
    -- Get current buyer
    local currentOrderIndex = State.currentResourceBuyerOrderIndex
    local actualPlayerIndex = State.resourceBuyingOrder[currentOrderIndex]
    local currentBuyer = State.players[actualPlayerIndex]
    
    if not currentBuyer then return end
    
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.print("Current Buyer: " .. currentBuyer.name .. " ($" .. currentBuyer.money .. ")", 20, 60)
    
    -- Draw resource market
    self:drawResourceMarket()
    
    -- Draw selected quantities and total cost
    self:drawSelectedResources()
    
    -- Draw buttons
    if not State.playersWhoPassedResourceBuying[actualPlayerIndex] then
        self.buyButton:draw()
        self.passButton:draw()
    end
end

function ResourceBuyingPhase:drawResourceMarket()
    local marketStartX = 50
    local marketStartY = 120
    local resourceWidth = 150
    local resourceHeight = 200
    local spacing = 20
    
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.print("Resource Market:", marketStartX, marketStartY - 30)
    
    love.graphics.setFont(love.graphics.newFont(14))
    
    -- Clear click regions
    self.resourceClickRegions = {}
    
    local resourceTypes = {"Coal", "Oil", "Garbage", "Uranium"}
    for i, resourceType in ipairs(resourceTypes) do
        local x = marketStartX + (i - 1) * (resourceWidth + spacing)
        local y = marketStartY
        
        -- Draw resource box
        love.graphics.setColor(0.2, 0.2, 0.25, 1)
        love.graphics.rectangle("fill", x, y, resourceWidth, resourceHeight, 5)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", x, y, resourceWidth, resourceHeight, 5)
        
        -- Resource name
        love.graphics.print(resourceType, x + 10, y + 10)
        
        -- Available amount (simplified)
        local market = State.getResourceMarket()
        if market then
            local available = market:getAvailable(resourceType)
            local cost = market:getCostForAmount(resourceType, 1)
            love.graphics.print("Available: " .. available, x + 10, y + 40)
            love.graphics.print("Cost: $" .. cost .. "/unit", x + 10, y + 60)
        end
        
        -- Quantity selector
        local qty = self.selectedQuantities[resourceType] or 0
        love.graphics.print("Selected: " .. qty, x + 10, y + 100)
        
        -- +/- buttons
        local btnSize = 30
        -- Minus button
        love.graphics.setColor(0.8, 0.3, 0.3, 1)
        love.graphics.rectangle("fill", x + 10, y + 130, btnSize, btnSize, 3)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("-", x + 20, y + 135)
        
        -- Plus button
        love.graphics.setColor(0.3, 0.8, 0.3, 1)
        love.graphics.rectangle("fill", x + 50, y + 130, btnSize, btnSize, 3)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("+", x + 60, y + 135)
        
        -- Store click regions
        table.insert(self.resourceClickRegions, {
            type = resourceType,
            minusRegion = {x = x + 10, y = y + 130, w = btnSize, h = btnSize},
            plusRegion = {x = x + 50, y = y + 130, w = btnSize, h = btnSize}
        })
    end
end

function ResourceBuyingPhase:drawSelectedResources()
    local y = 350
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.print("Selected Resources:", 50, y)
    
    y = y + 30
    local totalCost = 0
    
    for resourceType, quantity in pairs(self.selectedQuantities) do
        if quantity > 0 then
            local market = State.getResourceMarket()
            if market then
                local cost = market:getCostForAmount(resourceType, quantity) * quantity
                love.graphics.print(resourceType .. ": " .. quantity .. " units - $" .. cost, 70, y)
                totalCost = totalCost + cost
                y = y + 25
            end
        end
    end
    
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.print("Total Cost: $" .. totalCost, 50, y + 10)
    
    -- Update buy button text
    if totalCost > 0 then
        self.buyButton.text = "Buy ($" .. totalCost .. ")"
    else
        self.buyButton.text = "Buy Resources"
    end
end

function ResourceBuyingPhase:mousepressed(x, y, button)
    if button == 1 then
        -- Don't process clicks if waiting
        if self.waitingForServer or NetworkActions.isWaitingForOthers() then
            return
        end
        
        -- Check quantity buttons
        for _, region in ipairs(self.resourceClickRegions) do
            -- Minus button
            if x >= region.minusRegion.x and x <= region.minusRegion.x + region.minusRegion.w and
               y >= region.minusRegion.y and y <= region.minusRegion.y + region.minusRegion.h then
                if self.selectedQuantities[region.type] > 0 then
                    self.selectedQuantities[region.type] = self.selectedQuantities[region.type] - 1
                end
                return
            end
            
            -- Plus button
            if x >= region.plusRegion.x and x <= region.plusRegion.x + region.plusRegion.w and
               y >= region.plusRegion.y and y <= region.plusRegion.y + region.plusRegion.h then
                -- Check if player can afford and resource is available
                local market = State.getResourceMarket()
                if market then
                    local available = market:getAvailable(region.type)
                    if self.selectedQuantities[region.type] < available then
                        self.selectedQuantities[region.type] = self.selectedQuantities[region.type] + 1
                    end
                end
                return
            end
        end
        
        -- Check buy button
        if self.buyButton:isHovered(x, y) then
            local resourcesToBuy = {}
            local hasSelection = false
            
            for resourceType, quantity in pairs(self.selectedQuantities) do
                if quantity > 0 then
                    resourcesToBuy[resourceType] = quantity
                    hasSelection = true
                end
            end
            
            if hasSelection then
                if NetworkActions.shouldWaitForServer() then
                    self.waitingForServer = true
                    NetworkActions.buyResources(resourcesToBuy)
                else
                    -- Offline mode - process locally
                    self:processPurchase(resourcesToBuy)
                end
            end
            return
        end
        
        -- Check pass button
        if self.passButton:isHovered(x, y) then
            if NetworkActions.shouldWaitForServer() then
                self.waitingForServer = true
                NetworkActions.endTurn()
            else
                -- Offline mode
                self:passTurn()
            end
            return
        end
    end
end

function ResourceBuyingPhase:processPurchase(resources)
    -- This would be the local processing logic
    -- In online mode, the server handles this
    local currentOrderIndex = State.currentResourceBuyerOrderIndex
    local actualPlayerIndex = State.resourceBuyingOrder[currentOrderIndex]
    local buyer = State.players[actualPlayerIndex]
    
    -- Reset selections
    for resourceType, _ in pairs(self.selectedQuantities) do
        self.selectedQuantities[resourceType] = 0
    end
    
    -- Move to next player
    self:advanceToNextBuyer()
end

function ResourceBuyingPhase:passTurn()
    local currentOrderIndex = State.currentResourceBuyerOrderIndex
    local actualPlayerIndex = State.resourceBuyingOrder[currentOrderIndex]
    State.playersWhoPassedResourceBuying[actualPlayerIndex] = true
    
    self:advanceToNextBuyer()
end

function ResourceBuyingPhase:advanceToNextBuyer()
    State.currentResourceBuyerOrderIndex = State.currentResourceBuyerOrderIndex + 1
    
    -- Check if all players have had their turn
    if State.currentResourceBuyerOrderIndex > #State.resourceBuyingOrder then
        self.phaseComplete = true
    end
end

return ResourceBuyingPhase