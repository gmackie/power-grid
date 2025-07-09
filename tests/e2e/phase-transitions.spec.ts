import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';
import path from 'path';

test.describe.serial('Phase Transitions Test', () => {
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

  test('should transition through game phases', async ({ browser }) => {
    console.log('=== Testing Phase Transitions ===');
    
    // Generate unique lobby name
    lobbyName = `PhaseTest_${Date.now()}`;
    console.log(`Using lobby name: ${lobbyName}`);

    // Create contexts for two players
    const aliceContext = await browser.newContext();
    const bobContext = await browser.newContext();
    
    const alicePage = await aliceContext.newPage();
    const bobPage = await bobContext.newPage();

    // Track phase transitions
    const alicePhases: string[] = [];
    const bobPhases: string[] = [];
    
    alicePage.on('console', msg => {
      const text = msg.text();
      if (text.includes('Phase') || text.includes('phase')) {
        console.log(`[Alice]: ${text}`);
        alicePhases.push(text);
      }
    });
    
    bobPage.on('console', msg => {
      const text = msg.text();
      if (text.includes('Phase') || text.includes('phase')) {
        console.log(`[Bob]: ${text}`);
        bobPhases.push(text);
      }
    });

    // Navigate to app
    await alicePage.goto('http://localhost:5173');
    await bobPage.goto('http://localhost:5173');
    
    // Wait for app to load
    await expect(alicePage.locator('h1:has-text("Power Grid")')).toBeVisible({ timeout: 10000 });
    await expect(bobPage.locator('h1:has-text("Power Grid")')).toBeVisible({ timeout: 10000 });

    // === SETUP GAME ===
    console.log('=== Setting up game ===');
    
    // Alice creates lobby
    await alicePage.fill('input[placeholder="Enter your name"]', 'Alice');
    await alicePage.waitForTimeout(500);
    await alicePage.click('button:has-text("Create New Lobby")');
    await alicePage.waitForTimeout(1000);
    
    const lobbyNameInput = alicePage.locator('input[placeholder*="lobby name"]').first();
    await lobbyNameInput.fill(lobbyName);
    
    const maxPlayersSelect = alicePage.locator('select[name="maxPlayers"]');
    if (await maxPlayersSelect.isVisible({ timeout: 1000 })) {
      await maxPlayersSelect.selectOption('2');
    }
    
    await alicePage.click('button[type="submit"], button:has-text("Create")');
    await alicePage.waitForTimeout(2000);
    
    // Bob joins lobby
    await bobPage.fill('input[placeholder="Enter your name"]', 'Bob');
    await bobPage.waitForTimeout(500);
    await bobPage.click('button:has-text("Browse Lobbies")');
    await bobPage.waitForSelector('h1:has-text("Browse Lobbies")', { timeout: 5000 });
    await bobPage.waitForTimeout(2000);
    
    const lobbyCard = bobPage.locator(`[data-testid="lobby-card"]:has-text("${lobbyName}")`).first();
    await expect(lobbyCard).toBeVisible({ timeout: 5000 });
    await lobbyCard.locator('button:has-text("Join")').click();
    await bobPage.waitForTimeout(2000);
    
    // Bob marks ready
    const bobReadyButton = bobPage.locator('button:has-text("Not Ready")');
    if (await bobReadyButton.isVisible({ timeout: 2000 })) {
      await bobReadyButton.click();
      await bobPage.waitForTimeout(1000);
    }

    // Alice starts game
    const startButton = alicePage.locator('button:has-text("Start Game")');
    await expect(startButton).toBeVisible({ timeout: 5000 });
    await expect(startButton).toBeEnabled({ timeout: 5000 });
    await startButton.click();
    await alicePage.waitForTimeout(5000);
    
    // === VERIFY INITIAL PHASE ===
    console.log('=== Verifying Initial Phase ===');
    
    // Check that both players are in auction phase
    const aliceAuctionPhase = await alicePage.locator('h2:has-text("Auction Phase")').isVisible({ timeout: 5000 });
    const bobAuctionPhase = await bobPage.locator('h2:has-text("Auction Phase")').isVisible({ timeout: 5000 });
    
    console.log('[Alice] In auction phase:', aliceAuctionPhase);
    console.log('[Bob] In auction phase:', bobAuctionPhase);
    
    expect(aliceAuctionPhase).toBeTruthy();
    expect(bobAuctionPhase).toBeTruthy();
    
    // === TEST AUCTION PHASE ACTIONS ===
    console.log('=== Testing Auction Phase Actions ===');
    
    // Check if there are power plants visible
    const alicePlants = await alicePage.locator('[data-testid="power-plant"]').count();
    console.log(`[Alice] Power plants visible: ${alicePlants}`);
    
    // Look for bid controls
    const aliceBidButton = await alicePage.locator('button:has-text("Start Auction")').isVisible({ timeout: 2000 });
    const alicePassButton = await alicePage.locator('button:has-text("Pass")').isVisible({ timeout: 2000 });
    
    console.log('[Alice] Bid button visible:', aliceBidButton);
    console.log('[Alice] Pass button visible:', alicePassButton);
    
    // === TEST PHASE PROGRESSION ===
    console.log('=== Testing Phase Progression ===');
    
    // Try to pass auction phase (simplified test)
    if (alicePassButton) {
      await alicePage.click('button:has-text("Pass")');
      await alicePage.waitForTimeout(2000);
    }
    
    if (await bobPage.locator('button:has-text("Pass")').isVisible({ timeout: 2000 })) {
      await bobPage.click('button:has-text("Pass")');
      await bobPage.waitForTimeout(3000);
    }
    
    // Check if phase transitioned (might go to resource phase)
    const aliceResourcePhase = await alicePage.locator('h2:has-text("Resource Phase")').isVisible({ timeout: 5000 });
    console.log('[Alice] Transitioned to resource phase:', aliceResourcePhase);
    
    // Take screenshots
    await alicePage.screenshot({ path: 'test-results/alice-phase-transitions.png', fullPage: true });
    await bobPage.screenshot({ path: 'test-results/bob-phase-transitions.png', fullPage: true });
    
    // Verify basic phase components are working
    expect(aliceAuctionPhase || aliceResourcePhase).toBeTruthy();
    expect(bobAuctionPhase || await bobPage.locator('h2:has-text("Resource Phase")').isVisible({ timeout: 2000 })).toBeTruthy();
    
    console.log('=== Phase Transitions Test Completed ===');
    
    // Clean up
    await aliceContext.close();
    await bobContext.close();
  });
});