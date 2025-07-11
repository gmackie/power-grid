# CLAUDE.md - LÖVE2D Client Development Guidelines

This file provides specific guidance for Claude Code when working with the LÖVE2D client portion of the Power Grid Digital project.

## Client-Specific Architecture

### Core Patterns

**State Management**
- Global state managed through `state.lua` singleton
- Screen states in `states/` directory using state machine pattern
- Phase-specific state in `phases/` directory
- Network state synchronized via WebSocket messages

**Object-Oriented Design**
- Uses `middleclass` library for class inheritance
- Base classes in `ui/component.lua` for UI elements
- Model classes in `models/` directory
- Composition over inheritance for complex behaviors

**Event-Driven Architecture**
- LÖVE2D callbacks (love.update, love.draw, love.mousepressed, etc.)
- Custom event system through state transitions
- Network events via WebSocket message handlers
- Touch events handled by `TouchAdapter` for mobile

## Essential Development Commands

### Running the Client
```bash
# Standard development
love .

# Direct phase testing (bypasses menu/lobby)
love . --auction       # Test auction phase UI
love . --resource      # Test resource buying phase
love . --building      # Test city building phase
love . --bureaucracy   # Test scoring phase

# Integration testing
love . --test-full           # Complete game simulation
love . --test-integration    # Network integration tests
love . --test-phase          # Phase transition validation

# Debug mode
love . --debug               # Enable debug overlays and verbose logging
```

### Testing Framework
```bash
# Run specific test suites
./scripts/run_tests.sh auction    # Test auction mechanics
./scripts/run_tests.sh building   # Test building phase
./scripts/run_tests.sh market     # Test resource market
./scripts/run_tests.sh ai         # Test AI player behavior
./scripts/run_tests.sh network    # Test WebSocket connectivity

# Run all tests
./scripts/run_tests.sh all
```

### Mobile Development
```bash
# Package for distribution
zip -9 -r ../powergrid.love .

# Test mobile UI scaling
love . --mobile-debug    # Force mobile UI mode on desktop
```

## File Organization and Patterns

### State Files (`states/`)
All state files should follow this pattern:
```lua
local StateName = {}

function StateName:enter(previous, ...)
    -- State initialization
end

function StateName:update(dt)
    -- Per-frame updates
end

function StateName:draw()
    -- Rendering
end

function StateName:leave()
    -- Cleanup
end

return StateName
```

### UI Components (`ui/`)
UI components inherit from the base Component class:
```lua
local Component = require("ui.component")
local MyComponent = Component:subclass("MyComponent")

function MyComponent:initialize(x, y, width, height)
    Component.initialize(self, x, y, width, height)
    -- Component-specific initialization
end

return MyComponent
```

### Phase Handlers (`phases/`)
Game phases should implement the standard interface:
```lua
local PhaseName = {}

function PhaseName:enter(gameState)
    -- Phase setup
end

function PhaseName:update(dt, gameState)
    -- Phase logic updates
end

function PhaseName:handlePlayerAction(action, gameState)
    -- Process player actions
end

function PhaseName:exit(gameState)
    -- Phase cleanup
end

return PhaseName
```

### Network Handlers (`network/`)
Network modules should handle WebSocket messages:
```lua
local NetworkHandler = {}

function NetworkHandler:handleMessage(message, gameState)
    if message.type == "specific_message" then
        -- Handle message
        return true
    end
    return false
end

return NetworkHandler
```

## Key Components and Their Responsibilities

### Core Systems
- `main.lua` - Entry point, handles LÖVE2D initialization and mobile detection
- `state.lua` - Global state singleton, manages shared game data
- `states/menu.lua` - Main menu with mode selection (multiplayer/local/AI)
- `states/game.lua` - Primary game loop, orchestrates phases

### Phase Management
- `phases/phase_manager.lua` - Controls phase transitions and timing
- `phases/auction.lua` - Handles power plant bidding logic
- `phases/resource_buying.lua` - Resource market interactions
- `phases/building.lua` - City connection and network expansion
- `phases/bureaucracy.lua` - Income calculation and end-of-round processing

### UI Framework
- `ui/component.lua` - Base class for all UI elements
- `ui/gameBoard.lua` - Main game board rendering and interaction
- `ui/button.lua` - Standardized button widget with mobile support
- `ui/panel.lua` - Container component for organizing layouts

### Mobile Support
- `mobile/mobile_config.lua` - Platform detection and screen configuration
- `mobile/touch_adapter.lua` - Converts touch events to standard input events
- `ui/mobile_button.lua` - Touch-optimized button implementation

### Testing Infrastructure
- `test/simulator.lua` - Automated game simulation for testing
- `test/ai_player.lua` - AI player implementation for single-player and testing
- `test/integration_test_harness.lua` - Full integration test runner

