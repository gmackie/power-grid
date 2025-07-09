import { test, expect } from '@playwright/test';

test.describe('Debug Lobby List', () => {
  test('check what Bob receives in lobby list', async ({ browser }) => {
    console.log('=== Testing Lobby List Response ===');

    const aliceContext = await browser.newContext();
    const bobContext = await browser.newContext();
    
    const alicePage = await aliceContext.newPage();
    const bobPage = await bobContext.newPage();

    // Set up detailed console logging for Bob
    bobPage.on('console', msg => {
      console.log(`[Bob]: ${msg.text()}`);
    });

    alicePage.on('console', msg => {
      if (msg.text().includes('Session ID') || msg.text().includes('Player registered')) {
        console.log(`[Alice]: ${msg.text()}`);
      }
    });

    // Alice creates lobby (simplified)
    console.log('\n=== Alice Creates Lobby ===');
    await alicePage.goto('http://localhost:5173');
    
    const aliceNameInput = alicePage.locator('input[placeholder="Enter your name"]');
    await aliceNameInput.waitFor({ state: 'visible', timeout: 5000 });
    
    let attempts = 0;
    while (!(await aliceNameInput.isEnabled()) && attempts < 15) {
      await alicePage.waitForTimeout(1000);
      attempts++;
    }
    
    await aliceNameInput.fill('Alice');
    await alicePage.waitForTimeout(2000);
    
    await alicePage.click('button:has-text("Browse Lobbies")');
    await alicePage.waitForSelector('h1:has-text("Lobbies")');
    
    await alicePage.click('button:has-text("Create")');
    const lobbyNameInput = alicePage.locator('input[placeholder*="lobby name"], input[placeholder*="name"], input[name="lobbyName"]');
    await lobbyNameInput.fill('Debug Lobby');
    
    const submitButton = alicePage.locator('button[type="submit"], button:has-text("Create")');
    await submitButton.click();
    
    await alicePage.waitForTimeout(3000);
    console.log('[Alice] Created lobby');

    // Bob checks lobby list
    console.log('\n=== Bob Checks Lobby List ===');
    await bobPage.goto('http://localhost:5173');
    
    const bobNameInput = bobPage.locator('input[placeholder="Enter your name"]');
    await bobNameInput.waitFor({ state: 'visible', timeout: 5000 });
    
    attempts = 0;
    while (!(await bobNameInput.isEnabled()) && attempts < 15) {
      await bobPage.waitForTimeout(1000);
      attempts++;
    }
    
    await bobNameInput.fill('Bob');
    await bobPage.waitForTimeout(2000);
    
    await bobPage.click('button:has-text("Browse Lobbies")');
    await bobPage.waitForSelector('h1:has-text("Lobbies")');
    
    // Take screenshot of what Bob sees
    await bobPage.screenshot({ 
      path: 'test-results/bob-lobby-list-view.png',
      fullPage: true 
    });

    // Wait a bit to see if any lobby list messages come through
    await bobPage.waitForTimeout(3000);
    
    // Check what text content is on the page
    const bodyText = await bobPage.locator('body').textContent();
    console.log('[Bob] Page contains "Debug Lobby":', bodyText?.includes('Debug Lobby'));
    console.log('[Bob] Page contains "Alice":', bodyText?.includes('Alice'));
    console.log('[Bob] Page contains "No lobbies":', bodyText?.includes('No lobbies') || bodyText?.includes('No games'));
    
    // Check for any lobby elements
    const lobbies = bobPage.locator('[data-testid*="lobby"], .lobby, div:has-text("Debug Lobby")');
    const lobbyCount = await lobbies.count();
    console.log('[Bob] Number of lobby elements found:', lobbyCount);

    await aliceContext.close();
    await bobContext.close();
    expect(true).toBeTruthy(); // Always pass for debugging
  });
});