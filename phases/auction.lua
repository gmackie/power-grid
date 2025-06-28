local AuctionPhase = {}
AuctionPhase.__index = AuctionPhase

local UI = require("ui")
local State = require("state")
local enums = require("models.enums")

-- Forward declaration for helper functions
local resolveAuctionWin
local determineNextBidderOrEndAuction
local advanceNominatorInternal -- To avoid conflict with a potential self.advanceNominator

function AuctionPhase.new()
    local self = setmetatable({}, AuctionPhase)
    self.bidButton = UI.Button.new("Bid", 0, 0, 120, 40)
    self.passBidButton = UI.Button.new("Pass Bid", 0, 0, 120, 40)
    self.passNominationButton = UI.Button.new("End My Auctions", 0, 0, 220, 40) -- Player opts out for the round
    self.nominatePlantButton = UI.Button.new("Nominate Plant",0,0, 200, 40) -- Dynamic text later
    self.cancelSelectionButton = UI.Button.new("Cancel Selection",0,0,200,40)

    self.marketStartY = 170 -- Player panel height + some padding
    self.cardRows = 2
    self.cardCols = 4
    self.cardW, self.cardH = 180, 120
    self.colSpacing = 200 -- Increased spacing
    self.rowSpacing = 140 -- Increased spacing
    self.marketActualWidth = (self.cardCols * self.cardW) + ((self.cardCols - 1) * (self.colSpacing - self.cardW))
    self.hoveredMarketCardIndex = nil
    self.phaseCompleteSignal = false -- Signal for game state to move to next phase
    
    -- Make helpers available to the instance if they need to modify self, like phaseCompleteSignal
    -- Or, ensure they are called in a context where they can set it.
    -- For now, keeping them local to the module.

    advanceNominatorInternal = function()
        if State.getPlayerCount() == 0 then return false end -- No players, can't advance
        local allDoneNominatingOrBought = true
        for i = 1, State.getPlayerCount() do
            if not State.hasBoughtPlantThisRoundOrPassedNomination[i] then
                allDoneNominatingOrBought = false
                break
            end
        end

        if allDoneNominatingOrBought then
            print("All players have bought a plant or passed nominating for this auction round.")
            State.resetAuctionRoundTracking() -- Prepare for a potential next game turn's auction phase
            -- TODO: Here, we should signal PhaseManager to go to the next game phase.
            -- For now, it might loop or stall. PhaseManager.nextPhase() should be called.
            return true -- Indicate all are done with auction phase turns
        end

        local originalNominator = State.currentPlayerIndex
        local nextNominatorFound = false
        for i = 1, State.getPlayerCount() do
            local potentialNominator = (State.currentPlayerIndex % State.getPlayerCount()) + 1
            State.currentPlayerIndex = potentialNominator -- Directly set for this internal logic
            if not State.hasBoughtPlantThisRoundOrPassedNomination[State.currentPlayerIndex] then
                nextNominatorFound = true
                break
            end
            if State.currentPlayerIndex == originalNominator and i > 1 then -- Full loop, no one found (should be caught by allDone)
                 break
            end
        end
        
        if nextNominatorFound then
             print("AUCTION PHASE: Nomination turn passes to Player " .. State.players[State.currentPlayerIndex].name)
        else
            -- This case should ideally be covered by allDoneNominatingOrBought, but as a fallback:
            print("AUCTION PHASE: Could not find next nominator, implies all done or error.")
            return true -- Treat as all done
        end
        return false -- Indicate not all are done
    end

    resolveAuctionWin = function(winnerIndex) -- Can't use self here directly for phaseCompleteSignal
        local winner = State.players[winnerIndex]
        print("Player " .. winner.name .. " wins plant #" .. State.currentAuction.plant.id .. " for $" .. State.currentBid)
        winner.money = winner.money - State.currentBid
        winner:addPowerPlant(State.currentAuction.plant)
        State.hasBoughtPlantThisRoundOrPassedNomination[winnerIndex] = true
        
        local plantIdToRemove = State.currentAuction.plant.id
        for i_market, p_market in ipairs(State.powerPlantMarket) do
            if p_market.id == plantIdToRemove then
                table.remove(State.powerPlantMarket, i_market)
                -- TODO: Replenish market from draw pile if applicable by rules
                break
            end
        end
        
        State.selectedPlant = nil 
        State.endAuction() 
        
        if advanceNominatorInternal() then
            -- This is tricky. resolveAuctionWin is not a method of AuctionPhase instance here.
            -- We need a way for it to signal phase completion to the instance that called it.
            -- For now, the caller (determineNextBidderOrEndAuction) will check advanceNominatorInternal's result.
            return true -- Signal that nominator advance indicated phase end
        end
        return false
    end

    determineNextBidderOrEndAuction = function()
        if not State.currentAuction then return false end

        local activeBiddersIndices = {}
        for i = 1, State.getPlayerCount() do
            if not State.currentAuction.passedPlayers[i] and 
               not State.hasBoughtPlantThisRoundOrPassedNomination[i] then
                table.insert(activeBiddersIndices, i)
            end
        end

        if #activeBiddersIndices == 0 then
            if State.currentAuction.bidOwner and State.currentBid >= State.currentAuction.plant.cost then
                print("No active bidders left. Current bid owner " .. State.players[State.currentAuction.bidOwner].name .. " wins by default.")
                return resolveAuctionWin(State.currentAuction.bidOwner)
            else
                print("No winner for plant #" .. State.currentAuction.plant.id .. ". Auction ends without a sale.")
                State.selectedPlant = nil
                State.endAuction()
                return advanceNominatorInternal()
            end
        elseif #activeBiddersIndices == 1 then
            local soleEligibleBidder = activeBiddersIndices[1]
            if soleEligibleBidder == State.currentAuction.bidOwner then
                print("Player " .. State.players[soleEligibleBidder].name .. " is the only remaining eligible bidder and owns the current bid. Wins!")
                return resolveAuctionWin(soleEligibleBidder)
            else
                State.currentAuction.currentBidder = soleEligibleBidder
                State.bidInput = tostring(State.currentBid + 1)
                print("Turn to bid passes to sole remaining eligible player: " .. State.players[State.currentAuction.currentBidder].name)
            end
        else -- More than one active bidder
            local lastActor = State.currentAuction.currentBidder 
            
            local nextBidderIndexInActiveList = -1
            local lastActorIndexInActiveList = -1

            for i, pIdx in ipairs(activeBiddersIndices) do
                if pIdx == lastActor then
                    lastActorIndexInActiveList = i
                    break
                end
            end

            if lastActorIndexInActiveList ~= -1 then
                nextBidderIndexInActiveList = (lastActorIndexInActiveList % #activeBiddersIndices) + 1
            else -- lastActor wasn't in active list (e.g. nominator, and this is the first turn setting)
                 -- Start from the first player in activeBiddersIndices that isn't the bidOwner (unless they are the only one)
                for i, pIdx in ipairs(activeBiddersIndices) do
                    if pIdx ~= State.currentAuction.bidOwner then
                        nextBidderIndexInActiveList = i
                        break
                    end
                end
                if nextBidderIndexInActiveList == -1 and #activeBiddersIndices > 0 then -- all are bidOwner (only 1 if so)
                    nextBidderIndexInActiveList = 1 -- pick the first one (must be bidOwner)
                end
            end
            
            if nextBidderIndexInActiveList ~= -1 then
                local nextPlayerToAct = activeBiddersIndices[nextBidderIndexInActiveList]
                if nextPlayerToAct == State.currentAuction.bidOwner then
                    print("All other eligible players have passed or are ineligible. Player " .. State.players[State.currentAuction.bidOwner].name .. " wins.")
                    return resolveAuctionWin(State.currentAuction.bidOwner)
                else
                    State.currentAuction.currentBidder = nextPlayerToAct
                    State.bidInput = tostring(State.currentBid + 1)
                    print("Turn to bid passes to Player " .. State.players[State.currentAuction.currentBidder].name)
                    -- nextBidderFound = true -> not needed with this logic
                end
            else
                 -- This path should ideally not be hit if #activeBiddersIndices > 1
                print("ERROR: Could not determine next bidder among multiple eligible players (active list issue). Auction ends without sale.")
                State.endAuction()
                return advanceNominatorInternal()
            end
        end
        return false -- Auction continues or nominator advanced without phase end
    end

    return self
end

function AuctionPhase:update(dt)
    local mx, my = love.mouse.getPosition()
    local windowWidth = love.graphics.getWidth()
    local auctionControlsBaseY = self.marketStartY + (self.cardRows * self.cardH) + ((self.cardRows -1) * (self.rowSpacing - self.cardH)) + 60

    -- Update market card hover state
    self.hoveredMarketCardIndex = nil
    local marketStartX = (windowWidth - self.marketActualWidth) / 2
    if not State.currentAuction then -- Can only hover to select if not in an active bid war
        for r = 0, self.cardRows - 1 do
            for c = 0, self.cardCols - 1 do
                local idx = r * self.cardCols + c + 1
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

    if State.currentAuction then
        self.bidButton.x = windowWidth/2 - self.bidButton.w - 10 
        self.bidButton.y = auctionControlsBaseY + 80
        self.passBidButton.x = windowWidth/2 + 10
        self.passBidButton.y = auctionControlsBaseY + 80
        
        self.bidButton:update(mx, my)
        self.passBidButton:update(mx, my)
    elseif State.selectedPlant then -- Plant tentatively selected, show Nominate/Cancel buttons
        self.nominatePlantButton.text = "Nominate #" .. State.selectedPlant.id .. " ($" .. State.selectedPlant.cost .. ")"
        self.nominatePlantButton.x = windowWidth/2 - self.nominatePlantButton.w - 5
        self.nominatePlantButton.y = auctionControlsBaseY
        self.cancelSelectionButton.x = windowWidth/2 + 5
        self.cancelSelectionButton.y = auctionControlsBaseY
        self.nominatePlantButton:update(mx,my)
        self.cancelSelectionButton:update(mx,my)
    else
        -- Update Pass Nomination button if no auction is active and current player hasn't finished their turn
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

    -- Draw power plant market cards
    for r = 0, self.cardRows - 1 do -- 0-indexed for easier calculation
        for c = 0, self.cardCols - 1 do -- 0-indexed
            local idx = r * self.cardCols + c + 1
            local plant = State.powerPlantMarket[idx]
            if plant then
                local cardX = marketStartX + c * self.colSpacing
                local cardY = self.marketStartY + r * self.rowSpacing
                
                local isSelectedForAuction = State.currentAuction and State.currentAuction.plant and State.currentAuction.plant.id == plant.id
                local isTentativelySelected = State.selectedPlant and State.selectedPlant.id == plant.id
                local isHovered = self.hoveredMarketCardIndex == idx
                
                -- Draw plant card
                local baseColor = plant:getResourceColor() or {0.3, 0.3, 0.3, 1}
                love.graphics.setColor(baseColor[1]* (isHovered and 1.2 or 1), baseColor[2]*(isHovered and 1.2 or 1), baseColor[3]*(isHovered and 1.2 or 1), baseColor[4])
                love.graphics.rectangle("fill", cardX, cardY, self.cardW, self.cardH, 10)

                if isSelectedForAuction or isTentativelySelected then
                    love.graphics.setColor(1, 1, 0, 1) -- Bright yellow for selected plant
                    love.graphics.setLineWidth(isTentativelySelected and 3 or 5) -- Thicker if actively in auction
                elseif isHovered then
                    love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Default border
                    love.graphics.setLineWidth(2)
                else
                    love.graphics.setColor(0.5, 0.5, 0.5, 1) -- Default border
                    love.graphics.setLineWidth(1)
                end
                love.graphics.rectangle("line", cardX, cardY, self.cardW, self.cardH, 10)
                love.graphics.setLineWidth(1)

                -- Draw plant info
                love.graphics.setColor(1, 1, 1, 1)
                local textPadding = 10
                love.graphics.print("Plant #" .. plant.id, cardX + textPadding, cardY + textPadding)
                love.graphics.print("Cost: $" .. plant.cost, cardX + textPadding, cardY + textPadding + 20)
                love.graphics.print("Type: " .. plant.resourceType, cardX + textPadding, cardY + textPadding + 40)
                love.graphics.print("Cities: " .. plant.capacity, cardX + textPadding, cardY + textPadding + 60)
                love.graphics.print("Fuel: " .. plant.resourceCost, cardX + textPadding, cardY + textPadding + 80)
            end
        end
    end

    if State.currentAuction then
        -- Draw Auction Controls (Bid, Pass Bid, Bid Input)
        local plantForAuction = State.currentAuction.plant
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Auctioning Plant #" .. plantForAuction.id .. " (Min. Bid: $" .. plantForAuction.cost .. ")", 0, auctionControlsBaseY, windowWidth, "center")
        local currentAuctionInfoY = auctionControlsBaseY + 30
        
        local nominatorPlayer = State.players[State.currentAuction.nominator]
        love.graphics.printf("(Nominated by " .. nominatorPlayer.name .. ")", 0, currentAuctionInfoY, windowWidth, "center")
        currentAuctionInfoY = currentAuctionInfoY + 25

        local currentBidderInAuction = State.players[State.currentAuction.currentBidder]
        if currentBidderInAuction then
            love.graphics.setColor(currentBidderInAuction.color or {1,1,1,1})
            love.graphics.printf(currentBidderInAuction.name .. "'s turn to bid.", 0, currentAuctionInfoY, windowWidth, "center")
            love.graphics.setColor(1,1,1,1)
        end
        currentAuctionInfoY = currentAuctionInfoY + 30
        love.graphics.printf("Current Bid: $" .. State.currentBid, 0, currentAuctionInfoY, windowWidth, "center")
        currentAuctionInfoY = currentAuctionInfoY + 30
        local bidInputX = windowWidth/2 - 60
        local bidInputY = currentAuctionInfoY
        love.graphics.setColor(State.bidInputFocused and {0.3, 0.3, 0.5, 1} or {0.2, 0.2, 0.3, 1})
        love.graphics.rectangle("fill", bidInputX, bidInputY, 120, 40, 8)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(State.bidInputFocused and 3 or 1)
        love.graphics.rectangle("line", bidInputX, bidInputY, 120, 40, 8)
        love.graphics.setLineWidth(1)
        love.graphics.printf(State.bidInput or "", bidInputX, bidInputY + 10, 120, "center")
        self.bidButton:draw()
        self.passBidButton:draw()
    elseif State.selectedPlant then
        -- Show Nominate Plant / Cancel Selection buttons
        love.graphics.setFont(love.graphics.newFont(20))
        local nominator = State.players[State.currentPlayerIndex]
        love.graphics.setColor(nominator.color or {1,1,1,1})
        love.graphics.printf(nominator.name .. ": Confirm nomination for Plant #" .. State.selectedPlant.id .. "?", 0, auctionControlsBaseY - 25, windowWidth, "center") 
        love.graphics.setColor(1,1,1,1)       
        self.nominatePlantButton:draw()
        self.cancelSelectionButton:draw()
    else
        local nominator = State.players[State.currentPlayerIndex] 
        if nominator and not State.hasBoughtPlantThisRoundOrPassedNomination[State.currentPlayerIndex] then
            love.graphics.setFont(love.graphics.newFont(20))
            love.graphics.setColor(nominator.color or {1,1,1,1})
            love.graphics.printf(nominator.name .. ": Select a plant to auction or End Your Auctions", 0, auctionControlsBaseY, windowWidth, "center")
            love.graphics.setColor(1,1,1,1)
            self.passNominationButton:draw()
        else
            -- This case implies all players are done for the round.
            local allDone = true
            for i=1, State.getPlayerCount() do if not State.hasBoughtPlantThisRoundOrPassedNomination[i] then allDone = false; break; end end
            if allDone then
                love.graphics.setFont(love.graphics.newFont(20))
                love.graphics.printf("All players done with auctions. Phase ending...", 0, auctionControlsBaseY, windowWidth, "center")
            end
        end
    end
end

function AuctionPhase:mousepressed(x, y, button)
    if button == 1 then
        local windowWidth = love.graphics.getWidth()
        local marketStartX = (windowWidth - self.marketActualWidth) / 2

        if not State.currentAuction then -- NOMINATION PART (either selecting plant, confirming, or passing nomination turn)
            local currentPlayerCanNominate = not State.hasBoughtPlantThisRoundOrPassedNomination[State.currentPlayerIndex]
            
            if currentPlayerCanNominate then
                if State.selectedPlant then -- A plant is tentatively selected, check Nominate/Cancel buttons
                    if self.nominatePlantButton:isHovered(x,y) then
                        State.startAuction(State.selectedPlant, State.currentPlayerIndex)
                        State.selectedPlant = nil 
                        if determineNextBidderOrEndAuction() then 
                            self.phaseCompleteSignal = true
                        end
                        return
                    elseif self.cancelSelectionButton:isHovered(x,y) then
                        State.selectedPlant = nil
                        return
                    end
                else -- No plant tentatively selected, check Pass Nomination or plant click
                    if self.passNominationButton:isHovered(x,y) then
                        State.hasBoughtPlantThisRoundOrPassedNomination[State.currentPlayerIndex] = true
                        print(State.players[State.currentPlayerIndex].name .. " has chosen to end their auctions for this round.")
                        State.selectedPlant = nil -- Ensure no lingering selection
                        if advanceNominatorInternal() then 
                            self.phaseCompleteSignal = true
                        end
                        return
                    end
                    -- Try to tentatively select a plant from market
                    for r = 0, self.cardRows - 1 do
                        for c = 0, self.cardCols - 1 do
                            local idx = r * self.cardCols + c + 1
                            local plant = State.powerPlantMarket[idx]
                            if plant then
                                local cardX = marketStartX + c * self.colSpacing
                                local cardY = self.marketStartY + r * self.rowSpacing
                                if x >= cardX and x <= cardX + self.cardW and y >= cardY and y <= cardY + self.cardH then
                                    State.selectedPlant = plant
                                    print("Player " .. State.players[State.currentPlayerIndex].name .. " tentatively selected Plant #" .. plant.id)
                                    return
                                end
                            end
                        end
                    end
                end
            end
        else -- BIDDING PHASE (State.currentAuction is active)
            local auctionControlsBaseY = self.marketStartY + (self.cardRows * self.cardH) + ((self.cardRows -1) * (self.rowSpacing - self.cardH)) + 30
            local bidInputY = auctionControlsBaseY + 30 + 25 + 30 + 30 -- Y position of bid input box
            local bidInputBoxX = windowWidth/2 - 60
            if x >= bidInputBoxX and x <= bidInputBoxX + 120 and y >= bidInputY and y <= bidInputY + 40 then
                State.setBidInputFocused(true)
            else
                State.setBidInputFocused(false)
            end

            if self.bidButton:isHovered(x, y) then
                local bidder = State.players[State.currentAuction.currentBidder]
                if not bidder or State.hasBoughtPlantThisRoundOrPassedNomination[State.currentAuction.currentBidder] then
                    print("Current bidder is ineligible or has already bought/passed nomination.")
                    return
                end
                local bidAmount = tonumber(State.bidInput)
                if bidAmount and bidder and bidAmount > State.currentBid and bidAmount <= bidder.money then
                    State.setCurrentBid(bidAmount)
                    State.currentAuction.bidOwner = State.currentAuction.currentBidder 
                    if determineNextBidderOrEndAuction() then
                        self.phaseCompleteSignal = true
                    end
                else
                    print("Invalid bid (amount or funds or eligibility).")
                end
                return
            end

            if self.passBidButton:isHovered(x, y) then
                local passingPlayerIndex = State.currentAuction.currentBidder
                if not State.players[passingPlayerIndex] or State.hasBoughtPlantThisRoundOrPassedNomination[passingPlayerIndex] then
                     print("Player " .. (State.players[passingPlayerIndex] and State.players[passingPlayerIndex].name or tostring(passingPlayerIndex)) .. " cannot pass as they are ineligible or not current bidder.")
                     return
                end
                State.currentAuction.passedPlayers[passingPlayerIndex] = true
                print(State.players[passingPlayerIndex].name .. " passed bid for plant #" .. State.currentAuction.plant.id)
                if determineNextBidderOrEndAuction() then
                    self.phaseCompleteSignal = true
                end
                return
            end
        end
    end
end

function AuctionPhase:textinput(t)
    if State.bidInputFocused then
        if t:match("%d") then
            State.bidInput = (State.bidInput or "") .. t
        end
    end
end

function AuctionPhase:keypressed(key)
    if State.currentAuction and State.bidInputFocused then
        if key == "backspace" then
            State.bidInput = (State.bidInput or ""):sub(1, -2)
        elseif key == "return" or key == "kpenter" then
            local bidder = State.players[State.currentAuction.currentBidder]
            if not bidder or State.hasBoughtPlantThisRoundOrPassedNomination[State.currentAuction.currentBidder] then
                print("Current bidder is ineligible for keypress bid.")
                return
            end
            local bidAmount = tonumber(State.bidInput)
            if bidAmount and bidder and bidAmount > State.currentBid and bidAmount <= bidder.money then
                State.setCurrentBid(bidAmount)
                State.currentAuction.bidOwner = State.currentAuction.currentBidder
                if determineNextBidderOrEndAuction() then
                    self.phaseCompleteSignal = true
                end
            else
                 print("Invalid bid from text input (amount or funds or eligibility).")
            end
        end
    end
end

-- mousemoved and mousereleased are not strictly needed for buttons if update handles hover
-- and mousepressed handles clicks, but can be kept for future complex interactions.

function AuctionPhase:isPhaseComplete()
    if self.phaseCompleteSignal then
        self.phaseCompleteSignal = false -- Reset signal after it's read
        return true
    end
    return false
end

function AuctionPhase:enter()
    print("Entering Auction Phase")
    State.resetAuctionRoundTracking() -- Ensure auction state is fresh for the round
    self.phaseCompleteSignal = false -- Ensure signal is reset
    -- Any other setup for when auction phase begins, like determining initial nominator if not already set
    -- For now, currentPlayerIndex should be set correctly by PlayerOrder phase or game setup.
end

return AuctionPhase 