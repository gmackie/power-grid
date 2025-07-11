-- Modified Auction Phase with network support
local AuctionPhase = {}
AuctionPhase.__index = AuctionPhase

local UI = require("ui")
local State = require("state")
local enums = require("models.enums")
local NetworkActions = require("network.network_actions")

-- Forward declaration for helper functions
local resolveAuctionWin
local determineNextBidderOrEndAuction
local advanceNominatorInternal

function AuctionPhase.new()
    local self = setmetatable({}, AuctionPhase)
    self.bidButton = UI.Button.new("Bid", 0, 0, 120, 40)
    self.passBidButton = UI.Button.new("Pass Bid", 0, 0, 120, 40)
    self.passNominationButton = UI.Button.new("End My Auctions", 0, 0, 220, 40)
    self.nominatePlantButton = UI.Button.new("Nominate Plant",0,0, 200, 40)
    self.cancelSelectionButton = UI.Button.new("Cancel Selection",0,0,200,40)

    self.marketStartY = 170
    self.cardRows = 2
    self.cardCols = 4
    self.cardW, self.cardH = 180, 120
    self.colSpacing = 200
    self.rowSpacing = 140
    self.marketActualWidth = (self.cardCols * self.cardW) + ((self.cardCols - 1) * (self.colSpacing - self.cardW))
    self.hoveredMarketCardIndex = nil
    self.phaseCompleteSignal = false
    self.waitingForServer = false
    
    return self
end

function AuctionPhase:enter()
    print("AuctionPhase entered")
    self.phaseCompleteSignal = false
    self.waitingForServer = false
    State.resetAuctionRoundTracking()
    State.currentAuction = nil
    State.selectedPlant = nil
end

function AuctionPhase:exit()
    print("AuctionPhase exited")
end

function AuctionPhase:update(dt)
    if self.phaseCompleteSignal then
        State.currentPhase = enums.GamePhase.RESOURCE_BUYING
        self.phaseCompleteSignal = false
        return
    end

    local mx, my = love.mouse.getPosition()
    local windowWidth = love.graphics.getWidth()
    local marketStartX = (windowWidth - self.marketActualWidth) / 2
    local auctionControlsBaseY = self.marketStartY + (self.cardRows * self.cardH) + ((self.cardRows -1) * (self.rowSpacing - self.cardH)) + 30

    -- Check if waiting for other players in online mode
    if NetworkActions.isWaitingForOthers() then
        self.waitingForServer = true
        return -- Don't update UI elements when not our turn
    else
        self.waitingForServer = false
    end

    -- Update hovered market card
    self.hoveredMarketCardIndex = nil
    for r = 0, self.cardRows - 1 do
        for c = 0, self.cardCols - 1 do
            local idx = r * self.cardCols + c + 1
            if idx <= #State.powerPlantMarket then
                local plant = State.powerPlantMarket[idx]
                if plant then
                    local cardX = marketStartX + c * self.colSpacing
                    local cardY = self.marketStartY + r * self.rowSpacing
                    if mx >= cardX and mx <= cardX + self.cardW and my >= cardY and my <= cardY + self.cardH then
                        self.hoveredMarketCardIndex = idx
                        break
                    end
                end
            end
            if self.hoveredMarketCardIndex then break end
        end
    end

    -- Update UI buttons based on state
    if State.currentAuction then
        self.bidButton.x = windowWidth/2 - self.bidButton.w - 10 
        self.bidButton.y = auctionControlsBaseY + 80
        self.passBidButton.x = windowWidth/2 + 10
        self.passBidButton.y = auctionControlsBaseY + 80
        
        self.bidButton:update(mx, my)
        self.passBidButton:update(mx, my)
    elseif State.selectedPlant then
        self.nominatePlantButton.text = "Nominate #" .. State.selectedPlant.id .. " ($" .. State.selectedPlant.cost .. ")"
        self.nominatePlantButton.x = windowWidth/2 - self.nominatePlantButton.w - 5
        self.nominatePlantButton.y = auctionControlsBaseY
        self.cancelSelectionButton.x = windowWidth/2 + 5
        self.cancelSelectionButton.y = auctionControlsBaseY
        self.nominatePlantButton:update(mx,my)
        self.cancelSelectionButton:update(mx,my)
    else
        local nominator = State.players[State.currentPlayerIndex]
        if nominator and not State.hasBoughtPlantThisRoundOrPassedNomination[State.currentPlayerIndex] then
            self.passNominationButton.x = windowWidth/2 - self.passNominationButton.w/2
            self.passNominationButton.y = auctionControlsBaseY
            self.passNominationButton:update(mx, my)
        end
    end
