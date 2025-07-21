# Admin E2E Tests Documentation

## Overview
This document describes the comprehensive e2e test suite for the Power Grid admin functionality, including simulated games with AI clients.

## Test Files

### 1. `admin-dashboard.spec.ts`
Tests the main admin dashboard navigation and overview functionality.

**Key Test Cases:**
- Admin dashboard access from main menu
- Server status display (health, version, uptime)
- Game activity metrics (7-day overview)
- Navigation between admin sections
- Quick action buttons
- API error handling
- Mobile and tablet responsiveness

### 2. `admin-analytics.spec.ts`
Tests analytics, player management, leaderboards, and system monitoring.

**Key Test Cases:**
- **Analytics Dashboard**
  - Game analytics with date filters
  - Phase distribution charts
  - Player statistics
  - Resource usage analytics
  - Data export (CSV/JSON)

- **Player Management**
  - Player list with search/filter
  - Player details and history
  - Achievement tracking

- **Leaderboards**
  - Global, weekly, monthly views
  - Map-specific leaderboards
  - Rating and win percentage tracking

- **System Status**
  - Server health metrics
  - WebSocket connection monitoring
  - System logs viewer
  - Configuration management

### 3. `admin-simulated-games.spec.ts`
Tests the creation and management of simulated games with AI players.

**Key Test Cases:**
- Create simulated games with AI configuration
- List and filter simulated games
- Real-time game monitoring
- AI player decision logs
- Game speed control (pause/resume/speed adjustment)
- Export game data and analytics
- AI performance metrics
- Multiple concurrent games
- AI personality configuration
- Game replay functionality

### 4. `admin-ai-behavior.spec.ts`
Tests detailed AI behavior observation and analysis.

**Key Test Cases:**
- **Phase-Specific AI Analysis**
  - Auction phase bidding strategies
  - Resource purchasing decisions
  - City building patterns
  - Power plant optimization

- **AI Performance**
  - Strategy comparison by difficulty
  - Adaptation to player behavior
  - Decision tree visualization
  - Performance benchmarking

- **AI Tools**
  - Behavior data export
  - Debug panel with step-through
  - State inspection
  - Parameter modification

## Running the Tests

```bash
# Run all admin tests
npm run test:e2e -- admin-*.spec.ts

# Run specific test file
npm run test:e2e -- admin-dashboard.spec.ts

# Run with UI mode for debugging
npm run test:e2e:ui -- admin-*.spec.ts

# Run specific test by name
npm run test:e2e -- -g "should create simulated game"
```

## Implementation Requirements

### API Endpoints Needed
The tests expect these API endpoints to be available:

**Admin API** (`/api/admin/`)
- `GET /server/info` - Server information
- `GET /health` - Health status
- `GET /analytics/games` - Game analytics
- `GET /analytics/players` - Player analytics
- `GET /analytics/resources` - Resource usage

**Player Management** (`/api/players/`)
- `GET /` - List players
- `GET /:id` - Player details
- `GET /:id/history` - Game history
- `GET /:id/achievements` - Achievements

**Simulated Games** (`/api/simulated/`)
- `POST /create` - Create simulated game
- `GET /` - List simulated games
- `GET /:id` - Game details
- `POST /:id/control` - Control game (pause/resume/stop)
- `GET /:id/decisions` - AI decision log
- `GET /:id/export` - Export game data

**AI Analytics** (`/api/ai/`)
- `GET /performance` - AI performance metrics
- `GET /strategies` - Strategy comparison
- `GET /decisions/:gameId` - Decision details
- `POST /debug/:gameId` - Debug controls

### UI Components Needed

1. **AdminDashboard.tsx** - Main dashboard component
2. **GameAnalyticsView.tsx** - Analytics visualization
3. **PlayerManagement.tsx** - Player list and details
4. **LeaderboardView.tsx** - Leaderboard display
5. **SystemStatus.tsx** - System monitoring
6. **SimulatedGameForm.tsx** - Create simulated games
7. **GameMonitor.tsx** - Real-time game monitoring
8. **AIDecisionLog.tsx** - AI decision viewer
9. **AIPerformanceChart.tsx** - Performance visualization

### Required Dependencies

```json
{
  "@power-grid/api-client": "^1.0.0",
  "recharts": "^2.5.0",
  "date-fns": "^2.29.0",
  "@tanstack/react-table": "^8.0.0"
}
```

## Test Data Requirements

The tests expect:
- WebSocket connection at `ws://localhost:4080/ws`
- Admin dashboard accessible without authentication (for testing)
- Mock data for analytics and player information
- Simulated game creation capability

## Next Steps

1. **Install Dependencies**
   ```bash
   npm install --save-dev @power-grid/api-client
   ```

2. **Create API Client Types**
   - Define TypeScript interfaces for API responses
   - Create the api-client package or mock it

3. **Implement Admin Components**
   - Start with AdminDashboard as the entry point
   - Build out child components incrementally

4. **Set Up API Routes**
   - Implement admin endpoints in the Go server
   - Add WebSocket message handlers for real-time updates

5. **Run Tests Incrementally**
   - Start with basic navigation tests
   - Gradually enable more complex tests as features are built

## Notes

- Tests use Playwright's built-in wait strategies for better reliability
- All tests include mobile responsiveness checks
- Error scenarios are tested to ensure graceful handling
- Export functionality tests verify file downloads
- Real-time features test WebSocket message handling