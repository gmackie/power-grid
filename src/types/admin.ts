// Admin-specific type definitions

export interface ServerInfo {
  version: string;
  uptime: number; // seconds
  startTime: string;
  environment: string;
  features: string[];
}

export interface HealthStatus {
  status: 'healthy' | 'degraded' | 'unhealthy';
  checks: {
    database: boolean;
    websocket: boolean;
    cache: boolean;
  };
  timestamp: string;
}

export interface GameAnalytics {
  totalGames: number;
  uniquePlayers: number;
  averageGameDuration: number; // minutes
  gamesInProgress: number;
  completedGames: number;
  abandonedGames: number;
  timeRange: {
    start: string;
    end: string;
  };
  phaseDistribution: {
    auction: number;
    resource: number;
    building: number;
    bureaucracy: number;
  };
  dailyStats: Array<{
    date: string;
    games: number;
    players: number;
    avgDuration: number;
  }>;
}

export interface PlayerSummary {
  id: string;
  name: string;
  gamesPlayed: number;
  wins: number;
  winRate: number;
  averageScore: number;
  lastActive: string;
  status: 'active' | 'inactive';
  favoriteMap?: string;
}

export interface PlayerDetailedStats extends PlayerSummary {
  achievements: PlayerAchievement[];
  gameHistory: GameHistory[];
  resourceStats: {
    totalCoalUsed: number;
    totalOilUsed: number;
    totalGarbageUsed: number;
    totalUraniumUsed: number;
    avgResourceEfficiency: number;
  };
  strategyProfile: {
    aggressiveness: number; // 0-1
    expansionRate: number; // 0-1
    resourcePreference: string;
    averageBidAmount: number;
  };
}

export interface PlayerAchievement {
  id: string;
  name: string;
  description: string;
  unlockedAt: string;
  rarity: 'common' | 'rare' | 'epic' | 'legendary';
}

export interface GameHistory {
  gameId: string;
  date: string;
  duration: number;
  position: number;
  totalPlayers: number;
  finalScore: number;
  citiesOwned: number;
  map: string;
}

export interface LeaderboardEntry {
  rank: number;
  playerId: string;
  playerName: string;
  rating: number;
  gamesPlayed: number;
  winRate: number;
  trend: 'up' | 'down' | 'stable';
}

export interface SimulatedGame {
  id: string;
  name: string;
  status: 'running' | 'paused' | 'completed' | 'stopped';
  aiPlayerCount: number;
  aiDifficulty: 'easy' | 'medium' | 'hard' | 'adaptive';
  mapId: string;
  currentRound: number;
  currentPhase: string;
  gameSpeed: 'slow' | 'normal' | 'fast' | 'instant';
  startedAt: string;
  duration: number; // seconds
  aiPlayers: AIPlayer[];
}

export interface AIPlayer {
  id: string;
  name: string;
  personality: 'aggressive' | 'conservative' | 'balanced' | 'random';
  strategy: 'power_plant_focused' | 'city_expansion' | 'resource_hoarding' | 'balanced';
  currentMoney: number;
  citiesOwned: number;
  powerPlants: number[];
  score: number;
}

export interface AIDecision {
  id: string;
  timestamp: string;
  playerId: string;
  playerName: string;
  phase: string;
  decisionType: string;
  decision: string;
  reasoning: string;
  factors: Record<string, any>;
  outcome?: string;
}

export interface AIPerformanceMetrics {
  difficultyLevel: string;
  totalGames: number;
  winRate: number;
  averageFinalScore: number;
  averageGameDuration: number;
  decisionSpeed: number; // ms
  strategyEffectiveness: {
    auction: number;
    resource: number;
    building: number;
    overall: number;
  };
}

export interface SystemMetrics {
  cpu: {
    usage: number;
    cores: number;
  };
  memory: {
    used: number;
    total: number;
    percentage: number;
  };
  disk: {
    used: number;
    total: number;
    percentage: number;
  };
  network: {
    inbound: number; // bytes/sec
    outbound: number; // bytes/sec
  };
  websocket: {
    activeConnections: number;
    peakConnections: number;
    messagesPerSecond: number;
  };
}

export interface ServerConfig {
  maxPlayersPerGame: number;
  gameTimeout: number; // minutes
  enableAIPlayers: boolean;
  debugMode: boolean;
  maintenanceMode: boolean;
  allowedMaps: string[];
  defaultAIDifficulty: string;
}

export interface LogEntry {
  id: string;
  timestamp: string;
  level: 'debug' | 'info' | 'warn' | 'error';
  source: string;
  message: string;
  metadata?: Record<string, any>;
}

// Form types for creating simulated games
export interface CreateSimulatedGameRequest {
  name: string;
  aiPlayerCount: number;
  aiDifficulty: 'easy' | 'medium' | 'hard' | 'adaptive';
  mapId: string;
  gameSpeed: 'slow' | 'normal' | 'fast' | 'instant';
  aiConfigurations?: Array<{
    personality: string;
    strategy: string;
  }>;
}

// Export data types
export interface ExportOptions {
  format: 'json' | 'csv';
  includeDecisions?: boolean;
  includeMetrics?: boolean;
  includeTimeline?: boolean;
  includeGameState?: boolean;
  includePlayerStats?: boolean;
}

// WebSocket message types for real-time updates
export interface AdminWebSocketMessage {
  type: 'game_update' | 'ai_decision' | 'system_metric' | 'player_action';
  gameId?: string;
  data: any;
  timestamp: string;
}