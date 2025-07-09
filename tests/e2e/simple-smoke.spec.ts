import { test, expect } from '@playwright/test';

test.describe('Simple Smoke Test', () => {
  test('app loads and shows main menu', async ({ page }) => {
    // Go to the app
    await page.goto('/');
    
    // Wait for app to load
    await page.waitForLoadState('networkidle');
    
    // Take a screenshot for debugging
    await page.screenshot({ path: 'test-results/main-menu.png' });
    
    // Check if the app loaded
    const title = await page.locator('h1').textContent();
    console.log('Page title:', title);
    
    // Check for main menu buttons
    const buttons = await page.locator('button').allTextContents();
    console.log('Buttons found:', buttons);
    
    // The app should show Power Grid title
    await expect(page.locator('h1')).toContainText('Power Grid');
    
    // Should have a Browse Lobbies button
    await expect(page.locator('button:has-text("Browse Lobbies")')).toBeVisible();
  });

  test('can navigate to lobby browser', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Click Browse Lobbies
    await page.click('button:has-text("Browse Lobbies")');
    
    // Wait for navigation
    await page.waitForTimeout(1000);
    
    // Take screenshot
    await page.screenshot({ path: 'test-results/lobby-browser.png' });
    
    // Should be on lobbies page
    await expect(page).toHaveURL(/lobbies/);
    
    // Should show lobby browser UI
    await expect(page.locator('h1')).toContainText('Game Lobbies');
  });

  test('connection status is visible', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Connection status should be visible
    const connectionStatus = page.locator('[data-testid="connection-status"]');
    await expect(connectionStatus).toBeVisible();
    
    // Get the connection text
    const statusText = await connectionStatus.textContent();
    console.log('Connection status:', statusText);
    
    // Should show some connection state
    expect(statusText).toMatch(/Connected|Connecting|Disconnected/);
  });
});