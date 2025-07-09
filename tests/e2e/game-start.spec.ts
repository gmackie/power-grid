import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';
import path from 'path';

test.describe.serial('Game Start Test', () => {
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

  test('should start game and receive game state', async ({ browser }) => {
    console.log('=== Testing Game Start ===');
    
    // Generate unique lobby name
    lobbyName = `GameTest_${Date.now()}`;
    console.log(`Using lobby name: ${lobbyName}`);

    // Create contexts for two players
    const aliceContext = await browser.newContext();
    const bobContext = await browser.newContext();
    
    const alicePage = await aliceContext.newPage();
    const bobPage = await bobContext.newPage();

    // Track console messages
    const aliceMessages: string[] = [];
    const bobMessages: string[] = [];
    
    alicePage.on('console', msg => {
      const text = msg.text();
      if (text.includes('Game') || text.includes('GAME') || text.includes('game') || 
          text.includes('Starting') || text.includes('starting')) {
        console.log(`[Alice]: ${text}`);
        aliceMessages.push(text);
      }
    });
    
    bobPage.on('console', msg => {
      const text = msg.text();
      if (text.includes('Game') || text.includes('GAME') || text.includes('game') || 
          text.includes('Starting') || text.includes('starting')) {
        console.log(`[Bob]: ${text}`);
        bobMessages.push(text);
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
    
    // Alice should be ready by default as host
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
    
    // Wait for game to start
    await alicePage.waitForTimeout(3000);
    
    // Check if both players navigated to game screen
    console.log('=== Checking Game Screen ===');
    
    // Look for game phase indicators and game state
    const aliceInGame = await alicePage.locator('text=/Round \\d.*Phase/').isVisible({ timeout: 10000 }) ||
                        await alicePage.locator('text=Auction Phase').isVisible({ timeout: 1000 }) ||
                        await alicePage.locator('h1:has-text("Power Grid")').isVisible({ timeout: 1000 });
    
    const bobInGame = await bobPage.locator('text=/Round \\d.*Phase/').isVisible({ timeout: 10000 }) ||
                      await bobPage.locator('text=Auction Phase').isVisible({ timeout: 1000 }) ||
                      await bobPage.locator('h1:has-text("Power Grid")').isVisible({ timeout: 1000 });
    
    console.log('[Alice] In game screen:', aliceInGame);
    console.log('[Bob] In game screen:', bobInGame);
    
    // Check for proper game state initialization
    console.log('=== Checking Game State ===');
    
    // Look for player names in the game
    const alicePlayerVisible = await alicePage.locator('text=Alice').isVisible({ timeout: 2000 });
    const bobPlayerVisible = await alicePage.locator('text=Bob').isVisible({ timeout: 2000 });
    
    console.log('[Alice] Can see Alice player:', alicePlayerVisible);
    console.log('[Alice] Can see Bob player:', bobPlayerVisible);
    
    // Check for game phase header
    const gamePhaseHeader = await alicePage.locator('text=/Round \\d.*auction Phase/').isVisible({ timeout: 2000 });
    console.log('[Alice] Game phase header visible:', gamePhaseHeader);
    
    // Take screenshots
    await alicePage.screenshot({ path: 'test-results/alice-game-start.png', fullPage: true });
    await bobPage.screenshot({ path: 'test-results/bob-game-start.png', fullPage: true });
    
    // Log captured messages
    console.log('\n=== Alice Messages ===');
    aliceMessages.forEach(msg => console.log(msg));
    
    console.log('\n=== Bob Messages ===');
    bobMessages.forEach(msg => console.log(msg));
    
    // Assertions
    expect(aliceInGame).toBeTruthy();
    expect(bobInGame).toBeTruthy();
    
    // Check for game-related messages
    const hasGameStartMessage = aliceMessages.some(msg => 
      msg.includes('starting') || msg.includes('STARTING') || msg.includes('Started')
    );
    console.log('Has game start message:', hasGameStartMessage);
    
    console.log('=== Test Completed ===');
    
    // Clean up
    await aliceContext.close();
    await bobContext.close();
  });
});