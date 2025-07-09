// Game State Management using Zustand

import { create } from 'zustand';
import { subscribeWithSelector } from 'zustand/middleware';
import type { GameState, Player, AppState, LobbyState, Lobby, LobbyListItem, PowerPlant, City, ResourceMarket, ResourceType } from '../types/game';
import { wsManager, gameActions, lobbyActions } from '../services/websocket';
import type { ConnectionStatus } from '../services/websocket';
import { PhaseManager } from '../utils/phaseManager';
import { TurnManager } from '../utils/turnManager';

// Helper function to create initial game state from lobby data
function createInitialGameState(serverLobby: any, currentPlayerId?: string): GameState {
  console.log('Creating initial game state from lobby:', serverLobby);
  
  // Convert lobby players to game players
  const players: Player[] = [];
  if (serverLobby.players && typeof serverLobby.players === 'object') {
    Object.entries(serverLobby.players).forEach(([id, player]: [string, any]) => {
      players.push({
        id: id,
        name: player.name,
        color: player.color || '#ff0000',
        money: 50, // Starting money
        powerPlants: [],
        cities: [],
        resources: {
          coal: 0,
          oil: 0,
          garbage: 0,
          uranium: 0,
          hybrid: 0,
          eco: 0
        }
      });
    });
  }
  
  // Create initial power plant market
  const powerPlantMarket: PowerPlant[] = [
    { id: 1, number: 3, cost: 7, resourceType: 'oil', resourceCount: 2, citiesPowered: 1 },
    { id: 2, number: 4, cost: 9, resourceType: 'coal', resourceCount: 2, citiesPowered: 1 },
    { id: 3, number: 5, cost: 10, resourceType: 'hybrid', resourceCount: 2, citiesPowered: 1 },
    { id: 4, number: 6, cost: 11, resourceType: 'garbage', resourceCount: 1, citiesPowered: 1 },
    { id: 5, number: 7, cost: 13, resourceType: 'oil', resourceCount: 3, citiesPowered: 2 },
    { id: 6, number: 8, cost: 15, resourceType: 'coal', resourceCount: 3, citiesPowered: 2 },
    { id: 7, number: 9, cost: 16, resourceType: 'oil', resourceCount: 1, citiesPowered: 1 },
    { id: 8, number: 10, cost: 12, resourceType: 'coal', resourceCount: 2, citiesPowered: 2 }
  ];
  
  // Create initial resource market
  const resourceMarket: ResourceMarket = {
    coal: 24,
    oil: 18,
    garbage: 6,
    uranium: 2,
    hybrid: 0,
    eco: 0,
    coalPrice: 1,
    oilPrice: 3,
    garbagePrice: 7,
    uraniumPrice: 14,
    hybridPrice: 0,
    ecoPrice: 0
  };
  
  // Create mock cities for the selected map
  const cities: City[] = createCitiesForMap(serverLobby.map_id);
  
  // Create turn order (can be randomized later)
  const turnOrder = players.map(p => p.id);
  
  return {
    id: serverLobby.game_id || serverLobby.id,
    players,
    currentPlayer: 0,
    currentRound: 1,
    phase: 'auction',
    powerPlantMarket,
    resourceMarket,
    cities,
    turnOrder,
    auctionState: {
      currentPlant: undefined,
      currentBid: 0,
      currentBidder: undefined,
      biddingOrder: turnOrder,
      passedPlayers: [],
      plantsWon: {}
    }
  };
}

