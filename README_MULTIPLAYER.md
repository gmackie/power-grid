# Power Grid Multiplayer Implementation

## Overview

The LÖVE2D client now supports both offline (pass-and-play) and online multiplayer modes. The multiplayer functionality connects to the Go server via WebSocket.

## Key Components Added

### 1. Network Layer (`network/`)
- **websocket_client.lua**: WebSocket client implementation with mock support for testing
- **network_manager.lua**: Singleton manager for handling connections and game state
- **network_actions.lua**: Wrapper for game actions that sends them to server when online

### 2. New Game States (`states/`)
- **lobbyBrowser.lua**: Browse and join online games
- **gameLobby.lua**: Wait for players before starting a game

### 3. Updated Components
- **states/menu.lua**: Added "Play Online" option
- **states/game.lua**: Added network support and state synchronization

## How to Use

### Starting a Multiplayer Game

1. **Start the Go Server**:
   ```bash
   cd go_server
   ./run_server.sh
   ```

2. **Start the LÖVE2D Client**:
   ```bash
   cd love_client
   love .
   ```

3. **Connect to Server**:
   - Click "Play Online" in the main menu
   - The client will connect to `ws://localhost:4080/game`

4. **Create or Join a Game**:
   - Click "Create Game" to start a new game
   - Or select an existing game and click "Join Game"

5. **Start Playing**:
   - Once 2+ players join, the host can start the game
   - Game state is synchronized automatically

### Testing Multiplayer

Use the provided test script to run both server and client:
```bash
./test_multiplayer.sh
```

## Network Protocol

The client communicates with the server using JSON messages over WebSocket:

### Message Types
- `CREATE_GAME`: Create a new game lobby
- `JOIN_GAME`: Join an existing game
- `START_GAME`: Start the game (host only)
- `GAME_STATE`: Full game state update
- `BID_PLANT`: Bid on a power plant
- `BUY_RESOURCES`: Purchase resources
- `BUILD_CITY`: Build in a city
- `POWER_CITIES`: Power cities in bureaucracy phase
- `END_TURN`: End current turn

### Connection Status

The game shows connection status:
- Green dot in top-right when connected
- "Waiting for other players..." when it's not your turn
- Error messages for connection issues

## Architecture

### Online Mode
1. Client connects to server via WebSocket
2. All game actions go through `NetworkActions`
3. Server validates actions and broadcasts state updates
4. Client updates local state from server messages

### Offline Mode
1. Game runs entirely locally
2. `NetworkActions` returns `true` to allow local processing
3. No server communication

## Current Limitations

1. **WebSocket Library**: The client uses a mock WebSocket implementation if lua-websockets is not installed
2. **Phase Integration**: Only auction phase has full network integration (see `phases/auction_networked.lua`)
3. **Reconnection**: No automatic reconnection on disconnect

## Next Steps

To complete the multiplayer implementation:

1. Update remaining phases to use `NetworkActions`
2. Add reconnection support
3. Implement spectator mode
4. Add chat functionality
5. Handle edge cases (player disconnect, timeout)

## Testing Without lua-websockets

The implementation includes a mock mode that simulates server responses. This allows testing the UI flow without a real WebSocket connection. The mock mode is automatically activated if lua-websockets is not available.

## Troubleshooting

### Connection Failed
- Ensure the Go server is running on port 4080
- Check firewall settings
- Verify the server URL in `network_manager.lua`

### Game Not Updating
- Check the server logs for errors
- Ensure all players have unique names/colors
- Verify WebSocket messages in browser dev tools

### Performance Issues
- The mock mode adds artificial delays
- Real WebSocket performance depends on network latency
- Consider reducing update frequency for slow connections