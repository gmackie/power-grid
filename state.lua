local State = {
    -- Game state
    currentState = "menu",  -- menu, playerSetup, game
    currentPhase = nil,     -- PLAYER_ORDER, AUCTION, RESOURCE_BUYING, BUILDING, BUREAUCRACY
    
    -- Players
    players = {},
    currentPlayerIndex = 1,
    
    -- Markets
    powerPlantMarket = {},
    resourceMarket = nil,
    
    -- Auction state
    currentAuction = nil,
    currentBid = 0,
    bidInput = "",
    bidInputFocused = false,
    playersWhoPassedNomination = {},
    hasBoughtPlantThisRoundOrPassedNomination = {},
    
    -- Game board
    cities = {},
    connections = {},
    
    -- Game settings
    playerCount = 0,
    step = 1,  -- Game step (1, 2, or 3)
    
    -- UI state
    selectedCity = nil,
    selectedPlant = nil,
    selectedResource = nil,

    -- Resource Buying Phase specific state
    selectedResourceForPurchase = nil, -- e.g., enums.ResourceType.COAL
    purchaseAmountInput = "", -- For typing in an amount
    selectedPlantForStoring = nil, -- Which of the current player's plants to store resources on
    resourceBuyingOrder = {}, -- Array of player indices in reverse player order for this phase
    currentResourceBuyerOrderIndex = 1, -- Index into resourceBuyingOrder (e.g. 1st, 2nd in order)
    playersWhoPassedResourceBuying = {} -- Map of player_index -> boolean, tracks who has passed buying for the round
}

-- Initialize the state
function State.init()
    print("****** State.init() CALLED ******")
    -- Reset all state
    State.currentState = "menu"
    State.currentPhase = nil
    State.players = {}
    State.currentPlayerIndex = 1
    State.powerPlantMarket = {}
    State.resourceMarket = nil
    State.currentAuction = nil
    State.currentBid = 0
    State.bidInput = ""
    State.bidInputFocused = false
    State.playersWhoPassedNomination = {} -- Tracks who passed on *bidding* for current plant in currentAuction
    State.hasBoughtPlantThisRoundOrPassedNomination = {} -- Tracks who is done nominating/buying for the whole phase round
    State.cities = {}
    State.connections = {}
    State.playerCount = 0
    State.step = 1
    State.selectedCity = nil
    State.selectedPlant = nil
    State.selectedResource = nil
    State.selectedResourceForPurchase = nil
    State.purchaseAmountInput = ""
    State.selectedPlantForStoring = nil
    State.resourceBuyingOrder = {}
    State.currentResourceBuyerOrderIndex = 1
    State.playersWhoPassedResourceBuying = {}
end

-- Game state management
function State.setCurrentState(state)
    State.currentState = state
end

function State.setCurrentPhase(phase)
    State.currentPhase = phase
end

-- Player management
function State.addPlayer(player)
    table.insert(State.players, player)
    State.playerCount = State.playerCount + 1
end

function State.getCurrentPlayer()
    return State.players[State.currentPlayerIndex]
end

function State.nextPlayer()
    State.currentPlayerIndex = State.currentPlayerIndex % State.playerCount + 1
    return State.getCurrentPlayer()
end

function State.getPlayerCount()
    return State.playerCount
end

-- Market management
function State.setPowerPlantMarket(market)
    State.powerPlantMarket = market
end

function State.setResourceMarket(market)
    State.resourceMarket = market
end

function State.getPowerPlantMarket()
    return State.powerPlantMarket
end

function State.getResourceMarket()
    return State.resourceMarket
end

-- Auction management
function State.startAuction(plant, nominatorIndex)
    State.currentAuction = {
        plant = plant,
        nominator = nominatorIndex, -- Store who nominated
        currentBidder = nominatorIndex, -- Nominator makes the first auto-bid, AuctionPhase will determine actual next actor
        bidOwner = nominatorIndex,    -- Player who made the current State.currentBid
        passedPlayers = {} -- Players who passed on bidding for THIS plant
    }
    State.currentBid = plant.cost
    State.bidInput = tostring(State.currentBid)
    print("Auction started for plant #" .. plant.id .. " by Player " .. State.players[nominatorIndex].name .. " at $" .. State.currentBid)
end

function State.endAuction()
    State.currentAuction = nil
    State.currentBid = 0
    State.bidInput = ""
    State.bidInputFocused = false
end

function State.getCurrentAuction()
    return State.currentAuction
end

function State.getCurrentBid()
    return State.currentBid
end

function State.setCurrentBid(bid)
    State.currentBid = bid
end

function State.setBidInput(input)
    State.bidInput = input
end

function State.getBidInput()
    return State.bidInput
end

function State.setBidInputFocused(focused)
    State.bidInputFocused = focused
end

function State.isBidInputFocused()
    return State.bidInputFocused
end

-- Game board management
function State.addCity(city)
    table.insert(State.cities, city)
end

function State.addConnection(connection)
    table.insert(State.connections, connection)
end

function State.getCities()
    return State.cities
end

function State.getConnections()
    return State.connections
end

-- Game settings
function State.setStep(step)
    State.step = step
end

function State.getStep()
    return State.step
end

-- UI state management
function State.setSelectedCity(city)
    State.selectedCity = city
end

function State.setSelectedPlant(plant)
    State.selectedPlant = plant
end

function State.setSelectedResource(resource)
    State.selectedResource = resource
end

function State.getSelectedCity()
    return State.selectedCity
end

function State.getSelectedPlant()
    return State.selectedPlant
end

function State.getSelectedResource()
    return State.selectedResource
end

function State.resetNominationPasses()
    State.playersWhoPassedNomination = {}
end

function State.resetAuctionRoundTracking()
    State.hasBoughtPlantThisRoundOrPassedNomination = {}
    State.resetNominationPasses() -- This might be redundant if combined or called at the same time
end

function State.resetResourceBuyingTurnState()
    State.resourceBuyingOrder = {}
    State.currentResourceBuyerOrderIndex = 1
    State.playersWhoPassedResourceBuying = {}
    State.selectedResourceForPurchase = nil
    State.purchaseAmountInput = ""
    State.selectedPlantForStoring = nil
    print("State: Resource buying turn state reset.")
end

-- For Resource Buying Phase
function State.setSelectedResourceForPurchase(resourceType)
    State.selectedResourceForPurchase = resourceType
    print("State: Selected resource for purchase: ", resourceType)
end

function State.getSelectedResourceForPurchase()
    return State.selectedResourceForPurchase
end

function State.setPurchaseAmountInput(text)
    State.purchaseAmountInput = text
end

function State.getPurchaseAmountInput()
    return State.purchaseAmountInput
end

function State.setSelectedPlantForStoring(plant)
    State.selectedPlantForStoring = plant
end

function State.getSelectedPlantForStoring()
    return State.selectedPlantForStoring
end

return State 