## Development Guidelines

### When Adding New Features

**New Game Mechanic**
1. Add data structures to appropriate model file in `models/`
2. Implement logic in the relevant phase file in `phases/`
3. Update UI components in `ui/` to display new information
4. Add network message handling in `network/`
5. Create tests in `test/` directory
6. Update mobile UI if needed

**New UI Component**
1. Create component file in `ui/` inheriting from `Component`
2. Implement mobile-responsive design
3. Add touch event handling if interactive
4. Register with `uiManager` if globally accessible
5. Test on both desktop and mobile form factors

**New Network Message**
1. Add message type to `network/network_actions.lua`
2. Implement handler in appropriate network module
3. Update game state synchronization logic
4. Test with real server connection
5. Handle disconnection/reconnection scenarios

### Code Style and Conventions

**Naming Conventions**
- Files: `snake_case.lua`
- Classes: `PascalCase`
- Functions: `camelCase`
- Constants: `UPPER_CASE`
- Local variables: `camelCase`

**File Structure**
```lua
-- Module description
-- Dependencies
local Class = require("path.to.dependency")

-- Constants
local CONSTANT_VALUE = 42

-- Local functions
local function helperFunction()
    -- Implementation
end

-- Class definition
local MyClass = Class:subclass("MyClass")

function MyClass:initialize()
    -- Constructor
end

-- Public methods
function MyClass:publicMethod()
    -- Implementation
end

return MyClass
```

**Error Handling**
- Use `assert()` for critical invariants
- Gracefully handle network disconnections
- Provide user-friendly error messages
- Log errors with sufficient context

### Mobile-Specific Considerations

**Touch Targets**
- Minimum 44px touch targets for buttons
- Provide visual feedback for touch events
- Handle touch drag gestures appropriately
- Test on actual mobile devices when possible

**Performance**
- Target 30 FPS minimum on mobile devices
- Optimize graphics for lower-end hardware
- Reduce memory allocations in update loops
- Use texture atlases for UI elements

**Screen Adaptation**
- Support both portrait and landscape orientations (prefer landscape)
- Handle safe areas on devices with notches
- Scale UI elements based on screen density
- Test on various screen sizes (phone, tablet)

### Testing Requirements

**Before Submitting Code**
1. Run full test suite: `./scripts/run_tests.sh all`
2. Test mobile UI scaling: `love . --mobile-debug`
3. Verify network connectivity: Test with real go_server
4. Check performance: Monitor FPS and memory usage
5. Test error handling: Simulate network failures

**Automated Testing**
- All new phases must include simulation tests
- UI components should have interaction tests
- Network features require integration tests
- Mobile features need touch event tests

### Common Pitfalls

**LÖVE2D Specific**
- Remember LÖVE2D uses 0-based indexing for some APIs
- Handle screen scaling properly for high-DPI displays
- Be careful with texture memory management
- Use love.filesystem for file operations

**Mobile Development**
- Test touch events separately from mouse events
- Handle device rotation gracefully
- Consider battery usage in update loops
- Optimize for varying hardware capabilities

**Networking**
- Always handle connection failures gracefully
- Implement proper reconnection logic
- Validate all incoming server messages
- Handle latency and message ordering issues

### Performance Optimization

**Graphics**
- Batch draw calls where possible
- Use SpriteBatch for repeated textures
- Minimize texture switches
- Cache expensive calculations

**Memory**
- Avoid creating objects in update loops
- Reuse table objects where appropriate
- Release resources in state transitions
- Monitor garbage collection impact

**Network**
- Minimize message frequency
- Compress large data structures
- Handle partial messages properly
- Implement message queuing for offline scenarios

## Integration with Go Server

### Message Protocol
The client communicates with the go_server via WebSocket using this message format:
```json
{
  "type": "action_type",
  "session_id": "player_session_id",
  "timestamp": "2025-07-11T10:30:00Z",
  "data": {
    // Action-specific data
  }
}
```

### Key Integration Points
- Player registration and session management
- Lobby creation and joining
- Real-time game state synchronization
- Turn-based action validation
- Reconnection and state restoration

### Testing Integration
Always test client changes against a running go_server:
```bash
# In separate terminals:
./scripts/launch_server.sh    # Start server
./scripts/launch_client.sh    # Start client
./scripts/test_websocket.sh   # Test connectivity
```

## Current Development Priorities

1. **Pass-and-Play Mode**: Complete local multiplayer implementation
2. **Mobile UI Polish**: Improve touch responsiveness and visual feedback  
3. **AI Player Enhancement**: Smarter decision-making algorithms
4. **Performance Optimization**: 60 FPS target on desktop, 30 FPS on mobile
5. **Network Resilience**: Better handling of disconnections and reconnections