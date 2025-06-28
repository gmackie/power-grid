local ResourceBuyingPhase = {}
ResourceBuyingPhase.__index = ResourceBuyingPhase

local State = require("state") -- Ensure State is required
local enums = require("models.enums") -- Require enums directly
local UI = require("ui") -- For potential buttons later

function ResourceBuyingPhase.new()
    local self = setmetatable({}, ResourceBuyingPhase)
    self.selectedResource = nil
    self.selectedAmount = 0
    self.phaseComplete = false -- Add phase complete flag
    -- Store clickable regions for resources
    self.resourceClickRegions = {}
    self.buyButton = UI.Button.new("Buy 1 Selected", 0,0, 180, 40)
    self.passButton = UI.Button.new("Pass Turn", 0,0, 120, 40)
    print("RBP:new() - self.buyButton initialized to: ", self.buyButton)
    print("RBP:new() - self.passButton initialized to: ", self.passButton)
    return self
end

function ResourceBuyingPhase:enter()
    print("Entering Resource Buying Phase")
    State.resetResourceBuyingTurnState() -- Clear any previous state

    print("--- Verifying player power plants in State AT START of ResourceBuyingPhase:enter ---")
    if State.players and type(State.players) == "table" then
        print("RBP:enter sees " .. #State.players .. " players in State.players.")
        for P_idx, P_player in ipairs(State.players) do
            if P_player and P_player.powerPlants and type(P_player.powerPlants) == "table" then
                print("RBP-ENTER Player " .. P_player.name .. " has " .. #P_player.powerPlants .. " power plant(s):")
                for pp_idx, pp_plant in ipairs(P_player.powerPlants) do
                    print("  RBP-ENTER Plant ID: " .. pp_plant.id)
                end
            elseif P_player then
                print("RBP-ENTER Player " .. P_player.name .. " has no powerPlants table or it\'s not a table.")
            else
                print("RBP-ENTER Player at index " .. P_idx .. " is nil.")
            end
        end
    else
        print("RBP-ENTER State.players is nil or not a table.")
    end
    print("-----------------------------------------------------------------------------")

    self.phaseComplete = false

    -- Determine player order for this phase (reverse of current player order)
    local playerIndicesToOrder = {}
    print("RBP:enter DBG - Before determining playerIndicesToOrder, #State.players = " .. #State.players .. ", State.playerCount = " .. State.getPlayerCount()) 

    if State.playerOrder and #State.playerOrder == #State.players and #State.players > 0 then
        print("Using State.playerOrder for resource buying order. #State.playerOrder = " .. #State.playerOrder)
        for i = 1, #State.playerOrder do
            table.insert(playerIndicesToOrder, State.playerOrder[i])
        end
    else
        if not State.playerOrder or #State.playerOrder ~= #State.players then
            print("State.playerOrder not available or mismatched. Using default player sequence. #State.players = " .. #State.players .. ", #State.playerOrder = " .. tostring(State.playerOrder and #State.playerOrder or 'nil'))
        elseif not (#State.players > 0) then
             print("State.players is empty. Using default player sequence (which will be empty). #State.players = " .. #State.players)
        end
        for i = 1, #State.players do
            table.insert(playerIndicesToOrder, i)
        end
    end
    print("RBP:enter DBG - After determining playerIndicesToOrder, #playerIndicesToOrder = " .. #playerIndicesToOrder)

    -- State.resourceBuyingOrder = {} -- This is redundant; resetResourceBuyingTurnState() already does this.
    
    for i = #playerIndicesToOrder, 1, -1 do
        table.insert(State.resourceBuyingOrder, playerIndicesToOrder[i])
    end
    print("RBP:enter DBG - After populating State.resourceBuyingOrder, #State.resourceBuyingOrder = " .. #State.resourceBuyingOrder)

    State.currentResourceBuyerOrderIndex = 1 -- Start with the first player in the reversed list
    State.playersWhoPassedResourceBuying = {} -- Reset pass states for all actual player indices
    for i=1, #State.players do
        State.playersWhoPassedResourceBuying[i] = false
    end
    
    if #State.resourceBuyingOrder > 0 then
        local firstBuyerOrderIndex = State.currentResourceBuyerOrderIndex
        local firstBuyerPlayerIndex = State.resourceBuyingOrder[firstBuyerOrderIndex]
        if firstBuyerPlayerIndex and State.players[firstBuyerPlayerIndex] then
             print("Resource Buying Phase: First buyer is Player " .. State.players[firstBuyerPlayerIndex].name .. " (PlayerIndex: " .. firstBuyerPlayerIndex .. ", OrderIndex: " .. firstBuyerOrderIndex .. ")")
        else
            print("Resource Buying Phase: ERROR - First buyer playerIndex " .. tostring(firstBuyerPlayerIndex) .. " (from orderIndex " .. tostring(firstBuyerOrderIndex) .. ") is invalid.")
        end
    else
        print("Resource Buying Phase: ERROR - No players in resourceBuyingOrder.")
    end

end

function ResourceBuyingPhase:update(dt)
    local mx, my = love.mouse.getPosition()
    local windowWidth = love.graphics.getWidth()
    local buttonY = love.graphics.getHeight() - 70

    self.buyButton.x = windowWidth / 2 - self.buyButton.w - 10
    self.buyButton.y = buttonY
    self.buyButton:update(mx, my)

    self.passButton.x = windowWidth / 2 + 10
    self.passButton.y = buttonY
    self.passButton:update(mx,my)
end

function ResourceBuyingPhase:draw()
    local windowWidth = love.graphics.getWidth()
    self.resourceClickRegions = {} -- Clear and recalculate each frame (or do in update if static)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Resource Buying Phase", 0, 180, windowWidth, "center") -- Adjusted Y
    
    if not State.resourceMarket then
        love.graphics.printf("Resource Market not initialized!", 0, 250, windowWidth, "center")
        return
    end

    local y = 230 -- Adjusted Y
    local resourceItemWidth = 160 -- Increased width
    local totalResourceDisplayWidth = 4 * resourceItemWidth
    local startX = (windowWidth - totalResourceDisplayWidth) / 2
    local currentX = startX
    local iconRadius = 20
    local textOffsetX = iconRadius + 15 -- Increased offset
    local textOffsetY1 = -10 
    local textOffsetY2 = 10
    local itemHeight = iconRadius * 2 + 20

    local resourcesToDraw = {
        {type = enums.ResourceType.COAL, color = {0.4, 0.2, 0.1, 1}, name = "Coal"},
        {type = enums.ResourceType.OIL, color = {0.1, 0.1, 0.1, 1}, name = "Oil"},
        {type = enums.ResourceType.GARBAGE, color = {0.8, 0.8, 0.2, 1}, name = "Garbage"},
        {type = enums.ResourceType.URANIUM, color = {0.8, 0.2, 0.2, 1}, name = "Uranium"}
    }

    for _, resData in ipairs(resourcesToDraw) do
        local region = {x = currentX, y = y - iconRadius, w = resourceItemWidth -5 , h = itemHeight}
        table.insert(self.resourceClickRegions, {type = resData.type, region = region})

        -- Highlight if selected
        if State.getSelectedResourceForPurchase() == resData.type then
            love.graphics.setColor(0.5, 0.5, 0.2, 0.5) -- Yellowish highlight
            love.graphics.rectangle("fill", region.x, region.y, region.w, region.h, 5)
        end

        love.graphics.setColor(resData.color[1], resData.color[2], resData.color[3], resData.color[4])
        love.graphics.circle("fill", currentX + iconRadius, y, iconRadius)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(resData.name .. ": " .. (State.resourceMarket:getTotal(resData.type) or "N/A"), currentX + textOffsetX, y + textOffsetY1)
        love.graphics.print("$" .. (State.resourceMarket:getPrice(resData.type) or "N/A"), currentX + textOffsetX, y + textOffsetY2)
        currentX = currentX + resourceItemWidth
    end
    
    -- Display current resource buyer's turn
    local currentOrderIndex_draw = State.currentResourceBuyerOrderIndex
    local actualPlayerIndex_draw = nil
    if currentOrderIndex_draw and State.resourceBuyingOrder[currentOrderIndex_draw] then
        actualPlayerIndex_draw = State.resourceBuyingOrder[currentOrderIndex_draw]
    end

    local currentTurnPlayer = nil
    if actualPlayerIndex_draw and State.players[actualPlayerIndex_draw] then
        currentTurnPlayer = State.players[actualPlayerIndex_draw]
    end

    if not currentTurnPlayer and #State.resourceBuyingOrder == 0 then -- Only log if critical info is missing
        print(string.format("RBP:draw DBG (Error Condition) - OrderIndex: %s, ActualPlayerIndex: %s, #ResourceBuyingOrder: %d, currentTurnPlayer is nil", 
            tostring(currentOrderIndex_draw), tostring(actualPlayerIndex_draw), #State.resourceBuyingOrder))
    end

    local infoY = y + itemHeight + 20
    if currentTurnPlayer then
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.printf(currentTurnPlayer.name .. "'s Turn to Buy Resources (Money: $" .. currentTurnPlayer.money .. ")", 0, infoY, windowWidth, "center")
        infoY = infoY + 30
        -- Only log this if we are actively debugging plant display issues.
        -- print(string.format("RBP:draw DBG - Drawing plants for %s, #Plants: %d", currentTurnPlayer.name, #currentTurnPlayer.powerPlants))
        
        local plantX = windowWidth/2 - 300
        local plantY = infoY
        local plantCardW, plantCardH = 100, 80
        local plantSpacing = 120

        if currentTurnPlayer.powerPlants and #currentTurnPlayer.powerPlants > 0 then
            for i, plant in ipairs(currentTurnPlayer.powerPlants) do
                local resourceColor = plant:getResourceColor() or {0.5,0.5,0.5,1}
                love.graphics.setColor(resourceColor[1], resourceColor[2], resourceColor[3], resourceColor[4])
                love.graphics.rectangle("fill", plantX + (i-1)*plantSpacing, plantY, plantCardW, plantCardH, 8)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print("Plant #" .. plant.id, plantX + (i-1)*plantSpacing + 10, plantY + 10)
                love.graphics.print(plant.resourceType, plantX + (i-1)*plantSpacing + 10, plantY + 30)
                love.graphics.print("Stored: " .. plant:getResourceStoredCount(), plantX + (i-1)*plantSpacing + 10, plantY + 50)
            end
        else
            love.graphics.printf("No power plants.", 0, plantY + 20, windowWidth, "center")
        end
    elseif #State.resourceBuyingOrder > 0 then
         love.graphics.printf("Waiting for player " .. (actualPlayerIndex_draw or "N/A") .. " in Resource Buying Phase.", 0, infoY, windowWidth, "center")
    else
        love.graphics.printf("Resource Buying Order not set or empty.", 0, infoY, windowWidth, "center")
    end
    self.buyButton:draw()
    self.passButton:draw()
end

function ResourceBuyingPhase:mousepressed(x, y, button)
    print("RBP:mousepressed() - Entered. self is: ", self, "self.buyButton is: ", self.buyButton, "self.passButton is: ", self.passButton)
    if button == 1 then
        -- Check resource selection clicks
        for _, item in ipairs(self.resourceClickRegions) do
            if x >= item.region.x and x <= item.region.x + item.region.w and 
               y >= item.region.y and y <= item.region.y + item.region.h then
                State.setSelectedResourceForPurchase(item.type)
                print("RBP: Clicked on resource region: " .. item.type)
                return -- consume click
            end
        end

        local currentOrderIndex_mouse = State.currentResourceBuyerOrderIndex
        local actualPlayerIndex_mouse = nil
        if currentOrderIndex_mouse and State.resourceBuyingOrder[currentOrderIndex_mouse] then
             actualPlayerIndex_mouse = State.resourceBuyingOrder[currentOrderIndex_mouse]
        end
        
        local playerHasPassed_mouse = false
        if actualPlayerIndex_mouse then
            playerHasPassed_mouse = State.playersWhoPassedResourceBuying[actualPlayerIndex_mouse]
        end

        print(string.format("RBP:mousepressed DBG - OrderIndex: %s, ActualPlayerIndex: %s, #RBO: %d, Passed: %s", 
            tostring(currentOrderIndex_mouse), 
            tostring(actualPlayerIndex_mouse), 
            #State.resourceBuyingOrder, 
            tostring(playerHasPassed_mouse)))

        if not actualPlayerIndex_mouse or playerHasPassed_mouse then
            print("RBP:mousepressed - No current buyer or buyer has passed. (OrderIdx: " .. tostring(currentOrderIndex_mouse) .. ", PlayerIdx: " .. tostring(actualPlayerIndex_mouse) .. ", Passed: " .. tostring(playerHasPassed_mouse) .. ")")
            return -- No active buyer for these buttons
        end
        local buyer = State.players[actualPlayerIndex_mouse]

        -- Handle Buy Button Click
        print("RBP:mousepressed() - About to check self.buyButton:isHovered. self.buyButton is: ", self.buyButton)
        if self.buyButton:isHovered(x,y) then
            print("RBP: Buy button clicked by " .. buyer.name)
            local selectedResourceType = State.getSelectedResourceForPurchase()
            if not selectedResourceType then
                print("RBP: No resource selected to buy.")
                return
            end

            local amountToBuy = 1 -- For now, always buy 1
            local canAfford = false
            local marketHasResource = false
            local plantToStore = nil
            local costOfPurchase = 0

            if State.resourceMarket:isResourceAvailable(selectedResourceType, amountToBuy) then
                marketHasResource = true
                costOfPurchase = State.resourceMarket:getPrice(selectedResourceType) * amountToBuy
                if buyer.money >= costOfPurchase then
                    canAfford = true
                else
                    print("RBP: Player " .. buyer.name .. " cannot afford " .. amountToBuy .. " " .. selectedResourceType .. ". Needs " .. costOfPurchase .. ", has " .. buyer.money)
                end
            else
                print("RBP: Market does not have " .. amountToBuy .. " of " .. selectedResourceType)
            end

            if canAfford and marketHasResource then
                -- Find a plant to store the resource
                for _, plant in ipairs(buyer.powerPlants) do
                    if plant:hasCapacityForResource(selectedResourceType, amountToBuy) then
                        plantToStore = plant
                        break
                    end
                end

                if plantToStore then
                    local success, actualCost = State.resourceMarket:removeResource(selectedResourceType, amountToBuy)
                    if success then
                        if buyer:removeMoney(actualCost) then 
                            if plantToStore:addSpecificResource(selectedResourceType, amountToBuy) then
                                print("RBP: Player " .. buyer.name .. " bought " .. amountToBuy .. " " .. selectedResourceType .. " for $" .. actualCost .. " and stored in plant #" .. plantToStore.id)
                                State.setSelectedResourceForPurchase(nil) -- Clear selection after successful buy
                            else
                                print("RBP: ERROR - Failed to store resource in plant after purchase! Refunding player and returning resource to market (not yet implemented).")
                                -- TODO: Implement rollback logic
                                buyer:addMoney(actualCost) -- crude refund
                                -- State.resourceMarket:addResource(selectedResourceType, amountToBuy) -- crude return (needs proper method)
                            end
                        else
                             print("RBP: ERROR - Failed to remove money after market confirmed sale! Returning resource to market (not yet implemented).")
                             -- TODO: Implement rollback logic
                             -- State.resourceMarket:addResource(selectedResourceType, amountToBuy) -- crude return
                        end
                    else
                        print("RBP: ERROR - Market failed to remove resource after checks passed!")
                    end
                else
                    print("RBP: Player " .. buyer.name .. " has no plant that can store 1 " .. selectedResourceType .. " or no capacity.")
                end
            end
            return -- consume click
        end

        -- Handle Pass Button Click
        print("RBP:mousepressed() - About to check self.passButton:isHovered. self.passButton is: ", self.passButton)
        if self.passButton:isHovered(x,y) then
            print("RBP: Pass button clicked by " .. buyer.name .. " (PlayerIndex: " .. actualPlayerIndex_mouse .. ")")
            State.playersWhoPassedResourceBuying[actualPlayerIndex_mouse] = true
            State.setSelectedResourceForPurchase(nil) -- Clear selection on pass
            
            -- Advance to next buyer
            local allPassed = true
            for i = 1, #State.players do
                if not State.playersWhoPassedResourceBuying[i] then
                    allPassed = false
                    break
                end
            end

            if allPassed then
                print("RBP: All players have passed. Phase should complete.")
                self.phaseComplete = true
            else
                local currentOrderIndex_pass = State.currentResourceBuyerOrderIndex
                local nextOrderIndex_pass = currentOrderIndex_pass
                repeat
                    nextOrderIndex_pass = nextOrderIndex_pass % #State.resourceBuyingOrder + 1
                    local nextPlayerActualIdx_pass = State.resourceBuyingOrder[nextOrderIndex_pass]
                    if not State.playersWhoPassedResourceBuying[nextPlayerActualIdx_pass] then
                        State.currentResourceBuyerOrderIndex = nextOrderIndex_pass
                        local nextPlayer = State.players[nextPlayerActualIdx_pass]
                        print("RBP: Advanced to next buyer: " .. nextPlayer.name .. " (PlayerIndex: " .. nextPlayerActualIdx_pass .. ", NewOrderIndex: ".. State.currentResourceBuyerOrderIndex ..")")
                        break
                    end
                until nextOrderIndex_pass == currentOrderIndex_pass -- Full circle, means all remaining have passed (should be caught by allPassed)
                if nextOrderIndex_pass == currentOrderIndex_pass and not allPassed then
                    print("RBP: Pass turn logic stuck or all remaining players passed simultaneously? Triggering phase complete. (OrderIndex: ".. currentOrderIndex_pass .. ")")
                    self.phaseComplete = true -- Should not happen if allPassed works
                end
            end
            return -- consume click
        end
    end
end

function ResourceBuyingPhase:keypressed(key)
    if key == "c" then -- Dev key to complete phase
        print("RBP: Dev key C pressed - completing phase.")
        self.phaseComplete = true
    end
end

function ResourceBuyingPhase:isPhaseComplete()
    if self.phaseComplete then
        print("RBP:isPhaseComplete() returning true.")
        -- self.phaseComplete = false -- Reset for next time - NO, PhaseManager should re-init or Game should control phase object lifetime
        return true
    end

    -- Check if all players have passed
    local allPlayersPassed = true
    if #State.players > 0 and #State.playersWhoPassedResourceBuying > 0 then
        for i = 1, #State.players do 
            -- Check against the actual player indices in the map
            if not State.playersWhoPassedResourceBuying[i] then
                allPlayersPassed = false
                break
            end
        end
    else
        allPlayersPassed = false -- No players or no pass tracking means not complete by this rule
    end

    if allPlayersPassed then
        print("RBP: All players have passed, phase is complete.")
        return true
    end

    return false
end

return ResourceBuyingPhase 