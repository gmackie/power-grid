# AI Client Backend Specification

This document describes the backend implementation needed to support launching AI game clients for simulated games.

## Overview

The backend needs to:
1. Create game lobbies for AI-only games
2. Launch AI client processes that connect to these lobbies
3. Monitor and control AI client execution
4. Stream game events and AI decisions to the admin interface

## API Endpoints

### 1. Create Simulated Game Lobby
```
POST /api/admin/simulated/create-lobby
Body: {
  "name": "AI Test Game",
  "maxPlayers": 4,
  "mapId": "usa"
}
Response: {
  "id": "lobby_123",
  "name": "AI Test Game",
  "maxPlayers": 4,
  "mapId": "usa",
  "created": "2025-01-20T10:00:00Z"
}
```

### 2. Launch AI Client
```
POST /api/admin/simulated/launch-ai-client
Body: {
  "lobbyId": "lobby_123",
  "playerName": "AI_aggressive_1",
  "difficulty": "medium",
  "personality": "aggressive",
  "strategy": "power_plant_focused",
  "gameSpeed": "normal"
}
Response: {
  "id": "client_456",
  "name": "AI_aggressive_1",
  "processId": 12345,
  "status": "launching"
}
```

### 3. Check Lobby Ready Status
```
GET /api/admin/simulated/lobby/{lobbyId}/ready
Response: {
  "ready": true,
  "players": 4,
  "maxPlayers": 4
}
```

### 4. Start Game
```
POST /api/admin/simulated/start-game/{lobbyId}
Response: {
  "gameId": "game_789",
  "status": "started"
}
```

### 5. Control Game
```
POST /api/admin/simulated/control/{gameId}
Body: {
  "action": "pause" | "resume" | "stop" | "speed",
  "speed": "slow" | "normal" | "fast" | "instant" (optional)
}
```

### 6. WebSocket Endpoint for Real-time Updates
```
WS /ws/admin/game/{gameId}
Messages:
- game_update: Current game state
- ai_decision: AI player decision with reasoning
- game_completed: Game has ended
```

## AI Client Process Management

### Launching AI Clients

The backend should spawn AI client processes with specific parameters:

```go
func launchAIClient(config AIClientConfig) (*AIClient, error) {
    // Build command line arguments
    args := []string{
        "--mode", "ai",
        "--server", "ws://localhost:4080/ws",
        "--lobby", config.LobbyID,
        "--name", config.PlayerName,
        "--difficulty", config.Difficulty,
        "--personality", config.Personality,
        "--strategy", config.Strategy,
        "--decision-delay", getDecisionDelay(config.GameSpeed),
        "--log-decisions", // Enable decision logging for admin view
    }
    
    // Launch the AI client process
    cmd := exec.Command("./love_client/love", ".", args...)
    
    // Capture stdout/stderr for debugging
    cmd.Stdout = &aiClient.logBuffer
    cmd.Stderr = &aiClient.logBuffer
    
    if err := cmd.Start(); err != nil {
        return nil, err
    }
    
    aiClient.process = cmd
    aiClient.processID = cmd.Process.Pid
    
    // Monitor the process
    go aiClient.monitor()
    
    return aiClient, nil
}
```

### AI Client Configuration

The AI client (LÖVE2D client) would need to support these command-line arguments:

```lua
-- main.lua modifications for AI mode
function love.load(args)
    local config = parseArgs(args)
    
    if config.mode == "ai" then
        -- Initialize AI player
        AI_MODE = true
        AI_CONFIG = {
            server = config.server,
            lobby = config.lobby,
            playerName = config.name,
            difficulty = config.difficulty,
            personality = config.personality,
            strategy = config.strategy,
            decisionDelay = config.decisionDelay,
            logDecisions = config.logDecisions
        }
        
        -- Auto-connect to server
        connectToServer(AI_CONFIG.server)
        
        -- Auto-join lobby when connected
        onConnected = function()
            joinLobby(AI_CONFIG.lobby, AI_CONFIG.playerName)
        end
    end
end
```

