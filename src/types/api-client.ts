// Mock API client types until the real package is available
// This file exports types that match what @power-grid/api-client would provide

export * from './admin';

// Re-export with the expected names from the admin types
export type {
  ServerInfo,
  HealthStatus,
  GameAnalytics,
  PlayerSummary,
  PlayerDetailedStats as PlayerStats,
  PlayerDetailedStats,
  PlayerAchievement,
  GameHistory,
  LeaderboardEntry,
  AIPerformanceMetrics as AchievementAnalytics,
  LeaderboardEntry as AchievementLeaderboardEntry,
  PlayerSummary as PlayerProgress,
  PlayerSummary as Achievement,
  SimulatedGame as MapSummary
} from './admin';

// API client classes (mocked for now)
export class ServerApi {
  constructor(config: any) {}
  async getServerInfo() {
    return { data: {} as any };
  }
  async getHealth() {
    return { data: {} as any };
  }
}

export class MapsApi {
  constructor(config: any) {}
  async listMaps() {
    return { data: [] as any[] };
  }
  async getMapById(id: string) {
    return { data: {} as any };
  }
}

export class PlayersApi {
  constructor(config: any) {}
  async listPlayers() {
    return { data: [] as any[] };
  }
  async getPlayerStats(name: string) {
    return { data: {} as any };
  }
  async getPlayerDetailedStats(name: string) {
    return { data: {} as any };
  }
  async getPlayerAchievements(name: string) {
    return { data: [] as any[] };
  }
  async getPlayerHistory(name: string, limit?: number) {
    return { data: [] as any[] };
  }
  async getPlayerProgress(name: string) {
    return { data: {} as any };
  }
}

export class AchievementsApi {
  constructor(config: any) {}
  async listAchievements() {
    return { data: [] as any[] };
  }
}

export class LeaderboardsApi {
  constructor(config: any) {}
  async getLeaderboard(limit?: number) {
    return { data: [] as any[] };
  }
  async getAchievementLeaderboard() {
    return { data: [] as any[] };
  }
}

export class AnalyticsApi {
  constructor(config: any) {}
  async getGameAnalytics(start?: string, end?: string, days?: number) {
    return { data: {} as any };
  }
  async getAchievementAnalytics() {
    return { data: {} as any };
  }
  async getApiHealth() {
    return { data: {} as any };
  }
}

export function createApiConfiguration(options: { basePath: string }) {
  return {
    basePath: options.basePath
  };
}