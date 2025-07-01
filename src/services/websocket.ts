// WebSocket Manager for Power Grid React Client

import { WebSocketMessage, GameState } from '../types/game';

export type ConnectionStatus = 'disconnected' | 'connecting' | 'connected' | 'error';

export interface WebSocketConfig {
  url: string;
  reconnectAttempts?: number;
  reconnectDelay?: number;
  heartbeatInterval?: number;
}

export class WebSocketManager {
  private ws: WebSocket | null = null;
  private config: WebSocketConfig;
  private connectionStatus: ConnectionStatus = 'disconnected';
  private reconnectAttempts = 0;
  private heartbeatTimer: NodeJS.Timeout | null = null;
  private reconnectTimer: NodeJS.Timeout | null = null;
  
  // Event handlers
  private onConnectionChange: ((status: ConnectionStatus) => void) | null = null;
  private onGameState: ((state: GameState) => void) | null = null;
  private onError: ((error: string) => void) | null = null;
  private onMessage: ((message: WebSocketMessage) => void) | null = null;

  constructor(config: WebSocketConfig) {
    this.config = {
      reconnectAttempts: 5,
      reconnectDelay: 2000,
      heartbeatInterval: 30000,
      ...config
    };
  }

  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      if (this.ws?.readyState === WebSocket.OPEN) {
        resolve();
        return;
      }

      this.setConnectionStatus('connecting');
      
      try {
        this.ws = new WebSocket(this.config.url);
        
        this.ws.onopen = () => {
          console.log('WebSocket connected');
          this.setConnectionStatus('connected');
          this.reconnectAttempts = 0;
          this.startHeartbeat();
          resolve();
        };

        this.ws.onmessage = (event) => {
          try {
            const message: WebSocketMessage = JSON.parse(event.data);
            this.handleMessage(message);
          } catch (error) {
            console.error('Failed to parse WebSocket message:', error);
            this.handleError('Invalid message format');
          }
        };

        this.ws.onclose = (event) => {
          console.log('WebSocket closed:', event.code, event.reason);
          this.setConnectionStatus('disconnected');
          this.stopHeartbeat();
          
          if (!event.wasClean && this.reconnectAttempts < (this.config.reconnectAttempts || 5)) {
            this.scheduleReconnect();
          }
        };

        this.ws.onerror = (error) => {
          console.error('WebSocket error:', error);
          this.setConnectionStatus('error');
          this.handleError('Connection error');
          reject(error);
        };

      } catch (error) {
        this.setConnectionStatus('error');
        this.handleError('Failed to create WebSocket connection');
        reject(error);
      }
    });
  }

  disconnect(): void {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    
    this.stopHeartbeat();
    
    if (this.ws) {
      this.ws.close(1000, 'Client disconnect');
      this.ws = null;
    }
    
    this.setConnectionStatus('disconnected');
  }

  send(message: WebSocketMessage): boolean {
    if (this.ws?.readyState === WebSocket.OPEN) {
      try {
        this.ws.send(JSON.stringify(message));
        return true;
      } catch (error) {
        console.error('Failed to send message:', error);
        this.handleError('Failed to send message');
        return false;
      }
    }
    
    console.warn('WebSocket not connected, cannot send message');
    return false;
  }

  // Event handler setters
  setOnConnectionChange(handler: (status: ConnectionStatus) => void): void {
    this.onConnectionChange = handler;
  }

  setOnGameState(handler: (state: GameState) => void): void {
    this.onGameState = handler;
  }

  setOnError(handler: (error: string) => void): void {
    this.onError = handler;
  }

  setOnMessage(handler: (message: WebSocketMessage) => void): void {
    this.onMessage = handler;
  }

  getConnectionStatus(): ConnectionStatus {
    return this.connectionStatus;
  }

  isConnected(): boolean {
    return this.connectionStatus === 'connected' && this.ws?.readyState === WebSocket.OPEN;
  }

  private setConnectionStatus(status: ConnectionStatus): void {
    if (this.connectionStatus !== status) {
      this.connectionStatus = status;
      this.onConnectionChange?.(status);
    }
  }

  private handleMessage(message: WebSocketMessage): void {
    // Call generic message handler first
    this.onMessage?.(message);

    // Handle specific message types
    switch (message.type) {
      case 'game_state':
        if (message.data) {
          this.onGameState?.(message.data as GameState);
        }
        break;
        
      case 'error':
        this.handleError(message.error || 'Unknown server error');
        break;
        
      case 'pong':
        // Heartbeat response
        break;
        
      default:
        console.log('Received message:', message.type, message.data);
    }
  }

  private handleError(error: string): void {
    console.error('WebSocket error:', error);
    this.onError?.(error);
  }

  private startHeartbeat(): void {
    this.stopHeartbeat();
    
    this.heartbeatTimer = setInterval(() => {
      if (this.isConnected()) {
        this.send({ type: 'ping' });
      }
    }, this.config.heartbeatInterval);
  }

  private stopHeartbeat(): void {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
  }

  private scheduleReconnect(): void {
    this.reconnectAttempts++;
    const delay = this.config.reconnectDelay! * Math.pow(2, this.reconnectAttempts - 1);
    
    console.log(`Attempting reconnect ${this.reconnectAttempts}/${this.config.reconnectAttempts} in ${delay}ms`);
    
    this.reconnectTimer = setTimeout(() => {
      this.connect().catch((error) => {
        console.error('Reconnect failed:', error);
      });
    }, delay);
  }
}

