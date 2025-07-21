import { CreateSimulatedGameRequest, SimulatedGame, AIPlayer } from '../types/admin';

export interface LaunchAIClientRequest {
  lobbyId: string;
  playerName: string;
  difficulty: string;
  personality: string;
  strategy: string;
  gameSpeed: string;
}

export interface AIClientResponse {
  id: string;
  name: string;
  processId: number;
  status: 'launching' | 'connected' | 'ready' | 'error';
}

export class SimulatedGamesApi {
  private baseUrl: string;

  constructor(baseUrl: string = 'http://localhost:5080') {
    this.baseUrl = baseUrl;
  }

  /**
   * Create a new lobby for simulated game
   */
  async createLobby(name: string, maxPlayers: number, mapId: string): Promise<any> {
    const response = await fetch(`${this.baseUrl}/api/admin/simulated/create-lobby`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, maxPlayers, mapId })
    });

    if (!response.ok) {
      throw new Error(`Failed to create lobby: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * Launch an AI client process
   * This will spawn a new AI client that connects to the specified lobby
   */
  async launchAIClient(request: LaunchAIClientRequest): Promise<AIClientResponse> {
    const response = await fetch(`${this.baseUrl}/api/admin/simulated/launch-ai-client`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(request)
    });

    if (!response.ok) {
      throw new Error(`Failed to launch AI client: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * Check if all AI clients in a lobby are ready
   */
  async checkLobbyReady(lobbyId: string): Promise<boolean> {
    const response = await fetch(`${this.baseUrl}/api/admin/simulated/lobby/${lobbyId}/ready`);
    
    if (!response.ok) {
      throw new Error(`Failed to check lobby status: ${response.statusText}`);
    }

    const data = await response.json();
    return data.ready;
  }

  /**
   * Start a simulated game
   */
  async startGame(lobbyId: string): Promise<void> {
    const response = await fetch(`${this.baseUrl}/api/admin/simulated/start-game/${lobbyId}`, {
      method: 'POST'
    });

    if (!response.ok) {
      throw new Error(`Failed to start game: ${response.statusText}`);
    }
  }

  /**
   * Get list of all simulated games
   */
  async listGames(): Promise<SimulatedGame[]> {
    const response = await fetch(`${this.baseUrl}/api/admin/simulated/games`);
    
    if (!response.ok) {
      throw new Error(`Failed to list games: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * Get game details
   */
  async getGame(gameId: string): Promise<SimulatedGame> {
    const response = await fetch(`${this.baseUrl}/api/admin/simulated/games/${gameId}`);
    
    if (!response.ok) {
      throw new Error(`Failed to get game: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * Control game execution (pause, resume, stop, change speed)
   */
  async controlGame(gameId: string, action: string, params?: any): Promise<void> {
    const response = await fetch(`${this.baseUrl}/api/admin/simulated/control/${gameId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action, ...params })
    });

    if (!response.ok) {
      throw new Error(`Failed to control game: ${response.statusText}`);
    }
  }

  /**
   * Get AI decision log for a game
   */
  async getDecisions(gameId: string, limit: number = 100): Promise<any[]> {
    const response = await fetch(
      `${this.baseUrl}/api/admin/simulated/games/${gameId}/decisions?limit=${limit}`
    );
    
    if (!response.ok) {
      throw new Error(`Failed to get decisions: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * Export game data
   */
  async exportGame(gameId: string, format: 'json' | 'csv' = 'json'): Promise<Blob> {
    const response = await fetch(
      `${this.baseUrl}/api/admin/simulated/games/${gameId}/export?format=${format}`
    );
    
    if (!response.ok) {
      throw new Error(`Failed to export game: ${response.statusText}`);
    }

    return response.blob();
  }

  /**
   * Delete a completed or stopped game
   */
  async deleteGame(gameId: string): Promise<void> {
    const response = await fetch(`${this.baseUrl}/api/admin/simulated/games/${gameId}`, {
      method: 'DELETE'
    });

    if (!response.ok) {
      throw new Error(`Failed to delete game: ${response.statusText}`);
    }
  }

  /**
   * Get AI performance metrics
   */
  async getAIMetrics(params?: {
    difficulty?: string;
    days?: number;
  }): Promise<any> {
    const queryParams = new URLSearchParams();
    if (params?.difficulty) queryParams.append('difficulty', params.difficulty);
    if (params?.days) queryParams.append('days', params.days.toString());

    const response = await fetch(
      `${this.baseUrl}/api/admin/simulated/ai-metrics?${queryParams}`
    );
    
    if (!response.ok) {
      throw new Error(`Failed to get AI metrics: ${response.statusText}`);
    }

    return response.json();
  }
}

// Export singleton instance
export const simulatedGamesApi = new SimulatedGamesApi();