# Simulated Games Implementation

## Overview

We've implemented a comprehensive system for creating and monitoring AI-powered simulated games in the Power Grid admin panel. This feature allows administrators to:

1. **Launch AI Game Clients**: Spawn multiple AI clients that play complete games autonomously
2. **Configure AI Behavior**: Set difficulty levels, personalities, and strategies for each AI player
3. **Monitor Games in Real-Time**: Watch AI decisions and game progression with detailed logging
4. **Control Game Execution**: Pause, resume, stop games, and adjust game speed
5. **Analyze AI Performance**: Track metrics and export game data for analysis

## Architecture

### Frontend Components

1. **SimulatedGames.tsx**
   - Main container for simulated games feature
   - Manages navigation between list, create, and monitor views

2. **SimulatedGamesList.tsx**
   - Displays all simulated games with filtering
   - Shows game status, AI players, and duration
   - Provides quick actions (view, pause/resume, delete)

3. **CreateSimulatedGame.tsx**
   - Form for configuring new simulated games
   - Supports basic and advanced AI configuration
   - Shows real-time launch progress as AI clients connect

4. **GameMonitor.tsx**
   - Real-time game monitoring interface
   - Displays AI player states and decisions
   - WebSocket connection for live updates
   - Game control buttons (pause/resume/stop/speed)

### API Service

**simulatedGamesApi.ts**
- Handles all API calls for simulated games
- Key methods:
  - `createLobby()` - Creates a new game lobby
  - `launchAIClient()` - Spawns an AI client process
  - `startGame()` - Begins the game once all clients are ready
  - `controlGame()` - Pause/resume/stop/change speed
  - `exportGame()` - Export game data for analysis

## How It Works

### Creating a Simulated Game

1. **User Configuration**
   - Select number of AI players (2-6)
   - Choose AI difficulty level
   - Select game map
   - Set game speed
   - (Optional) Configure individual AI personalities

2. **Lobby Creation**
   - Backend creates a dedicated lobby for AI players
   - Returns lobby ID for AI clients to join

3. **AI Client Launch**
   - For each AI player, backend spawns a LÖVE2D client process
   - Each client runs with specific command-line arguments:
     ```
     love . --mode ai --server ws://localhost:4080/ws --lobby lobby_123 
            --name AI_aggressive_1 --difficulty medium --personality aggressive
            --strategy power_plant_focused --decision-delay 2000 --log-decisions
     ```

4. **Game Start**
   - Backend waits for all AI clients to connect and be ready
   - Starts the game automatically
   - Begins streaming game updates and AI decisions

### AI Client Implementation

The AI clients are modified LÖVE2D game clients that:

1. **Auto-Connect**: Automatically connect to the server on launch
2. **Auto-Join**: Join the specified lobby with configured name
3. **Make Decisions**: Use AI logic for each game phase
4. **Log Decisions**: Send decision reasoning to admin interface
5. **Respect Speed**: Apply configured delays between decisions

### Real-Time Monitoring

The GameMonitor component connects via WebSocket to receive:

1. **Game Updates**: Current game state, phase, round
2. **AI Decisions**: What each AI decided and why
3. **Player States**: Money, cities, power plants, scores
4. **Game Events**: Phase transitions, game completion

## Backend Requirements

The backend (Go server) needs to implement:

### API Endpoints

```
POST   /api/admin/simulated/create-lobby
POST   /api/admin/simulated/launch-ai-client  
GET    /api/admin/simulated/lobby/{id}/ready
POST   /api/admin/simulated/start-game/{id}
POST   /api/admin/simulated/control/{id}
GET    /api/admin/simulated/games
GET    /api/admin/simulated/games/{id}
GET    /api/admin/simulated/games/{id}/decisions
GET    /api/admin/simulated/games/{id}/export
DELETE /api/admin/simulated/games/{id}
GET    /api/admin/simulated/ai-metrics
WS     /ws/admin/game/{id}
```

