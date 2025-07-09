import { test, expect } from '@playwright/test';
import { spawn, ChildProcess } from 'child_process';
import path from 'path';

test.describe('Session Persistence', () => {
  let serverProcess: ChildProcess;

  test.beforeEach(async () => {
    // Start the Go server
    const serverPath = path.join(process.cwd(), '../go_server');
    serverProcess = spawn('go', ['run', 'cmd/server/main.go'], {
      cwd: serverPath,
      stdio: 'pipe'
    });

    // Wait for server to start
    await new Promise((resolve) => {
      if (serverProcess.stdout) {
        serverProcess.stdout.on('data', (data) => {
          const output = data.toString();
          if (output.includes('Server listening on :4080')) {
            resolve(undefined);
          }
        });
      }
      // Fallback timeout
      setTimeout(resolve, 3000);
    });
  });

  test.afterEach(async () => {
    if (serverProcess) {
      serverProcess.kill();
    }
  });

  test('session persists during navigation', async ({ page }) => {
    console.log('=== Testing Session Persistence ===');

    // Navigate to app
    await page.goto('http://localhost:5173');
    await expect(page.locator('h1')).toHaveText('Power Grid');

    // Set up console logging
    page.on('console', msg => {
      if (msg.text().includes('Session ID') || msg.text().includes('WebSocket') || msg.text().includes('CREATE_LOBBY')) {
        console.log(`[Client]: ${msg.text()}`);
      }
    });

    // Navigate to player setup
    await page.click('button:has-text("Play Online")');
    
    // Wait for player setup screen
    await expect(page.locator('h2')).toHaveText('Player Setup');

    // Set player name and connect
    await page.fill('input[placeholder="Enter your name"]', 'TestPlayer');
    await page.click('button:has-text("Connect")');

    // Wait for connection confirmation
    await page.waitForSelector('text=Connected to server', { timeout: 10000 });
    console.log('[Test]: Player connected successfully');

    // Navigate to lobby browser
    await page.click('button:has-text("Browse Lobbies")');
    
    // Wait for lobby browser to load
    await page.waitForSelector('h1:has-text("Lobbies")', { timeout: 10000 });
    console.log('[Test]: Navigated to lobby browser');

    // Try to create a lobby
    await page.click('button:has-text("Create Lobby")');
    
    // Fill lobby creation form
    await page.fill('input[placeholder="Enter lobby name"]', 'Test Session Lobby');
    await page.selectOption('select', 'usa'); // map selection
    await page.click('button:has-text("Create")');

    // Check for successful lobby creation or error
    const lobbyCreated = await Promise.race([
      page.waitForSelector('h2:has-text("Test Session Lobby")', { timeout: 5000 }).then(() => true),
      page.waitForSelector('text=error', { timeout: 5000 }).then(() => false),
      new Promise<boolean>(resolve => setTimeout(() => resolve(false), 6000))
    ]);

    console.log(`[Test]: Lobby creation result: ${lobbyCreated ? 'SUCCESS' : 'FAILED'}`);

    if (lobbyCreated) {
      console.log('[Test]: ✅ Session persistence working - lobby created successfully');
    } else {
      console.log('[Test]: ❌ Session persistence failed - lobby creation failed');
      
      // Capture any error messages
      const errorElements = page.locator('text*=error');
      if (await errorElements.count() > 0) {
        const errorText = await errorElements.first().textContent();
        console.log(`[Test]: Error message: ${errorText}`);
      }
    }

    expect(lobbyCreated).toBeTruthy();
  });

  test('reconnection preserves session', async ({ page }) => {
    console.log('=== Testing Reconnection ===');

    // Navigate to app and connect
    await page.goto('http://localhost:5173');
    await page.click('button:has-text("Play Online")');
    await page.fill('input[placeholder="Enter your name"]', 'ReconnectTest');
    await page.click('button:has-text("Connect")');
    await page.waitForSelector('text=Connected to server', { timeout: 10000 });

    // Force a page reload to simulate reconnection
    await page.reload();
    await page.waitForLoadState('networkidle');

    console.log('[Test]: Page reloaded, testing reconnection...');

    // Navigate back to player setup and reconnect
    await page.click('button:has-text("Play Online")');
    await page.fill('input[placeholder="Enter your name"]', 'ReconnectTest');
    await page.click('button:has-text("Connect")');

    // Check if reconnection works
    const reconnected = await Promise.race([
      page.waitForSelector('text=Connected to server', { timeout: 5000 }).then(() => true),
      page.waitForSelector('text=Welcome back', { timeout: 5000 }).then(() => true),
      new Promise<boolean>(resolve => setTimeout(() => resolve(false), 6000))
    ]);

    console.log(`[Test]: Reconnection result: ${reconnected ? 'SUCCESS' : 'FAILED'}`);
    expect(reconnected).toBeTruthy();
  });
});