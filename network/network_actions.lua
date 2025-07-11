-- Network Actions - Wrapper for game actions that sends them to server when online

local NetworkManager = require("network.network_manager")
local State = require("state")

local NetworkActions = {}

-- Check if we're in online mode
local function isOnline()
    return State.networkGame and State.networkGame.isOnline
end

-- Get the network manager instance
local function getNetwork()
    return NetworkManager.getInstance()
end

-- Auction Phase Actions

function NetworkActions.bidOnPlant(plantId, bidAmount)
    if isOnline() then
        return getNetwork():bidOnPlant(plantId, bidAmount)
    end
    -- For offline mode, return true to indicate action should proceed locally
    return true
end

function NetworkActions.passOnBid()
    if isOnline() then
        -- Pass is represented as a 0 bid
        return getNetwork():bidOnPlant(State.currentAuction.plantId, 0)
    end
    return true
end

-- Resource Buying Actions

function NetworkActions.buyResources(resources)
    if isOnline() then
        return getNetwork():buyResources(resources)
    end
    return true
end

-- Building Phase Actions

function NetworkActions.buildCity(cityId)
    if isOnline() then
        return getNetwork():buildCity(cityId)
    end
    return true
end

-- Bureaucracy Phase Actions

function NetworkActions.powerCities(plantIds)
    if isOnline() then
        return getNetwork():powerCities(plantIds)
    end
    return true
end

-- General Actions

function NetworkActions.endTurn()
    if isOnline() then
        return getNetwork():endTurn()
    end
    return true
end

-- Check if it's the local player's turn
function NetworkActions.isMyTurn()
    if isOnline() then
        return getNetwork():isMyTurn()
    else
        -- In offline mode, always allow actions
        return true
    end
end

-- Get the current player (useful for displaying whose turn it is)
function NetworkActions.getCurrentPlayer()
    if isOnline() then
        local network = getNetwork()
        if network.currentGame and network.currentGame.current_turn then
            -- Find player by ID
            for _, player in ipairs(State.players) do
                if player.id == network.currentGame.current_turn then
                    return player
                end
            end
        end
    end
    
    -- Fallback to local current player
    return State.players[State.currentPlayerIndex]
end

-- Check if we should wait for server response
function NetworkActions.shouldWaitForServer()
    return isOnline()
end

-- Helper to show "waiting for other players" message
function NetworkActions.isWaitingForOthers()
    if isOnline() then
        return not NetworkActions.isMyTurn()
    end
    return false
end

return NetworkActions