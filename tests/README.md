# Playwright E2E Test Suite

This directory contains comprehensive end-to-end tests for the Power Grid React client using Playwright.

## Test Structure

### Test Files

- **`lobby-setup.spec.ts`** - Tests lobby creation, joining, and player configuration
- **`auction-phase.spec.ts`** - Tests power plant auction mechanics and bidding
- **`resource-phase.spec.ts`** - Tests resource market purchasing and management
- **`building-phase.spec.ts`** - Tests city building and network expansion
- **`bureaucracy-game-completion.spec.ts`** - Tests power generation, earnings, and game completion

### Test Coverage

#### Lobby and Setup Tests
- Main menu navigation
- Lobby browser functionality
- Lobby creation and configuration
- Player setup and configuration
- Connection error handling
- State persistence on page refresh

#### Auction Phase Tests
- Power plant market display
- Plant selection and highlighting
- Bid validation and placement
- Auction progression and turn management
- Quick bid functionality
- Pass mechanics
- Auction history and results
- Mobile responsive design

#### Resource Phase Tests
- Resource market display and pricing
- Storage capacity management
- Resource purchase interactions
- Cost calculation and validation
- Money constraint validation
- Turn-based purchasing
- Purchase history tracking
- Resource type filtering based on plants

#### Building Phase Tests
- Game board interaction
- City selection and validation
- Building cost calculation
- Construction constraints (money, capacity, step rules)
- Connection cost calculation
- Mobile city list view
- Building history and progress tracking
- House visualization

#### Bureaucracy Phase Tests
- Power plant resource management
- Hybrid plant fuel selection
- Eco plant handling
- Earnings calculation
- Resource consumption tracking
- City powering mechanics
- Phase results display
- Game completion scenarios

## Running Tests

### Prerequisites

1. Ensure the Go server is running on port 4080
2. Install dependencies: `npm install`
3. Install Playwright browsers: `npx playwright install`

### Test Commands

```bash
# Run all tests
npm run test:e2e

# Run tests with UI (interactive mode)
npm run test:e2e:ui

# Run tests in debug mode
npm run test:e2e:debug

# Run specific test file
npx playwright test lobby-setup.spec.ts

# Run tests for specific browser
npx playwright test --project=chromium

# Run mobile tests
npx playwright test --project="Mobile Chrome"
```

### Test Configuration

The tests are configured in `playwright.config.ts` with:

- **Base URL**: http://localhost:5173 (Vite dev server)
- **Browsers**: Chromium, Firefox, WebKit, Mobile Chrome, Mobile Safari
- **Timeouts**: 2 minutes for commands, 10 minutes for overall test
- **Retries**: 2 retries on CI, 0 locally
- **Reporters**: HTML report with traces on failure

## Test Patterns

### Page Navigation
```typescript
// Standard setup for most tests
await page.goto('/');
await page.click('text=Browse Lobbies');
await page.click('text=Create Lobby');
// ... configure and start game
```

### Element Selection
```typescript
// Use data-testid attributes for reliable selection
await page.locator('[data-testid="power-plant"]').first().click();

// Text-based selection for user-visible elements
await page.click('button:has-text("Place Bid")');

// CSS selectors for styling validation
await expect(firstPlant).toHaveClass(/border-blue-500/);
```

### Async Waiting
```typescript
// Wait for elements to appear
await page.waitForSelector('[data-testid="city"]');

// Wait for navigation
await expect(page).toHaveURL('/lobby');

// Wait for text content
await expect(page.locator('h1')).toContainText('Power Grid');
```

### Mobile Testing
```typescript
// Set mobile viewport
await page.setViewportSize({ width: 375, height: 667 });

// Validate touch targets
const boundingBox = await button.boundingBox();
expect(boundingBox.height).toBeGreaterThanOrEqual(44);
```

## Test Data Requirements

### Mock Data
The tests expect certain data to be available:

- **Power Plants**: Various types (coal, oil, garbage, uranium, hybrid, eco)
- **Cities**: Multiple cities with different connection costs
- **Resources**: Available resources in the market
- **Players**: Configurable player count (2-6)

### Test Isolation
Each test file uses `beforeEach` hooks to:
1. Start fresh from the main menu
2. Create a new lobby
3. Configure a test player
4. Navigate to the appropriate game phase

## CI/CD Integration

### GitHub Actions
The test suite integrates with GitHub Actions via `.github/workflows/playwright-tests.yml`:

- **Triggers**: Push to main/develop, PRs affecting client/server code
- **Matrix Testing**: Tests across multiple browsers
- **Mobile Testing**: Dedicated mobile test job
- **Artifacts**: Test reports, screenshots, and videos uploaded on failure
- **Server Setup**: Automatically starts Go server before tests

### Test Reports
- **HTML Report**: Generated in `playwright-report/`
- **Test Results**: Screenshots and videos in `test-results/`
- **Traces**: Full interaction traces for debugging failures

## Best Practices

### Test Design
1. **Atomic Tests**: Each test is independent and can run in isolation
2. **Descriptive Names**: Test names clearly describe the behavior being tested
3. **Positive and Negative Cases**: Test both success paths and error conditions
4. **Mobile Responsive**: Include mobile-specific test variations

### Maintenance
1. **Data Test IDs**: Use `data-testid` attributes for stable element selection
2. **Page Objects**: Consider extracting common patterns into page object models
3. **Test Data**: Use factories or fixtures for complex test data setup
4. **Flaky Tests**: Implement proper waits and retry logic for unreliable elements

### Debugging
1. **Debug Mode**: Use `--debug` flag to step through tests
2. **Screenshots**: Automatic screenshots on failure
3. **Traces**: Record full interaction traces for post-mortem analysis
4. **Console Logs**: Capture browser console output for debugging

## Common Issues

### Server Connection
- Ensure Go server is running before starting tests
- Check that WebSocket connections are properly established
- Verify port 4080 is not blocked

### Timing Issues
- Use `waitForSelector` instead of fixed delays
- Wait for network requests to complete
- Use `expect` with timeout for dynamic content

### Test Flakiness
- Implement proper waiting strategies
- Avoid hardcoded delays
- Use page state checks instead of time-based waits

### Mobile Testing
- Ensure touch targets meet minimum size requirements (44px)
- Test responsive breakpoints
- Validate gesture interactions

## Future Enhancements

### Potential Improvements
1. **Visual Regression Testing**: Add screenshot comparison tests
2. **Performance Testing**: Measure load times and rendering performance
3. **Accessibility Testing**: Add a11y checks with axe-playwright
4. **API Testing**: Add tests for WebSocket message protocols
5. **Load Testing**: Test with multiple concurrent players
6. **Cross-Platform**: Add tests for different operating systems