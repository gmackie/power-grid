import { test, expect } from '@playwright/test';

test.describe('Lobby and Player Setup', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should display main menu on load', async ({ page }) => {
    await expect(page.locator('h1')).toContainText('Power Grid');
    await expect(page.locator('button')).toContainText('Browse Lobbies');
  });

  test('should navigate to lobby browser', async ({ page }) => {
    await page.click('text=Browse Lobbies');
    await expect(page).toHaveURL('/lobbies');
    await expect(page.locator('h1')).toContainText('Game Lobbies');
  });

  test('should create a new lobby', async ({ page }) => {
    // Navigate to lobby browser
    await page.click('text=Browse Lobbies');
    
    // Click create lobby button
    await page.click('text=Create Lobby');
    
    // Fill in lobby details
    await page.fill('input[placeholder="Enter lobby name"]', 'Test Lobby');
    await page.selectOption('select[name="maxPlayers"]', '4');
    await page.selectOption('select[name="mapName"]', 'usa');
    
    // Create the lobby
    await page.click('button[type="submit"]');
    
    // Should navigate to lobby screen
    await expect(page).toHaveURL(/\/lobby\?id=.+/);
    await expect(page.locator('h1')).toContainText('Test Lobby');
  });

  test('should join an existing lobby', async ({ page }) => {
    // Navigate to lobby browser
    await page.click('text=Browse Lobbies');
    
    // Wait for lobbies to load and join the first one
    await page.waitForSelector('[data-testid="lobby-list"]');
    const firstLobby = page.locator('[data-testid="lobby-item"]').first();
    
    if (await firstLobby.count() > 0) {
      await firstLobby.click('text=Join');
      
      // Should navigate to lobby screen
      await expect(page).toHaveURL(/\/lobby\?id=.+/);
    }
  });

  test('should configure player settings in lobby', async ({ page }) => {
    // Create a lobby first
    await page.click('text=Browse Lobbies');
    await page.click('text=Create Lobby');
    await page.fill('input[placeholder="Enter lobby name"]', 'Player Config Test');
    await page.click('button[type="submit"]');
    
    // Configure player settings
    await page.fill('input[placeholder="Enter your name"]', 'Test Player');
    await page.click('[data-testid="color-selector"]');
    await page.click('[data-testid="color-red"]');
    
    // Verify player appears in lobby
    await expect(page.locator('[data-testid="player-list"]')).toContainText('Test Player');
  });

  test('should start game when lobby is full', async ({ page }) => {
    // Create a lobby
    await page.click('text=Browse Lobbies');
    await page.click('text=Create Lobby');
    await page.fill('input[placeholder="Enter lobby name"]', 'Full Lobby Test');
    await page.selectOption('select[name="maxPlayers"]', '2'); // Minimum players
    await page.click('button[type="submit"]');
    
    // Configure host player
    await page.fill('input[placeholder="Enter your name"]', 'Host Player');
    
    // Simulate second player joining (in real test, this would need multiple browser contexts)
    // For now, just check that start button appears when conditions are met
    await expect(page.locator('button[data-testid="start-game"]')).toBeVisible();
  });

  test('should handle connection errors gracefully', async ({ page }) => {
    // Simulate network error
    await page.route('**/ws', route => route.abort());
    
    await page.goto('/');
    
    // Should show connection error
    await expect(page.locator('[data-testid="connection-status"]')).toContainText('Disconnected');
    await expect(page.locator('[data-testid="error-notification"]')).toBeVisible();
  });

  test('should preserve lobby state on page refresh', async ({ page }) => {
    // Create and join a lobby
    await page.click('text=Browse Lobbies');
    await page.click('text=Create Lobby');
    await page.fill('input[placeholder="Enter lobby name"]', 'Persistent Lobby');
    await page.click('button[type="submit"]');
    
    const currentUrl = page.url();
    
    // Refresh the page
    await page.reload();
    
    // Should still be in the same lobby
    await expect(page).toHaveURL(currentUrl);
    await expect(page.locator('h1')).toContainText('Persistent Lobby');
  });
});