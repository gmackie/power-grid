import type { GameState, GamePhase, Player } from '../types/game';

// Phase order in Power Grid
const PHASE_ORDER: GamePhase[] = ['auction', 'resource', 'building', 'bureaucracy'];

export class PhaseManager {
  /**
   * Get the next phase in the game cycle
   */
  static getNextPhase(currentPhase: GamePhase): GamePhase {
    const currentIndex = PHASE_ORDER.indexOf(currentPhase);
    const nextIndex = (currentIndex + 1) % PHASE_ORDER.length;
    return PHASE_ORDER[nextIndex];
  }

  /**
   * Advance to the next phase
   */
  static advancePhase(gameState: GameState): GameState {
    const currentPhase = gameState.phase;
    const nextPhase = this.getNextPhase(currentPhase);
    
    // If we're going back to auction, increment the round
    const newRound = nextPhase === 'auction' ? gameState.currentRound + 1 : gameState.currentRound;
    
    return {
      ...gameState,
      phase: nextPhase,
      currentRound: newRound,
      currentPlayer: 0, // Reset to first player
      // Reset phase-specific states
      auctionState: nextPhase === 'auction' ? this.createAuctionState(gameState) : undefined,
      resourcePhaseState: nextPhase === 'resource' ? this.createResourcePhaseState(gameState) : undefined,
      buildingPhaseState: nextPhase === 'building' ? this.createBuildingPhaseState(gameState) : undefined,
      bureaucracyState: nextPhase === 'bureaucracy' ? this.createBureaucracyState(gameState) : undefined
    };
  }

  /**
   * Get the turn order for a specific phase
   */
  static getTurnOrder(gameState: GameState, phase: GamePhase): string[] {
    const { players } = gameState;
    
    switch (phase) {
      case 'auction':
        // Auction order: determined by reverse order of cities owned, then by player order
        return [...players]
          .sort((a, b) => {
            const citiesA = a.cities.length;
            const citiesB = b.cities.length;
            if (citiesA !== citiesB) {
              return citiesA - citiesB; // Fewest cities first
            }
            // If tied, use turn order (highest numbered plant)
            const highestPlantA = Math.max(...(a.powerPlants.map(p => p.number) || [0]));
            const highestPlantB = Math.max(...(b.powerPlants.map(p => p.number) || [0]));
            return highestPlantB - highestPlantA;
          })
          .map(p => p.id);
      
      case 'resource':
        // Resource order: reverse of auction order
        return this.getTurnOrder(gameState, 'auction').reverse();
      
      case 'building':
        // Building order: reverse of auction order  
        return this.getTurnOrder(gameState, 'auction').reverse();
      
      case 'bureaucracy':
        // Bureaucracy order: same as auction order
        return this.getTurnOrder(gameState, 'auction');
      
      default:
        return players.map(p => p.id);
    }
  }

  /**
   * Advance to the next player in the current phase
   */
  static nextPlayer(gameState: GameState): GameState {
    const turnOrder = this.getTurnOrder(gameState, gameState.phase);
    const currentIndex = gameState.currentPlayer;
    const nextIndex = (currentIndex + 1) % turnOrder.length;
    
    return {
      ...gameState,
      currentPlayer: nextIndex
    };
  }

  /**
   * Check if the current phase is complete
   */
  static isPhaseComplete(gameState: GameState): boolean {
    const { phase } = gameState;
    
    switch (phase) {
      case 'auction':
        // Auction is complete when all players have won a plant or passed
        const auctionState = gameState.auctionState;
        if (!auctionState) return false;
        
        const activePlayers = auctionState.biddingOrder.filter(
          id => !auctionState.passedPlayers.includes(id)
        );
        
        // Phase complete if all players have passed or won plants
        return activePlayers.length === 0 || 
               Object.keys(auctionState.plantsWon).length === gameState.players.length;
      
      case 'resource':
        // Resource phase is complete when all players have taken their turn
        const resourceState = gameState.resourcePhaseState;
        if (!resourceState) return false;
        
        return Object.keys(resourceState.resourcesPurchased).length === gameState.players.length;
      
      case 'building':
        // Building phase is complete when all players have taken their turn
        const buildingState = gameState.buildingPhaseState;
        if (!buildingState) return false;
        
        return Object.keys(buildingState.citiesBuilt).length === gameState.players.length;
      
      case 'bureaucracy':
        // Bureaucracy phase is complete when all players have powered cities
        const bureaucracyState = gameState.bureaucracyState;
        if (!bureaucracyState) return false;
        
        return Object.keys(bureaucracyState.citiesPowered).length === gameState.players.length;
      
      default:
        return false;
    }
  }

  /**
   * Create initial auction state for the phase
   */
  private static createAuctionState(gameState: GameState) {
    const turnOrder = this.getTurnOrder(gameState, 'auction');
    
    return {
      currentPlant: undefined,
      currentBid: 0,
      currentBidder: undefined,
      biddingOrder: turnOrder,
      passedPlayers: [],
      plantsWon: {}
    };
  }

  /**
   * Create initial resource phase state
   */
  private static createResourcePhaseState(gameState: GameState) {
    const turnOrder = this.getTurnOrder(gameState, 'resource');
    
    return {
      buyingOrder: turnOrder,
      currentBuyer: undefined,
      resourcesPurchased: {}
    };
  }

  /**
   * Create initial building phase state
   */
  private static createBuildingPhaseState(gameState: GameState) {
    const turnOrder = this.getTurnOrder(gameState, 'building');
    
    return {
      buildingOrder: turnOrder,
      currentBuilder: undefined,
      citiesBuilt: {}
    };
  }

  /**
   * Create initial bureaucracy state
   */
  private static createBureaucracyState(gameState: GameState) {
    const turnOrder = this.getTurnOrder(gameState, 'bureaucracy');
    
    return {
      poweringOrder: turnOrder,
      currentPowerer: undefined,
      citiesPowered: {},
      earnings: {}
    };
  }

  /**
   * Check if the game is over
   */
  static isGameOver(gameState: GameState): boolean {
    // Game ends when a player has 17 or more cities
    return gameState.players.some(player => player.cities.length >= 17);
  }

  /**
   * Get the current player from the game state
   */
  static getCurrentPlayer(gameState: GameState): Player | undefined {
    const turnOrder = this.getTurnOrder(gameState, gameState.phase);
    const currentPlayerId = turnOrder[gameState.currentPlayer];
    return gameState.players.find(p => p.id === currentPlayerId);
  }

  /**
   * Get the winner of the game
   */
  static getWinner(gameState: GameState): Player | undefined {
    if (!this.isGameOver(gameState)) return undefined;
    
    // Winner is the player with the most cities, then most money
    return gameState.players.reduce((winner, player) => {
      if (!winner) return player;
      
      if (player.cities.length > winner.cities.length) {
        return player;
      } else if (player.cities.length === winner.cities.length) {
        return player.money > winner.money ? player : winner;
      }
      
      return winner;
    });
  }
}

// Export utility functions
export const phaseManager = PhaseManager;
export default PhaseManager;