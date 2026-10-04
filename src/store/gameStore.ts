// Game State Management using Zustand

import { create } from 'zustand';
import { subscribeWithSelector } from 'zustand/middleware';
import type { GameState, Player, AppState, LobbyState, Lobby, LobbyListItem, ResourceType , MapInfo } from '../types/game';
import { wsManager, lobbyActions } from '../services/websocket';
import { gameSocket } from '../services/gameSocket';
import { adaptGameState } from '../utils/gameStateAdapter';
import type { ServerGameState } from '../utils/gameStateAdapter';
import type { ConnectionStatus } from '../services/websocket';
import { PhaseManager } from '../utils/phaseManager';
import { TurnManager } from '../utils/turnManager';

const ACTIVE_GAME_KEY = 'powerGridActiveGame';
interface ActiveGame { gameId: string; playerId: string; playerName: string }
const readActiveGame = (): ActiveGame | null => {
  try { return JSON.parse(localStorage.getItem(ACTIVE_GAME_KEY) ?? 'null'); } catch { return null; }
};

interface GameStore extends AppState {
  /** Join the game socket and remember the game so a reload or killed tab can resume it. */
  enterGame: (gameId: string, playerId: string, playerName: string) => void;
  /** Resume a remembered game (app start / returning to the foreground). */
  resumeGame: () => void;
  leaveGame: () => void;
  // Connection state
  connect: () => Promise<void>;
  disconnect: () => void;
  
  // Lobby state
  lobbies: LobbyListItem[];
  availableMaps: MapInfo[];
  currentLobby: LobbyState | null;
  isPlayerRegistered: boolean;
  
  // Game actions
  createGame: (playerName: string, playerColor: string) => void;
  joinGame: (lobbyCode: string, playerName: string, playerColor: string, password?: string) => void;
  startGame: () => void;
  
  // Lobby actions
  registerPlayer: (playerName: string) => void;
  listLobbies: () => void;
  createLobby: (lobbyName: string, maxPlayers: number, mapId: string, password?: string) => boolean;
  joinLobby: (lobbyId: string, password?: string) => boolean;
  leaveLobby: () => void;
  setReady: (ready: boolean) => void;
  
  // Player actions
  bid: (amount: number, plantId?: number) => void;
  pass: () => void;
  buyResources: (resources: Record<ResourceType, number>) => void;
  buildCity: (cityId: string) => void;
  powerCities: (plantIds: number[]) => void;
  endTurn: () => void;
  
  // Local simulation methods
  simulateBid: (amount: number, plantId?: number) => void;
  simulatePass: () => void;
  simulateBuyResources: (resources: Record<ResourceType, number>) => void;
  simulateBuildCity: (cityId: string) => void;
  simulatePowerCities: (citiesPowered: number) => void;
  
  // UI state management
  setCurrentScreen: (screen: 'menu' | 'lobby' | 'game' | 'lobby-browser' | 'admin') => void;
  setConnectionStatus: (status: ConnectionStatus) => void;
  setGameState: (state: GameState) => void;
  setPlayerInfo: (id: string, name: string) => void;
  setPlayerName: (name: string) => void;
  setError: (error: string) => void;
  clearError: () => void;
  setLobbies: (lobbies: LobbyListItem[]) => void;
  requestMaps: () => void;
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
    availableMaps: [],
    currentLobby: null,
    isPlayerRegistered: false,

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
      gameSocket.disconnect();
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
    
    createLobby: (lobbyName: string, maxPlayers: number, mapId: string, password?: string) =>
      sendLobbyRequest((name) => lobbyActions.createLobby(lobbyName, name, maxPlayers, mapId, password)),
    
    joinLobby: (lobbyId: string, password?: string) =>
      sendLobbyRequest((name) => lobbyActions.joinLobby(lobbyId, name, password)),
    
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

    joinGame: (lobbyCode: string, playerName: string, _playerColor: string, password?: string) => {
      // Games are joined through lobbies; the code is the six-character lobby id.
      // CONNECT and JOIN_LOBBY go out on the same socket, so the server sees them in order.
      get().registerPlayer(playerName);
      get().joinLobby(lobbyCode.trim().toUpperCase(), password);
    },

    startGame: () => {
      if (!gameSocket.startGame()) {
        set({ errorMessage: 'Not connected to game' });
      }
    },

    // Player actions - sent over the game socket
    bid: (amount: number, plantId?: number) => {
      const state = get();
      if (!state.canPerformAction()) return;
      const id = plantId ?? state.gameState?.auctionState?.currentPlant?.id;
      if (id === undefined) {
        set({ errorMessage: 'No power plant selected' });
        return;
      }
      if (!gameSocket.bidPlant(id, amount)) {
        set({ errorMessage: 'Failed to send bid to server' });
      }
    },

    pass: () => {
      const state = get();
      if (!state.canPerformAction()) return;
      const auctionPlant = state.gameState?.auctionState?.currentPlant;
      const ok = auctionPlant
        ? gameSocket.bidPlant(auctionPlant.id, 0)
        : gameSocket.endTurn();
      if (!ok) set({ errorMessage: 'Failed to send pass to server' });
    },

    endTurn: () => {
      if (!get().canPerformAction()) return;
      if (!gameSocket.endTurn()) set({ errorMessage: 'Failed to end turn' });
    },

    buyResources: (resources: Record<ResourceType, number>) => {
      if (!get().canPerformAction()) return;
      const out: Record<string, number> = {};
      if (resources.coal) out.Coal = resources.coal;
      if (resources.oil) out.Oil = resources.oil;
      if (resources.garbage) out.Garbage = resources.garbage;
      if (resources.uranium) out.Uranium = resources.uranium;
      if (!gameSocket.buyResources(out)) {
        set({ errorMessage: 'Failed to send buy resources to server' });
      }
    },

