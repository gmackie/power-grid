import type { GameState, Player, PowerPlant, ResourceType } from '../types/game';
import { PhaseManager } from './phaseManager';

export class TurnManager {
  /**
   * Process a player bid action
   */
  static processBid(gameState: GameState, playerId: string, amount: number, plantId?: number): GameState {
    if (gameState.phase !== 'auction' || !gameState.auctionState) {
      throw new Error('Cannot bid outside auction phase');
    }

    const player = gameState.players.find(p => p.id === playerId);
    if (!player) {
      throw new Error('Player not found');
    }

    if (amount > player.money) {
      throw new Error('Insufficient funds');
    }

    const auctionState = { ...gameState.auctionState };
    
    // If no current plant, start new auction
    if (!auctionState.currentPlant && plantId) {
      const plant = gameState.powerPlantMarket.find(p => p.id === plantId);
      if (!plant) {
        throw new Error('Plant not found');
      }
      
      auctionState.currentPlant = plant;
      auctionState.currentBid = amount;
      auctionState.currentBidder = playerId;
    } else if (auctionState.currentPlant) {
      // Bid on existing auction
      if (amount <= auctionState.currentBid) {
        throw new Error('Bid must be higher than current bid');
      }
      
      auctionState.currentBid = amount;
      auctionState.currentBidder = playerId;
    }

    // Move to next player
    const newGameState = PhaseManager.nextPlayer({ ...gameState, auctionState });
    
    // Check if auction is won (all other players passed)
    const activeBidders = auctionState.biddingOrder.filter(
      id => !auctionState.passedPlayers.includes(id) && id !== playerId
    );
    
    if (activeBidders.length === 0 && auctionState.currentPlant) {
      // Auction won
      auctionState.plantsWon[playerId] = auctionState.currentPlant;
      
      // Deduct money from winner
      const winnerIndex = gameState.players.findIndex(p => p.id === playerId);
      const updatedPlayers = [...gameState.players];
      updatedPlayers[winnerIndex] = {
        ...updatedPlayers[winnerIndex],
        money: updatedPlayers[winnerIndex].money - amount,
        powerPlants: [...updatedPlayers[winnerIndex].powerPlants, auctionState.currentPlant]
      };
      
      // Reset auction for next plant
      auctionState.currentPlant = undefined;
      auctionState.currentBid = 0;
      auctionState.currentBidder = undefined;
      auctionState.passedPlayers = [];
      
      return {
        ...newGameState,
        players: updatedPlayers,
        auctionState
      };
    }
    
    return newGameState;
  }

  /**
   * Process a player pass action
   */
  static processPass(gameState: GameState, playerId: string): GameState {
    const { phase } = gameState;
    
    switch (phase) {
      case 'auction':
        return this.processAuctionPass(gameState, playerId);
      case 'resource':
        return this.processResourcePass(gameState, playerId);
      case 'building':
        return this.processBuildingPass(gameState, playerId);
      case 'bureaucracy':
        return this.processBureaucracyPass(gameState, playerId);
      default:
        throw new Error('Invalid phase for pass action');
    }
  }

  /**
   * Process resource purchase
   */
  static processBuyResources(
    gameState: GameState, 
    playerId: string, 
    resources: Record<ResourceType, number>
  ): GameState {
    if (gameState.phase !== 'resource' || !gameState.resourcePhaseState) {
      throw new Error('Cannot buy resources outside resource phase');
    }

    const player = gameState.players.find(p => p.id === playerId);
    if (!player) {
      throw new Error('Player not found');
    }

    // Calculate total cost
    const totalCost = Object.entries(resources).reduce((cost, [type, amount]) => {
      const priceKey = `${type}Price` as keyof typeof gameState.resourceMarket;
      const price = gameState.resourceMarket[priceKey] as number;
      return cost + (price * amount);
    }, 0);

    if (totalCost > player.money) {
      throw new Error('Insufficient funds');
    }

    // Update player resources and money
    const playerIndex = gameState.players.findIndex(p => p.id === playerId);
    const updatedPlayers = [...gameState.players];
    updatedPlayers[playerIndex] = {
      ...player,
      money: player.money - totalCost,
      resources: {
        ...player.resources,
        coal: player.resources.coal + resources.coal,
        oil: player.resources.oil + resources.oil,
        garbage: player.resources.garbage + resources.garbage,
        uranium: player.resources.uranium + resources.uranium,
        hybrid: player.resources.hybrid + resources.hybrid,
        eco: player.resources.eco + resources.eco
      }
    };

    // Update resource market
    const updatedResourceMarket = {
      ...gameState.resourceMarket,
      coal: gameState.resourceMarket.coal - resources.coal,
      oil: gameState.resourceMarket.oil - resources.oil,
      garbage: gameState.resourceMarket.garbage - resources.garbage,
      uranium: gameState.resourceMarket.uranium - resources.uranium,
      hybrid: gameState.resourceMarket.hybrid - resources.hybrid,
      eco: gameState.resourceMarket.eco - resources.eco
    };

    // Update resource phase state
    const resourcePhaseState = {
      ...gameState.resourcePhaseState,
      resourcesPurchased: {
        ...gameState.resourcePhaseState.resourcesPurchased,
        [playerId]: resources
      }
    };

    return {
      ...gameState,
      players: updatedPlayers,
      resourceMarket: updatedResourceMarket,
      resourcePhaseState
    };
  }

