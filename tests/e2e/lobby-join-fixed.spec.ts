import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';
import path from 'path';

// Run tests serially to avoid multiple server instances
test.describe.serial('Lobby Join Test - Fixed', () => {
  let serverProcess: any;
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

  test('create and join lobby with unique names', async ({ browser }) => {
    console.log('=== Testing Lobby Creation and Join ===');
    
    // Generate unique lobby name for this test run
    lobbyName = `Lobby_${Date.now()}`;
    console.log(`Using unique lobby name: ${lobbyName}`);

    // Create two browser contexts for different players
    const aliceContext = await browser.newContext();
    const bobContext = await browser.newContext();
    
    const alicePage = await aliceContext.newPage();
    const bobPage = await bobContext.newPage();

    // Set up console logging
    alicePage.on('console', msg => {
      if (msg.text().includes('Session ID') || msg.text().includes('WebSocket') || 
          msg.text().includes('Player registered') || msg.text().includes('lobby')) {
        console.log(`[Alice]: ${msg.text()}`);
      }
    });
    
    bobPage.on('console', msg => {
      if (msg.text().includes('Session ID') || msg.text().includes('WebSocket') || 
          msg.text().includes('Player registered') || msg.text().includes('lobby')) {
        console.log(`[Bob]: ${msg.text()}`);
      }
    });

    // Navigate both to the app
    await alicePage.goto('http://localhost:5173');
    await bobPage.goto('http://localhost:5173');
    
    // Wait for app to load
    await expect(alicePage.locator('h1:has-text("Power Grid")')).toBeVisible({ timeout: 10000 });
    await expect(bobPage.locator('h1:has-text("Power Grid")')).toBeVisible({ timeout: 10000 });
    console.log('Both pages loaded successfully');

    // === ALICE CREATES LOBBY ===
    console.log('=== Alice Creating Lobby ===');
    
    // Alice enters name
    await alicePage.fill('input[placeholder="Enter your name"]', 'Alice');
    await alicePage.waitForTimeout(500);
    
    // Alice creates a new lobby
    await alicePage.click('button:has-text("Create New Lobby")');
    console.log('[Alice] Clicked create new lobby');
    
    // Wait for create lobby form
    await alicePage.waitForTimeout(1000);
    
    // Fill lobby details
    const lobbyNameInput = alicePage.locator('input[placeholder*="lobby name"], input[placeholder*="name"], input[name="lobbyName"]').first();
    await lobbyNameInput.fill(lobbyName);
    console.log(`[Alice] Filled lobby name: ${lobbyName}`);
    
    // Set map if available
    const mapSelect = alicePage.locator('select').first();
    if (await mapSelect.isVisible({ timeout: 1000 })) {
      await mapSelect.selectOption('usa');
      console.log('[Alice] Selected map: usa');
    }
    
    // Submit form
    const submitButton = alicePage.locator('button[type="submit"], button:has-text("Create")').first();
    await submitButton.click();
    console.log('[Alice] Submitted lobby creation');
    
    // Wait for lobby to be created
    await alicePage.waitForTimeout(2000);
    
    // Verify Alice is in the lobby
    const aliceInLobby = await alicePage.locator(`text=${lobbyName}`).isVisible({ timeout: 5000 });
    console.log('[Alice] In lobby:', aliceInLobby);
    
    if (!aliceInLobby) {
      await alicePage.screenshot({ path: 'test-results/alice-lobby-fail.png', fullPage: true });
      throw new Error('Alice failed to create/join lobby');
    }

    // === BOB JOINS LOBBY ===
    console.log('=== Bob Joining Lobby ===');
    
    // Bob enters name
    await bobPage.fill('input[placeholder="Enter your name"]', 'Bob');
    await bobPage.waitForTimeout(500);
    
    // Bob browses lobbies
    await bobPage.click('button:has-text("Browse Lobbies")');
    console.log('[Bob] Clicked browse lobbies');
    
    // Wait for lobby browser to load
    await bobPage.waitForSelector('h1:has-text("Browse Lobbies")', { timeout: 5000 });
    console.log('[Bob] In lobby browser');
    
    // Wait for lobbies to load
    await bobPage.waitForTimeout(2000);
    
    // Look for the specific lobby created by Alice
    const lobbyCard = bobPage.locator(`[data-testid="lobby-card"]:has-text("${lobbyName}")`);
    const lobbyCardVisible = await lobbyCard.isVisible({ timeout: 5000 });
    
    if (!lobbyCardVisible) {
      // Try refreshing
      const refreshBtn = bobPage.locator('button:has([class*="RefreshCw"])');
      if (await refreshBtn.isVisible()) {
        await refreshBtn.click();
        console.log('[Bob] Clicked refresh');
        await bobPage.waitForTimeout(2000);
      }
      
      // Check again
      if (!await lobbyCard.isVisible({ timeout: 5000 })) {
        await bobPage.screenshot({ path: 'test-results/bob-no-lobby.png', fullPage: true });
        
        // Debug: Check what lobbies are visible
        const allCards = await bobPage.locator('[data-testid="lobby-card"]').count();
        console.log(`[Bob] Found ${allCards} lobby cards total`);
        
        for (let i = 0; i < allCards; i++) {
          const cardText = await bobPage.locator('[data-testid="lobby-card"]').nth(i).textContent();
          console.log(`[Bob] Card ${i}: ${cardText}`);
        }
        
        throw new Error(`Bob cannot see lobby: ${lobbyName}`);
      }
    }
    
    console.log(`[Bob] Can see lobby: ${lobbyName}`);
    
    // Click join button
    const joinButton = lobbyCard.locator('button:has-text("Join")');
    await joinButton.click();
    console.log('[Bob] Clicked join button');
    
    // Wait for Bob to join the lobby
    await bobPage.waitForTimeout(2000);
    
    // Verify Bob is in the lobby
    const bobInLobby = await bobPage.locator(`h1:has-text("${lobbyName}")`).isVisible({ timeout: 5000 });
    console.log('[Bob] Joined lobby:', bobInLobby);
    
    if (!bobInLobby) {
      await bobPage.screenshot({ path: 'test-results/bob-join-fail.png', fullPage: true });
      throw new Error('Bob failed to join lobby');
    }
    
    // === VERIFY BOTH PLAYERS SEE EACH OTHER ===
    console.log('=== Verifying Both Players ===');
    
    // Check if Alice sees Bob
    const aliceSeeBob = await alicePage.locator('text=Bob').isVisible({ timeout: 5000 });
    console.log('[Alice] Can see Bob:', aliceSeeBob);
    
    // Check if Bob sees Alice
    const bobSeeAlice = await bobPage.locator('text=Alice').isVisible({ timeout: 5000 });
    console.log('[Bob] Can see Alice:', bobSeeAlice);
    
    // Take final screenshots
    await alicePage.screenshot({ path: 'test-results/alice-final.png', fullPage: true });
    await bobPage.screenshot({ path: 'test-results/bob-final.png', fullPage: true });
    
    // Final assertions
    expect(aliceInLobby).toBeTruthy();
    expect(bobInLobby).toBeTruthy();
    expect(aliceSeeBob).toBeTruthy();
    expect(bobSeeAlice).toBeTruthy();
    
    console.log('=== Test Completed Successfully ===');
    
    // Clean up
    await aliceContext.close();
    await bobContext.close();
  });
});