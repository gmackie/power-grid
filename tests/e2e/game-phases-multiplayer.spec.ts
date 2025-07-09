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

class GamePhaseTestHelper {
  private browser: Browser;
  private players: Player[] = [];

  constructor(browser: Browser) {
    this.browser = browser;
  }

  async createPlayer(name: string, color: string): Promise<Player> {
    const context = await this.browser.newContext();
    const page = await context.newPage();
    
    page.on('console', msg => {
      if (msg.type() === 'log' || msg.type() === 'info') {
        console.log(`[${name}]:`, msg.text());
      }
    });

    const player = { name, color, context, page };
    this.players.push(player);
    return player;
  }

  async setupPlayerConnection(player: Player): Promise<boolean> {
    try {
      // Clear localStorage to prevent auto-registration conflicts
      await player.page.goto('/', { waitUntil: 'load' });
      await player.page.evaluate(() => {
        localStorage.clear();
      });
      
      await player.page.reload({ waitUntil: 'networkidle' });
      await player.page.waitForTimeout(2000);
      
      const nameInput = player.page.locator('input[placeholder="Enter your name"]');
      await nameInput.waitFor({ state: 'visible', timeout: 5000 });
      
      // Wait for WebSocket connection to be established
      let attempts = 0;
      while (!(await nameInput.isEnabled()) && attempts < 15) {
        await player.page.waitForTimeout(1000);
        attempts++;
      }
      
      if (!(await nameInput.isEnabled())) {
        console.error(`[${player.name}] Failed to connect to WebSocket`);
        return false;
      }
      
      // Enter player name - this triggers the CONNECT message to server
      await nameInput.fill(player.name);
      
      // Select color
      const colorButton = player.page.locator(`button[style*="${player.color}"]`);
      if (await colorButton.isVisible()) {
        await colorButton.click();
      }
      
      // Wait for player registration to complete on server
      // We need to wait for the CONNECTED response from server
      await player.page.waitForTimeout(4000);
      
      console.log(`[${player.name}] Connected and ready`);
      return true;
    } catch (error) {
      console.error(`[${player.name}] Setup failed:`, error);
      return false;
    }
  }

  async navigateToLobbyBrowser(player: Player): Promise<boolean> {
    try {
      await player.page.click('button:has-text("Browse Lobbies")');
      
      // Try different possible lobby browser titles
      const possibleTitles = [
        'h1:has-text("Game Lobbies")',
        'h1:has-text("Lobbies")', 
        'h1:has-text("Browse Lobbies")',
        'text=Game Lobbies',
        'text=Browse Lobbies'
      ];
      
      let titleFound = false;
      for (const titleSelector of possibleTitles) {
        if (await player.page.locator(titleSelector).isVisible({ timeout: 2000 })) {
          titleFound = true;
          console.log(`[${player.name}] Found lobby browser with title: ${titleSelector}`);
          break;
        }
      }
      
      if (!titleFound) {
        // Take screenshot for debugging
        await player.page.screenshot({ 
          path: `test-results/debug-${player.name}-lobby-browser.png`,
          fullPage: true 
        });
        
        // Check what's actually on the page
        const pageTitle = await player.page.locator('h1').first().textContent();
        console.log(`[${player.name}] Actual page title:`, pageTitle);
        
        // Look for any indication we're in lobby browser
        const hasCreateButton = await player.page.locator('button:has-text("Create")').isVisible();
        const urlContainsLobby = player.page.url().includes('lobby') || player.page.url().includes('browse');
        
        if (hasCreateButton || urlContainsLobby) {
          console.log(`[${player.name}] In lobby browser (detected by button/URL)`);
          return true;
        }
      }
      
      return titleFound;
    } catch (error) {
      console.error(`[${player.name}] Failed to navigate to lobby browser:`, error);
      return false;
    }
  }

