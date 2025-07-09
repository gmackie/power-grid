import { test, expect, Browser, BrowserContext, Page } from '@playwright/test';
import { spawn, ChildProcess } from 'child_process';
import * as path from 'path';

let goServerProcess: ChildProcess | null = null;

interface PlayerSession {
  context: BrowserContext;
  page: Page;
  name: string;
  color: string;
}

test.describe('Multiplayer Full Game Test', () => {
  let browser: Browser;
  let player1: PlayerSession;
  let player2: PlayerSession;
  let player3: PlayerSession;

  test.beforeAll(async ({ browser: testBrowser }) => {
    browser = testBrowser;
    
    // Start Go server
    console.log('Starting Go server...');
    const goServerPath = path.join(process.cwd(), '..', 'go_server');
    
    goServerProcess = spawn('go', ['run', 'cmd/server/main.go'], {
      cwd: goServerPath,
      env: { ...process.env, PORT: '4080' },
      stdio: ['ignore', 'pipe', 'pipe']
    });

    goServerProcess.stdout?.on('data', (data) => {
      console.log(`[Server]: ${data.toString().trim()}`);
    });

    goServerProcess.stderr?.on('data', (data) => {
      console.error(`[Server Error]: ${data.toString().trim()}`);
    });

    // Wait for server to start
    await new Promise<void>((resolve) => {
      const checkStartup = (data: Buffer) => {
        if (data.toString().includes('Starting Power Grid Game Server')) {
          console.log('Server is ready!');
          resolve();
        }
      };
      goServerProcess!.stdout?.on('data', checkStartup);
      goServerProcess!.stderr?.on('data', checkStartup);
    });

    await new Promise(resolve => setTimeout(resolve, 1000));
  });

  test.afterAll(async () => {
    // Clean up all browser contexts
    if (player1?.context) await player1.context.close();
    if (player2?.context) await player2.context.close();
    if (player3?.context) await player3.context.close();
    
    // Stop server
    if (goServerProcess) {
      console.log('Stopping server...');
      goServerProcess.kill('SIGTERM');
      await new Promise(resolve => setTimeout(resolve, 2000));
    }
  });

  async function createPlayer(name: string, color: string): Promise<PlayerSession> {
    const context = await browser.newContext();
    const page = await context.newPage();
    
    // Enable console logging for debugging
    page.on('console', msg => {
      if (msg.type() === 'log' || msg.type() === 'info') {
        console.log(`[${name}]:`, msg.text());
      }
    });
    
    return { context, page, name, color };
  }

  async function setupPlayer(player: PlayerSession) {
    await player.page.goto('/');
    await player.page.waitForLoadState('networkidle');
    
    // Wait for connection
    await player.page.waitForTimeout(2000);
    
    // Enter player name
    await player.page.fill('input[placeholder="Enter your name"]', player.name);
    
    // Select color
    await player.page.click(`button[title][style*="${player.color}"]`);
    
    console.log(`${player.name} setup complete`);
  }

  test('full multiplayer game flow', async () => {
    test.setTimeout(300000); // 5 minutes for full game
    
    // Create three players
    player1 = await createPlayer('Alice', '#ff0000'); // Red
    player2 = await createPlayer('Bob', '#0000ff');   // Blue
    player3 = await createPlayer('Charlie', '#00ff00'); // Green
    
    // Setup all players
    await setupPlayer(player1);
    await setupPlayer(player2);
    await setupPlayer(player3);
    
    // STEP 1: Create Lobby (Player 1)
    console.log('\n=== STEP 1: Creating Lobby ===');
    await player1.page.click('button:has-text("Create New Lobby")');
    await player1.page.waitForTimeout(1000);
    
    // Should show create lobby form
    await player1.page.fill('input[placeholder="Enter lobby name"]', 'Test Game');
    await player1.page.selectOption('select[name="maxPlayers"]', '3');
    await player1.page.click('button[type="submit"]');
    
    // Wait for lobby creation
    await player1.page.waitForURL(/\/lobby/, { timeout: 5000 });
    
    // Get lobby ID from URL
    const lobbyUrl = player1.page.url();
    const lobbyId = new URL(lobbyUrl).searchParams.get('id');
    console.log('Lobby created with ID:', lobbyId);
    
    // Take screenshot
    await player1.page.screenshot({ 
      path: 'test-results/multiplayer-1-lobby-created.png',
      fullPage: true 
    });
    
    // STEP 2: Other players join lobby
    console.log('\n=== STEP 2: Players Joining Lobby ===');
    
    // Player 2 joins
    await player2.page.click('button:has-text("Browse Lobbies")');
    await player2.page.waitForSelector('text=Game Lobbies');
    
    // Look for the created lobby
    await player2.page.waitForSelector('text=Test Game', { timeout: 5000 });
    await player2.page.click('button:has-text("Join")');
    
    // Player 3 joins
    await player3.page.click('button:has-text("Browse Lobbies")');
    await player3.page.waitForSelector('text=Game Lobbies');
    await player3.page.waitForSelector('text=Test Game', { timeout: 5000 });
    await player3.page.click('button:has-text("Join")');
    
    // Wait for all players to be in lobby
    await player1.page.waitForTimeout(2000);
    
    // Verify all players see each other
    for (const player of [player1, player2, player3]) {
      await expect(player.page.locator('text=Alice')).toBeVisible();
      await expect(player.page.locator('text=Bob')).toBeVisible();
      await expect(player.page.locator('text=Charlie')).toBeVisible();
    }
    
    await player1.page.screenshot({ 
      path: 'test-results/multiplayer-2-lobby-full.png',
      fullPage: true 
    });
    
    // STEP 3: Start Game (Host)
    console.log('\n=== STEP 3: Starting Game ===');
    
    // All players mark ready
    await player1.page.click('button:has-text("Ready")');
    await player2.page.click('button:has-text("Ready")');
    await player3.page.click('button:has-text("Ready")');
    
    await player1.page.waitForTimeout(1000);
    
    // Host starts game
    const startButton = player1.page.locator('button:has-text("Start Game")');
    if (await startButton.isVisible()) {
      await startButton.click();
    }
    
    // Wait for game to start
    await player1.page.waitForTimeout(3000);
    
    // All players should transition to game screen
    for (const player of [player1, player2, player3]) {
      await expect(player.page.locator('text=Power Grid')).toBeVisible();
    }
    
    // STEP 4: Auction Phase
    console.log('\n=== STEP 4: Auction Phase ===');
    
    // Check if we're in auction phase
    const auctionPhaseVisible = await player1.page.locator('text=Auction Phase').isVisible();
    if (auctionPhaseVisible) {
      console.log('Auction phase started');
      
      // Player 1 selects a power plant
      const firstPlant = player1.page.locator('[data-testid="power-plant"]').first();
      if (await firstPlant.isVisible()) {
        await firstPlant.click();
        await player1.page.fill('input[label="Bid Amount"]', '15');
        await player1.page.click('button:has-text("Start Auction")');
      }
      
      await player1.page.screenshot({ 
        path: 'test-results/multiplayer-4-auction-phase.png',
        fullPage: true 
      });
      
      // Other players pass or bid
      if (await player2.page.locator('button:has-text("Pass")').isVisible()) {
        await player2.page.click('button:has-text("Pass")');
      }
      
      if (await player3.page.locator('button:has-text("Pass")').isVisible()) {
        await player3.page.click('button:has-text("Pass")');
      }
    }
    
    // STEP 5: Resource Phase
    console.log('\n=== STEP 5: Resource Phase ===');
    await player1.page.waitForTimeout(2000);
    
    const resourcePhaseVisible = await player1.page.locator('text=Resource Phase').isVisible();
    if (resourcePhaseVisible) {
      console.log('Resource phase started');
      
      // Try to buy some resources
      const plusButton = player1.page.locator('button').filter({ hasText: '+' }).first();
      if (await plusButton.isVisible() && await plusButton.isEnabled()) {
        await plusButton.click();
        await plusButton.click();
        
        const buyButton = player1.page.locator('button:has-text("Buy Resources")');
        if (await buyButton.isVisible() && await buyButton.isEnabled()) {
          await buyButton.click();
        }
      }
      
      await player1.page.screenshot({ 
        path: 'test-results/multiplayer-5-resource-phase.png',
        fullPage: true 
      });
    }
    
    // STEP 6: Building Phase
    console.log('\n=== STEP 6: Building Phase ===');
    await player1.page.waitForTimeout(2000);
    
    const buildingPhaseVisible = await player1.page.locator('text=Building Phase').isVisible();
    if (buildingPhaseVisible) {
      console.log('Building phase started');
      
      // Try to build in a city
      const firstCity = player1.page.locator('[data-testid="city"]').first();
      if (await firstCity.isVisible()) {
        await firstCity.click();
        
        const buildButton = player1.page.locator('button:has-text("Build in")');
        if (await buildButton.isVisible() && await buildButton.isEnabled()) {
          await buildButton.click();
        }
      }
      
      await player1.page.screenshot({ 
        path: 'test-results/multiplayer-6-building-phase.png',
        fullPage: true 
      });
    }
    
    // STEP 7: Bureaucracy Phase
    console.log('\n=== STEP 7: Bureaucracy Phase ===');
    await player1.page.waitForTimeout(2000);
    
    const bureaucracyPhaseVisible = await player1.page.locator('text=Bureaucracy Phase').isVisible();
    if (bureaucracyPhaseVisible) {
      console.log('Bureaucracy phase started');
      
      // Try to power cities
      const powerPlant = player1.page.locator('[data-testid="power-plant"]').first();
      if (await powerPlant.isVisible()) {
        await powerPlant.click();
        
        const powerButton = player1.page.locator('button:has-text("Power")');
        if (await powerButton.isVisible() && await powerButton.isEnabled()) {
          await powerButton.click();
        }
      }
      
      await player1.page.screenshot({ 
        path: 'test-results/multiplayer-7-bureaucracy-phase.png',
        fullPage: true 
      });
    }
    
    // Final state
    console.log('\n=== STEP 8: Game State ===');
    await player1.page.waitForTimeout(2000);
    
    // Take final screenshots from all players
    await player1.page.screenshot({ 
      path: 'test-results/multiplayer-final-player1.png',
      fullPage: true 
    });
    await player2.page.screenshot({ 
      path: 'test-results/multiplayer-final-player2.png',
      fullPage: true 
    });
    await player3.page.screenshot({ 
      path: 'test-results/multiplayer-final-player3.png',
      fullPage: true 
    });
    
    console.log('\n=== Test Complete ===');
  });

  test('concurrent player actions', async () => {
    // This test verifies that multiple players can perform actions simultaneously
    
    // Create two players
    player1 = await createPlayer('Player 1', '#ff0000');
    player2 = await createPlayer('Player 2', '#0000ff');
    
    await setupPlayer(player1);
    await setupPlayer(player2);
    
    // Both browse lobbies at the same time
    await Promise.all([
      player1.page.click('button:has-text("Browse Lobbies")'),
      player2.page.click('button:has-text("Browse Lobbies")')
    ]);
    
    // Both should see the lobby browser
    await expect(player1.page.locator('text=Game Lobbies')).toBeVisible();
    await expect(player2.page.locator('text=Game Lobbies')).toBeVisible();
    
    console.log('Concurrent actions test passed');
  });
});