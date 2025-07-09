import { test, expect, Browser, Page, BrowserContext } from '@playwright/test';
import { spawn, ChildProcess, execSync } from 'child_process';
import * as path from 'path';

let goServerProcess: ChildProcess | null = null;

test.describe('Basic Lobby Functionality', () => {
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
    
    goServerProcess = spawn('go', ['run', 'cmd/server/main.go'], {
      cwd: goServerPath,
      env: { ...process.env, PORT: '4080' },
      stdio: ['ignore', 'pipe', 'pipe']
    });

    let serverReady = false;
    
    goServerProcess.stdout?.on('data', (data) => {
      const output = data.toString();
      console.log(`[Server]: ${output.trim()}`);
      if (output.includes('Starting Power Grid Game Server')) {
        serverReady = true;
      }
    });

    goServerProcess.stderr?.on('data', (data) => {
      console.error(`[Server Error]: ${data.toString().trim()}`);
    });

    // Wait for server to be ready
    let attempts = 0;
    while (!serverReady && attempts < 20) {
      await new Promise(resolve => setTimeout(resolve, 500));
      attempts++;
    }
    
    if (!serverReady) {
      throw new Error('Server failed to start');
    }
    
    console.log('Server is ready!');
    await new Promise(resolve => setTimeout(resolve, 1000));
  });

  test.afterAll(async () => {
    if (goServerProcess) {
      console.log('Stopping server...');
      goServerProcess.kill('SIGTERM');
      await new Promise(resolve => setTimeout(resolve, 2000));
    }
  });

  test('single player can connect and navigate', async ({ page }) => {
    test.setTimeout(60000);

    // Add console logging
    page.on('console', msg => {
      console.log('[Client]:', msg.text());
    });

    try {
      console.log('Loading app...');
      await page.goto('/');
      await page.waitForLoadState('networkidle');
      await page.waitForTimeout(2000);

      // Fill name and wait for connection
      const nameInput = page.locator('input[placeholder="Enter your name"]');
      await nameInput.waitFor({ state: 'visible' });
      
      // Wait for connection
      let attempts = 0;
      while (!(await nameInput.isEnabled()) && attempts < 10) {
        await page.waitForTimeout(1000);
        attempts++;
      }

      expect(await nameInput.isEnabled()).toBeTruthy();

      await nameInput.fill('TestPlayer');
      console.log('Player name entered');

      // Wait for registration
      await page.waitForTimeout(3000);

      // Try to browse lobbies
      const browseButton = page.locator('button:has-text("Browse Lobbies")');
      await expect(browseButton).toBeVisible();
      await browseButton.click();

      console.log('Clicked Browse Lobbies');

      // Wait for lobby browser
      await page.waitForTimeout(2000);
      
      // Take screenshot for debugging
      await page.screenshot({ 
        path: 'test-results/lobby-browser.png',
        fullPage: true 
      });

      // Check if we're in lobby browser
      const lobbyBrowserVisible = await page.locator('h1:has-text("Lobbies")').isVisible({ timeout: 5000 });
      console.log('Lobby browser visible:', lobbyBrowserVisible);

      if (lobbyBrowserVisible) {
        // Try to create a lobby
        const createButton = page.locator('button:has-text("Create")');
        if (await createButton.isVisible()) {
          await createButton.click();
          console.log('Clicked Create Lobby');
          
          // Wait for navigation to CreateLobby screen
          await page.waitForTimeout(2000);
          
          // Check if we're on Create Lobby screen
          const createLobbyTitle = await page.locator('h1:has-text("Create Lobby")').isVisible({ timeout: 3000 });
          console.log('On Create Lobby screen:', createLobbyTitle);
          
          if (createLobbyTitle) {
            // Fill lobby form
            const lobbyNameInput = page.locator('input[placeholder="Enter lobby name"]');
            if (await lobbyNameInput.isVisible({ timeout: 2000 })) {
              await lobbyNameInput.fill('Test Lobby');
              console.log('Filled lobby name');
              
              // Click Create Lobby button
              const createLobbyButton = page.locator('button:has-text("Create Lobby")');
              if (await createLobbyButton.isVisible() && await createLobbyButton.isEnabled()) {
                await createLobbyButton.click();
                console.log('Submitted lobby creation');
                
                await page.waitForTimeout(3000);
                
                // Check if we're in a lobby
                const inLobby = await page.locator('text=Ready').isVisible({ timeout: 3000 }) ||
                               await page.locator('text=Start Game').isVisible({ timeout: 3000 }) ||
                               await page.locator('text=Host').isVisible({ timeout: 3000 });
                
                console.log('Successfully created and joined lobby:', inLobby);
              }
            }
          }
        }
      }

      await page.screenshot({ 
        path: 'test-results/final-state.png',
        fullPage: true 
      });

      // Basic success: we can connect and navigate
      expect(lobbyBrowserVisible).toBeTruthy();

    } catch (error) {
      console.error('Test failed:', error);
      await page.screenshot({ 
        path: 'test-results/error-state.png',
        fullPage: true 
      });
      throw error;
    }
  });
});