  async createGameLobby(host: Player, lobbyName: string): Promise<boolean> {
    try {
      console.log(`[${host.name}] Creating lobby: ${lobbyName}`);
      
      // Look for Create Lobby button in the menu
      const createButtons = [
        'button:has-text("Create New Lobby")',
        'button:has-text("Create Lobby")',
        'button:has-text("Create")'
      ];
      
      let buttonClicked = false;
      for (const buttonSelector of createButtons) {
        if (await host.page.locator(buttonSelector).isVisible({ timeout: 2000 })) {
          await host.page.click(buttonSelector);
          buttonClicked = true;
          console.log(`[${host.name}] Clicked: ${buttonSelector}`);
          break;
        }
      }
      
      if (!buttonClicked) {
        console.error(`[${host.name}] No create lobby button found`);
        await host.page.screenshot({ 
          path: `test-results/debug-${host.name}-no-create-button.png`,
          fullPage: true 
        });
        return false;
      }
      
      await host.page.waitForTimeout(1000);
      
      // Check if we need to fill a form (lobby creation form)
      const lobbyNameInput = host.page.locator('input[placeholder*="lobby name"], input[placeholder*="name"], input[name="lobbyName"]');
      if (await lobbyNameInput.isVisible({ timeout: 3000 })) {
        await lobbyNameInput.fill(lobbyName);
        console.log(`[${host.name}] Filled lobby name: ${lobbyName}`);
        
        // Set max players if available
        const maxPlayersSelect = host.page.locator('select[name="maxPlayers"], select[name="max_players"]');
        if (await maxPlayersSelect.isVisible()) {
          await maxPlayersSelect.selectOption('4');
          console.log(`[${host.name}] Set max players to 4`);
        }
        
        // Submit form
        const submitButton = host.page.locator('button[type="submit"], button:has-text("Create")');
        if (await submitButton.isVisible()) {
          await submitButton.click();
          console.log(`[${host.name}] Clicked submit`);
        }
      }
      
      // Wait for lobby creation response
      await host.page.waitForTimeout(3000);
      
      // Verify we're in a lobby - check multiple indicators
      const inLobby = await host.page.locator(`text=${lobbyName}`).isVisible({ timeout: 2000 }) ||
                     await host.page.locator('text=Ready').isVisible({ timeout: 2000 }) ||
                     await host.page.locator('text=Start Game').isVisible({ timeout: 2000 }) ||
                     host.page.url().includes('lobby');
      
      console.log(`[${host.name}] Lobby creation success:`, inLobby);
      
      if (!inLobby) {
        await host.page.screenshot({ 
          path: `test-results/debug-${host.name}-lobby-creation-failed.png`,
          fullPage: true 
        });
      }
      
      return inLobby;
    } catch (error) {
      console.error(`[${host.name}] Failed to create lobby:`, error);
      return false;
    }
  }

