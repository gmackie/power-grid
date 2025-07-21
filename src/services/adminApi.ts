import {
  ServerApi,
  MapsApi,
  PlayersApi,
  AchievementsApi,
  LeaderboardsApi,
  AnalyticsApi,
  createApiConfiguration,
  ServerInfo,
  MapSummary,
  PlayerSummary,
  Achievement,
  LeaderboardEntry,
  GameAnalytics,
  PlayerStats,
  PlayerDetailedStats,
  PlayerAchievement,
  GameHistory,
  PlayerProgress,
  AchievementAnalytics,
  AchievementLeaderboardEntry,
  HealthStatus
} from '@power-grid/api-client';

export class AdminApiService {
  private serverApi: ServerApi;
  private mapsApi: MapsApi;
  private playersApi: PlayersApi;
  private achievementsApi: AchievementsApi;
  private leaderboardsApi: LeaderboardsApi;
  private analyticsApi: AnalyticsApi;

  constructor(baseUrl: string = 'http://localhost:5080') {
    const config = createApiConfiguration({ basePath: baseUrl });
    
    this.serverApi = new ServerApi(config);
    this.mapsApi = new MapsApi(config);
    this.playersApi = new PlayersApi(config);
    this.achievementsApi = new AchievementsApi(config);
    this.leaderboardsApi = new LeaderboardsApi(config);
    this.analyticsApi = new AnalyticsApi(config);
  }

  // Server endpoints
  async getServerInfo(): Promise<ServerInfo> {
    const response = await this.serverApi.getServerInfo();
    return response.data;
  }

  async getHealth(): Promise<HealthStatus> {
    const response = await this.serverApi.getHealth();
    return response.data;
  }

  async getApiHealth(): Promise<HealthStatus> {
    const response = await this.analyticsApi.getApiHealth();
    return response.data;
  }

  // Maps endpoints
  async getMaps(): Promise<MapSummary[]> {
    const response = await this.mapsApi.listMaps();
    return response.data;
  }

  async getMapById(id: string) {
    const response = await this.mapsApi.getMapById(id);
    return response.data;
  }

  // Players endpoints
  async getPlayers(): Promise<PlayerSummary[]> {
    const response = await this.playersApi.listPlayers();
    return response.data;
  }

  async getPlayerStats(name: string): Promise<PlayerStats> {
    const response = await this.playersApi.getPlayerStats(name);
    return response.data;
  }

  async getPlayerDetailedStats(name: string): Promise<PlayerDetailedStats> {
    const response = await this.playersApi.getPlayerDetailedStats(name);
    return response.data;
  }

  async getPlayerAchievements(name: string): Promise<PlayerAchievement[]> {
    const response = await this.playersApi.getPlayerAchievements(name);
    return response.data;
  }

  async getPlayerHistory(name: string, limit?: number): Promise<GameHistory[]> {
    const response = await this.playersApi.getPlayerHistory(name, limit);
    return response.data;
  }

  async getPlayerProgress(name: string): Promise<PlayerProgress> {
    const response = await this.playersApi.getPlayerProgress(name);
    return response.data;
  }

  // Achievements endpoints
  async getAchievements(): Promise<Achievement[]> {
    const response = await this.achievementsApi.listAchievements();
    return response.data;
  }

  // Leaderboards endpoints
  async getLeaderboard(limit?: number): Promise<LeaderboardEntry[]> {
    const response = await this.leaderboardsApi.getLeaderboard(limit);
    return response.data;
  }

  async getAchievementLeaderboard(): Promise<AchievementLeaderboardEntry[]> {
    const response = await this.leaderboardsApi.getAchievementLeaderboard();
    return response.data;
  }

  // Analytics endpoints
  async getGameAnalytics(params?: {
    start?: string;
    end?: string;
    days?: number;
  }): Promise<GameAnalytics> {
    const response = await this.analyticsApi.getGameAnalytics(
      params?.start,
      params?.end,
      params?.days
    );
    return response.data;
  }

  async getAchievementAnalytics(): Promise<AchievementAnalytics> {
    const response = await this.analyticsApi.getAchievementAnalytics();
    return response.data;
  }
}

// Export singleton instance
export const adminApi = new AdminApiService();