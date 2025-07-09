import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';
import path from 'path';

test.describe('Lobby Join Test', () => {
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

  test('create and join lobby', async ({ browser }) => {
    console.log('=== Testing Lobby Creation and Join ===');

    // Create two browser contexts for different players
    const aliceContext = await browser.newContext();
    const bobContext = await browser.newContext();
    
    const alicePage = await aliceContext.newPage();
    const bobPage = await bobContext.newPage();

    // Set up console logging
    alicePage.on('console', msg => {
      if (msg.text().includes('Session ID') || msg.text().includes('WebSocket') || msg.text().includes('Player registered')) {
        console.log(`[Alice]: ${msg.text()}`);
      }
    });

    // More comprehensive logging for Bob to catch all messages
    bobPage.on('console', msg => {
      console.log(`[Bob]: ${msg.text()}`);
    });

    // Alice creates lobby
    console.log('\n=== Alice Creates Lobby ===');
    await alicePage.goto('http://localhost:5173');
    
    // Wait for name input and fill it
    const aliceNameInput = alicePage.locator('input[placeholder="Enter your name"]');
    await aliceNameInput.waitFor({ state: 'visible', timeout: 5000 });
    
    // Wait for WebSocket connection
    let attempts = 0;
    while (!(await aliceNameInput.isEnabled()) && attempts < 15) {
      await alicePage.waitForTimeout(1000);
      attempts++;
    }
    
    await aliceNameInput.fill('Alice');
    console.log('[Alice] Filled name');
    await alicePage.waitForTimeout(2000); // Wait for connection
    
    await alicePage.click('button:has-text("Browse Lobbies")');
    await alicePage.waitForSelector('h1:has-text("Lobbies")');
    
    // Try different Create Lobby button selectors
    const createButtons = [
      'button:has-text("Create New Lobby")',
      'button:has-text("Create Lobby")',
      'button:has-text("Create")'
    ];
    
    let buttonClicked = false;
    for (const buttonSelector of createButtons) {
      if (await alicePage.locator(buttonSelector).isVisible({ timeout: 2000 })) {
        await alicePage.click(buttonSelector);
        console.log(`[Alice] Clicked: ${buttonSelector}`);
        buttonClicked = true;
        break;
      }
    }
    
    if (!buttonClicked) {
      console.error('[Alice] No create lobby button found');
      await alicePage.screenshot({ 
        path: 'test-results/alice-no-create-button.png',
        fullPage: true 
      });
      expect(false).toBeTruthy();
      return;
    }
    
    await alicePage.waitForTimeout(1000);
    
    // Look for lobby name input with flexible selectors
    const lobbyNameInput = alicePage.locator('input[placeholder*="lobby name"], input[placeholder*="name"], input[name="lobbyName"]');
    if (await lobbyNameInput.isVisible({ timeout: 3000 })) {
      await lobbyNameInput.fill('Test Join Lobby');
      console.log('[Alice] Filled lobby name: Test Join Lobby');
      
      // Set map selection if available
      const mapSelect = alicePage.locator('select');
      if (await mapSelect.isVisible()) {
        await mapSelect.selectOption('usa');
        console.log('[Alice] Selected map: usa');
      }
      
      // Submit form
      const submitButton = alicePage.locator('button[type="submit"], button:has-text("Create")');
      if (await submitButton.isVisible()) {
        await submitButton.click();
        console.log('[Alice] Clicked submit');
      }
    }
    
    // Wait for lobby creation response
    await alicePage.waitForTimeout(3000);
    
    // Verify we're in a lobby - check multiple indicators
    const inLobby = await alicePage.locator('text=Test Join Lobby').isVisible({ timeout: 2000 }) ||
                   await alicePage.locator('text=Ready').isVisible({ timeout: 2000 }) ||
                   await alicePage.locator('text=Start Game').isVisible({ timeout: 2000 }) ||
                   alicePage.url().includes('lobby');
    
    console.log('[Alice] Created lobby successfully:', inLobby);
    
    if (!inLobby) {
      await alicePage.screenshot({ 
        path: 'test-results/alice-lobby-creation-failed.png',
        fullPage: true 
      });
      expect(false).toBeTruthy();
      return;
    }

    // Wait for lobby to be fully registered on server
    await alicePage.waitForTimeout(3000);

    // Bob joins lobby
    console.log('\n=== Bob Joins Lobby ===');
    await bobPage.goto('http://localhost:5173');
    
    // Wait for name input and fill it
    const bobNameInput = bobPage.locator('input[placeholder="Enter your name"]');
    await bobNameInput.waitFor({ state: 'visible', timeout: 5000 });
    
    // Wait for WebSocket connection
    attempts = 0;
    while (!(await bobNameInput.isEnabled()) && attempts < 15) {
      await bobPage.waitForTimeout(1000);
      attempts++;
    }
    
    await bobNameInput.fill('Bob');
    console.log('[Bob] Filled name');
    await bobPage.waitForTimeout(2000); // Wait for connection
    
    await bobPage.click('button:has-text("Browse Lobbies")');
    await bobPage.waitForSelector('h1:has-text("Lobbies")');
    
    // Wait a bit for the lobby list to load, then refresh
    await bobPage.waitForTimeout(2000);
    
    // Try refreshing the lobby list (if there's a refresh button)
    const refreshButton = bobPage.locator('button:has-text("Refresh"), button:has-text("Reload")');
    if (await refreshButton.isVisible({ timeout: 1000 })) {
      await refreshButton.click();
      console.log('[Bob] Clicked refresh button');
      await bobPage.waitForTimeout(2000);
    }
    
    // Check what lobby text is actually on the page
    const bodyText = await bobPage.locator('body').textContent();
    console.log('[Bob] Page contains "Test Join Lobby":', bodyText?.includes('Test Join Lobby'));
    console.log('[Bob] Page contains "Debug Lobby":', bodyText?.includes('Debug Lobby'));
    console.log('[Bob] Page contains "Alice":', bodyText?.includes('Alice'));
    
    // Try different selectors for finding lobbies
    const lobbySelectors = [
      'text=Test Join Lobby',
      '*[data-testid*="lobby"]',
      '.lobby',
      'div:has-text("Test")',
      'div:has-text("Lobby")',
      'div:has-text("Alice")'
    ];
    
    let lobbyVisible = false;
    let foundSelector = '';
    
    for (const selector of lobbySelectors) {
      if (await bobPage.locator(selector).isVisible({ timeout: 1000 })) {
        lobbyVisible = true;
        foundSelector = selector;
        console.log(`[Bob] Found lobby using selector: ${selector}`);
        break;
      }
    }
    
    console.log('[Bob] Can see lobby:', lobbyVisible);
    
    if (!lobbyVisible) {
      console.log('[Bob] Lobby not visible with any selector, taking screenshot');
      await bobPage.screenshot({ path: 'test-results/bob-no-lobby-visible.png', fullPage: true });
      
      // Also check for any cards, tables, or list items that might contain lobby data
      const cards = bobPage.locator('div[class*="card"], div[class*="item"], tr, li');
      const cardCount = await cards.count();
      console.log(`[Bob] Found ${cardCount} potential lobby containers`);
      
      if (cardCount > 0) {
        for (let i = 0; i < Math.min(cardCount, 5); i++) {
          const cardText = await cards.nth(i).textContent();
          console.log(`[Bob] Container ${i}: "${cardText?.substring(0, 100)}"`);
        }
      }
      
      expect(false).toBeTruthy();
      return;
    }
    
    // Look for the lobby and join it
    const lobbyRow = bobPage.locator('text=Test Join Lobby').locator('..');
    const joinButton = lobbyRow.locator('button:has-text("Join")');
    
    if (await joinButton.isVisible({ timeout: 5000 })) {
      await joinButton.click();
      console.log('[Bob] Clicked join button');
      await bobPage.waitForTimeout(2000);
      
      // Check if Bob is now in the lobby using multiple indicators
      const bobInLobby = await bobPage.locator('text=Test Join Lobby').isVisible({ timeout: 2000 }) ||
                        await bobPage.locator('text=Ready').isVisible({ timeout: 2000 }) ||
                        await bobPage.locator('text=Start Game').isVisible({ timeout: 2000 }) ||
                        bobPage.url().includes('lobby');
      
      console.log('[Bob] Joined lobby successfully:', bobInLobby);
      
      if (bobInLobby) {
        // Check if both players are visible in the lobby
        const aliceListed = await bobPage.locator('text=Alice').isVisible();
        const bobListed = await bobPage.locator('text=Bob').isVisible();
        
        console.log('[Lobby] Alice visible:', aliceListed);
        console.log('[Lobby] Bob visible:', bobListed);
        
        expect(aliceListed && bobListed).toBeTruthy();
      } else {
        console.log('[Bob] Failed to join lobby');
        await bobPage.screenshot({ path: 'test-results/bob-join-failed.png', fullPage: true });
        expect(false).toBeTruthy(); // Force failure
      }
    } else {
      console.log('[Bob] Could not find join button');
      await bobPage.screenshot({ path: 'test-results/no-join-button.png', fullPage: true });
      expect(false).toBeTruthy(); // Force failure
    }
    
    await aliceContext.close();
    await bobContext.close();
  });
});