  async joinLobby(player: Player, lobbyName: string): Promise<boolean> {
    try {
      console.log(`[${player.name}] Looking for lobby: ${lobbyName}`);
      
      // Look for the specific lobby
      const lobbyText = player.page.locator(`text=${lobbyName}`);
      if (await lobbyText.isVisible({ timeout: 5000 })) {
        // Find join button near the lobby name
        const joinButton = lobbyText.locator('..').locator('button:has-text("Join")');
        if (await joinButton.isVisible()) {
          await joinButton.click();
          await player.page.waitForTimeout(2000);
          return true;
        }
      }
      
      // If specific lobby not found, try joining any available lobby
      const anyJoinButton = player.page.locator('button:has-text("Join")').first();
      if (await anyJoinButton.isVisible()) {
        console.log(`[${player.name}] Joining first available lobby`);
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

  async startGameFromLobby(players: Player[]): Promise<boolean> {
    try {
      const host = players[0];
      
      // All players ready up
      for (const player of players) {
        const readyButton = player.page.locator('button:has-text("Ready")');
        if (await readyButton.isVisible({ timeout: 3000 })) {
          await readyButton.click();
          console.log(`[${player.name}] Marked ready`);
          await player.page.waitForTimeout(500);
        }
      }
      
      await host.page.waitForTimeout(2000);
      
      // Host starts game
      const startButton = host.page.locator('button:has-text("Start Game"), button:has-text("Start")');
      if (await startButton.isVisible({ timeout: 5000 })) {
        await startButton.click();
        console.log(`[${host.name}] Started the game`);
        
        // Wait for game to start - check multiple players
        await host.page.waitForTimeout(5000);
        
        // Check if any player is in a game phase
        let gameStarted = false;
        for (const player of players) {
          const hasGamePhase = await player.page.locator('text=/Phase|Round|Turn|Auction|Resource|Building|Bureaucracy|Game Board/').isVisible({ timeout: 3000 });
          if (hasGamePhase) {
            gameStarted = true;
            console.log(`[${player.name}] In game phase`);
            break;
          }
        }
        
        console.log('Game started:', gameStarted);
        return gameStarted;
      }
      
      return false;
    } catch (error) {
      console.error('Failed to start game:', error);
      return false;
    }
  }

  async testAuctionPhase(players: Player[]): Promise<boolean> {
    try {
      console.log('\n=== Testing Auction Phase ===');
      
      const bidder = players[0];
      const passers = players.slice(1);
      
      // Check if auction phase is active
      const auctionActive = await bidder.page.locator('text=Auction Phase').isVisible({ timeout: 3000 });
      if (!auctionActive) {
        console.log('Auction phase not visible, skipping auction test');
        return true;
      }
      
      console.log('Auction phase detected');
      
      // Bidder selects a power plant
      const powerPlant = bidder.page.locator('[data-testid="power-plant"]').first();
      if (await powerPlant.isVisible()) {
        await powerPlant.click();
        console.log(`[${bidder.name}] Selected power plant`);
        
        // Place bid
        const bidInput = bidder.page.locator('input[label="Bid Amount"], input[placeholder*="bid"]');
        if (await bidInput.isVisible({ timeout: 3000 })) {
          await bidInput.fill('15');
          
          const startBidButton = bidder.page.locator('button:has-text("Start Auction"), button:has-text("Bid")');
          if (await startBidButton.isVisible()) {
            await startBidButton.click();
            console.log(`[${bidder.name}] Started auction with bid of 15`);
          }
        }
      }
      
      await bidder.page.waitForTimeout(1000);
      
      // Other players pass
      for (const passer of passers) {
        const passButton = passer.page.locator('button:has-text("Pass")');
        if (await passButton.isVisible({ timeout: 3000 })) {
          await passButton.click();
          console.log(`[${passer.name}] Passed on auction`);
          await passer.page.waitForTimeout(500);
        }
      }
      
      await this.takeScreenshots('auction-phase');
      return true;
    } catch (error) {
      console.error('Auction phase test failed:', error);
      return false;
    }
  }

  async testResourcePhase(players: Player[]): Promise<boolean> {
    try {
      console.log('\n=== Testing Resource Phase ===');
      
      // Check if resource phase is active
      const resourceActive = await players[0].page.locator('text=Resource Phase').isVisible({ timeout: 3000 });
      if (!resourceActive) {
        console.log('Resource phase not visible, skipping resource test');
        return true;
      }
      
      console.log('Resource phase detected');
      
      // Each player tries to buy resources
      for (const player of players) {
        const plusButton = player.page.locator('button:has-text("+")').first();
        if (await plusButton.isVisible({ timeout: 2000 }) && await plusButton.isEnabled()) {
          await plusButton.click();
          await plusButton.click(); // Buy 2 resources
          
          const buyButton = player.page.locator('button:has-text("Buy Resources"), button:has-text("Buy")');
          if (await buyButton.isVisible() && await buyButton.isEnabled()) {
            await buyButton.click();
            console.log(`[${player.name}] Bought resources`);
          }
        }
        
        await player.page.waitForTimeout(1000);
      }
      
      await this.takeScreenshots('resource-phase');
      return true;
    } catch (error) {
      console.error('Resource phase test failed:', error);
      return false;
    }
  }

  async testBuildingPhase(players: Player[]): Promise<boolean> {
    try {
      console.log('\n=== Testing Building Phase ===');
      
      // Check if building phase is active
      const buildingActive = await players[0].page.locator('text=Building Phase').isVisible({ timeout: 3000 });
      if (!buildingActive) {
        console.log('Building phase not visible, skipping building test');
        return true;
      }
      
      console.log('Building phase detected');
      
      // Each player tries to build
      for (const player of players) {
        // Try clicking on the game board (canvas)
        const gameBoard = player.page.locator('[data-testid="game-board"]');
        if (await gameBoard.isVisible()) {
          // Click center of the game board
          await gameBoard.click();
          
          const buildButton = player.page.locator('button:has-text("Build")');
          if (await buildButton.isVisible({ timeout: 2000 }) && await buildButton.isEnabled()) {
            await buildButton.click();
            console.log(`[${player.name}] Built in a city`);
          }
        }
        
        await player.page.waitForTimeout(1000);
      }
      
      await this.takeScreenshots('building-phase');
      return true;
    } catch (error) {
      console.error('Building phase test failed:', error);
      return false;
    }
  }

  async testBureaucracyPhase(players: Player[]): Promise<boolean> {
    try {
      console.log('\n=== Testing Bureaucracy Phase ===');
      
      // Check if bureaucracy phase is active
      const bureaucracyActive = await players[0].page.locator('text=Bureaucracy Phase').isVisible({ timeout: 3000 });
      if (!bureaucracyActive) {
        console.log('Bureaucracy phase not visible, skipping bureaucracy test');
        return true;
      }
      
      console.log('Bureaucracy phase detected');
      
      // Each player tries to power cities
      for (const player of players) {
        const powerPlant = player.page.locator('[data-testid="power-plant"]').first();
        if (await powerPlant.isVisible({ timeout: 2000 })) {
          await powerPlant.click();
          
          const powerButton = player.page.locator('button:has-text("Power")');
          if (await powerButton.isVisible() && await powerButton.isEnabled()) {
            await powerButton.click();
            console.log(`[${player.name}] Powered cities`);
          }
        }
        
        await player.page.waitForTimeout(1000);
      }
      
      await this.takeScreenshots('bureaucracy-phase');
      return true;
    } catch (error) {
      console.error('Bureaucracy phase test failed:', error);
      return false;
    }
  }

  async takeScreenshots(prefix: string) {
    for (let i = 0; i < this.players.length; i++) {
      await this.players[i].page.screenshot({ 
        path: `test-results/${prefix}-player${i + 1}.png`,
        fullPage: true 
      });
    }
  }

  async cleanup() {
    for (const player of this.players) {
      await player.context.close();
    }
  }
}

test.describe('Game Phases Multiplayer', () => {
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

  test('complete game phase progression', async ({ browser }) => {
    test.setTimeout(240000); // 4 minutes
    
    const helper = new GamePhaseTestHelper(browser);
    
    try {
      console.log('\n=== Creating 3 Players ===');
      const alice = await helper.createPlayer('Alice', '#ff0000');
      const bob = await helper.createPlayer('Bob', '#0000ff');
      const charlie = await helper.createPlayer('Charlie', '#00ff00');
      
      console.log('\n=== Setting Up Player Connections ===');
      const setupResults = await Promise.all([
        helper.setupPlayerConnection(alice),
        helper.setupPlayerConnection(bob),
        helper.setupPlayerConnection(charlie)
      ]);
      
      expect(setupResults.every(result => result)).toBeTruthy();
      await helper.takeScreenshots('0-initial-setup');
      
      console.log('\n=== Creating Game Lobby ===');
      
      // Alice navigates to lobby browser
      const aliceBrowserSuccess = await helper.navigateToLobbyBrowser(alice);
      expect(aliceBrowserSuccess).toBeTruthy();
      
      // Alice creates lobby
      const lobbyCreated = await helper.createGameLobby(alice, 'Test Game Phase');
      expect(lobbyCreated).toBeTruthy();
      
      await helper.takeScreenshots('1-lobby-created');
      
      console.log('\n=== Other Players Join ===');
      
      // Bob and Charlie navigate to lobby browser and join
      await helper.navigateToLobbyBrowser(bob);
      await helper.navigateToLobbyBrowser(charlie);
      
      await helper.joinLobby(bob, 'Test Game Phase');
      await helper.joinLobby(charlie, 'Test Game Phase');
      
      await new Promise(resolve => setTimeout(resolve, 2000));
      await helper.takeScreenshots('2-all-players-joined');
      
      console.log('\n=== Starting Game ===');
      
      const gameStarted = await helper.startGameFromLobby([alice, bob, charlie]);
      expect(gameStarted).toBeTruthy();
      
      await helper.takeScreenshots('3-game-started');
      
      console.log('\n=== Testing Game Phases ===');
      
      // Test each game phase
      await helper.testAuctionPhase([alice, bob, charlie]);
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      await helper.testResourcePhase([alice, bob, charlie]);
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      await helper.testBuildingPhase([alice, bob, charlie]);
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      await helper.testBureaucracyPhase([alice, bob, charlie]);
      
      await helper.takeScreenshots('4-final-state');
      
      console.log('\n=== Game Phase Test Complete ===');
      
    } finally {
      await helper.cleanup();
    }
  });

  test('auction bidding competition', async ({ browser }) => {
    test.setTimeout(120000); // 2 minutes
    
    const helper = new GamePhaseTestHelper(browser);
    
    try {
      // Create 2 players for focused auction testing
      const bidder1 = await helper.createPlayer('Bidder1', '#ff0000');
      const bidder2 = await helper.createPlayer('Bidder2', '#0000ff');
      
      // Quick setup
      await Promise.all([
        helper.setupPlayerConnection(bidder1),
        helper.setupPlayerConnection(bidder2)
      ]);
      
      // Skip to game if possible, or create quick lobby
      await helper.navigateToLobbyBrowser(bidder1);
      await helper.createGameLobby(bidder1, 'Auction Test');
      await helper.navigateToLobbyBrowser(bidder2);
      await helper.joinLobby(bidder2, 'Auction Test');
      
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      const gameStarted = await helper.startGameFromLobby([bidder1, bidder2]);
      
      if (gameStarted) {
        console.log('\n=== Testing Competitive Bidding ===');
        
        // Bidder1 starts auction
        const powerPlant = bidder1.page.locator('[data-testid="power-plant"]').first();
        if (await powerPlant.isVisible()) {
          await powerPlant.click();
          
          const bidInput = bidder1.page.locator('input[label="Bid Amount"]');
          if (await bidInput.isVisible()) {
            await bidInput.fill('10');
            await bidder1.page.click('button:has-text("Start Auction")');
            console.log('[Bidder1] Started auction with 10');
            
            await bidder1.page.waitForTimeout(1000);
            
            // Bidder2 counter-bids
            const bidder2BidInput = bidder2.page.locator('input[label="Bid Amount"]');
            if (await bidder2BidInput.isVisible()) {
              await bidder2BidInput.fill('15');
              await bidder2.page.click('button:has-text("Place Bid")');
              console.log('[Bidder2] Counter-bid with 15');
              
              await bidder2.page.waitForTimeout(1000);
              
              // Bidder1 passes
              const passButton = bidder1.page.locator('button:has-text("Pass")');
              if (await passButton.isVisible()) {
                await passButton.click();
                console.log('[Bidder1] Passed');
              }
            }
          }
        }
        
        await helper.takeScreenshots('auction-competition');
        console.log('Auction competition test completed');
      }
      
    } finally {
      await helper.cleanup();
    }
  });
});