  /**
   * Process city building
   */
  static processBuildCity(gameState: GameState, playerId: string, cityId: string): GameState {
    if (gameState.phase !== 'building' || !gameState.buildingPhaseState) {
      throw new Error('Cannot build outside building phase');
    }

    const player = gameState.players.find(p => p.id === playerId);
    if (!player) {
      throw new Error('Player not found');
    }

    const city = gameState.cities.find(c => c.id === cityId);
    if (!city) {
      throw new Error('City not found');
    }

    // Check if city is available
    if (city.houses.length >= 3) {
      throw new Error('City is full');
    }

    if (city.houses.some(h => h.playerColor === player.color)) {
      throw new Error('Player already owns this city');
    }

    // Calculate building cost (simplified)
    const houseCost = 10 + (city.houses.length * 5);
    const connectionCost = player.cities.length === 0 ? 0 : 20; // Simplified connection cost
    const totalCost = houseCost + connectionCost;

    if (totalCost > player.money) {
      throw new Error('Insufficient funds');
    }

    // Update player
    const playerIndex = gameState.players.findIndex(p => p.id === playerId);
    const updatedPlayers = [...gameState.players];
    updatedPlayers[playerIndex] = {
      ...player,
      money: player.money - totalCost,
      cities: [...player.cities, cityId]
    };

    // Update city
    const cityIndex = gameState.cities.findIndex(c => c.id === cityId);
    const updatedCities = [...gameState.cities];
    updatedCities[cityIndex] = {
      ...city,
      houses: [...city.houses, { playerColor: player.color, cost: houseCost }]
    };

    // Update building phase state
    const buildingPhaseState = {
      ...gameState.buildingPhaseState,
      citiesBuilt: {
        ...gameState.buildingPhaseState.citiesBuilt,
        [playerId]: [...(gameState.buildingPhaseState.citiesBuilt[playerId] || []), cityId]
      }
    };

    return {
      ...gameState,
      players: updatedPlayers,
      cities: updatedCities,
      buildingPhaseState
    };
  }

  /**
   * Process city powering
   */
  static processPowerCities(gameState: GameState, playerId: string, citiesPowered: number): GameState {
    if (gameState.phase !== 'bureaucracy' || !gameState.bureaucracyState) {
      throw new Error('Cannot power cities outside bureaucracy phase');
    }

    const player = gameState.players.find(p => p.id === playerId);
    if (!player) {
      throw new Error('Player not found');
    }

    // Calculate earnings (simplified)
    const earnings = Math.min(citiesPowered, player.cities.length) * 10 + 10;

    // Update player money
    const playerIndex = gameState.players.findIndex(p => p.id === playerId);
    const updatedPlayers = [...gameState.players];
    updatedPlayers[playerIndex] = {
      ...player,
      money: player.money + earnings
    };

    // Update bureaucracy state
    const bureaucracyState = {
      ...gameState.bureaucracyState,
      citiesPowered: {
        ...gameState.bureaucracyState.citiesPowered,
        [playerId]: citiesPowered
      },
      earnings: {
        ...gameState.bureaucracyState.earnings,
        [playerId]: earnings
      }
    };

    return {
      ...gameState,
      players: updatedPlayers,
      bureaucracyState
    };
  }

  // Private helper methods
  private static processAuctionPass(gameState: GameState, playerId: string): GameState {
    if (!gameState.auctionState) return gameState;
    
    const auctionState = {
      ...gameState.auctionState,
      passedPlayers: [...gameState.auctionState.passedPlayers, playerId]
    };

    return PhaseManager.nextPlayer({ ...gameState, auctionState });
  }

  private static processResourcePass(gameState: GameState, playerId: string): GameState {
    if (!gameState.resourcePhaseState) return gameState;
    
    const resourcePhaseState = {
      ...gameState.resourcePhaseState,
      resourcesPurchased: {
        ...gameState.resourcePhaseState.resourcesPurchased,
        [playerId]: { coal: 0, oil: 0, garbage: 0, uranium: 0, hybrid: 0, eco: 0 }
      }
    };

    return PhaseManager.nextPlayer({ ...gameState, resourcePhaseState });
  }

  private static processBuildingPass(gameState: GameState, playerId: string): GameState {
    if (!gameState.buildingPhaseState) return gameState;
    
    const buildingPhaseState = {
      ...gameState.buildingPhaseState,
      citiesBuilt: {
        ...gameState.buildingPhaseState.citiesBuilt,
        [playerId]: []
      }
    };

    return PhaseManager.nextPlayer({ ...gameState, buildingPhaseState });
  }

  private static processBureaucracyPass(gameState: GameState, playerId: string): GameState {
    // In bureaucracy phase, "pass" means power 0 cities
    return this.processPowerCities(gameState, playerId, 0);
  }
}

export const turnManager = TurnManager;
export default TurnManager;