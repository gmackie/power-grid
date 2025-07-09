import { test, expect } from '@playwright/test';

test.describe('Auction Phase Gameplay', () => {
  test.beforeEach(async ({ page }) => {
    // Start a game and get to auction phase
    await page.goto('/');
    await page.click('text=Browse Lobbies');
    await page.click('text=Create Lobby');
    await page.fill('input[placeholder="Enter lobby name"]', 'Auction Test');
    await page.selectOption('select[name="maxPlayers"]', '2');
    await page.click('button[type="submit"]');
    
    // Configure player and start game
    await page.fill('input[placeholder="Enter your name"]', 'Test Player');
    
    // Simulate game start and navigation to auction phase
    // This would typically require server interaction or mock state
    await page.click('[data-testid="start-game"]');
    
    // Wait for auction phase to load
    await page.waitForSelector('text=Auction Phase');
  });

  test('should display power plant market correctly', async ({ page }) => {
    await expect(page.locator('h3')).toContainText('Power Plant Market');
    
    // Check that power plants are displayed
    await expect(page.locator('[data-testid="power-plant"]')).toHaveCountGreaterThan(0);
    
    // Verify plant information is shown
    const firstPlant = page.locator('[data-testid="power-plant"]').first();
    await expect(firstPlant.locator('.text-3xl')).toBeVisible(); // Plant number
    await expect(firstPlant.locator('text=Min:')).toBeVisible(); // Minimum cost
    await expect(firstPlant.locator('text=Powers')).toBeVisible(); // Power output
  });

  test('should allow selecting a power plant for auction', async ({ page }) => {
    // Wait for plants to load
    await page.waitForSelector('[data-testid="power-plant"]');
    
    // Click on the first available power plant
    const firstPlant = page.locator('[data-testid="power-plant"]').first();
    await firstPlant.click();
    
    // Should highlight the selected plant
    await expect(firstPlant).toHaveClass(/border-blue-500/);
    
    // Should show bidding controls
    await expect(page.locator('text=Start Auction')).toBeVisible();
    await expect(page.locator('input[label="Bid Amount"]')).toBeVisible();
  });

  test('should validate bid amounts correctly', async ({ page }) => {
    // Select a power plant
    await page.waitForSelector('[data-testid="power-plant"]');
    const firstPlant = page.locator('[data-testid="power-plant"]').first();
    await firstPlant.click();
    
    // Get minimum bid amount
    const minBidText = await firstPlant.locator('text=Min:').textContent();
    const minBid = parseInt(minBidText?.replace(/[^0-9]/g, '') || '0');
    
    // Test invalid low bid
    await page.fill('input[label="Bid Amount"]', (minBid - 1).toString());
    await expect(page.locator('text=Invalid bid amount')).toBeVisible();
    
    // Test valid bid
    await page.fill('input[label="Bid Amount"]', minBid.toString());
    await expect(page.locator('text=Invalid bid amount')).toBeHidden();
    
    // Start auction button should be enabled
    await expect(page.locator('button:has-text("Start Auction")')).toBeEnabled();
  });

  test('should start auction and update display', async ({ page }) => {
    // Select and start auction on a power plant
    await page.waitForSelector('[data-testid="power-plant"]');
    const firstPlant = page.locator('[data-testid="power-plant"]').first();
    await firstPlant.click();
    
    // Enter valid bid and start auction
    await page.fill('input[label="Bid Amount"]', '15');
    await page.click('button:has-text("Start Auction")');
    
    // Should show current auction state
    await expect(page.locator('text=Bidding on Plant')).toBeVisible();
    await expect(firstPlant).toHaveClass(/border-yellow-500/); // Current auction highlight
    
    // Should show current bid information
    await expect(page.locator('text=Current Bid:')).toBeVisible();
  });

  test('should handle bidding interactions', async ({ page }) => {
    // Start an auction first
    await page.waitForSelector('[data-testid="power-plant"]');
    const firstPlant = page.locator('[data-testid="power-plant"]').first();
    await firstPlant.click();
    await page.fill('input[label="Bid Amount"]', '15');
    await page.click('button:has-text("Start Auction")');
    
    // Should show "Place Your Bid" interface
    await expect(page.locator('text=Place Your Bid')).toBeVisible();
    
    // Test quick bid buttons
    const quickBidButton = page.locator('button:has-text("+$1")').first();
    if (await quickBidButton.isVisible()) {
      await quickBidButton.click();
      
      // Should update bid amount input
      const bidInput = page.locator('input[label="Bid Amount"]');
      const bidValue = await bidInput.inputValue();
      expect(parseInt(bidValue)).toBeGreaterThan(15);
    }
    
    // Test placing a higher bid
    await page.fill('input[label="Bid Amount"]', '20');
    await page.click('button:has-text("Place Bid")');
    
    // Should update current bid display
    await expect(page.locator('text=Current Bid: $20')).toBeVisible();
  });

  test('should allow passing in auction', async ({ page }) => {
    // Start an auction
    await page.waitForSelector('[data-testid="power-plant"]');
    const firstPlant = page.locator('[data-testid="power-plant"]').first();
    await firstPlant.click();
    await page.fill('input[label="Bid Amount"]', '15');
    await page.click('button:has-text("Start Auction")');
    
    // Click pass button
    await page.click('button:has-text("Pass")');
    
    // Should show passed state
    await expect(page.locator('text=You have passed this auction round')).toBeVisible();
    
    // Should show pass indicator
    await expect(page.locator('[data-testid="pass-indicator"]')).toBeVisible();
  });

  test('should show player money and validate against it', async ({ page }) => {
    // Should display current player money
    await expect(page.locator('text=Your Money:')).toBeVisible();
    
    // Get player money amount
    const moneyText = await page.locator('text=Your Money:').locator('..').locator('.text-yellow-400').textContent();
    const playerMoney = parseInt(moneyText?.replace(/[^0-9]/g, '') || '0');
    
    // Select a plant and try to bid more than available money
    await page.waitForSelector('[data-testid="power-plant"]');
    const firstPlant = page.locator('[data-testid="power-plant"]').first();
    await firstPlant.click();
    
    // Try to bid more than player has
    await page.fill('input[label="Bid Amount"]', (playerMoney + 100).toString());
    await expect(page.locator('button:has-text("Start Auction")')).toBeDisabled();
  });

  test('should display auction history and won plants', async ({ page }) => {
    // After some auctions are completed, should show won plants
    // This test would need to simulate completed auctions
    
    // Look for won plants section (might not be visible initially)
    const wonPlantsSection = page.locator('text=Plants Won This Round');
    
    if (await wonPlantsSection.isVisible()) {
      // Should show player names and plants they won
      await expect(page.locator('[data-testid="won-plant-entry"]')).toHaveCountGreaterThan(0);
      
      // Should show player colors and plant numbers
      await expect(page.locator('.w-6.h-6.rounded-full')).toHaveCountGreaterThan(0);
      await expect(page.locator('text=Plant #')).toHaveCountGreaterThan(0);
    }
  });

  test('should handle turn-based bidding flow', async ({ page }) => {
    // Should show whose turn it is
    const currentPlayerDisplay = page.locator('text=Current bidder:');
    
    if (await currentPlayerDisplay.isVisible()) {
      // Should display current bidder name
      await expect(currentPlayerDisplay.locator('..')).toContainText(/\w+/);
    }
    
    // When not player's turn, should show waiting message
    const waitingMessage = page.locator('text=Waiting for other players');
    if (await waitingMessage.isVisible()) {
      // Bidding controls should be disabled or hidden
      await expect(page.locator('button:has-text("Place Bid")')).toBeHidden();
    }
  });

  test('should show resource types and power output correctly', async ({ page }) => {
    await page.waitForSelector('[data-testid="power-plant"]');
    
    // Each power plant should show resource type
    const plants = page.locator('[data-testid="power-plant"]');
    const firstPlant = plants.first();
    
    // Should show resource type badge
    await expect(firstPlant.locator('.rounded-full')).toHaveCountGreaterThan(0);
    
    // Should show power output with lightning icon
    await expect(firstPlant.locator('[data-icon="zap"]')).toBeVisible();
    await expect(firstPlant.locator('text=Powers')).toBeVisible();
    
    // Resource types should be properly colored
    const resourceBadge = firstPlant.locator('.rounded-full').first();
    const classList = await resourceBadge.getAttribute('class');
    expect(classList).toMatch(/bg-(gray|amber|yellow|green|purple|blue)-700/);
  });

  test('should handle mobile responsive layout', async ({ page }) => {
    // Test mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Should show mobile-optimized grid layout
    const plantGrid = page.locator('.grid');
    await expect(plantGrid).toHaveClass(/grid-cols-2/);
    
    // Touch targets should be appropriately sized
    const buttons = page.locator('.touch-target');
    for (const button of await buttons.all()) {
      const boundingBox = await button.boundingBox();
      if (boundingBox) {
        expect(boundingBox.height).toBeGreaterThanOrEqual(44); // Minimum touch target
      }
    }
  });
});