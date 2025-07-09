import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';
import path from 'path';

test.describe('Lobby Creation Test', () => {
  test.beforeAll(async () => {
    // Kill any existing server
    try {
      execSync('lsof -ti:4080 | xargs kill -9 2>/dev/null || true', { stdio: 'ignore' });
    } catch (e) {
      // Ignore errors
    }
    
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Start Go server
    console.log('Starting Go server...');
    const goServerPath = path.join(process.cwd(), '..', 'go_server');
    execSync('go run cmd/server/main.go &', { 
      cwd: goServerPath,
      stdio: 'inherit',
      detached: true
    });
    
    console.log('Server is ready!');
    await new Promise(resolve => setTimeout(resolve, 3000));
  });

  test.afterAll(async () => {
    console.log('Stopping server...');
    try {
      execSync('lsof -ti:4080 | xargs kill -9 2>/dev/null || true', { stdio: 'ignore' });
    } catch (e) {
      // Ignore errors
    }
  });

  test('create lobby successfully', async ({ page }) => {
    console.log('=== Testing Lobby Creation ===');

    // Set up console logging
    page.on('console', msg => {
      if (msg.text().includes('Session ID') || msg.text().includes('WebSocket') || msg.text().includes('No session ID')) {
        console.log(`[Client]: ${msg.text()}`);
      }
    });

    // Navigate to app and clear storage
    await page.goto('http://localhost:5173');
    await page.evaluate(() => {
      sessionStorage.clear();
      localStorage.clear();
    });

    // Go to player setup
    await page.click('button:has-text("Play Online")');
    await page.waitForSelector('h2:has-text("Player Setup")');

    // Enter name and connect
    await page.fill('input[placeholder="Enter your name"]', 'TestPlayer');
    
    // Wait for connection to be established 
    await page.waitForTimeout(2000);
    
    // Navigate to lobby browser
    await page.click('button:has-text("Browse Lobbies")');
    await page.waitForSelector('h1:has-text("Lobbies")');
    console.log('[Test]: Navigated to lobby browser');

    // Try to create a lobby
    await page.click('button:has-text("Create Lobby")');
    
    // Fill lobby details
    await page.fill('input[placeholder="Enter lobby name"]', 'Test Lobby Creation');
    await page.selectOption('select', 'usa');
    
    // Submit lobby creation
    await page.click('button:has-text("Create")');
    
    // Check for successful lobby creation
    const lobbyCreated = await Promise.race([
      page.waitForSelector('h2:has-text("Test Lobby Creation")', { timeout: 10000 }).then(() => true),
      page.waitForSelector('text*=error', { timeout: 10000 }).then(() => false),
      new Promise<boolean>(resolve => setTimeout(() => resolve(false), 12000))
    ]);

    console.log(`[Test]: Lobby creation result: ${lobbyCreated ? 'SUCCESS' : 'FAILED'}`);
    
    if (!lobbyCreated) {
      // Take screenshot for debugging
      await page.screenshot({ 
        path: 'test-results/lobby-creation-failed.png',
        fullPage: true 
      });
      
      // Check for any error messages
      const errorElements = page.locator('text*=error');
      if (await errorElements.count() > 0) {
        const errorText = await errorElements.first().textContent();
        console.log(`[Test]: Error message: ${errorText}`);
      }
    }

    expect(lobbyCreated).toBeTruthy();
  });
});