// Helper function to create cities for a map
function createCitiesForMap(mapId: string): City[] {
  // For now, create a generic set of cities
  // In a real implementation, this would load actual map data
  return [
    {
      id: 'berlin',
      name: 'Berlin',
      x: 0.5,
      y: 0.3,
      region: 'North',
      houses: [],
      connections: [
        { to: 'hamburg', cost: 10 },
        { to: 'munich', cost: 15 }
      ]
    },
    {
      id: 'hamburg',
      name: 'Hamburg',
      x: 0.4,
      y: 0.2,
      region: 'North',
      houses: [],
      connections: [
        { to: 'berlin', cost: 10 },
        { to: 'cologne', cost: 12 }
      ]
    },
    {
      id: 'munich',
      name: 'Munich',
      x: 0.6,
      y: 0.5,
      region: 'South',
      houses: [],
      connections: [
        { to: 'berlin', cost: 15 },
        { to: 'frankfurt', cost: 8 }
      ]
    },
    {
      id: 'cologne',
      name: 'Cologne',
      x: 0.3,
      y: 0.4,
      region: 'West',
      houses: [],
      connections: [
        { to: 'hamburg', cost: 12 },
        { to: 'frankfurt', cost: 6 }
      ]
    },
    {
      id: 'frankfurt',
      name: 'Frankfurt',
      x: 0.5,
      y: 0.4,
      region: 'Central',
      houses: [],
      connections: [
        { to: 'munich', cost: 8 },
        { to: 'cologne', cost: 6 }
      ]
    }
  ];
}

interface GameStore extends AppState {
  // Connection state
  connect: () => Promise<void>;
  disconnect: () => void;
  
  // Lobby state
  lobbies: LobbyListItem[];
  currentLobby: LobbyState | null;
  isPlayerRegistered: boolean;
  
  // Game actions
  createGame: (playerName: string, playerColor: string) => void;
  joinGame: (gameId: string, playerName: string, playerColor: string) => void;
  startGame: () => void;
  
  // Lobby actions
  registerPlayer: (playerName: string) => void;
  listLobbies: () => void;
  createLobby: (lobbyName: string, maxPlayers: number, mapId: string, password?: string) => void;
  joinLobby: (lobbyId: string, password?: string) => void;
  leaveLobby: () => void;
  setReady: (ready: boolean) => void;
  
  // Player actions
  bid: (amount: number, plantId?: number) => void;
  pass: () => void;
  buyResources: (resources: Record<ResourceType, number>) => void;
  buildCity: (cityId: string) => void;
  powerCities: (citiesPowered: number) => void;
  
  // Local simulation methods
  simulateBid: (amount: number, plantId?: number) => void;
  simulatePass: () => void;
  simulateBuyResources: (resources: Record<ResourceType, number>) => void;
  simulateBuildCity: (cityId: string) => void;
  simulatePowerCities: (citiesPowered: number) => void;
  
  // UI state management
  setCurrentScreen: (screen: 'menu' | 'lobby' | 'game' | 'lobby-browser') => void;
  setConnectionStatus: (status: ConnectionStatus) => void;
  setGameState: (state: GameState) => void;
  setPlayerInfo: (id: string, name: string) => void;
  setPlayerName: (name: string) => void;
  setError: (error: string) => void;
  clearError: () => void;
  setLobbies: (lobbies: LobbyListItem[]) => void;
  setCurrentLobby: (lobby: LobbyState | null) => void;
  
  // Helper getters
  getCurrentPlayer: () => Player | undefined;
  isCurrentPlayerTurn: () => boolean;
  canPerformAction: () => boolean;
  getCurrentTurnPlayer: () => Player | undefined;
  isPhaseComplete: () => boolean;
  isGameOver: () => boolean;
  getWinner: () => Player | undefined;
}

