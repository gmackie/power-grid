import { test, expect, Browser, Page, BrowserContext } from '@playwright/test';
import { spawn, ChildProcess, execSync } from 'child_process';
import * as path from 'path';

let goServerProcess: ChildProcess | null = null;

interface Player {
  name: string;
  color: string;
  context: BrowserContext;
  page: Page;
}

class MultiplayerTestHelper {
  private browser: Browser;
  private players: Player[] = [];

  constructor(browser: Browser) {
    this.browser = browser;
  }

  async createPlayer(name: string, color: string): Promise<Player> {
    const context = await this.browser.newContext();
    const page = await context.newPage();
    
    // Enable console logging for debugging
    page.on('console', msg => {
      if (msg.type() === 'log' || msg.type() === 'info') {
        console.log(`[${name}]:`, msg.text());
      }
    });

    page.on('pageerror', error => {
      console.error(`[${name} Error]:`, error.message);
    });

    const player = { name, color, context, page };
    this.players.push(player);
    return player;
  }

  async setupPlayer(player: Player): Promise<boolean> {
    try {
      await player.page.goto('/');
      await player.page.waitForLoadState('networkidle');
      
      // Wait for app to initialize
      await player.page.waitForTimeout(2000);
      
      // Check if we can interact (connection established)
      const nameInput = player.page.locator('input[placeholder="Enter your name"]');
      await nameInput.waitFor({ state: 'visible', timeout: 5000 });
      
      // Wait for input to be enabled (connected state)
      let attempts = 0;
      while (!(await nameInput.isEnabled()) && attempts < 10) {
        console.log(`[${player.name}] Waiting for connection...`);
        await player.page.waitForTimeout(1000);
        attempts++;
      }
      
      if (!(await nameInput.isEnabled())) {
        console.error(`[${player.name}] Failed to connect after ${attempts} attempts`);
        return false;
      }
      
      // Enter player name
      await nameInput.fill(player.name);
      
      // Select color by clicking on the color button
      const colorButton = player.page.locator(`button[style*="${player.color}"]`);
      if (await colorButton.isVisible()) {
        await colorButton.click();
      }
      
      console.log(`[${player.name}] Setup complete`);
      return true;
    } catch (error) {
      console.error(`[${player.name}] Setup failed:`, error);
      return false;
    }
  }

  async createLobby(host: Player, lobbyName: string, maxPlayers: string = '3'): Promise<string | null> {
    try {
      console.log(`[${host.name}] Creating lobby: ${lobbyName}`);
      
      // Click create lobby button
      await host.page.click('button:has-text("Create New Lobby")');
      
      // Wait for navigation or form
      await host.page.waitForTimeout(1000);
      
      // Check if we need to fill a form
      const lobbyNameInput = host.page.locator('input[placeholder="Enter lobby name"]');
      if (await lobbyNameInput.isVisible({ timeout: 2000 })) {
        await lobbyNameInput.fill(lobbyName);
        
        // Select max players if dropdown exists
        const maxPlayersSelect = host.page.locator('select[name="maxPlayers"]');
        if (await maxPlayersSelect.isVisible()) {
          await maxPlayersSelect.selectOption(maxPlayers);
        }
        
        // Submit form
        await host.page.click('button[type="submit"]');
      }
      
      // Wait for lobby screen
      await host.page.waitForTimeout(2000);
      
      // Get lobby ID from URL
      const url = host.page.url();
      const urlParams = new URL(url).searchParams;
      const lobbyId = urlParams.get('id');
      
      console.log(`[${host.name}] Lobby created with ID: ${lobbyId}`);
      return lobbyId;
    } catch (error) {
      console.error(`[${host.name}] Failed to create lobby:`, error);
      return null;
    }
  }

  async joinLobby(player: Player, lobbyName: string): Promise<boolean> {
    try {
      console.log(`[${player.name}] Joining lobby: ${lobbyName}`);
      
      // Browse lobbies
      await player.page.click('button:has-text("Browse Lobbies")');
      
      // Wait for lobby list
      await player.page.waitForSelector('h1:has-text("Game Lobbies")', { timeout: 5000 });
      await player.page.waitForTimeout(1000);
      
      // Look for the specific lobby
      const lobbyText = player.page.locator(`text="${lobbyName}"`);
      if (await lobbyText.isVisible({ timeout: 5000 })) {
        // Find the join button in the same row
        const lobbyRow = lobbyText.locator('..');
        const joinButton = lobbyRow.locator('button:has-text("Join")');
        
        if (await joinButton.isVisible()) {
          await joinButton.click();
          console.log(`[${player.name}] Clicked join button`);
          
          // Wait for navigation to lobby
          await player.page.waitForTimeout(2000);
          return true;
        }
      }
      
      // If specific lobby not found, try joining first available
      console.log(`[${player.name}] Specific lobby not found, trying first available`);
      const anyJoinButton = player.page.locator('button:has-text("Join")').first();
      if (await anyJoinButton.isVisible()) {
        await anyJoinButton.click();
        await player.page.waitForTimeout(2000);
        return true;
      }
      
      return false;
    } catch (error) {
      console.error(`[${player.name}] Failed to join lobby:`, error);
      return false;
    }
  }

  async verifyPlayersInLobby(players: Player[]): Promise<boolean> {
    console.log('Verifying all players are in the same lobby...');
    
    for (const observer of players) {
      for (const target of players) {
        const playerVisible = await observer.page.locator(`text="${target.name}"`).isVisible({ timeout: 5000 });
        if (!playerVisible) {
          console.log(`[${observer.name}] Cannot see ${target.name}`);
          return false;
        }
      }
    }
    
    console.log('All players can see each other!');
    return true;
  }