// Default WebSocket manager instance
const getWebSocketUrl = (): string => {
  // Always use ws:// for localhost development
  return 'ws://localhost:4080/ws';
};

export const wsManager = new WebSocketManager({
  url: getWebSocketUrl(),
  reconnectAttempts: 5,
  reconnectDelay: 1000,
  heartbeatInterval: 25000
});

// Game-specific helper functions
export const gameActions = {
  joinGame: (gameId: string, playerName: string, playerColor: string) => {
    return wsManager.send({
      type: 'join_game',
      data: { gameId, playerName, playerColor }
    });
  },

  createGame: (playerName: string, playerColor: string) => {
    return wsManager.send({
      type: 'create_game',
      data: { playerName, playerColor }
    });
  },

  startGame: () => {
    return wsManager.send({
      type: 'start_game'
    });
  },

  bid: (amount: number) => {
    return wsManager.send({
      type: 'player_action',
      data: { action: 'bid', params: { amount } }
    });
  },

  pass: () => {
    return wsManager.send({
      type: 'player_action',
      data: { action: 'pass', params: {} }
    });
  },

  buyResources: (resources: Record<string, number>) => {
    return wsManager.send({
      type: 'player_action',
      data: { action: 'buy_resources', params: { resources } }
    });
  },

  buildCity: (cityId: string) => {
    return wsManager.send({
      type: 'player_action',
      data: { action: 'build_city', params: { cityId } }
    });
  },

  powerCities: (citiesPowered: number) => {
    return wsManager.send({
      type: 'player_action',
      data: { action: 'power_cities', params: { citiesPowered } }
    });
  }
};

// Lobby-specific helper functions
export const lobbyActions = {
  connect: (playerName: string) => {
    return wsManager.send({
      type: 'CONNECT',
      data: { player_name: playerName }
    });
  },

  listMaps: () => {
    return wsManager.send({
      type: 'LIST_MAPS'
    });
  },

  listLobbies: () => {
    return wsManager.send({
      type: 'LIST_LOBBIES'
    });
  },

  createLobby: (lobbyName: string, playerName: string, maxPlayers: number, mapId: string, password?: string) => {
    return wsManager.send({
      type: 'CREATE_LOBBY',
      data: { 
        lobby_name: lobbyName, 
        player_name: playerName,
        max_players: maxPlayers,
        map_id: mapId,
        password: password || ''
      }
    });
  },

  joinLobby: (lobbyId: string, playerName: string, password?: string) => {
    return wsManager.send({
      type: 'JOIN_LOBBY',
      data: { 
        lobby_id: lobbyId, 
        player_name: playerName,
        password: password || ''
      }
    });
  },

  leaveLobby: () => {
    return wsManager.send({
      type: 'LEAVE_LOBBY'
    });
  },

  setReady: (ready: boolean) => {
    return wsManager.send({
      type: 'SET_READY',
      data: { ready }
    });
  },

  startGame: () => {
    return wsManager.send({
      type: 'START_GAME'
    });
  },

  sendChatMessage: (content: string) => {
    return wsManager.send({
      type: 'CHAT_MESSAGE',
      data: { content }
    });
  }
};