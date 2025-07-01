// Game State Management using Zustand

import { create } from 'zustand';
import { subscribeWithSelector } from 'zustand/middleware';
import { GameState, Player, AppState, LobbyState } from '../types/game';
import { wsManager, gameActions, ConnectionStatus } from '../services/websocket';

interface GameStore extends AppState {
  // Connection state
  connect: () => Promise<void>;
  disconnect: () => void;
  
  // Game actions
  createGame: (playerName: string, playerColor: string) => void;
  joinGame: (gameId: string, playerName: string, playerColor: string) => void;
  startGame: () => void;
  
  // Player actions
  bid: (amount: number) => void;
  pass: () => void;
  buyResources: (resources: Record<string, number>) => void;
  buildCity: (cityId: string) => void;
  powerCities: (citiesPowered: number) => void;
  
  // UI state management
  setCurrentScreen: (screen: 'menu' | 'lobby' | 'game') => void;
  setConnectionStatus: (status: ConnectionStatus) => void;
  setGameState: (state: GameState) => void;
  setPlayerInfo: (id: string, name: string) => void;
  setPlayerName: (name: string) => void;
  setError: (error: string) => void;
  clearError: () => void;
  
  // Helper getters
  getCurrentPlayer: () => Player | undefined;
  isCurrentPlayerTurn: () => boolean;
  canPerformAction: () => boolean;
}

export const useGameStore = create<GameStore>()(
  subscribeWithSelector((set, get) => ({
    // Initial state
    currentScreen: 'menu',
    connectionStatus: 'disconnected',
    gameState: undefined,
    playerId: undefined,
    playerName: undefined,
    errorMessage: undefined,

    // Connection methods
    connect: async () => {
      try {
        set({ connectionStatus: 'connecting', errorMessage: undefined });
        await wsManager.connect();
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
        playerId: undefined
      });
    },

    // Game actions
    createGame: (playerName: string, playerColor: string) => {
      if (gameActions.createGame(playerName, playerColor)) {
        set({ 
          playerName,
          currentScreen: 'lobby'
        });
      }
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

    // Player actions
    bid: (amount: number) => {
      const state = get();
      if (state.canPerformAction()) {
        gameActions.bid(amount);
      }
    },

    pass: () => {
      const state = get();
      if (state.canPerformAction()) {
        gameActions.pass();
      }
    },

    buyResources: (resources: Record<string, number>) => {
      const state = get();
      if (state.canPerformAction()) {
        gameActions.buyResources(resources);
      }
    },

    buildCity: (cityId: string) => {
      const state = get();
      if (state.canPerformAction()) {
        gameActions.buildCity(cityId);
      }
    },

    powerCities: (citiesPowered: number) => {
      const state = get();
      if (state.canPerformAction()) {
        gameActions.powerCities(citiesPowered);
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
      set({ playerName: name });
    },

    setError: (error) => {
      set({ errorMessage: error });
    },

    clearError: () => {
      set({ errorMessage: undefined });
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
      
      const currentPlayerIndex = gameState.currentPlayer;
      return gameState.players[currentPlayerIndex]?.id === playerId;
    },

    canPerformAction: () => {
      const state = get();
      return state.connectionStatus === 'connected' && 
             state.gameState !== undefined && 
             state.isCurrentPlayerTurn();
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
      store.setCurrentScreen('game');
      break;
      
    case 'player_disconnected':
      // Handle player disconnection
      console.log('Player disconnected:', message.data);
      break;
      
    case 'game_ended':
      // Handle game end
      console.log('Game ended:', message.data);
      break;
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