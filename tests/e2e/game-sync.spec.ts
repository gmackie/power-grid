import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';
import path from 'path';

test.describe.serial('Game State Synchronization Test', () => {
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

  test('should synchronize game state between players', async ({ browser }) => {
    console.log('=== Testing Game State Synchronization ===');
    
    // Generate unique lobby name
    lobbyName = `SyncTest_${Date.now()}`;
    console.log(`Using lobby name: ${lobbyName}`);

    // Create contexts for two players
    const aliceContext = await browser.newContext();
    const bobContext = await browser.newContext();
    
    const alicePage = await aliceContext.newPage();
    const bobPage = await bobContext.newPage();

    // Track synchronization messages
    const aliceMessages: string[] = [];
    const bobMessages: string[] = [];
    
    alicePage.on('console', msg => {
      const text = msg.text();
      if (text.includes('sync') || text.includes('SYNC') || text.includes('update') || text.includes('UPDATE')) {
        console.log(`[Alice]: ${text}`);
        aliceMessages.push(text);
      }
    });
    
    bobPage.on('console', msg => {
      const text = msg.text();
      if (text.includes('sync') || text.includes('SYNC') || text.includes('update') || text.includes('UPDATE')) {
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
    
    // === VERIFY GAME STATE SYNCHRONIZATION ===
    console.log('=== Verifying Game State Synchronization ===');
    
    // Check that both players are in the same phase
    const alicePhase = await alicePage.locator('h2').first().textContent();
    const bobPhase = await bobPage.locator('h2').first().textContent();
    
    console.log(`[Alice] Current phase: ${alicePhase}`);
    console.log(`[Bob] Current phase: ${bobPhase}`);
    
    // Verify both players see the same phase
    expect(alicePhase).toBe(bobPhase);
    
    // === TEST LOCAL MODE TOGGLE ===
    console.log('=== Testing Local Mode Toggle ===');
    
    // Enable local mode on Alice's side
    const localModeCheckbox = alicePage.locator('input[type="checkbox"]').first();
    if (await localModeCheckbox.isVisible({ timeout: 2000 })) {
      await localModeCheckbox.check();
      console.log('[Alice] Enabled local mode');
      await alicePage.waitForTimeout(1000);
    }
    
    // === TEST CONNECTION STATUS ===
    console.log('=== Testing Connection Status ===');
    
    // Check connection status indicators
    const aliceConnected = await alicePage.locator('div.bg-green-400').isVisible({ timeout: 2000 });
    const bobConnected = await bobPage.locator('div.bg-green-400').isVisible({ timeout: 2000 });
    
    console.log('[Alice] Connected status:', aliceConnected);
    console.log('[Bob] Connected status:', bobConnected);
    
    // Both should be connected
    expect(aliceConnected).toBeTruthy();
    expect(bobConnected).toBeTruthy();
    
    // === TEST GAME ACTIONS ===
    console.log('=== Testing Game Actions ===');
    
    // Check if game actions are available
    const aliceActions = await alicePage.locator('button').count();
    const bobActions = await bobPage.locator('button').count();
    
    console.log(`[Alice] Available actions: ${aliceActions}`);
    console.log(`[Bob] Available actions: ${bobActions}`);
    
    // Take screenshots
    await alicePage.screenshot({ path: 'test-results/alice-game-sync.png', fullPage: true });
    await bobPage.screenshot({ path: 'test-results/bob-game-sync.png', fullPage: true });
    
    // Verify game synchronization is working
    expect(alicePhase).toBeTruthy();
    expect(bobPhase).toBeTruthy();
    expect(alicePhase).toBe(bobPhase);
    
    console.log('=== Game State Synchronization Test Completed ===');
    
    // Clean up
    await aliceContext.close();
    await bobContext.close();
  });
});