### AI Decision Engine

The AI client would need decision-making logic for each game phase:

```lua
-- ai/decision_engine.lua
function makeDecision(gameState, phase)
    local decision = {
        timestamp = os.time(),
        playerId = AI_CONFIG.playerId,
        playerName = AI_CONFIG.playerName,
        phase = phase,
        decision = "",
        reasoning = "",
        factors = {}
    }
    
    if phase == "auction" then
        decision = makeAuctionDecision(gameState)
    elseif phase == "resource" then
        decision = makeResourceDecision(gameState)
    elseif phase == "building" then
        decision = makeBuildingDecision(gameState)
    elseif phase == "bureaucracy" then
        decision = makeBureaucracyDecision(gameState)
    end
    
    -- Log decision for admin interface
    if AI_CONFIG.logDecisions then
        sendDecisionLog(decision)
    end
    
    -- Apply decision delay
    love.timer.sleep(AI_CONFIG.decisionDelay)
    
    return decision
end
```

### Process Monitoring

The backend needs to monitor AI client processes:

```go
type AIClientManager struct {
    clients map[string]*AIClient
    mu      sync.RWMutex
}

func (m *AIClientManager) MonitorClient(client *AIClient) {
    for {
        select {
        case <-client.done:
            return
        default:
            // Check if process is still running
            if client.process.ProcessState != nil {
                // Process has exited
                m.handleClientExit(client)
                return
            }
            
            // Check health
            if time.Since(client.lastHeartbeat) > 30*time.Second {
                // Client seems unresponsive
                m.handleUnresponsiveClient(client)
            }
            
            time.Sleep(5 * time.Second)
        }
    }
}
```

## Game Speed Control

The backend should support different game speeds by controlling AI decision delays:

```go
func getDecisionDelay(speed string) string {
    switch speed {
    case "slow":
        return "5000" // 5 seconds
    case "normal":
        return "2000" // 2 seconds
    case "fast":
        return "500"  // 0.5 seconds
    case "instant":
        return "0"    // No delay
    default:
        return "2000"
    }
}
```

## Cleanup

When a game ends or is stopped, the backend should:

1. Send shutdown signal to all AI clients
2. Wait for graceful shutdown (with timeout)
3. Force kill if necessary
4. Clean up resources

```go
func (m *AIClientManager) StopGame(gameId string) error {
    clients := m.getClientsForGame(gameId)
    
    // Send shutdown signal
    for _, client := range clients {
        client.sendShutdown()
    }
    
    // Wait for graceful shutdown
    timeout := time.After(10 * time.Second)
    for _, client := range clients {
        select {
        case <-client.done:
            // Client shut down gracefully
        case <-timeout:
            // Force kill
            client.process.Kill()
        }
    }
    
    // Clean up
    m.removeGame(gameId)
    
    return nil
}
```

## Database Schema

Store simulated game data for analytics:

```sql
-- Simulated games
CREATE TABLE simulated_games (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    status VARCHAR(50),
    ai_player_count INT,
    ai_difficulty VARCHAR(50),
    map_id VARCHAR(50),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AI players
CREATE TABLE ai_players (
    id UUID PRIMARY KEY,
    game_id UUID REFERENCES simulated_games(id),
    name VARCHAR(255),
    personality VARCHAR(50),
    strategy VARCHAR(50),
    final_score INT,
    final_position INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AI decisions log
CREATE TABLE ai_decisions (
    id UUID PRIMARY KEY,
    game_id UUID REFERENCES simulated_games(id),
    player_id UUID REFERENCES ai_players(id),
    timestamp TIMESTAMP,
    phase VARCHAR(50),
    decision_type VARCHAR(100),
    decision_data JSONB,
    reasoning TEXT,
    factors JSONB,
    outcome TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_ai_decisions_game_id ON ai_decisions(game_id);
CREATE INDEX idx_ai_decisions_player_id ON ai_decisions(player_id);
CREATE INDEX idx_ai_decisions_timestamp ON ai_decisions(timestamp);
```