export const useGameStore = create<GameStore>()(
  subscribeWithSelector((set, get) => ({
    // Initial state
    currentScreen: 'menu',
    connectionStatus: 'disconnected',
    gameState: undefined,
    playerId: undefined,
    playerName: localStorage.getItem('powerGridPlayerName') || undefined,
    errorMessage: undefined,
    lobbies: [],
    currentLobby: null,
    isPlayerRegistered: false,

    // Connection methods
    connect: async () => {
      try {
        set({ connectionStatus: 'connecting', errorMessage: undefined });
        await wsManager.connect();
        
        // Auto-register player if we have a saved name
        const { playerName } = get();
        if (playerName) {
          setTimeout(() => {
            get().registerPlayer(playerName);
          }, 100);
        }
      } catch (error) {
        console.error('Connection failed:', error);
        set({ 
          connectionStatus: 'error', 
          errorMessage: 'Failed to connect to server' 
        });
      }
    },

    disconnect: () => {
      wsManager.disconnect();
      set({ 
        connectionStatus: 'disconnected',
        currentScreen: 'menu',
        gameState: undefined,
        playerId: undefined,
        isPlayerRegistered: false,
        lobbies: [],
        currentLobby: null
      });
    },

    // Lobby actions
    registerPlayer: (playerName: string) => {
      localStorage.setItem('powerGridPlayerName', playerName);
      lobbyActions.connect(playerName);
      set({ playerName, isPlayerRegistered: true });
    },
    
    listLobbies: () => {
      if (get().isPlayerRegistered) {
        lobbyActions.listLobbies();
      }
    },
    
    createLobby: (lobbyName: string, maxPlayers: number, mapId: string, password?: string) => {
      const { playerName, isPlayerRegistered } = get();
      if (playerName && isPlayerRegistered) {
        lobbyActions.createLobby(lobbyName, playerName, maxPlayers, mapId, password);
      }
    },
    
    joinLobby: (lobbyId: string, password?: string) => {
      const { playerName, isPlayerRegistered } = get();
      if (playerName && isPlayerRegistered) {
        lobbyActions.joinLobby(lobbyId, playerName, password);
      }
    },
    
    leaveLobby: () => {
      lobbyActions.leaveLobby();
      // Clear lobby from URL
      const url = new URL(window.location.href);
      url.pathname = '/lobbies';
      url.search = '';
      window.history.pushState({}, '', url.toString());
      
      set({ currentLobby: null, currentScreen: 'lobby-browser' });
    },
    
    setReady: (ready: boolean) => {
      lobbyActions.setReady(ready);
    },

    // Game actions
    createGame: (playerName: string, playerColor: string) => {
      // This is now a legacy method - use createLobby instead
      get().registerPlayer(playerName);
      setTimeout(() => {
        get().createLobby('Game Lobby', 6, 'usa', '');
      }, 100);
    },

    joinGame: (gameId: string, playerName: string, playerColor: string) => {
      if (gameActions.joinGame(gameId, playerName, playerColor)) {
        set({ 
          playerName,
          currentScreen: 'lobby'
        });
      }
    },

    startGame: () => {
      gameActions.startGame();
    },

    // Player actions - Send to server for synchronization
    bid: (amount: number, plantId?: number) => {
      const state = get();
      if (state.canPerformAction()) {
        // Send bid action to server
        const success = gameActions.bid(amount, plantId);
        if (!success) {
          set({ errorMessage: 'Failed to send bid to server' });
        }
      }
    },

    pass: () => {
      const state = get();
      if (state.canPerformAction()) {
        // Send pass action to server
        const success = gameActions.pass();
        if (!success) {
          set({ errorMessage: 'Failed to send pass to server' });
        }
      }
    },

    buyResources: (resources: Record<ResourceType, number>) => {
      const state = get();
      if (state.canPerformAction()) {
        // Send buy resources action to server
        const success = gameActions.buyResources(resources);
        if (!success) {
          set({ errorMessage: 'Failed to send buy resources to server' });
        }
      }
    },

    buildCity: (cityId: string) => {
      const state = get();
      if (state.canPerformAction()) {
        // Send build city action to server
        const success = gameActions.buildCity(cityId);
        if (!success) {
          set({ errorMessage: 'Failed to send build city to server' });
        }
      }
    },

    powerCities: (citiesPowered: number) => {
      const state = get();
      if (state.canPerformAction()) {
        // Send power cities action to server
        const success = gameActions.powerCities(citiesPowered);
        if (!success) {
          set({ errorMessage: 'Failed to send power cities to server' });
        }
      }
    },

    // Local game simulation methods (for testing without server)
    simulateBid: (amount: number, plantId?: number) => {
      const state = get();
      if (state.canPerformAction() && state.gameState && state.playerId) {
        try {
          const newGameState = TurnManager.processBid(state.gameState, state.playerId, amount, plantId);
          set({ gameState: newGameState });
          
          // Check if phase is complete
          if (PhaseManager.isPhaseComplete(newGameState)) {
            const nextPhaseState = PhaseManager.advancePhase(newGameState);
            set({ gameState: nextPhaseState });
          }
        } catch (error) {
          console.error('Bid failed:', error);
          set({ errorMessage: error instanceof Error ? error.message : 'Bid failed' });
        }
      }
    },

    simulatePass: () => {
      const state = get();
      if (state.canPerformAction() && state.gameState && state.playerId) {
        try {
          const newGameState = TurnManager.processPass(state.gameState, state.playerId);
          set({ gameState: newGameState });
          
          // Check if phase is complete
          if (PhaseManager.isPhaseComplete(newGameState)) {
            const nextPhaseState = PhaseManager.advancePhase(newGameState);
            set({ gameState: nextPhaseState });
          }
        } catch (error) {
          console.error('Pass failed:', error);
          set({ errorMessage: error instanceof Error ? error.message : 'Pass failed' });
        }
      }
    },

    simulateBuyResources: (resources: Record<ResourceType, number>) => {
      const state = get();
      if (state.canPerformAction() && state.gameState && state.playerId) {
        try {
          const newGameState = TurnManager.processBuyResources(state.gameState, state.playerId, resources);
          set({ gameState: newGameState });
          
          // Check if phase is complete
          if (PhaseManager.isPhaseComplete(newGameState)) {
            const nextPhaseState = PhaseManager.advancePhase(newGameState);
            set({ gameState: nextPhaseState });
          }
        } catch (error) {
          console.error('Buy resources failed:', error);
          set({ errorMessage: error instanceof Error ? error.message : 'Buy resources failed' });
        }
      }
    },

    simulateBuildCity: (cityId: string) => {
      const state = get();
      if (state.canPerformAction() && state.gameState && state.playerId) {
        try {
          const newGameState = TurnManager.processBuildCity(state.gameState, state.playerId, cityId);
          set({ gameState: newGameState });
          
          // Check if phase is complete
          if (PhaseManager.isPhaseComplete(newGameState)) {
            const nextPhaseState = PhaseManager.advancePhase(newGameState);
            set({ gameState: nextPhaseState });
          }
        } catch (error) {
          console.error('Build city failed:', error);
          set({ errorMessage: error instanceof Error ? error.message : 'Build city failed' });
        }
      }
    },

    simulatePowerCities: (citiesPowered: number) => {
      const state = get();
      if (state.canPerformAction() && state.gameState && state.playerId) {
        try {
          const newGameState = TurnManager.processPowerCities(state.gameState, state.playerId, citiesPowered);
          set({ gameState: newGameState });
          
          // Check if phase is complete
          if (PhaseManager.isPhaseComplete(newGameState)) {
            const nextPhaseState = PhaseManager.advancePhase(newGameState);
            set({ gameState: nextPhaseState });
          }
        } catch (error) {
          console.error('Power cities failed:', error);
          set({ errorMessage: error instanceof Error ? error.message : 'Power cities failed' });
        }
      }
    },

    // UI state management
    setCurrentScreen: (screen) => {
      set({ currentScreen: screen });
    },

    setConnectionStatus: (status) => {
      set({ connectionStatus: status });
    },

    setGameState: (gameState) => {
      set({ 
        gameState,
        currentScreen: gameState ? 'game' : get().currentScreen
      });
    },

    setPlayerInfo: (id, name) => {
      set({ playerId: id, playerName: name });
    },

    setPlayerName: (name) => {
      localStorage.setItem('powerGridPlayerName', name);
      set({ playerName: name });
    },

    setError: (error) => {
      set({ errorMessage: error });
    },

    clearError: () => {
      set({ errorMessage: undefined });
    },
    
    setLobbies: (lobbies) => {
      set({ lobbies });
    },
    
    setCurrentLobby: (lobby) => {
      set({ currentLobby: lobby });
    },

    // Helper getters
    getCurrentPlayer: () => {
      const { gameState, playerId } = get();
      if (!gameState || !playerId) return undefined;
      
      return gameState.players.find(p => p.id === playerId);
    },

    isCurrentPlayerTurn: () => {
      const { gameState, playerId } = get();
      if (!gameState || !playerId) return false;
      
      const turnOrder = PhaseManager.getTurnOrder(gameState, gameState.phase);
      const currentPlayerId = turnOrder[gameState.currentPlayer];
      return currentPlayerId === playerId;
    },

    canPerformAction: () => {
      const state = get();
      return state.connectionStatus === 'connected' && 
             state.gameState !== undefined && 
             state.isCurrentPlayerTurn();
    },

    // Additional helper methods
    getCurrentTurnPlayer: () => {
      const { gameState } = get();
      if (!gameState) return undefined;
      
      return PhaseManager.getCurrentPlayer(gameState);
    },

    isPhaseComplete: () => {
      const { gameState } = get();
      if (!gameState) return false;
      
      return PhaseManager.isPhaseComplete(gameState);
    },

    isGameOver: () => {
      const { gameState } = get();
      if (!gameState) return false;
      
      return PhaseManager.isGameOver(gameState);
    },

    getWinner: () => {
      const { gameState } = get();
      if (!gameState) return undefined;
      
      return PhaseManager.getWinner(gameState);
    }
  }))
);

