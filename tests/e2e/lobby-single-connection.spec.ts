import { test, expect } from '@playwright/test';
import { spawn, ChildProcess, execSync } from 'child_process';
import * as path from 'path';

let goServerProcess: ChildProcess | null = null;

test.describe('Single Connection Lobby Test', () => {
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

  test('direct lobby creation without navigation', async ({ page }) => {
    test.setTimeout(60000);

    // Add console logging
    page.on('console', msg => {
      console.log('[Client]:', msg.text());
    });

    try {
      console.log('Loading app and registering player...');
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

      // Wait for registration to complete
      await page.waitForTimeout(3000);

      // Use the Create New Lobby button directly from main menu
      const createNewLobbyButton = page.locator('button:has-text("Create New Lobby")');
      if (await createNewLobbyButton.isVisible()) {
        await createNewLobbyButton.click();
        console.log('Clicked Create New Lobby from main menu');

        await page.waitForTimeout(2000);

        // Check if we're on Create Lobby screen
        const createLobbyTitle = await page.locator('h1:has-text("Create Lobby")').isVisible({ timeout: 3000 });
        console.log('On Create Lobby screen:', createLobbyTitle);
        
        if (createLobbyTitle) {
          // Fill lobby form
          const lobbyNameInput = page.locator('input[placeholder="Enter lobby name"]');
          if (await lobbyNameInput.isVisible({ timeout: 2000 })) {
            await lobbyNameInput.fill('Direct Test Lobby');
            console.log('Filled lobby name');
            
            // Click Create Lobby button
            const createLobbyButton = page.locator('button:has-text("Create Lobby")');
            if (await createLobbyButton.isVisible() && await createLobbyButton.isEnabled()) {
              await createLobbyButton.click();
              console.log('Submitted lobby creation');
              
              await page.waitForTimeout(3000);
              
              // Check for success or error
              const lobbyCreated = await page.locator('text=Ready').isVisible({ timeout: 3000 }) ||
                                 await page.locator('text=Start Game').isVisible({ timeout: 3000 }) ||
                                 await page.locator('text=Host').isVisible({ timeout: 3000 });
              
              console.log('Lobby created successfully:', lobbyCreated);
              
              await page.screenshot({ 
                path: 'test-results/direct-lobby-result.png',
                fullPage: true 
              });
              
              expect(lobbyCreated).toBeTruthy();
            }
          }
        }
      } else {
        console.log('Create New Lobby button not found in main menu');
        await page.screenshot({ 
          path: 'test-results/main-menu-state.png',
          fullPage: true 
        });
      }

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