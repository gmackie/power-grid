# Power Grid Digital - LÖVE2D Client

A LÖVE2D-based game client for Power Grid Digital, supporting both desktop and mobile platforms with comprehensive multiplayer networking capabilities.

## Overview

This is the LÖVE2D client implementation for Power Grid Digital, a digital adaptation of the classic Power Grid board game. The client features:

- **Cross-platform support**: Desktop (Windows, macOS, Linux) and mobile (iOS, Android)
- **Multiplayer networking**: WebSocket-based real-time multiplayer
- **Local modes**: Pass-and-play and single-player with AI
- **Comprehensive testing**: Automated testing framework with simulation capabilities
- **Mobile-optimized UI**: Touch-friendly interface with responsive design

## Requirements

- **LÖVE2D 11.4+** - Download from [love2d.org](https://love2d.org/)
- **Network connection** - Required for multiplayer mode
- **Go server** - The corresponding `go_server` must be running for multiplayer

## Quick Start

### Desktop
```bash
# From the love_client directory
love .
```

### Mobile Development
```bash
# Package for mobile distribution
zip -9 -r ../powergrid.love .
```

## Project Structure

```
love_client/
├── main.lua                    # Entry point with mobile support
├── conf.lua                    # LÖVE2D configuration
├── state.lua                   # Global state management
├── states/                     # Game screen states
│   ├── menu.lua               # Main menu
│   ├── playerSetup.lua        # Player configuration
│   ├── gameLobby.lua          # Multiplayer lobby
│   ├── lobbyBrowser.lua       # Server browser
│   └── game.lua               # Main game screen
├── phases/                     # Game phase implementations
│   ├── phase_manager.lua      # Phase orchestration
│   ├── auction.lua            # Auction phase logic
│   ├── resource_buying.lua    # Resource market phase
│   ├── building.lua           # City building phase
│   └── bureaucracy.lua        # Income/scoring phase
├── models/                     # Game data models
│   ├── player.lua             # Player entity
│   ├── power_plant.lua        # Power plant data
│   ├── resource_market.lua    # Market state
│   └── enums.lua              # Game constants
├── ui/                         # UI components
│   ├── component.lua          # Base UI component
│   ├── button.lua             # Button widget
│   ├── panel.lua              # Panel container
│   ├── gameBoard.lua          # Main game board
│   └── [other components]     # Various UI elements
├── network/                    # Networking layer
│   ├── network_manager.lua    # Network orchestration
│   ├── websocket_client.lua   # WebSocket implementation
│   └── network_actions.lua    # Action handlers
├── mobile/                     # Mobile platform support
│   ├── mobile_config.lua      # Platform detection
│   └── touch_adapter.lua      # Touch input handling
├── test/                       # Testing framework
│   ├── simulator.lua          # Game simulation
│   ├── ai_player.lua          # AI player implementation
│   └── integration_test_harness.lua
├── data/                       # Game data files
│   ├── power_plants.json      # Power plant definitions
│   └── test_map.json          # Test map data
└── lib/                        # External libraries
    ├── json.lua               # JSON parsing
    └── middleclass.lua        # OOP framework
```

## Game Modes

### 1. Multiplayer (Network)
Connect to a running Go server for real-time multiplayer games:
```bash
love .  # Connects to localhost:4080 by default
```

### 2. Pass-and-Play (Local)
Local multiplayer on a single device:
- Configure 2-6 players
- Players take turns using the same device
- No network connection required

### 3. Single Player (AI)
Play against computer opponents:
- Choose number of AI players (1-5)
- AI handles all phases automatically
- Good for learning and testing

## Development Commands

### Basic Usage
```bash
# Run normally
love .

# Run with specific server
love . --server=192.168.1.100:4080

# Direct phase testing (for development)
love . --auction              # Start in auction phase
love . --resource             # Start in resource phase
love . --building             # Start in building phase
love . --bureaucracy          # Start in bureaucracy phase
```

### Testing Framework
```bash
# Comprehensive testing
love . --test-full            # Complete game simulation
love . --test-building        # Test building phase mechanics
love . --test-phase           # Test phase transitions
love . --test-auction         # Test auction mechanics
love . --test-market          # Test resource market
love . --test-integration     # Run integration tests

# Test runner script
./scripts/run_tests.sh        # Show all available tests
./scripts/run_tests.sh all    # Run all tests sequentially
```

## Mobile Platform Support

### Configuration
The client automatically detects mobile platforms and applies appropriate optimizations:

- **Touch controls**: Finger-friendly UI elements
- **Screen scaling**: Responsive layout for various screen sizes
- **Performance**: Optimized graphics and reduced complexity
- **Orientation**: Landscape mode for optimal gameplay

### Building for Mobile

#### Android
```bash
# Using love-android-sdl2
# See android_config/AndroidManifest.xml for configuration
```

#### iOS
```bash
# Using love-ios-source
# See ios_config/Info.plist for configuration
```

## Network Protocol

The client communicates with the Go server via WebSocket using JSON messages:

### Message Format
```json
{
  "type": "message_type",
  "session_id": "unique_session_id", 
  "timestamp": "2025-07-11T10:30:00Z",
  "data": {
    // Message-specific data
  }
}
```

### Key Message Types
- `connect` - Initial connection
- `create_lobby` - Create new game lobby
- `join_lobby` - Join existing lobby
- `player_action` - Game action (bid, buy, build)
- `game_state_update` - Server state synchronization

## Testing and Quality Assurance

### Automated Testing
The client includes comprehensive testing capabilities:

- **Unit Tests**: Individual component testing
- **Integration Tests**: Full game flow validation
- **Simulation Tests**: AI-driven complete games
- **Network Tests**: WebSocket connectivity validation

### Test Coverage
- ✅ All game phases (auction, resource, building, bureaucracy)
- ✅ Player actions and validation
- ✅ Network connectivity and reconnection
- ✅ Mobile touch input handling
- ✅ State transitions and error handling

### Debugging Features
- **Debug overlays**: Performance metrics and state visualization
- **Console logging**: Detailed operation logging
- **Network diagnostics**: Connection status and message tracking
- **Phase jumping**: Direct testing of specific game phases

## Performance Optimization

### Desktop
- Target: 60 FPS at 1600x900
- Memory usage: < 100MB
- Startup time: < 3 seconds

### Mobile
- Target: 30 FPS minimum
- Memory usage: < 50MB
- Battery optimization: Reduced animation complexity
- Touch responsiveness: < 100ms input latency

## Troubleshooting

### Common Issues

**Connection Failed**
```
Error: Unable to connect to server
Solution: Ensure go_server is running on port 4080
```

**Module Loading Error**
```
Error: module 'json' not found
Solution: Check that lib/json.lua exists
```

**Touch Input Not Working**
```
Error: Touch events not registering
Solution: Ensure mobile/touch_adapter.lua is properly loaded
```

### Debug Mode
Enable detailed logging:
```bash
love . --debug
```

### Log Files
Check logs in the main project directory:
- `logs/client.log` - General client logs
- `logs/client1.log` - First client instance
- `logs/client2.log` - Second client instance

## Contributing

### Code Style
- Use 4-space indentation
- Follow Lua naming conventions (camelCase for functions, PascalCase for classes)
- Add comments for complex logic
- Use middleclass for object-oriented code

### Adding New Features

1. **New UI Component**:
   - Create in `ui/` directory
   - Inherit from base `Component` class
   - Register with `uiManager` if needed

2. **New Game Phase**:
   - Add logic in `phases/` directory
   - Update `phase_manager.lua`
   - Add corresponding network handlers

3. **Mobile Optimization**:
   - Test on both phone and tablet form factors
   - Ensure touch targets are minimum 44px
   - Optimize for landscape orientation

### Testing New Features
Always run the full test suite before submitting changes:
```bash
./scripts/run_tests.sh all
```

## License

Part of the Power Grid Digital project. See main project LICENSE for details.