// Set up WebSocket event handlers
wsManager.setOnConnectionChange((status) => {
  useGameStore.getState().setConnectionStatus(status);
});

wsManager.setOnGameState((gameState) => {
  useGameStore.getState().setGameState(gameState);
});

wsManager.setOnError((error) => {
  useGameStore.getState().setError(error);
});

wsManager.setOnMessage((message) => {
  const store = useGameStore.getState();
  
  switch (message.type) {
    // Connection messages
    case 'CONNECTED':
      console.log('Player registered successfully:', message.data);
      useGameStore.setState({ isPlayerRegistered: true });
      break;
      
    // Lobby messages
    case 'LOBBIES_LISTED':
    case 'LOBBY_LIST':
      if (message.data?.lobbies) {
        console.log('Raw lobby data received:', JSON.stringify(message.data.lobbies, null, 2));
        console.log('Lobby data type:', typeof message.data.lobbies, 'isArray:', Array.isArray(message.data.lobbies));
        if (Array.isArray(message.data.lobbies)) {
          // Log the first lobby structure to debug
          if (message.data.lobbies.length > 0) {
            console.log('First lobby structure:', JSON.stringify(message.data.lobbies[0], null, 2));
          }
          store.setLobbies(message.data.lobbies);
          console.log('Updated lobby list with', message.data.lobbies.length, 'lobbies');
        } else {
          console.error('Lobbies data is not an array:', message.data.lobbies);
        }
      } else {
        console.log('No lobbies data in message:', message.data);
      }
      break;
      
    case 'LOBBY_CREATED':
      console.log('Lobby created:', message.data);
      if (message.data?.lobby) {
        // Transform server lobby format to client LobbyState format
        const serverLobby = message.data.lobby;
        const lobbyState: LobbyState = {
          id: serverLobby.id,
          name: serverLobby.name,
          status: serverLobby.status || 'waiting',
          max_players: serverLobby.max_players,
          map_id: serverLobby.map_id,
          gameId: serverLobby.game_id || '',
          players: [],
          isHost: true, // Creator is always host
          gameStarted: false
        };
        
        // Convert players map to array
        if (serverLobby.players && typeof serverLobby.players === 'object') {
          lobbyState.players = Object.entries(serverLobby.players).map(([id, player]: [string, any]) => ({
            id: id,
            name: player.name,
            color: player.color || '#ff0000',
            ready: player.is_ready || false,
            is_host: player.is_host || false
          }));
        }
        
        store.setCurrentLobby(lobbyState);
        store.setCurrentScreen('lobby');
        
        // Update URL with lobby ID
        const url = new URL(window.location.href);
        url.pathname = '/lobby';
        url.searchParams.set('id', serverLobby.id);
        window.history.pushState({}, '', url.toString());
      }
      break;
      
    case 'LOBBY_JOINED':
      console.log('Lobby joined:', message.data);
      if (message.data?.lobby) {
        // Transform server lobby format to client LobbyState format
        const serverLobby = message.data.lobby;
        const currentPlayerId = store.playerId;
        const lobbyState: LobbyState = {
          id: serverLobby.id,
          name: serverLobby.name,
          status: serverLobby.status || 'waiting',
          max_players: serverLobby.max_players,
          map_id: serverLobby.map_id,
          gameId: serverLobby.game_id || '',
          players: [],
          isHost: false, // Will be determined below
          gameStarted: false
        };
        
        // Convert players map to array
        if (serverLobby.players && typeof serverLobby.players === 'object') {
          lobbyState.players = Object.entries(serverLobby.players).map(([id, player]: [string, any]) => ({
            id: id,
            name: player.name,
            color: player.color || '#ff0000',
            ready: player.is_ready || false,
            is_host: player.is_host || false
          }));
          
          // Check if current player is host
          const currentPlayer = serverLobby.players[currentPlayerId];
          if (currentPlayer?.is_host) {
            lobbyState.isHost = true;
          }
        }
        
        store.setCurrentLobby(lobbyState);
        store.setCurrentScreen('lobby');
        
        // Update URL with lobby ID
        const url = new URL(window.location.href);
        url.pathname = '/lobby';
        url.searchParams.set('id', serverLobby.id);
        window.history.pushState({}, '', url.toString());
      }
      break;
      
    case 'LOBBY_UPDATED':
      if (message.data?.lobby) {
        // Transform server lobby format to client LobbyState format
        const serverLobby = message.data.lobby;
        const currentPlayerId = store.playerId;
        const currentLobby = store.currentLobby;
        
        if (currentLobby && currentLobby.id === serverLobby.id) {
          const lobbyState: LobbyState = {
            id: serverLobby.id,
            name: serverLobby.name,
            status: serverLobby.status || 'waiting',
            max_players: serverLobby.max_players,
            map_id: serverLobby.map_id,
            gameId: serverLobby.game_id || '',
            players: [],
            isHost: currentLobby.isHost, // Preserve host status
            gameStarted: serverLobby.status === 'in_progress' || serverLobby.status === 'starting'
          };
          
          // Convert players map to array
          if (serverLobby.players && typeof serverLobby.players === 'object') {
            lobbyState.players = Object.entries(serverLobby.players).map(([id, player]: [string, any]) => ({
              id: id,
              name: player.name,
              color: player.color || '#ff0000',
              ready: player.is_ready || false,
              is_host: player.is_host || false
            }));
            
            // Update host status if needed
            const currentPlayer = serverLobby.players[currentPlayerId];
            if (currentPlayer?.is_host) {
              lobbyState.isHost = true;
            }
          }
          
          store.setCurrentLobby(lobbyState);
        }
      }
      break;
      
    case 'PLAYER_CONNECTED':
      console.log('Player connected:', message.data);
      break;
      
    // Game messages
    case 'game_created':
      if (message.data?.gameId && message.data?.playerId) {
        store.setPlayerInfo(message.data.playerId, store.playerName || 'Player');
      }
      break;
      
    case 'game_joined':
      if (message.data?.playerId) {
        store.setPlayerInfo(message.data.playerId, store.playerName || 'Player');
      }
      break;
      
    case 'game_started':
    case 'GAME_STARTED':
      store.setCurrentScreen('game');
      break;

    // Game state synchronization messages
    case 'GAME_STATE_UPDATE':
    case 'game_state_update':
      console.log('Received game state update:', message.data);
      if (message.data?.game_state || message.data?.gameState) {
        const gameState = message.data.game_state || message.data.gameState;
        store.setGameState(gameState);
      }
      break;

    case 'PLAYER_ACTION_RESULT':
    case 'player_action_result':
      console.log('Player action result:', message.data);
      if (message.data?.success === false && message.data?.error) {
        store.setError(message.data.error);
      }
      break;

    case 'PHASE_TRANSITION':
    case 'phase_transition':
      console.log('Phase transition:', message.data);
      if (message.data?.new_phase) {
        // Server handles phase transitions, just update the state
        const currentGameState = store.gameState;
        if (currentGameState) {
          const updatedGameState = {
            ...currentGameState,
            phase: message.data.new_phase,
            currentRound: message.data.new_round || currentGameState.currentRound,
            currentPlayer: message.data.current_player || 0
          };
          store.setGameState(updatedGameState);
        }
      }
      break;
      
    case 'GAME_STARTING':
      console.log('Game starting:', message.data);
      if (message.data?.lobby) {
        // Update lobby status to starting
        const serverLobby = message.data.lobby;
        const currentLobby = store.currentLobby;
        if (currentLobby && currentLobby.id === serverLobby.id) {
          const updatedLobby = { ...currentLobby };
          updatedLobby.status = 'starting';
          updatedLobby.gameStarted = true;
          store.setCurrentLobby(updatedLobby);
        }
        
        // Initialize game state from lobby data
        const gameState = createInitialGameState(serverLobby, store.playerId);
        store.setGameState(gameState);
        
        // Set player ID from lobby if not set
        if (!store.playerId && serverLobby.players && store.playerName) {
          const playerEntry = Object.entries(serverLobby.players).find(([id, player]: [string, any]) => 
            player.name === store.playerName
          );
          if (playerEntry) {
            store.setPlayerInfo(playerEntry[0], store.playerName);
          }
        }
        
        // Navigate to game screen
        store.setCurrentScreen('game');
      }
      break;
      
    case 'player_disconnected':
      // Handle player disconnection
      console.log('Player disconnected:', message.data);
      break;
      
    case 'game_ended':
      // Handle game end
      console.log('Game ended:', message.data);
      break;
      
    default:
      console.log('Unhandled message:', message.type, message.data);
  }
});

