// Game socket: second WebSocket (separate from the lobby socket) that talks to the
// per-game Durable Object at /game?game_id=<id>.

import { WebSocketManager, getWebSocketUrl } from './websocket';
import type { ConnectionStatus } from './websocket';
import type { WebSocketMessage } from '../types/game';

export type ResourceCounts = Partial<Record<'Coal' | 'Oil' | 'Garbage' | 'Uranium', number>>;

/** Derive the game socket URL from the lobby URL: trailing "/ws" -> "/game", or append "/game". */
export function buildGameUrl(lobbyUrl: string, gameId: string): string {
  const u = new URL(lobbyUrl);
  if (/\/ws\/?$/.test(u.pathname)) {
    u.pathname = u.pathname.replace(/\/ws\/?$/, '/game');
  } else {
    u.pathname = u.pathname.replace(/\/$/, '') + '/game';
  }
  u.search = '';
  u.searchParams.set('game_id', gameId);
  return u.toString();
}

class GameSocket {
  private manager: WebSocketManager | null = null;
  private identity: { playerId: string; playerName: string; gameId: string } | null = null;
  private messageHandler: ((m: WebSocketMessage) => void) | null = null;
  private errorHandler: ((e: string) => void) | null = null;
  private statusHandler: ((s: ConnectionStatus) => void) | null = null;

  setHandlers(h: {
    onMessage?: (m: WebSocketMessage) => void;
    onError?: (e: string) => void;
    onStatus?: (s: ConnectionStatus) => void;
  }): void {
    this.messageHandler = h.onMessage ?? null;
    this.errorHandler = h.onError ?? null;
    this.statusHandler = h.onStatus ?? null;
  }

  async connect(playerId: string, playerName: string, gameId: string): Promise<void> {
    this.disconnect();
    this.identity = { playerId, playerName, gameId };

    const manager = new WebSocketManager({
      url: buildGameUrl(getWebSocketUrl(), gameId),
      reconnectAttempts: 5,
      reconnectDelay: 1000,
      heartbeatInterval: 0,
      persistSession: false,
    });
    manager.setOnMessage((m) => {
      // The server uses `payload`; normalise so consumers can read `data`.
      if (m.payload !== undefined && m.data === undefined) m.data = m.payload;
      this.messageHandler?.(m);
    });
    manager.setOnError((e) => this.errorHandler?.(e));
    manager.setOnConnectionChange((s) => this.statusHandler?.(s));
    // Fires on the initial connect and on every reconnect.
    manager.setOnOpen(() => this.sendConnect());
    this.manager = manager;

    await manager.connect();
  }

  disconnect(): void {
    if (this.manager) {
      this.manager.disconnect();
      this.manager = null;
    }
    this.identity = null;
  }

  isConnected(): boolean {
    return this.manager?.isConnected() ?? false;
  }

  private sendConnect(): void {
    if (!this.identity) return;
    this.send('CONNECT', {
      player_id: this.identity.playerId,
      player_name: this.identity.playerName,
      game_id: this.identity.gameId,
    });
  }

  private send(type: string, payload?: Record<string, unknown>): boolean {
    if (!this.manager) return false;
    const msg: WebSocketMessage = { type, timestamp: Date.now() };
    if (payload) msg.payload = payload;
    return this.manager.send(msg);
  }

  startGame = () => this.send('START_GAME');
  bidPlant = (plantId: number, bid: number) => this.send('BID_PLANT', { plant_id: plantId, bid });
  buyResources = (resources: ResourceCounts) => this.send('BUY_RESOURCES', { resources });
  buildCity = (cityId: string) => this.send('BUILD_CITY', { city_id: cityId });
  powerCities = (plantIds: number[]) => this.send('POWER_CITIES', { power_plants: plantIds });
  endTurn = () => this.send('END_TURN', {});
  ping = () => this.send('PING');
}

export const gameSocket = new GameSocket();