end

function AuctionPhase:draw()
    local windowWidth = love.graphics.getWidth()
    local marketStartX = (windowWidth - self.marketActualWidth) / 2
    local auctionControlsBaseY = self.marketStartY + (self.cardRows * self.cardH) + ((self.cardRows -1) * (self.rowSpacing - self.cardH)) + 30

    -- Draw power plant market title
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf("Power Plant Market", 0, self.marketStartY - 30, windowWidth, "center")
    love.graphics.setFont(love.graphics.newFont(16))

    -- Draw waiting message if not our turn
    if self.waitingForServer or NetworkActions.isWaitingForOthers() then
        love.graphics.setColor(1, 1, 0.5, 1)
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.printf("Waiting for other players...", 0, windowWidth/2 - 100, windowWidth, "center")
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Draw market cards
    for r = 0, self.cardRows - 1 do
        for c = 0, self.cardCols - 1 do
            local idx = r * self.cardCols + c + 1
            if idx <= #State.powerPlantMarket then
                local plant = State.powerPlantMarket[idx]
                if plant then
                    local cardX = marketStartX + c * self.colSpacing
                    local cardY = self.marketStartY + r * self.rowSpacing
                    self:drawPowerPlantCard(plant, cardX, cardY, idx == self.hoveredMarketCardIndex, plant == State.selectedPlant)
                end
            end
        end
    end

    -- Draw controls based on current state
    if State.currentAuction then
        self:drawAuctionControls(auctionControlsBaseY)
    elseif State.selectedPlant then
        self.nominatePlantButton:draw()
        self.cancelSelectionButton:draw()
    else
        local nominator = State.players[State.currentPlayerIndex]
        if nominator and not State.hasBoughtPlantThisRoundOrPassedNomination[State.currentPlayerIndex] then
            self.passNominationButton:draw()
        end
    end

    -- Draw selected plant info
    if State.selectedPlant and not State.currentAuction then
        love.graphics.setColor(1, 1, 0.8, 1)
        love.graphics.printf("Selected Plant #" .. State.selectedPlant.id .. " for nomination", 0, auctionControlsBaseY - 30, windowWidth, "center")
    end
end

function AuctionPhase:drawPowerPlantCard(plant, x, y, isHovered, isSelected)
    -- Card background
    if isSelected then
        love.graphics.setColor(0.3, 0.8, 0.3, 1)
    elseif isHovered then
        love.graphics.setColor(0.25, 0.25, 0.3, 1)
    else
        love.graphics.setColor(0.2, 0.2, 0.25, 1)
    end
    love.graphics.rectangle("fill", x, y, self.cardW, self.cardH, 10)
    
    -- Card border
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, self.cardW, self.cardH, 10)
    
    -- Plant number and cost
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print("#" .. plant.id, x + 10, y + 10)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.print("$" .. plant.cost, x + self.cardW - 50, y + 10)
    
    -- Resource type and cost
    love.graphics.setFont(love.graphics.newFont(14))
    local resourceText = plant.resourceType
    if plant.resourcesRequired > 0 then
        resourceText = resourceText .. " x" .. plant.resourcesRequired
    end
    love.graphics.print(resourceText, x + 10, y + 50)
    
    -- Cities powered
    love.graphics.print("Powers " .. plant.citiesPowered .. " cities", x + 10, y + 80)
end

function AuctionPhase:drawAuctionControls(baseY)
    love.graphics.setFont(love.graphics.newFont(18))
    local auctionText = "Auction for Plant #" .. State.currentAuction.plant.id
    love.graphics.printf(auctionText, 0, baseY - 80, love.graphics.getWidth(), "center")
    
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf("Current Bid: $" .. State.currentBid, 0, baseY - 50, love.graphics.getWidth(), "center")
    love.graphics.printf("Bidder: " .. State.currentAuction.currentBidder.name, 0, baseY - 30, love.graphics.getWidth(), "center")
    
    -- Show remaining bidders
    local remainingText = "Remaining bidders: "
    for i, bidder in ipairs(State.currentAuction.activeBidders) do
        if i > 1 then remainingText = remainingText .. ", " end
        remainingText = remainingText .. bidder.name
    end
    love.graphics.printf(remainingText, 0, baseY, love.graphics.getWidth(), "center")
    
    self.bidButton:draw()
    self.passBidButton:draw()
