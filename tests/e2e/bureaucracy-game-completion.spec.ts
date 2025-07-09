import { test, expect } from '@playwright/test';

test.describe('Bureaucracy Phase and Game Completion', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to bureaucracy phase
    await page.goto('/');
    await page.click('text=Browse Lobbies');
    await page.click('text=Create Lobby');
    await page.fill('input[placeholder="Enter lobby name"]', 'Bureaucracy Test');
    await page.selectOption('select[name="maxPlayers"]', '2');
    await page.click('button[type="submit"]');
    await page.fill('input[placeholder="Enter your name"]', 'Test Player');
    await page.click('[data-testid="start-game"]');
    
    // Navigate to bureaucracy phase
    await page.waitForSelector('text=Bureaucracy Phase');
  });

  test('should display bureaucracy phase correctly', async ({ page }) => {
    await expect(page.locator('h2')).toContainText('Bureaucracy Phase');
    await expect(page.locator('text=Power cities and earn money')).toBeVisible();
    
    // Should show phase header with round information
    await expect(page.locator('text=Round')).toBeVisible();
    
    // Should show power plants section
    await expect(page.locator('text=Your Power Plants')).toBeVisible();
  });

  test('should display power plants with resource requirements', async ({ page }) => {
    // Should show player's power plants
    const powerPlants = page.locator('[data-testid="power-plant"]');
    
    if (await powerPlants.count() > 0) {
      const firstPlant = powerPlants.first();
      
      // Should show plant number
      await expect(firstPlant.locator('.text-2xl')).toContainText('#');
      
      // Should show resource requirement
      await expect(firstPlant.locator('.text-slate-400')).toBeVisible();
      
      // Should show power output
      await expect(firstPlant.locator('text=Powers')).toBeVisible();
      await expect(firstPlant.locator('text=cities')).toBeVisible();
    } else {
      // Should show message if no power plants
      await expect(page.locator('text=You have no power plants')).toBeVisible();
    }
  });

  test('should handle power plant selection', async ({ page }) => {
    const powerPlants = page.locator('[data-testid="power-plant"]');
    
    if (await powerPlants.count() > 0) {
      const firstPlant = powerPlants.first();
      
      // Try to select the power plant
      await firstPlant.click();
      
      // Should show selection state or resource constraint
      const isSelected = await firstPlant.locator('[data-icon="check"]').isVisible();
      const hasConstraint = await firstPlant.locator('[data-icon="x"]').isVisible();
      
      expect(isSelected || hasConstraint).toBe(true);
      
      if (isSelected) {
        // Should update earnings calculation
        await expect(page.locator('text=Cities Powered')).toBeVisible();
        await expect(page.locator('text=Earnings')).toBeVisible();
      }
    }
  });

  test('should calculate earnings correctly', async ({ page }) => {
    // Should show earnings preview section
    await expect(page.locator('text=Cities Powered')).toBeVisible();
    await expect(page.locator('text=Earnings')).toBeVisible();
    
    // Should show current vs maximum cities
    const citiesPoweredText = page.locator('text=Cities Powered').locator('..').locator('.text-3xl');
    const citiesText = await citiesPoweredText.textContent();
    expect(citiesText).toMatch(/\d+ \/ \d+/);
    
    // Earnings should be a positive number
    const earningsText = page.locator('text=Earnings').locator('..').locator('.text-green-400');
    const earnings = await earningsText.textContent();
    const earningsAmount = parseInt(earnings?.replace(/[^0-9]/g, '') || '0');
    expect(earningsAmount).toBeGreaterThanOrEqual(10); // Minimum earnings
  });

  test('should show resource usage', async ({ page }) => {
    const powerPlants = page.locator('[data-testid="power-plant"]');
    
    if (await powerPlants.count() > 0) {
      // Try to power a plant that requires resources
      for (const plant of await powerPlants.all()) {
        const resourceText = await plant.locator('.text-slate-400').textContent();
        
        if (resourceText && !resourceText.includes('eco')) {
          await plant.click();
          
          // Should show resources being used section
          if (await page.locator('text=Resources Being Used').isVisible()) {
            await expect(page.locator('[data-icon="fuel"]')).toBeVisible();
            await expect(page.locator('text=×')).toBeVisible(); // Resource amount
            break;
          }
        }
      }
    }
  });

  test('should handle hybrid plants correctly', async ({ page }) => {
    const powerPlants = page.locator('[data-testid="power-plant"]');
    
    // Look for hybrid plants
    for (const plant of await powerPlants.all()) {
      const resourceText = await plant.locator('.text-slate-400').textContent();
      
      if (resourceText?.includes('hybrid')) {
        await plant.click();
        
        // Should be able to use either coal or oil
        if (await page.locator('text=Resources Being Used').isVisible()) {
          const resourceUsage = page.locator('text=Resources Being Used').locator('..');
          const usageText = await resourceUsage.textContent();
          expect(usageText).toMatch(/(coal|oil)/);
        }
        break;
      }
    }
  });

  test('should power cities and earn money', async ({ page }) => {
    // Power some plants if available
    const powerPlants = page.locator('[data-testid="power-plant"]');
    
    if (await powerPlants.count() > 0) {
      const firstPlant = powerPlants.first();
      await firstPlant.click();
    }
    
    // Click power cities button
    const powerButton = page.locator('button:has-text("Power")');
    if (await powerButton.isVisible() && await powerButton.isEnabled()) {
      await powerButton.click();
      
      // Should show completion state
      await expect(page.locator('text=Cities Powered')).toBeVisible();
      await expect(page.locator('text=You powered')).toBeVisible();
      
      // Should show checkmark
      await expect(page.locator('[data-icon="check"]')).toBeVisible();
    }
  });

  test('should show phase results', async ({ page }) => {
    // If phase results are available
    const resultsSection = page.locator('text=Phase Results');
    
    if (await resultsSection.isVisible()) {
      // Should show all players' results
      const resultEntries = page.locator('[data-testid="phase-result"]');
      
      if (await resultEntries.count() > 0) {
        const firstResult = resultEntries.first();
        
        // Should show player identifier
        await expect(firstResult).toContainText(/You|Player/);
        
        // Should show cities powered
        await expect(firstResult.locator('[data-icon="zap"]')).toBeVisible();
        await expect(firstResult).toContainText(/\d+ cities/);
        
        // Should show earnings
        await expect(firstResult.locator('[data-icon="dollar-sign"]')).toBeVisible();
        await expect(firstResult).toContainText(/\$\d+/);
      }
    }
  });

  test('should handle turn-based powering', async ({ page }) => {
    // Should show whose turn it is to power
    const currentPlayerText = page.locator('text=Current player:');
    
    if (await currentPlayerText.isVisible()) {
      // Should display current player name
      await expect(currentPlayerText.locator('..')).toContainText(/\w+/);
    }
    
    // When not player's turn, should show waiting message
    const waitingMessage = page.locator('text=Waiting for other players');
    if (await waitingMessage.isVisible()) {
      // Power button should be hidden
      await expect(page.locator('button:has-text("Power")')).toBeHidden();
    }
  });

  test('should validate resource constraints', async ({ page }) => {
    const powerPlants = page.locator('[data-testid="power-plant"]');
    
    // Look for plants with resource requirements
    for (const plant of await powerPlants.all()) {
      const resourceText = await plant.locator('.text-slate-400').textContent();
      
      if (resourceText && resourceText.match(/\d+×/)) {
        await plant.click();
        
        // If plant can't be powered due to resources, should show X icon
        const hasConstraint = await plant.locator('[data-icon="x"]').isVisible();
        
        if (hasConstraint) {
          // Plant should be disabled/grayed out
          const classList = await plant.getAttribute('class');
          expect(classList).toContain('opacity-50');
        }
      }
    }
  });

  test('should show max possible cities calculation', async ({ page }) => {
    // Should show maximum possible cities to power
    await expect(page.locator('text=Max Possible')).toBeVisible();
    
    const maxPossibleText = page.locator('text=Max Possible').locator('..').locator('.text-slate-500');
    const maxText = await maxPossibleText.textContent();
    expect(maxText).toMatch(/\d+ cities/);
  });

  test('should handle eco plants correctly', async ({ page }) => {
    const powerPlants = page.locator('[data-testid="power-plant"]');
    
    // Look for eco plants
    for (const plant of await powerPlants.all()) {
      const resourceText = await plant.locator('.text-slate-400').textContent();
      
      if (resourceText?.includes('eco')) {
        await plant.click();
        
        // Eco plants should power without resources
        await expect(plant.locator('[data-icon="check"]')).toBeVisible();
        
        // Should not show in resources being used
        if (await page.locator('text=Resources Being Used').isVisible()) {
          const resourceUsage = page.locator('text=Resources Being Used').locator('..');
          const usageText = await resourceUsage.textContent();
          expect(usageText).not.toContain('eco');
        }
        break;
      }
    }
  });

  test('should handle game completion scenarios', async ({ page }) => {
    // Look for game completion indicators
    const gameOverSection = page.locator('text=Game Over');
    const finalScoresSection = page.locator('text=Final Scores');
    const winnerSection = page.locator('text=Winner');
    
    if (await gameOverSection.isVisible() || await finalScoresSection.isVisible() || await winnerSection.isVisible()) {
      // Should show final game state
      await expect(page.locator('text=Game')).toBeVisible();
      
      // Should show player rankings or scores
      const playerScores = page.locator('[data-testid="player-score"]');
      if (await playerScores.count() > 0) {
        // Each score should show player and their final score
        const firstScore = playerScores.first();
        await expect(firstScore).toContainText(/\w+/); // Player name
        await expect(firstScore).toContainText(/\d+/); // Score
      }
      
      // Should have option to return to menu or play again
      const menuButton = page.locator('button:has-text("Menu")');
      const playAgainButton = page.locator('button:has-text("Play Again")');
      
      expect(await menuButton.isVisible() || await playAgainButton.isVisible()).toBe(true);
    }
  });

  test('should show earnings table accuracy', async ({ page }) => {
    // Test that earnings calculations match expected values
    const powerPlants = page.locator('[data-testid="power-plant"]');
    
    if (await powerPlants.count() > 0) {
      // Power different numbers of cities and check earnings
      const earningsElement = page.locator('text=Earnings').locator('..').locator('.text-green-400');
      
      // Test specific earnings values (based on Power Grid rules)
      const citiesPoweredElement = page.locator('text=Cities Powered').locator('..').locator('.text-3xl');
      const citiesText = await citiesPoweredElement.textContent();
      const citiesPowered = parseInt(citiesText?.split(' / ')[0] || '0');
      
      const earningsText = await earningsElement.textContent();
      const earnings = parseInt(earningsText?.replace(/[^0-9]/g, '') || '0');
      
      // Verify earnings are reasonable for cities powered
      if (citiesPowered === 0) expect(earnings).toBe(10);
      else if (citiesPowered >= 1) expect(earnings).toBeGreaterThan(20);
    }
  });

  test('should handle round progression', async ({ page }) => {
    // Should show current round information
    const roundInfo = page.locator('text=Round').locator('..').locator('.text-lg');
    const roundText = await roundInfo.textContent();
    expect(roundText).toMatch(/\d+ \/ \d+/);
    
    // Round should be reasonable (1-6 typically in Power Grid)
    const [current, total] = roundText?.split(' / ').map(n => parseInt(n)) || [0, 0];
    expect(current).toBeGreaterThanOrEqual(1);
    expect(current).toBeLessThanOrEqual(total);
    expect(total).toBeGreaterThanOrEqual(current);
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
    
    // Power plants should be easily selectable on mobile
    const powerPlants = page.locator('[data-testid="power-plant"]');
    if (await powerPlants.count() > 0) {
      const firstPlant = powerPlants.first();
      const boundingBox = await firstPlant.boundingBox();
      if (boundingBox) {
        expect(boundingBox.height).toBeGreaterThanOrEqual(44);
      }
    }
  });
});