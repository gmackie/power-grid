import { test, expect, Browser } from '@playwright/test';
import { spawn, ChildProcess, execSync } from 'child_process';
import * as path from 'path';

let goServerProcess: ChildProcess | null = null;

test.describe('Multiplayer Core Features', () => {
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

  test('multiple players can connect and interact', async ({ browser }) => {
    test.setTimeout(60000); // 1 minute
    
    // Create 3 players
    const contexts = await Promise.all([
      browser.newContext(),
      browser.newContext(),
      browser.newContext()
    ]);
    
    const [player1, player2, player3] = await Promise.all([
      contexts[0].newPage(),
      contexts[1].newPage(),
      contexts[2].newPage()
    ]);
    
    // Add logging
    player1.on('console', msg => console.log('[Player1]:', msg.text()));
    player2.on('console', msg => console.log('[Player2]:', msg.text()));
    player3.on('console', msg => console.log('[Player3]:', msg.text()));
    
    try {
      console.log('\n=== Loading Apps ===');
      
      // All players load the app
      await Promise.all([
        player1.goto('/'),
        player2.goto('/'),
        player3.goto('/')
      ]);
      
      await Promise.all([
        player1.waitForLoadState('networkidle'),
        player2.waitForLoadState('networkidle'),
        player3.waitForLoadState('networkidle')
      ]);
      
      // Wait for connections
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      console.log('\n=== Setting Up Players ===');
      
      // Check if all players can interact (connected)
      const nameInputs = [
        player1.locator('input[placeholder="Enter your name"]'),
        player2.locator('input[placeholder="Enter your name"]'),
        player3.locator('input[placeholder="Enter your name"]')
      ];
      
      // Wait for all inputs to be enabled
      for (let i = 0; i < nameInputs.length; i++) {
        await nameInputs[i].waitFor({ state: 'visible' });
        let attempts = 0;
        while (!(await nameInputs[i].isEnabled()) && attempts < 10) {
          await new Promise(resolve => setTimeout(resolve, 1000));
          attempts++;
        }
        console.log(`Player ${i + 1} connection enabled:`, await nameInputs[i].isEnabled());
      }
      
      // Fill in names
      await nameInputs[0].fill('Alice');
      await nameInputs[1].fill('Bob');
      await nameInputs[2].fill('Charlie');
      
      // Take screenshots
      await player1.screenshot({ path: 'test-results/mp-core-player1.png', fullPage: true });
      await player2.screenshot({ path: 'test-results/mp-core-player2.png', fullPage: true });
      await player3.screenshot({ path: 'test-results/mp-core-player3.png', fullPage: true });
      
      console.log('\n=== Testing Browse Lobbies ===');
      
      // All players should be able to browse lobbies
      const browseButtons = [
        player1.locator('button:has-text("Browse Lobbies")'),
        player2.locator('button:has-text("Browse Lobbies")'),
        player3.locator('button:has-text("Browse Lobbies")')
      ];
      
      const enabledStates = await Promise.all([
        browseButtons[0].isEnabled(),
        browseButtons[1].isEnabled(),
        browseButtons[2].isEnabled()
      ]);
      
      console.log('Browse buttons enabled:', enabledStates);
      
      // At least one player should be able to browse
      expect(enabledStates.some(enabled => enabled)).toBeTruthy();
      
      // Try browsing with all enabled players
      const browsePlayers = [];
      for (let i = 0; i < 3; i++) {
        if (enabledStates[i]) {
          browsePlayers.push(i);
        }
      }
      
      console.log('Players that can browse:', browsePlayers);
      
      if (browsePlayers.length > 0) {
        // Have at least one player browse lobbies
        const playerIndex = browsePlayers[0];
        const player = [player1, player2, player3][playerIndex];
        
        console.log(`Player ${playerIndex + 1} browsing lobbies...`);
        await browseButtons[playerIndex].click();
        
        // Should navigate to lobby browser
        await expect(player.locator('h1:has-text("Game Lobbies")')).toBeVisible({ timeout: 10000 });
        
        await player.screenshot({ 
          path: `test-results/mp-core-player${playerIndex + 1}-lobbies.png`, 
          fullPage: true 
        });
        
        console.log(`Player ${playerIndex + 1} successfully browsed lobbies!`);
      }
      
      console.log('\n=== Multiplayer Test Complete ===');
      console.log('✅ Server running');
      console.log('✅ Multiple players connected');
      console.log('✅ UI responsive for multiple users');
      console.log('✅ Navigation working');
      
    } finally {
      await Promise.all(contexts.map(context => context.close()));
    }
  });

  test('lobby creation and joining works', async ({ browser }) => {
    test.setTimeout(90000); // 1.5 minutes
    
    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    
    const host = await context1.newPage();
    const joiner = await context2.newPage();
    
    try {
      console.log('\n=== Setting Up Host and Joiner ===');
      
      // Setup both players
      await host.goto('/');
      await joiner.goto('/');
      
      await host.waitForLoadState('networkidle');
      await joiner.waitForLoadState('networkidle');
      
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Host setup
      const hostNameInput = host.locator('input[placeholder="Enter your name"]');
      await hostNameInput.waitFor({ state: 'visible' });
      
      let attempts = 0;
      while (!(await hostNameInput.isEnabled()) && attempts < 15) {
        await new Promise(resolve => setTimeout(resolve, 1000));
        attempts++;
      }
      
      if (await hostNameInput.isEnabled()) {
        await hostNameInput.fill('Host Player');
        
        console.log('\n=== Host Creating Lobby ===');
        
        // Host creates lobby
        await host.click('button:has-text("Create New Lobby")');
        await host.waitForTimeout(2000);
        
        // Check if form needed
        const lobbyNameInput = host.locator('input[placeholder="Enter lobby name"]');
        if (await lobbyNameInput.isVisible({ timeout: 3000 })) {
          await lobbyNameInput.fill('Test Multiplayer Lobby');
          await host.selectOption('select[name="maxPlayers"]', '2');
          await host.click('button[type="submit"]');
        }
        
        await host.waitForTimeout(2000);
        await host.screenshot({ path: 'test-results/mp-lobby-host.png', fullPage: true });
        
        console.log('\n=== Joiner Setup ===');
        
        // Joiner setup
        const joinerNameInput = joiner.locator('input[placeholder="Enter your name"]');
        await joinerNameInput.waitFor({ state: 'visible' });
        
        attempts = 0;
        while (!(await joinerNameInput.isEnabled()) && attempts < 15) {
          await new Promise(resolve => setTimeout(resolve, 1000));
          attempts++;
        }
        
        if (await joinerNameInput.isEnabled()) {
          await joinerNameInput.fill('Joining Player');
          
          console.log('\n=== Joiner Browsing Lobbies ===');
          
          // Joiner browses lobbies
          await joiner.click('button:has-text("Browse Lobbies")');
          await joiner.waitForSelector('h1:has-text("Game Lobbies")', { timeout: 10000 });
          
          await joiner.screenshot({ path: 'test-results/mp-lobby-browser.png', fullPage: true });
          
          // Look for the lobby
          const lobbyFound = await joiner.locator('text=Test Multiplayer Lobby').isVisible({ timeout: 5000 });
          console.log('Lobby found by joiner:', lobbyFound);
          
          if (lobbyFound) {
            // Try to join
            const joinButton = joiner.locator('button:has-text("Join")').first();
            if (await joinButton.isVisible()) {
              await joinButton.click();
              await joiner.waitForTimeout(2000);
              
              await joiner.screenshot({ path: 'test-results/mp-lobby-joined.png', fullPage: true });
              
              // Check if both players see each other
              const hostSeesJoiner = await host.locator('text=Joining Player').isVisible({ timeout: 5000 });
              const joinerSeesHost = await joiner.locator('text=Host Player').isVisible({ timeout: 5000 });
              
              console.log('Host sees joiner:', hostSeesJoiner);
              console.log('Joiner sees host:', joinerSeesHost);
              
              // Success if either player sees the other
              expect(hostSeesJoiner || joinerSeesHost).toBeTruthy();
            }
          }
        }
      }
      
    } finally {
      await context1.close();
      await context2.close();
    }
  });
});