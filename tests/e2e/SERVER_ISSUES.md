# Power Grid Game Server Issues Summary

## Overview
This document summarizes the server-side issues discovered during React client end-to-end testing with Playwright. These issues prevent successful lobby creation and multiplayer game functionality.

## Primary Issue: WebSocket Session Management

### Problem Description
The Go server is unable to properly track player sessions, resulting in "Player session not found" errors when players attempt to create lobbies.

### Root Cause Analysis

1. **~~Multiple WebSocket Connections Per Client~~ FIXED**
   - ~~Each client establishes 2 WebSocket connections instead of 1~~ 
   - **SOLUTION**: Removed React StrictMode which was causing double-mounting in development
   - Now shows single connection per client:
   ```
   [backend] 2025/07/08 09:25:08 New client connected with session ID: 1a375208-9ed6-4197-9aef-e80a7451896f
   [Client]: WebSocket connected
   ```

2. **Session Restoration Issue** (ACTIVE)
   - ✅ Client-side session persistence implemented and working
   - ✅ Session IDs properly stored in sessionStorage and restored
   - ✅ Session IDs correctly included in messages to server
   - ❌ Server doesn't restore existing sessions on reconnection
   - When client reconnects with existing session ID, server should restore session instead of rejecting it

2. **Player Registration Flow**
   - Client sends `CONNECT` message with player name
   - Server responds with `CONNECTED` confirmation
   - Server maintains a `clients` map: `conn -> playerID`
   - When `CREATE_LOBBY` is sent, server cannot find player in the `clients` map

3. **Connection Lifecycle Issues**
   - WebSocket connections close unexpectedly: `websocket: close 1001 (going away)`
   - This happens during navigation between React components
   - The connection that registered the player may not be the same one sending CREATE_LOBBY

### Affected Server Code

**File**: `/go_server/handlers/lobby_handler.go`

Key areas:
- Line 255-257: Player registration in `handleConnect()`
  ```go
  h.mu.Lock()
  h.clients[conn] = playerID
  h.mu.Unlock()
  ```

- Line 269-275: Player lookup in `handleCreateLobby()`
  ```go
  h.mu.Lock()
  playerID, exists := h.clients[conn]
  h.mu.Unlock()
  
  if !exists {
      h.sendErrorMessage(conn, sessionID, "Player not found")
      return
  }
  ```

### Test Results

**Successful Operations:**
- ✅ WebSocket connection establishment
- ✅ Player registration (CONNECT message)
- ✅ Lobby listing (LIST_LOBBIES message)
- ✅ Client receives server responses

**Failed Operations:**
- ❌ Lobby creation (CREATE_LOBBY returns "Player not found")
- ❌ Any operation requiring player lookup after initial connection

## Recommended Fixes

### 1. Connection Deduplication
- Investigate why React client creates multiple WebSocket connections
- Possible causes:
  - React StrictMode in development (double-mounting components)
  - Multiple WebSocket manager instances
  - Auto-reconnection logic creating duplicate connections

### 2. Player Session Management
- Consider using session IDs instead of WebSocket connections as primary key
- Implement player session persistence across reconnections
- Example approach:
  ```go
  type LobbyHandler struct {
      sessions map[string]*PlayerSession  // sessionID -> PlayerSession
      connections map[*websocket.Conn]string  // conn -> sessionID
  }
  ```

### 3. Connection State Tracking
- Add logging to track connection lifecycle:
  - Connection establishment
  - Player registration
  - Connection closure
  - Player lookup attempts

### 4. Client-Side Connection Management
- Ensure single WebSocket instance per client
- Handle reconnection without losing player state
- Consider implementing connection pooling or singleton pattern

## Testing Evidence

### Client Logs Showing Issue
```
[Client]: WebSocket connected
[Client]: Player registered successfully: {message: Welcome to Power Grid Game Server}
[Client]: Received message: CONNECTED {message: Welcome to Power Grid Game Server}
[Client]: WebSocket connected  // <-- Duplicate connection
[Client]: Player registered successfully: {message: Welcome to Power Grid Game Server}
[Client]: Received message: CONNECTED {message: Welcome to Power Grid Game Server}
```

### Server Response to CREATE_LOBBY
```
[Server]: Received message: {"type":"CREATE_LOBBY","data":{"lobby_name":"Test Lobby","player_name":"TestPlayer","max_players":4,"map_id":"usa","password":""}}
[Client]: Unhandled message: ERROR {message: Player not found}
```

## Impact on Testing

These issues prevent:
- Full end-to-end multiplayer testing
- Lobby creation and management testing
- Game phase progression testing
- Multi-player interaction testing

## Additional Observations

1. **React Client Behavior**
   - Client appears to handle navigation correctly
   - UI indicates successful operations despite server errors
   - WebSocket connections close during component transitions

2. **Server Stability**
   - Server remains stable despite connection issues
   - No crashes or panics observed
   - Proper error handling for missing players

## Debugging Recommendations

1. Add detailed logging in `lobby_handler.go`:
   - Log all connection establishments with timestamps
   - Log all player registrations with connection details
   - Log all connection closures
   - Log player lookup attempts with connection info

2. Implement connection tracking middleware:
   - Track active connections
   - Monitor connection lifecycle
   - Detect duplicate connections from same client

3. Test with simplified client:
   - Create minimal WebSocket client without React
   - Verify single connection behavior
   - Test lobby creation flow in isolation

## Latest Status (Updated)

### ✅ Client-Side Fixes Completed
1. **Session Persistence**: Session IDs now stored in sessionStorage and restored on reconnection
2. **Message Format**: Session IDs properly included in all messages to server
3. **StrictMode Removed**: Eliminated duplicate WebSocket connections

### ❌ Remaining Server-Side Issue
**Problem**: Server doesn't restore existing sessions on reconnection

**Current Flow**:
1. Client connects → Server creates session: `session123`
2. Client navigates → WebSocket closes (code 1001)
3. Client reconnects with same session ID → Server rejects because session not found

**Required Server Fix**:
The server's `handleConnect()` method needs to check if the incoming CONNECT message includes an existing session ID, and if so, restore that session instead of creating a new one.

**Evidence from Latest Test**:
```
[Client]: Session ID restored from sessionStorage: bc0a77f8-6591-4520-801a-de009d625251
[Server]: Received message: {"type":"CREATE_LOBBY",...,"session_id":"4a2f75f5-3c07-4bb7-a1e2-47884ca27d62"}
[Server]: CREATE_LOBBY attempted without session for sessionID: 4a2f75f5-3c07-4bb7-a1e2-47884ca27d62
```

## Success Criteria

The server should:
1. ✅ Accept single WebSocket connection per client (FIXED)
2. ❌ Handle session restoration when client reconnects with existing session ID
3. ❌ Successfully create lobbies after player reconnection
4. ❌ Maintain player state across WebSocket reconnections

## References

- Server code: `/go_server/handlers/lobby_handler.go`
- Client WebSocket manager: `/react_client/src/services/websocket.ts`
- Client store: `/react_client/src/store/gameStore.ts`
- Test logs: Available in Playwright test output