// Device detection store
interface DeviceStore {
  isMobile: boolean;
  isTablet: boolean;
  orientation: 'portrait' | 'landscape';
  screenWidth: number;
  screenHeight: number;
  touchSupport: boolean;
  updateDeviceInfo: () => void;
}

export const useDeviceStore = create<DeviceStore>()((set) => ({
  isMobile: false,
  isTablet: false,
  orientation: 'landscape',
  screenWidth: window.innerWidth,
  screenHeight: window.innerHeight,
  touchSupport: 'ontouchstart' in window,

  updateDeviceInfo: () => {
    const width = window.innerWidth;
    const height = window.innerHeight;
    const isMobile = width < 768;
    const isTablet = width >= 768 && width < 1024;
    const orientation = width > height ? 'landscape' : 'portrait';

    set({
      isMobile,
      isTablet,
      orientation,
      screenWidth: width,
      screenHeight: height,
      touchSupport: 'ontouchstart' in window
    });
  }
}));

// Update device info on window resize
if (typeof window !== 'undefined') {
  const updateDeviceInfo = useDeviceStore.getState().updateDeviceInfo;
  updateDeviceInfo(); // Initial call
  
  window.addEventListener('resize', updateDeviceInfo);
  window.addEventListener('orientationchange', () => {
    setTimeout(updateDeviceInfo, 100); // Delay to ensure orientation change is complete
  });
}