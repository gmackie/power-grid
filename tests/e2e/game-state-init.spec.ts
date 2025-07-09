import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';
import path from 'path';

test.describe.serial('Game State Initialization Test', () => {
  let lobbyName: string;

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

  test('should initialize game state from lobby data', async ({ browser }) => {
    console.log('=== Testing Game State Initialization ===');
    
    // Generate unique lobby name
    lobbyName = `StateTest_${Date.now()}`;
    console.log(`Using lobby name: ${lobbyName}`);

    // Create contexts for two players
    const aliceContext = await browser.newContext();
    const bobContext = await browser.newContext();
    
    const alicePage = await aliceContext.newPage();
    const bobPage = await bobContext.newPage();

    // Track console messages for game state
    const aliceMessages: string[] = [];
    alicePage.on('console', msg => {
      const text = msg.text();
      if (text.includes('Creating initial game state') || text.includes('game state') || text.includes('Game state')) {
        console.log(`[Alice]: ${text}`);
        aliceMessages.push(text);
      }
    });

    // Navigate to app
    await alicePage.goto('http://localhost:5173');
    await bobPage.goto('http://localhost:5173');
    
    // Wait for app to load
    await expect(alicePage.locator('h1:has-text("Power Grid")')).toBeVisible({ timeout: 10000 });
    await expect(bobPage.locator('h1:has-text("Power Grid")')).toBeVisible({ timeout: 10000 });

    // === ALICE CREATES LOBBY ===
    console.log('=== Alice Creating Lobby ===');
    
    // Alice enters name and creates lobby
    await alicePage.fill('input[placeholder="Enter your name"]', 'Alice');
    await alicePage.waitForTimeout(500);
    await alicePage.click('button:has-text("Create New Lobby")');
    await alicePage.waitForTimeout(1000);
    
    // Fill lobby details
    const lobbyNameInput = alicePage.locator('input[placeholder*="lobby name"]').first();
    await lobbyNameInput.fill(lobbyName);
    
    // Set to 2 players for faster testing
    const maxPlayersSelect = alicePage.locator('select[name="maxPlayers"]');
    if (await maxPlayersSelect.isVisible({ timeout: 1000 })) {
      await maxPlayersSelect.selectOption('2');
    }
    
    // Submit
    await alicePage.click('button[type="submit"], button:has-text("Create")');
    await alicePage.waitForTimeout(2000);
    
    // Verify Alice is in lobby
    const aliceInLobby = await alicePage.locator(`text=${lobbyName}`).isVisible({ timeout: 5000 });
    expect(aliceInLobby).toBeTruthy();

    // === BOB JOINS LOBBY ===
    console.log('=== Bob Joining Lobby ===');
    
    // Bob enters name
    await bobPage.fill('input[placeholder="Enter your name"]', 'Bob');
    await bobPage.waitForTimeout(500);
    
    // Bob browses lobbies
    await bobPage.click('button:has-text("Browse Lobbies")');
    await bobPage.waitForSelector('h1:has-text("Browse Lobbies")', { timeout: 5000 });
    await bobPage.waitForTimeout(2000);
    
    // Find and join lobby
    const lobbyCard = bobPage.locator(`[data-testid="lobby-card"]:has-text("${lobbyName}")`);
    await expect(lobbyCard).toBeVisible({ timeout: 5000 });
    await lobbyCard.locator('button:has-text("Join")').click();
    await bobPage.waitForTimeout(2000);
    
    // Verify Bob is in lobby
    const bobInLobby = await bobPage.locator(`h1:has-text("${lobbyName}")`).isVisible({ timeout: 5000 });
    expect(bobInLobby).toBeTruthy();

    // === BOTH PLAYERS READY UP ===
    console.log('=== Players Getting Ready ===');
    
    // Bob marks ready
    const bobReadyButton = bobPage.locator('button:has-text("Not Ready")');
    if (await bobReadyButton.isVisible({ timeout: 2000 })) {
      await bobReadyButton.click();
      console.log('[Bob] Clicked ready');
      await bobPage.waitForTimeout(1000);
    }

    // === ALICE STARTS GAME ===
    console.log('=== Alice Starting Game ===');
    
    // Alice clicks start game
    const startButton = alicePage.locator('button:has-text("Start Game")');
    await expect(startButton).toBeVisible({ timeout: 5000 });
    await expect(startButton).toBeEnabled({ timeout: 5000 });
    
    console.log('[Alice] Clicking start game...');
    await startButton.click();
    
    // Wait for game to start and state to initialize
    await alicePage.waitForTimeout(5000);
    
    // Check if both players navigated to game screen
    console.log('=== Checking Game State Initialization ===');
    
    // Look for game screen elements
    const aliceInGame = await alicePage.locator('text=/Round \\d.*Phase/').isVisible({ timeout: 10000 });
    const bobInGame = await bobPage.locator('text=/Round \\d.*Phase/').isVisible({ timeout: 10000 });
    
    console.log('[Alice] In game screen:', aliceInGame);
    console.log('[Bob] In game screen:', bobInGame);
    
    // Check for auction phase (should be first phase)
    const aliceAuctionPhase = await alicePage.locator('text=auction Phase').isVisible({ timeout: 2000 });
    console.log('[Alice] Auction phase visible:', aliceAuctionPhase);
    
    // Check for player data in game
    const alicePlayerCard = await alicePage.locator('text=Alice (You)').isVisible({ timeout: 2000 });
    const bobPlayerCard = await alicePage.locator('text=Bob').isVisible({ timeout: 2000 });
    
    console.log('[Alice] Alice player card visible:', alicePlayerCard);
    console.log('[Alice] Bob player card visible:', bobPlayerCard);
    
    // Check for money display (should be $50 starting money)
    const moneyDisplay = await alicePage.locator('text=$50').isVisible({ timeout: 2000 });
    console.log('[Alice] Starting money display visible:', moneyDisplay);
    
    // Take screenshots
    await alicePage.screenshot({ path: 'test-results/alice-game-state-init.png', fullPage: true });
    await bobPage.screenshot({ path: 'test-results/bob-game-state-init.png', fullPage: true });
    
    // Log captured messages
    console.log('\n=== Alice Game State Messages ===');
    aliceMessages.forEach(msg => console.log(msg));
    
    // Assertions
    expect(aliceInGame).toBeTruthy();
    expect(bobInGame).toBeTruthy();
    expect(aliceAuctionPhase).toBeTruthy();
    expect(alicePlayerCard).toBeTruthy();
    expect(bobPlayerCard).toBeTruthy();
    
    console.log('=== Game State Initialization Test Completed ===');
    
    // Clean up
    await aliceContext.close();
    await bobContext.close();
  });
});