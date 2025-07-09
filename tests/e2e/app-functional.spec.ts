import { test, expect } from '@playwright/test';

test.describe('App Functionality Test', () => {
  test('app is functional and can navigate with player name', async ({ page }) => {
    // Go to the app
    await page.goto('/');
    
    // Wait for app to load
    await page.waitForLoadState('networkidle');
    
    // Take initial screenshot
    await page.screenshot({ path: 'test-results/app-initial.png', fullPage: true });
    
    // Check main elements are present
    await expect(page.locator('h1')).toContainText('Power Grid');
    await expect(page.locator('text=Player Setup')).toBeVisible();
    await expect(page.locator('text=Game Options')).toBeVisible();
    
    // Check connection status card
    const connectionCard = page.locator('text=Connect').locator('..');
    await expect(connectionCard).toBeVisible();
    
    // Enter a player name to enable buttons
    await page.fill('input[placeholder="Enter your name"]', 'Test Player');
    
    // Take screenshot after entering name
    await page.screenshot({ path: 'test-results/app-with-name.png', fullPage: true });
    
    // Now Browse Lobbies button should be enabled
    const browseLobbyButton = page.locator('button:has-text("Browse Lobbies")');
    await expect(browseLobbyButton).toBeEnabled();
    
    // Click Browse Lobbies
    await browseLobbyButton.click();
    
    // Wait a moment for navigation
    await page.waitForTimeout(1000);
    
    // Take screenshot of lobby browser
    await page.screenshot({ path: 'test-results/lobby-browser-screen.png', fullPage: true });
    
    // Should navigate to lobby browser
    const currentUrl = page.url();
    console.log('Current URL:', currentUrl);
    
    // Should show lobby browser UI
    const pageTitle = await page.locator('h1').textContent();
    console.log('Page title:', pageTitle);
    
    // Success if we navigated away from main menu
    expect(currentUrl).toContain('lobbies');
  });

  test('all UI elements render correctly', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Check all main UI sections
    const sections = [
      'Power Grid',
      'Player Setup',
      'Game Options',
      'Settings'
    ];
    
    for (const section of sections) {
      await expect(page.locator(`text=${section}`)).toBeVisible();
    }
    
    // Check color selector is present
    const colorButtons = page.locator('button[title]');
    const colorCount = await colorButtons.count();
    expect(colorCount).toBeGreaterThanOrEqual(6); // Should have at least 6 color options
    
    // Check all game option buttons
    const gameButtons = [
      'Browse Lobbies',
      'Create New Lobby',
      'Join Game by ID'
    ];
    
    for (const button of gameButtons) {
      await expect(page.locator(`button:has-text("${button}")`)).toBeVisible();
    }
    
    // Platform indicator should be visible
    await expect(page.locator('text=/Desktop|Mobile|Tablet/')).toBeVisible();
  });

  test('can create a new lobby', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Enter player name
    await page.fill('input[placeholder="Enter your name"]', 'Test Player');
    
    // Click Create New Lobby
    await page.click('button:has-text("Create New Lobby")');
    
    // Wait for navigation
    await page.waitForTimeout(1000);
    
    // Take screenshot
    await page.screenshot({ path: 'test-results/create-lobby-screen.png', fullPage: true });
    
    // Should navigate away from main menu
    const currentUrl = page.url();
    console.log('After create lobby URL:', currentUrl);
    
    // Check if we're on a different screen
    const hasNavigated = currentUrl !== 'http://localhost:5173/';
    expect(hasNavigated).toBeTruthy();
  });
});