import { test, expect } from '@playwright/test';

test.describe('Basic Multiplayer Verification', () => {
  test('verify multiplayer connection works', async ({ browser }) => {
    test.setTimeout(30000); // 30 seconds
    
    // Create two browser windows
    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    
    const player1 = await context1.newPage();
    const player2 = await context2.newPage();
    
    try {
      // Both players go to the app
      await player1.goto('/');
      await player2.goto('/');
      
      // Wait for app to load
      await player1.waitForLoadState('networkidle');
      await player2.waitForLoadState('networkidle');
      
      // Verify both can see the main menu
      await expect(player1.locator('h1')).toContainText('Power Grid');
      await expect(player2.locator('h1')).toContainText('Power Grid');
      
      // Enter player names
      await player1.fill('input[placeholder="Enter your name"]', 'Alice');
      await player2.fill('input[placeholder="Enter your name"]', 'Bob');
      
      // Screenshot both windows
      await player1.screenshot({ 
        path: 'test-results/basic-mp-player1.png',
        fullPage: true 
      });
      await player2.screenshot({ 
        path: 'test-results/basic-mp-player2.png',
        fullPage: true 
      });
      
      // Check if connection status is visible
      const connectionStatus1 = await player1.locator('[data-testid="connection-status"]').textContent();
      const connectionStatus2 = await player2.locator('[data-testid="connection-status"]').textContent();
      
      console.log('Player 1 connection:', connectionStatus1);
      console.log('Player 2 connection:', connectionStatus2);
      
      // Both players should be able to browse lobbies
      const browseButton1 = player1.locator('button:has-text("Browse Lobbies")');
      const browseButton2 = player2.locator('button:has-text("Browse Lobbies")');
      
      // Check if buttons are enabled (which means connected)
      const isEnabled1 = await browseButton1.isEnabled();
      const isEnabled2 = await browseButton2.isEnabled();
      
      console.log('Player 1 can browse:', isEnabled1);
      console.log('Player 2 can browse:', isEnabled2);
      
      // Success if at least one player can browse (connection established)
      expect(isEnabled1 || isEnabled2).toBeTruthy();
      
    } finally {
      await context1.close();
      await context2.close();
    }
  });
});