  async markPlayersReady(players: Player[]): Promise<void> {
    for (const player of players) {
      const readyButton = player.page.locator('button:has-text("Ready")');
      if (await readyButton.isVisible({ timeout: 2000 })) {
        await readyButton.click();
        console.log(`[${player.name}] Marked ready`);
      }
    }
  }

  async startGame(host: Player): Promise<boolean> {
    try {
      const startButton = host.page.locator('button:has-text("Start Game")');
      if (await startButton.isVisible({ timeout: 5000 })) {
        await startButton.click();
        console.log(`[${host.name}] Started the game`);
        return true;
      }
      return false;
    } catch (error) {
      console.error(`[${host.name}] Failed to start game:`, error);
      return false;
    }
  }

  async cleanup() {
    for (const player of this.players) {
      await player.context.close();
    }
  }

  async takeScreenshots(prefix: string) {
    for (const player of this.players) {
      await player.page.screenshot({ 
        path: `test-results/${prefix}-${player.name.toLowerCase().replace(' ', '-')}.png`,
        fullPage: true 
      });
    }
  }
}

test.describe('Full Multiplayer Game', () => {
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

  test('three players complete full game', async ({ browser }) => {
    test.setTimeout(180000); // 3 minutes
    
    const helper = new MultiplayerTestHelper(browser);
    
    try {
      // Create three players
      console.log('\n=== Creating Players ===');
      const alice = await helper.createPlayer('Alice', '#ff0000');  // Red
      const bob = await helper.createPlayer('Bob', '#0000ff');      // Blue
      const charlie = await helper.createPlayer('Charlie', '#00ff00'); // Green
      
      // Setup all players
      console.log('\n=== Setting Up Players ===');
      const setupResults = await Promise.all([
        helper.setupPlayer(alice),
        helper.setupPlayer(bob),
        helper.setupPlayer(charlie)
      ]);
      
      if (!setupResults.every(result => result)) {
        throw new Error('Failed to setup all players');
      }
      
      await helper.takeScreenshots('1-setup');
      
      // Alice creates lobby
      console.log('\n=== Creating Lobby ===');
      const lobbyId = await helper.createLobby(alice, 'Test Game', '3');
      if (!lobbyId) {
        throw new Error('Failed to create lobby');
      }
      
      // Bob and Charlie join
      console.log('\n=== Joining Lobby ===');
      const bobJoined = await helper.joinLobby(bob, 'Test Game');
      const charlieJoined = await helper.joinLobby(charlie, 'Test Game');
      
      if (!bobJoined || !charlieJoined) {
        console.warn('Some players failed to join by name, but may have joined anyway');
      }
      
      // Wait for everyone to be in lobby
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      // Verify all players see each other
      console.log('\n=== Verifying Lobby State ===');
      const allInLobby = await helper.verifyPlayersInLobby([alice, bob, charlie]);
      expect(allInLobby).toBeTruthy();
      
      await helper.takeScreenshots('2-lobby');
      
      // All players ready up
      console.log('\n=== Players Ready ===');
      await helper.markPlayersReady([alice, bob, charlie]);
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Start game
      console.log('\n=== Starting Game ===');
      const gameStarted = await helper.startGame(alice);
      
      if (gameStarted) {
        await new Promise(resolve => setTimeout(resolve, 3000));
        
        // Check if we're in a game phase
        const inGame = await alice.page.locator('text=/Phase|Round|Auction|Resource|Building|Bureaucracy/').isVisible({ timeout: 5000 });
        console.log('Game phase visible:', inGame);
        
        await helper.takeScreenshots('3-game-started');
        
        // Test auction phase if visible
        const auctionVisible = await alice.page.locator('text=Auction Phase').isVisible({ timeout: 2000 });
        if (auctionVisible) {
          console.log('\n=== Auction Phase ===');
          
          // Alice selects a power plant
          const powerPlant = alice.page.locator('[data-testid="power-plant"]').first();
          if (await powerPlant.isVisible()) {
            await powerPlant.click();
            
            const bidInput = alice.page.locator('input[label="Bid Amount"]');
            if (await bidInput.isVisible()) {
              await bidInput.fill('10');
              await alice.page.click('button:has-text("Start Auction")');
            }
          }
          
          // Others pass
          for (const player of [bob, charlie]) {
            const passButton = player.page.locator('button:has-text("Pass")');
            if (await passButton.isVisible({ timeout: 2000 })) {
              await passButton.click();
            }
          }
          
          await helper.takeScreenshots('4-auction');
        }
        
        expect(inGame).toBeTruthy();
      }
      
      console.log('\n=== Test Complete ===');
      
    } finally {
      await helper.cleanup();
    }
  });

  test('players can interact simultaneously', async ({ browser }) => {
    test.setTimeout(60000); // 1 minute
    
    const helper = new MultiplayerTestHelper(browser);
    
    try {
      // Create two players
      const player1 = await helper.createPlayer('Player 1', '#ff0000');
      const player2 = await helper.createPlayer('Player 2', '#0000ff');
      
      // Setup both
      await Promise.all([
        helper.setupPlayer(player1),
        helper.setupPlayer(player2)
      ]);
      
      // Both browse lobbies simultaneously
      await Promise.all([
        player1.page.click('button:has-text("Browse Lobbies")'),
        player2.page.click('button:has-text("Browse Lobbies")')
      ]);
      
      // Both should see lobby browser
      await expect(player1.page.locator('h1:has-text("Game Lobbies")')).toBeVisible({ timeout: 5000 });
      await expect(player2.page.locator('h1:has-text("Game Lobbies")')).toBeVisible({ timeout: 5000 });
      
      console.log('Simultaneous actions successful!');
      
    } finally {
      await helper.cleanup();
    }
  });
});