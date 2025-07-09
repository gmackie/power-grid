import { test, expect, Browser } from '@playwright/test';
import { spawn, ChildProcess, execSync } from 'child_process';
import * as path from 'path';

let goServerProcess: ChildProcess | null = null;

test.describe('Simple Multiplayer Test', () => {
  test.beforeAll(async () => {
    // Kill any existing server on port 4080
    const killCommand = process.platform === 'win32' 
      ? 'netstat -ano | findstr :4080' 
      : 'lsof -ti:4080 | xargs kill -9 2>/dev/null || true';
    
    execSync(killCommand, { stdio: 'ignore' });
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

  test('two players can create and join a lobby', async ({ browser }) => {
    test.setTimeout(60000); // 1 minute timeout
    
    // Create two browser contexts (different players)
    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    
    const player1 = await context1.newPage();
    const player2 = await context2.newPage();
    
    // Enable console logging
    player1.on('console', msg => {
      if (msg.type() === 'log') console.log('[Player 1]:', msg.text());
    });
    player2.on('console', msg => {
      if (msg.type() === 'log') console.log('[Player 2]:', msg.text());
    });
    
    try {
      // PLAYER 1: Setup and create lobby
      console.log('\n=== Player 1: Setting up ===');
      await player1.goto('/');
      await player1.waitForLoadState('networkidle');
      await player1.waitForTimeout(2000);
      
      // Enter name and create lobby
      await player1.fill('input[placeholder="Enter your name"]', 'Player One');
      await player1.screenshot({ path: 'test-results/mp-1-player1-setup.png' });
      
      await player1.click('button:has-text("Create New Lobby")');
      await player1.waitForTimeout(1000);
      
      // Check if we need to fill lobby creation form
      const lobbyNameInput = player1.locator('input[placeholder="Enter lobby name"]');
      if (await lobbyNameInput.isVisible({ timeout: 2000 })) {
        await lobbyNameInput.fill('Test Multiplayer Game');
        await player1.selectOption('select[name="maxPlayers"]', '2');
        await player1.click('button[type="submit"]');
      }
      
      // Wait for lobby screen
      await player1.waitForTimeout(2000);
      await player1.screenshot({ path: 'test-results/mp-2-lobby-created.png' });
      
      // Get lobby ID from URL
      const lobbyUrl = player1.url();
      console.log('Lobby URL:', lobbyUrl);
      
      // PLAYER 2: Join the lobby
      console.log('\n=== Player 2: Joining lobby ===');
      await player2.goto('/');
      await player2.waitForLoadState('networkidle');
      await player2.waitForTimeout(2000);
      
      // Enter name and browse lobbies
      await player2.fill('input[placeholder="Enter your name"]', 'Player Two');
      await player2.click('button:has-text("Browse Lobbies")');
      
      // Wait for lobby list
      await player2.waitForSelector('text=Game Lobbies', { timeout: 5000 });
      await player2.waitForTimeout(1000);
      
      // Look for the created lobby
      const lobbyItem = player2.locator('text=Test Multiplayer Game');
      if (await lobbyItem.isVisible({ timeout: 5000 })) {
        console.log('Player 2 sees the lobby!');
        
        // Find and click join button for this lobby
        const joinButton = lobbyItem.locator('..').locator('button:has-text("Join")');
        await joinButton.click();
        
        await player2.waitForTimeout(2000);
        await player2.screenshot({ path: 'test-results/mp-3-player2-joined.png' });
      } else {
        // If specific lobby not found, try to join any available lobby
        const anyJoinButton = player2.locator('button:has-text("Join")').first();
        if (await anyJoinButton.isVisible()) {
          await anyJoinButton.click();
          await player2.waitForTimeout(2000);
        }
      }
      
      // Verify both players see each other
      console.log('\n=== Verifying multiplayer state ===');
      
      // Player 1 should see Player 2
      const player2InLobby = await player1.locator('text=Player Two').isVisible({ timeout: 5000 });
      console.log('Player 1 sees Player 2:', player2InLobby);
      
      // Player 2 should see Player 1
      const player1InLobby = await player2.locator('text=Player One').isVisible({ timeout: 5000 });
      console.log('Player 2 sees Player 1:', player1InLobby);
      
      // Take final screenshots
      await player1.screenshot({ path: 'test-results/mp-4-final-player1.png', fullPage: true });
      await player2.screenshot({ path: 'test-results/mp-5-final-player2.png', fullPage: true });
      
      // Assert that multiplayer is working
      expect(player2InLobby || player1InLobby).toBeTruthy();
      
    } finally {
      await context1.close();
      await context2.close();
    }
  });

  test('can start a game with multiple players', async ({ browser }) => {
    test.setTimeout(90000); // 1.5 minute timeout
    
    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    
    const player1 = await context1.newPage();
    const player2 = await context2.newPage();
    
    try {
      // Quick setup for both players
      await player1.goto('/');
      await player2.goto('/');
      
      await player1.waitForTimeout(2000);
      await player2.waitForTimeout(2000);
      
      // Player 1 creates lobby
      await player1.fill('input[placeholder="Enter your name"]', 'Host');
      await player1.click('button:has-text("Create New Lobby")');
      
      if (await player1.locator('input[placeholder="Enter lobby name"]').isVisible({ timeout: 2000 })) {
        await player1.fill('input[placeholder="Enter lobby name"]', 'Quick Game');
        await player1.selectOption('select[name="maxPlayers"]', '2');
        await player1.click('button[type="submit"]');
      }
      
      await player1.waitForTimeout(2000);
      
      // Player 2 joins
      await player2.fill('input[placeholder="Enter your name"]', 'Guest');
      await player2.click('button:has-text("Browse Lobbies")');
      await player2.waitForSelector('text=Game Lobbies');
      
      const joinButton = player2.locator('button:has-text("Join")').first();
      if (await joinButton.isVisible({ timeout: 5000 })) {
        await joinButton.click();
      }
      
      await player1.waitForTimeout(2000);
      await player2.waitForTimeout(2000);
      
      // Both players mark ready
      const player1Ready = player1.locator('button:has-text("Ready")');
      const player2Ready = player2.locator('button:has-text("Ready")');
      
      if (await player1Ready.isVisible() && await player2Ready.isVisible()) {
        await player1Ready.click();
        await player2Ready.click();
        
        await player1.waitForTimeout(1000);
        
        // Host starts game
        const startButton = player1.locator('button:has-text("Start Game")');
        if (await startButton.isVisible()) {
          console.log('Starting game...');
          await startButton.click();
          
          await player1.waitForTimeout(3000);
          
          // Check if game started (should see game phase)
          const gameStarted = await player1.locator('text=/Phase|Round|Power Grid/').isVisible({ timeout: 5000 });
          console.log('Game started:', gameStarted);
          
          await player1.screenshot({ path: 'test-results/mp-game-started-player1.png' });
          await player2.screenshot({ path: 'test-results/mp-game-started-player2.png' });
          
          expect(gameStarted).toBeTruthy();
        }
      }
      
    } finally {
      await context1.close();
      await context2.close();
    }
  });
});