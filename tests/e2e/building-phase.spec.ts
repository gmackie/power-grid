import { test, expect } from '@playwright/test';

test.describe('Building Phase', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to building phase
    await page.goto('/');
    await page.click('text=Browse Lobbies');
    await page.click('text=Create Lobby');
    await page.fill('input[placeholder="Enter lobby name"]', 'Building Test');
    await page.selectOption('select[name="maxPlayers"]', '2');
    await page.click('button[type="submit"]');
    await page.fill('input[placeholder="Enter your name"]', 'Test Player');
    await page.click('[data-testid="start-game"]');
    
    // Navigate to building phase
    await page.waitForSelector('text=Building Phase');
  });

  test('should display building phase correctly', async ({ page }) => {
    await expect(page.locator('h2')).toContainText('Building Phase');
    await expect(page.locator('text=Expand your network')).toBeVisible();
    
    // Should show phase header with building stats
    await expect(page.locator('text=Cities Built')).toBeVisible();
    
    // Should show player status
    await expect(page.locator('text=Your Money')).toBeVisible();
    await expect(page.locator('text=Your Cities')).toBeVisible();
  });

  test('should display game board', async ({ page }) => {
    await expect(page.locator('h3')).toContainText('Game Board');
    
    // Should show game board component
    await expect(page.locator('[data-testid="game-board"]')).toBeVisible();
    
    // Board should show cities
    const cities = page.locator('[data-testid="city"]');
    await expect(cities).toHaveCountGreaterThan(0);
  });

  test('should handle city selection', async ({ page }) => {
    // Wait for cities to load
    await page.waitForSelector('[data-testid="city"]');
    
    // Find a selectable city
    const cities = page.locator('[data-testid="city"]');
    const firstSelectableCity = cities.first();
    
    if (await firstSelectableCity.isVisible()) {
      await firstSelectableCity.click();
      
      // Should highlight selected city
      await expect(firstSelectableCity).toHaveClass(/selected|border-blue/);
      
      // Should show build cost
      await expect(page.locator('text=Build Cost')).toBeVisible();
      
      // Should enable build button
      await expect(page.locator('button:has-text("Build in")')).toBeEnabled();
    }
  });

  test('should calculate building costs correctly', async ({ page }) => {
    await page.waitForSelector('[data-testid="city"]');
    const cities = page.locator('[data-testid="city"]');
    const firstCity = cities.first();
    
    if (await firstCity.isVisible()) {
      await firstCity.click();
      
      // Should show cost breakdown
      await expect(page.locator('text=House Cost:')).toBeVisible();
      await expect(page.locator('text=Connection Cost:')).toBeVisible();
      await expect(page.locator('text=Total:')).toBeVisible();
      
      // Costs should be numeric values
      const totalCost = page.locator('text=Total:').locator('..').locator('.text-green-400');
      const costText = await totalCost.textContent();
      const cost = parseInt(costText?.replace(/[^0-9]/g, '') || '0');
      expect(cost).toBeGreaterThan(0);
    }
  });

  test('should validate building constraints', async ({ page }) => {
    await page.waitForSelector('[data-testid="city"]');
    const cities = page.locator('[data-testid="city"]');
    
    // Look for cities with different constraints
    for (const city of await cities.all()) {
      const cityName = await city.locator('[data-testid="city-name"]').textContent();
      
      // Try to select the city
      await city.click();
      
      // Check if constraints are shown
      const constraintText = city.locator('.text-red-400');
      if (await constraintText.isVisible()) {
        const constraint = await constraintText.textContent();
        
        // Common constraints
        expect(constraint).toMatch(/(full|already own|built here|need \$|empty cities)/i);
        
        // Build button should be disabled for constrained cities
        if (constraint) {
          await expect(page.locator('button:has-text("Build in")')).toBeDisabled();
        }
      }
    }
  });

  test('should handle city building action', async ({ page }) => {
    await page.waitForSelector('[data-testid="city"]');
    
    // Find and select a buildable city
    const buildableCities = page.locator('[data-testid="city"]:not(.disabled)');
    const firstBuildable = buildableCities.first();
    
    if (await firstBuildable.isVisible()) {
      await firstBuildable.click();
      
      // Get city name
      const cityName = await firstBuildable.locator('[data-testid="city-name"]').textContent();
      
      // Build in the city
      const buildButton = page.locator('button:has-text("Build in")');
      if (await buildButton.isEnabled()) {
        await buildButton.click();
        
        // Should show in building history
        await expect(page.locator('text=Cities Built This Turn')).toBeVisible();
        await expect(page.locator('text=You')).toBeVisible();
        
        // Should update cities built counter
        const citiesBuilt = page.locator('text=Cities Built').locator('..').locator('.text-lg');
        const count = await citiesBuilt.textContent();
        expect(parseInt(count || '0')).toBeGreaterThanOrEqual(1);
      }
    }
  });

  test('should show mobile city list view', async ({ page }) => {
    // Test mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Should show mobile city list
    await expect(page.locator('text=Available Cities')).toBeVisible();
    
    // Should group cities by region
    const regionHeaders = page.locator('h4.text-slate-400');
    await expect(regionHeaders).toHaveCountGreaterThan(0);
    
    // City items should show relevant information
    const cityButtons = page.locator('button[data-testid="city-item"]');
    
    if (await cityButtons.count() > 0) {
      const firstCity = cityButtons.first();
      
      // Should show city name and cost
      await expect(firstCity.locator('.text-white')).toBeVisible();
      await expect(firstCity.locator('text=Cost:')).toBeVisible();
      
      // Should show existing houses
      await expect(firstCity.locator('text=houses')).toBeVisible();
      
      // Should show player colors as colored dots
      const houseDots = firstCity.locator('.w-4.h-4.rounded-full');
      // May have 0 or more houses depending on game state
    }
  });

  test('should handle house visualization', async ({ page }) => {
    await page.waitForSelector('[data-testid="city"]');
    
    // Cities should show existing houses as colored indicators
    const cities = page.locator('[data-testid="city"]');
    const firstCity = cities.first();
    
    // Check for house indicators
    const houseIndicators = firstCity.locator('.rounded-full[style*="background"]');
    
    // If houses exist, they should have player colors
    for (const house of await houseIndicators.all()) {
      const style = await house.getAttribute('style');
      expect(style).toContain('background');
    }
  });

  test('should validate money constraints', async ({ page }) => {
    // Get player money
    const moneyText = await page.locator('text=Your Money').locator('..').locator('.text-yellow-400').textContent();
    const playerMoney = parseInt(moneyText?.replace(/[^0-9]/g, '') || '0');
    
    await page.waitForSelector('[data-testid="city"]');
    const cities = page.locator('[data-testid="city"]');
    
    // Look for expensive cities
    for (const city of await cities.all()) {
      await city.click();
      
      const costElement = page.locator('text=Build Cost').locator('..').locator('.text-green-400');
      if (await costElement.isVisible()) {
        const costText = await costElement.textContent();
        const buildCost = parseInt(costText?.replace(/[^0-9]/g, '') || '0');
        
        if (buildCost > playerMoney) {
          // Should show constraint message
          const constraintText = city.locator('.text-red-400');
          if (await constraintText.isVisible()) {
            await expect(constraintText).toContainText('Need $');
          }
          
          // Build button should be disabled
          await expect(page.locator('button:has-text("Build in")')).toBeDisabled();
          break;
        }
      }
    }
  });

  test('should handle step restrictions', async ({ page }) => {
    // In step 1, should only allow building in empty cities
    // This test would need to be adapted based on actual game state
    
    await page.waitForSelector('[data-testid="city"]');
    const cities = page.locator('[data-testid="city"]');
    
    // Look for cities with existing houses
    for (const city of await cities.all()) {
      const houseCount = await city.locator('.rounded-full[style*="background"]').count();
      
      if (houseCount > 0) {
        await city.click();
        
        // Should show step restriction if in step 1
        const constraintText = city.locator('.text-red-400');
        if (await constraintText.isVisible()) {
          const constraint = await constraintText.textContent();
          if (constraint?.includes('Step 1')) {
            expect(constraint).toContain('empty cities');
          }
        }
      }
    }
  });

  test('should show connection costs', async ({ page }) => {
    await page.waitForSelector('[data-testid="city"]');
    const cities = page.locator('[data-testid="city"]');
    const firstCity = cities.first();
    
    if (await firstCity.isVisible()) {
      await firstCity.click();
      
      // Should show connection cost breakdown
      await expect(page.locator('text=Connection Cost:')).toBeVisible();
      
      // Connection cost should be reasonable (not infinity)
      const connectionCostElement = page.locator('text=Connection Cost:').locator('..').locator('.text-white');
      const costText = await connectionCostElement.textContent();
      const connectionCost = parseInt(costText?.replace(/[^0-9]/g, '') || '0');
      
      expect(connectionCost).toBeGreaterThanOrEqual(0);
      expect(connectionCost).toBeLessThan(1000); // Sanity check
    }
  });

  test('should handle pass/done building', async ({ page }) => {
    // Should show done building button
    const doneButton = page.locator('button:has-text("Done Building")');
    await expect(doneButton).toBeVisible();
    
    if (await doneButton.isEnabled()) {
      await doneButton.click();
      
      // Should show waiting state or move to next player/phase
      await expect(page.locator('text=Waiting for other players')).toBeVisible();
    }
  });

  test('should display building history', async ({ page }) => {
    // If buildings have been made, should show history
    const historySection = page.locator('text=Cities Built This Turn');
    
    if (await historySection.isVisible()) {
      // Should show player names and cities they built
      const buildingEntries = page.locator('[data-testid="building-entry"]');
      
      if (await buildingEntries.count() > 0) {
        const firstEntry = buildingEntries.first();
        
        // Should show player identifier
        await expect(firstEntry).toContainText(/You|Player/);
        
        // Should show number of cities
        await expect(firstEntry).toContainText(/\d+ cities/);
        
        // Should show city names
        await expect(firstEntry.locator('.text-xs')).toBeVisible();
        
        // Should show checkmark
        await expect(firstEntry.locator('[data-icon="check"]')).toBeVisible();
      }
    }
  });

  test('should handle turn-based building', async ({ page }) => {
    // Should show whose turn it is
    const currentBuilderText = page.locator('text=Current builder:');
    
    if (await currentBuilderText.isVisible()) {
      // Should display current builder name
      await expect(currentBuilderText.locator('..')).toContainText(/\w+/);
    }
    
    // When not player's turn, should show waiting message
    const waitingMessage = page.locator('text=Waiting for other players');
    if (await waitingMessage.isVisible()) {
      // Building controls should be disabled or hidden
      await expect(page.locator('button:has-text("Build in")')).toBeHidden();
    }
  });

  test('should show city capacity limits', async ({ page }) => {
    await page.waitForSelector('[data-testid="city"]');
    const cities = page.locator('[data-testid="city"]');
    
    // Look for cities with house capacity information
    for (const city of await cities.all()) {
      // Should show house count like "2/3 houses"
      const capacityText = city.locator('text=/\\d+\\/3 houses/');
      
      if (await capacityText.isVisible()) {
        const text = await capacityText.textContent();
        const [current, max] = text?.match(/(\d+)\/(\d+)/)?.slice(1, 3).map(Number) || [0, 0];
        
        expect(current).toBeLessThanOrEqual(max);
        expect(max).toBe(3); // Cities have max 3 houses
        
        // If city is full, should show constraint
        if (current === max) {
          await city.click();
          const constraintText = city.locator('.text-red-400');
          if (await constraintText.isVisible()) {
            await expect(constraintText).toContainText('full');
          }
        }
      }
    }
  });

  test('should handle mobile responsive layout', async ({ page }) => {
    // Test mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Touch targets should be appropriately sized
    const touchButtons = page.locator('.touch-target');
    for (const button of await touchButtons.all()) {
      const boundingBox = await button.boundingBox();
      if (boundingBox) {
        expect(boundingBox.height).toBeGreaterThanOrEqual(44);
      }
    }
    
    // City list should be easier to use on mobile
    const cityButtons = page.locator('button[data-testid="city-item"]');
    if (await cityButtons.count() > 0) {
      const firstCity = cityButtons.first();
      const boundingBox = await firstCity.boundingBox();
      if (boundingBox) {
        expect(boundingBox.height).toBeGreaterThanOrEqual(44);
      }
    }
  });
});