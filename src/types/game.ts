// Game Types for Power Grid React Client

export interface MapInfo {
  id: string;
  name: string;
  description: string;
  playerCount: {
    min: number;
    max: number;
    recommended: number[];
  };
  regionCount: number;
  cityCount: number;
}

export interface LobbyInfo {
  id: string;
  name: string;
  status: string;
  player_count: number;
  max_players: number;
  map_id: string;
  has_password: boolean;
  created_at: string;
}

export interface Player {
  id: string;
  name: string;
  color: string;
  money: number;
  powerPlants: PowerPlant[];
  cities: string[];
  resources: {
    coal: number;
    oil: number;
    garbage: number;
    uranium: number;
    hybrid: number;
    eco: number;
  };
}

export interface PowerPlant {
  id: number;
  number: number;
  cost: number;
  resourceType: ResourceType;
  resourceCount: number;
  citiesPowered: number;
}

export interface City {
  id: string;
  name: string;
  x: number;
  y: number;
  region: string;
  connections: Connection[];
  houses: House[];
}

export interface Connection {
  to: string;
  cost: number;
}

export interface House {
  playerColor: string;
  cost: number;
}

export interface ResourceMarket {
  coal: number;
  oil: number;
  garbage: number;
  uranium: number;
  hybrid: number;
  eco: number;
  coalPrice: number;
  oilPrice: number;
  garbagePrice: number;
  uraniumPrice: number;
  hybridPrice: number;
  ecoPrice: number;
}

export type ResourceType = 'coal' | 'oil' | 'garbage' | 'uranium' | 'hybrid' | 'eco';

export type GamePhase = 'auction' | 'resource' | 'building' | 'bureaucracy';

export interface GameState {
  id: string;
  players: Player[];
  currentPlayer: number;
  currentRound: number;
  phase: GamePhase;
  powerPlantMarket: PowerPlant[];
  resourceMarket: ResourceMarket;
  cities: City[];
  turnOrder: string[];
  auctionState?: AuctionState;
  resourcePhaseState?: ResourcePhaseState;
  buildingPhaseState?: BuildingPhaseState;
  bureaucracyState?: BureaucracyState;
}

export interface AuctionState {
  currentPlant?: PowerPlant;
  currentBid: number;
  currentBidder?: string;
  biddingOrder: string[];
  passedPlayers: string[];
  plantsWon: Record<string, PowerPlant>;
}

export interface ResourcePhaseState {
  buyingOrder: string[];
  currentBuyer?: string;
  resourcesPurchased: Record<string, Record<ResourceType, number>>;
}

export interface BuildingPhaseState {
  buildingOrder: string[];
  currentBuilder?: string;
  citiesBuilt: Record<string, string[]>;
}

export interface BureaucracyState {
  poweringOrder: string[];
  currentPowerer?: string;
  citiesPowered: Record<string, number>;
  earnings: Record<string, number>;
}

// WebSocket Message Types
export interface WebSocketMessage {
  type: string;
  session_id?: string;
  data?: any;
  error?: string;
}

export interface JoinGameMessage {
  type: 'join_game';
  data: {
    gameId: string;
    playerName: string;
    playerColor: string;
  };
}

export interface GameStateMessage {
  type: 'game_state';
  data: GameState;
}

export interface PlayerActionMessage {
  type: 'player_action';
  data: {
    action: string;
    params: Record<string, any>;
  };
}

export interface ErrorMessage {
  type: 'error';
  error: string;
}

// UI State Types
export interface AppState {
  currentScreen: 'menu' | 'lobby' | 'game' | 'lobby-browser';
  connectionStatus: 'disconnected' | 'connecting' | 'connected' | 'error';
  gameState?: GameState;
  playerId?: string;
  playerName?: string;
  errorMessage?: string;
}

// Lobby Types
export interface Lobby {
  id: string;
  name: string;
  status: 'waiting' | 'starting' | 'in_progress' | 'finished';
  players: LobbyPlayer[];
  max_players: number;
  map_id: string;
  has_password: boolean;
  created_at: string;
  host_id: string;
}

// Lobby list item type - what the server actually sends in LOBBIES_LISTED
export interface LobbyListItem {
  id: string;
  name: string;
  status: 'waiting' | 'starting' | 'in_progress' | 'finished';
  player_count: number;  // Server sends count, not array
  max_players: number;
  map_id: string;
  has_password: boolean;
  created_at: string;
}

export interface LobbyPlayer {
  id: string;
  name: string;
  color: string;
  ready: boolean;
  is_host: boolean;
}

export interface LobbyState {
  id: string;
  name: string;
  status: 'waiting' | 'starting' | 'in_progress' | 'finished';
  max_players: number;
  map_id: string;
  gameId: string;
  players: {
    id: string;
    name: string;
    color: string;
    ready: boolean;
    is_host: boolean;
  }[];
  isHost: boolean;
  gameStarted: boolean;
}

// Input/Touch Types
export interface TouchPoint {
  id: number;
  x: number;
  y: number;
  startX: number;
  startY: number;
  startTime: number;
}

export interface GestureState {
  touches: TouchPoint[];
  scale: number;
  rotation: number;
  panX: number;
  panY: number;
}