### Process Management

```go
type AIClient struct {
    ID        string
    Name      string
    Process   *os.Process
    ProcessID int
    Status    string
    LogBuffer bytes.Buffer
}

type AIClientManager struct {
    clients map[string]*AIClient
    mu      sync.RWMutex
}
```

### Database Schema

```sql
CREATE TABLE simulated_games (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    status VARCHAR(50),
    ai_player_count INT,
    ai_difficulty VARCHAR(50),
    map_id VARCHAR(50),
    started_at TIMESTAMP,
    ended_at TIMESTAMP
);

CREATE TABLE ai_decisions (
    id UUID PRIMARY KEY,
    game_id UUID,
    player_id UUID,
    timestamp TIMESTAMP,
    phase VARCHAR(50),
    decision_type VARCHAR(100),
    decision_data JSONB,
    reasoning TEXT,
    factors JSONB
);
```

## AI Decision Making

The AI clients need decision logic for each phase:

### Auction Phase
```lua
function makeAuctionDecision(gameState)
    local decision = evaluatePowerPlants(gameState)
    
    -- Log reasoning
    return {
        action = decision.bid and "bid" or "pass",
        amount = decision.bidAmount,
        plantId = decision.plantId,
        reasoning = string.format(
            "Plant %d can power %d cities for %d resources. " ..
            "Current money: $%d. Max bid: $%d",
            decision.plantId, 
            decision.citiesPowered,
            decision.resourceCost,
            gameState.myMoney,
            decision.maxBid
        ),
        factors = {
            plantEfficiency = decision.efficiency,
            moneyAvailable = gameState.myMoney,
            citiesOwned = #gameState.myCities
        }
    }
end
```

### Resource Phase
```lua
function makeResourceDecision(gameState)
    local needed = calculateResourceNeeds(gameState)
    local purchases = optimizeResourcePurchases(needed, gameState.market)
    
    return {
        action = "buy_resources",
        resources = purchases,
        reasoning = string.format(
            "Need %d coal, %d oil to power %d cities. " ..
            "Total cost: $%d",
            needed.coal, needed.oil, 
            gameState.citiesToPower,
            purchases.totalCost
        ),
        factors = {
            resourcesNeeded = needed,
            marketPrices = gameState.market.prices,
            moneyAvailable = gameState.myMoney
        }
    }
end
```

## UI Features

### Game Speed Control
- **Slow**: 5 seconds between AI decisions
- **Normal**: 2 seconds between AI decisions  
- **Fast**: 0.5 seconds between AI decisions
- **Instant**: No delay (stress testing)

### Decision Filtering
- View all AI decisions or filter by player
- Auto-scroll to latest decisions
- Color-coded by decision type

### Export Options
- JSON format with full game data
- CSV format for spreadsheet analysis
- Includes game state, decisions, and metrics

## Testing

The e2e tests verify:

1. **Game Creation Flow**
   - Form validation
   - API calls
   - Progress tracking

2. **AI Client Launch**
   - Process spawning
   - Connection verification
   - Ready state detection

3. **Real-Time Monitoring**
   - WebSocket updates
   - Decision streaming
   - State synchronization

4. **Game Control**
   - Pause/resume functionality
   - Speed changes
   - Graceful shutdown

## Performance Considerations

1. **Process Limits**: Limit concurrent AI games to prevent resource exhaustion
2. **Decision Buffering**: Buffer AI decisions to prevent UI flooding
3. **WebSocket Optimization**: Use message batching for high-frequency updates
4. **Cleanup**: Ensure proper process termination and resource cleanup

## Future Enhancements

1. **AI Profiles**: Save and reuse AI configurations
2. **Tournaments**: Run multiple games with statistics
3. **Learning AI**: Implement machine learning for adaptive difficulty
4. **Replay System**: Record and replay games
5. **AI vs Human**: Mix AI and human players in games
6. **Performance Analytics**: Detailed AI performance metrics and visualizations