end

function AuctionPhase:mousepressed(x, y, button)
    if button == 1 then
        -- Don't process clicks if waiting for server
        if self.waitingForServer or NetworkActions.isWaitingForOthers() then
            return
        end

        local windowWidth = love.graphics.getWidth()
        local marketStartX = (windowWidth - self.marketActualWidth) / 2

        if not State.currentAuction then
            local currentPlayerCanNominate = not State.hasBoughtPlantThisRoundOrPassedNomination[State.currentPlayerIndex]
            
            if currentPlayerCanNominate then
                if State.selectedPlant then
                    if self.nominatePlantButton:isHovered(x,y) then
                        -- Send nomination to server in online mode
                        if NetworkActions.shouldWaitForServer() then
                            self.waitingForServer = true
                            NetworkActions.bidOnPlant(State.selectedPlant.id, State.selectedPlant.cost)
                        else
                            -- Offline mode - proceed normally
                            State.startAuction(State.selectedPlant, State.currentPlayerIndex)
                            State.selectedPlant = nil 
                            if determineNextBidderOrEndAuction() then 
                                self.phaseCompleteSignal = true
                            end
                        end
                        return
                    elseif self.cancelSelectionButton:isHovered(x,y) then
                        State.selectedPlant = nil
                        return
                    end
                else
                    if self.passNominationButton:isHovered(x,y) then
                        -- Send pass to server in online mode
                        if NetworkActions.shouldWaitForServer() then
                            self.waitingForServer = true
                            NetworkActions.endTurn()
                        else
                            -- Offline mode
                            State.hasBoughtPlantThisRoundOrPassedNomination[State.currentPlayerIndex] = true
                            print(State.players[State.currentPlayerIndex].name .. " has chosen to end their auctions for this round.")
                            State.selectedPlant = nil
                            if advanceNominatorInternal() then 
                                self.phaseCompleteSignal = true
                            end
                        end
                        return
                    end
                    
                    -- Check if clicking on a power plant card
                    for r = 0, self.cardRows - 1 do
                        for c = 0, self.cardCols - 1 do
                            local idx = r * self.cardCols + c + 1
                            if idx <= #State.powerPlantMarket then
                                local plant = State.powerPlantMarket[idx]
                                if plant then
                                    local cardX = marketStartX + c * self.colSpacing
                                    local cardY = self.marketStartY + r * self.rowSpacing
                                    if x >= cardX and x <= cardX + self.cardW and y >= cardY and y <= cardY + self.cardH then
                                        State.selectedPlant = plant
                                        return
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            -- Auction in progress
            local currentPlayer = State.players[State.currentPlayerIndex]
            local currentBidder = State.currentAuction.currentBidder
            
            if currentPlayer == currentBidder then
                if self.bidButton:isHovered(x,y) then
                    local newBid = State.currentBid + 1
                    -- Send bid to server in online mode
                    if NetworkActions.shouldWaitForServer() then
                        self.waitingForServer = true
                        NetworkActions.bidOnPlant(State.currentAuction.plant.id, newBid)
                    else
                        -- Offline mode
                        State.currentBid = newBid
                        State.currentAuction.highestBidder = currentBidder
                        if determineNextBidderOrEndAuction() then
                            self.phaseCompleteSignal = true
                        end
                    end
                elseif self.passBidButton:isHovered(x,y) then
                    -- Send pass to server in online mode
                    if NetworkActions.shouldWaitForServer() then
                        self.waitingForServer = true
                        NetworkActions.passOnBid()
                    else
                        -- Offline mode
                        State.removeBidder(currentBidder)
                        if determineNextBidderOrEndAuction() then
                            self.phaseCompleteSignal = true
                        end
                    end
                end
            end
        end
    end
end

-- Keep the helper functions from the original
-- ... (rest of the original helper functions)

return AuctionPhase