    buildCity: (cityId: string) => {
      if (!get().canPerformAction()) return;
      if (!gameSocket.buildCity(cityId)) {
        set({ errorMessage: 'Failed to send build city to server' });
      }
    },

    powerCities: (plantIds: number[]) => {
      if (!get().canPerformAction()) return;
      if (!gameSocket.powerCities(plantIds)) {
        set({ errorMessage: 'Failed to send power cities to server' });
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

    enterGame: (gameId, playerId, playerName) => {
      localStorage.setItem(ACTIVE_GAME_KEY, JSON.stringify({ gameId, playerId, playerName }));
      set({ gamePlayerId: playerId, currentScreen: 'game' });
      gameSocket.connect(playerId, playerName, gameId).catch(() => set({ errorMessage: 'Failed to connect to game' }));
    },

    resumeGame: () => {
      const active = readActiveGame();
      if (!active) return;
      const { currentScreen, gameConnection } = get();
      if (currentScreen === 'game' && (gameConnection === 'connected' || gameConnection === 'connecting')) return;
      get().enterGame(active.gameId, active.playerId, active.playerName);
    },

    leaveGame: () => {
      localStorage.removeItem(ACTIVE_GAME_KEY);
      gameSocket.disconnect();
      set({ gameState: undefined, gamePlayerId: undefined, currentLobby: null, currentScreen: 'menu' });
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
    
    requestMaps: () => {
      lobbyActions.listMaps();
    },

    setLobbies: (lobbies) => {
      set({ lobbies });
    },
    
    setCurrentLobby: (lobby) => {
      set({ currentLobby: lobby });
    },

    // Helper getters
    getCurrentPlayer: () => {
      const { gameState } = get();
      const playerId = get().gamePlayerId ?? get().playerId;
      if (!gameState || !playerId) return undefined;
      
      return gameState.players.find(p => p.id === playerId);
    },

    isCurrentPlayerTurn: () => {
      const { gameState } = get();
      const playerId = get().gamePlayerId ?? get().playerId;
      if (!gameState || !playerId) return false;
      return gameState.currentTurn === playerId;
    },

    canPerformAction: () => {
      const state = get();
      // Moves go over the game socket; the lobby socket may be down mid-game.
      return gameSocket.isConnected() &&
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
// Pending lobby request (create/join), replayed once if the server lost our session.
let pendingLobbyRequest: { run: () => boolean; retried: boolean } | null = null;

function sendLobbyRequest(send: (playerName: string) => boolean): boolean {
  const { playerName, isPlayerRegistered, registerPlayer } = useGameStore.getState();
  if (!playerName) {
    useGameStore.setState({ errorMessage: 'Enter your name first' });
    return false;
  }
  if (!isPlayerRegistered) registerPlayer(playerName);
  const run = () => send(useGameStore.getState().playerName ?? playerName);
  pendingLobbyRequest = { run, retried: false };
  if (!run()) {
    pendingLobbyRequest = null;
    useGameStore.setState({ errorMessage: 'Not connected to the server. Check your connection and try again.' });
    return false;
  }
  return true;
}

// The server forgets idle sessions (and phones background tabs for a long time), so
// re-announce ourselves every time the lobby socket opens, including reconnects.
wsManager.setOnOpen(() => {
  const { playerName, registerPlayer } = useGameStore.getState();
  if (playerName) registerPlayer(playerName);
});

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
      useGameStore.setState({
        isPlayerRegistered: true,
        ...(message.data?.player_id ? { playerId: message.data.player_id as string } : {}),
        ...(message.data?.player_name ? { playerName: message.data.player_name as string } : {})
      });
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
      pendingLobbyRequest = null;
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
      pendingLobbyRequest = null;
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
        
      }
      if (message.data?.game_id) {
        const { playerId, playerName } = useGameStore.getState();
        if (playerId) {
          store.enterGame(message.data.game_id as string, playerId, playerName || 'Player');
        } else {
          store.setError('Cannot join game: player id unknown');
        }
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
      
    case 'MAPS_LISTED': {
      const maps = (message.data as { maps?: MapInfo[] } | undefined)?.maps;
      if (Array.isArray(maps)) useGameStore.setState({ availableMaps: maps });
      break;
    }

    case 'ERROR': {
      const errorText = (message.data as { message?: string } | undefined)?.message || message.error || 'Server error';
      // "No active session found…" / "Player session not found…": re-register and replay once.
      if (/session/i.test(errorText) && store.playerName) {
        store.registerPlayer(store.playerName);
        if (pendingLobbyRequest && !pendingLobbyRequest.retried) {
          pendingLobbyRequest.retried = true;
          pendingLobbyRequest.run();
          break;
        }
      }
      pendingLobbyRequest = null;
      store.setError(errorText);
      break;
    }

    default:
      console.log('Unhandled message:', message.type, message.data);
  }
});

// Game socket handlers
gameSocket.setHandlers({
  onStatus: (status) => useGameStore.setState({ gameConnection: status }),
  onError: (error) => useGameStore.getState().setError(error),
  onMessage: (message) => {
    const store = useGameStore.getState();
    switch (message.type) {
      case 'GAME_STATE':
        if (message.data) {
          store.setGameState(adaptGameState(message.data as ServerGameState));
        }
        break;
      case 'ERROR': {
        const text: string = message.data?.message || message.error || 'Server error';
        // A remembered game that no longer exists: drop it instead of leaving the player stuck.
        if (/^game not found|session not in any game/i.test(text) && !store.gameState) {
          store.leaveGame();
          store.setError('That game is no longer available.');
          break;
        }
        store.setError(text);
        break;
      }
      default:
        break;
    }
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