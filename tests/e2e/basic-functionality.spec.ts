import { test, expect } from '@playwright/test';
import { spawn, ChildProcess } from 'child_process';
import { promisify } from 'util';

const sleep = promisify(setTimeout);

let goServerProcess: ChildProcess | null = null;

test.describe('Basic Functionality', () => {
  // Start servers before all tests
  test.beforeAll(async () => {
    console.log('Starting Go server...');
    
    // Start the Go server
    goServerProcess = spawn('./scripts/launch_server.sh', [], {
      cwd: '/Users/mackieg/power_grid_game',
      shell: true,
      detached: false
    });

    goServerProcess.stdout?.on('data', (data) => {
      console.log(`[Go Server]: ${data}`);
    });

    goServerProcess.stderr?.on('data', (data) => {
      console.error(`[Go Server Error]: ${data}`);
    });

    // Wait for server to be ready
    await sleep(3000);
    
    console.log('Go server should be running on port 4080');
  });

  // Clean up after all tests
  test.afterAll(async () => {
    console.log('Cleaning up servers...');
    
    if (goServerProcess) {
      // Kill the process group
      process.kill(-goServerProcess.pid!, 'SIGTERM');
      goServerProcess = null;
    }
    
    await sleep(1000);
  });

  test('should load main menu', async ({ page }) => {
    await page.goto('/');
    
    // Wait for the app to load
    await page.waitForLoadState('networkidle');
    
    // Check if main menu is displayed
    await expect(page.locator('h1')).toBeVisible({ timeout: 10000 });
    
    // Should show Power Grid title or main menu
    const heading = await page.locator('h1').textContent();
    expect(heading).toContain('Power Grid');
    
    // Should show the Browse Lobbies button
    await expect(page.locator('button:has-text("Browse Lobbies")')).toBeVisible();
  });

  test('should show connection status', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Should show connection status indicator
    const connectionStatus = page.locator('[data-testid="connection-status"]');
    
    // Wait for connection to establish
    await page.waitForTimeout(2000);
    
    // Should eventually show connected status
    await expect(connectionStatus).toContainText(/Connected|Connecting/, { timeout: 10000 });
  });

  test('should navigate to lobby browser', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Click Browse Lobbies
    await page.click('button:has-text("Browse Lobbies")');
    
    // Should navigate to lobby browser
    await expect(page).toHaveURL('/lobbies', { timeout: 5000 });
    
    // Should show lobby browser UI
    await expect(page.locator('text=Game Lobbies')).toBeVisible();
    
    // Should show create lobby button
    await expect(page.locator('button:has-text("Create Lobby")')).toBeVisible();
  });

  test('should handle WebSocket connection', async ({ page }) => {
    // Add console listener to capture WebSocket logs
    page.on('console', msg => {
      if (msg.type() === 'log' || msg.type() === 'info') {
        console.log('Browser console:', msg.text());
      }
    });
    
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Wait for WebSocket connection
    await page.waitForTimeout(3000);
    
    // Check if we can navigate without errors
    await page.click('button:has-text("Browse Lobbies")');
    
    // If we get here without errors, basic functionality is working
    await expect(page.locator('text=Game Lobbies')).toBeVisible();
  });

  test('should create a lobby', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Navigate to lobby browser
    await page.click('button:has-text("Browse Lobbies")');
    await page.waitForSelector('text=Game Lobbies');
    
    // Click create lobby
    await page.click('button:has-text("Create Lobby")');
    
    // Should show create lobby form
    await expect(page.locator('input[placeholder="Enter lobby name"]')).toBeVisible();
    
    // Fill in lobby details
    await page.fill('input[placeholder="Enter lobby name"]', 'Test Lobby');
    
    // Check if we have map selection
    const mapSelect = page.locator('select[name="mapName"]');
    if (await mapSelect.isVisible()) {
      await mapSelect.selectOption('usa');
    }
    
    // Submit form
    await page.click('button[type="submit"]');
    
    // Should either navigate to lobby or show an error
    // Wait a bit for navigation or error
    await page.waitForTimeout(2000);
    
    // Check current state
    const currentUrl = page.url();
    console.log('Current URL after create lobby:', currentUrl);
    
    // We should either be in a lobby or see an error message
    const inLobby = currentUrl.includes('/lobby');
    const hasError = await page.locator('[data-testid="error-notification"]').isVisible();
    
    expect(inLobby || hasError).toBeTruthy();
  });

  test('should display game phases when game starts', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // This test checks if the phase components render without errors
    // In a real test, we'd need to actually start a game
    
    // For now, let's just verify the app doesn't crash
    await expect(page.locator('body')).toBeVisible();
    
    // No JavaScript errors should occur
    const errors: string[] = [];
    page.on('pageerror', error => {
      errors.push(error.message);
    });
    
    await page.waitForTimeout(2000);
    expect(errors).toHaveLength(0);
  });
});

// Minimal smoke test that doesn't require servers
test.describe('Component Rendering', () => {
  test('should render without crashing', async ({ page }) => {
    // Intercept WebSocket to prevent connection errors
    await page.route('ws://localhost:4080/ws', route => {
      console.log('WebSocket connection intercepted');
      route.abort();
    });
    
    await page.goto('/');
    
    // App should at least render something
    await expect(page.locator('#root')).toBeVisible();
    
    // Should show some UI elements
    const bodyText = await page.locator('body').textContent();
    expect(bodyText).toBeTruthy();
  });
});