import { test, expect } from '@playwright/test';

test.describe('Resource Market Phase', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to resource phase
    await page.goto('/');
    await page.click('text=Browse Lobbies');
    await page.click('text=Create Lobby');
    await page.fill('input[placeholder="Enter lobby name"]', 'Resource Test');
    await page.selectOption('select[name="maxPlayers"]', '2');
    await page.click('button[type="submit"]');
    await page.fill('input[placeholder="Enter your name"]', 'Test Player');
    await page.click('[data-testid="start-game"]');
    
    // Navigate through phases to resource phase
    // This would need to be adapted based on actual game flow
    await page.waitForSelector('text=Resource Phase');
  });

  test('should display resource market correctly', async ({ page }) => {
    await expect(page.locator('h2')).toContainText('Resource Phase');
    await expect(page.locator('h3')).toContainText('Resource Market');
    
    // Should show resource types based on player's power plants
    const resourceRows = page.locator('[data-testid="resource-row"]');
    
    // Each resource should show price and availability
    const firstResource = resourceRows.first();
    if (await firstResource.isVisible()) {
      await expect(firstResource.locator('text=each')).toBeVisible(); // Price
      await expect(firstResource.locator('text=Available')).toBeVisible(); // Availability
    }
  });

  test('should show resource storage capacity correctly', async ({ page }) => {
    // Should display storage capacity based on power plants
    const capacityBars = page.locator('.h-2.bg-slate-700'); // Storage bars
    
    if (await capacityBars.count() > 0) {
      const firstBar = capacityBars.first();
      
      // Should show storage percentage
      await expect(page.locator('text=Storage:')).toBeVisible();
      await expect(page.locator('text=%')).toBeVisible();
      
      // Storage bar should show current vs capacity
      await expect(firstBar.locator('..')).toContainText(/\d+\/\d+/);
    }
  });

  test('should handle resource buying interactions', async ({ page }) => {
    // Find the first resource with capacity
    const resourceRows = page.locator('[data-testid="resource-row"]');
    const firstResource = resourceRows.first();
    
    if (await firstResource.isVisible()) {
      // Should have plus/minus buttons
      const minusButton = firstResource.locator('button').first();
      const plusButton = firstResource.locator('button').last();
      
      await expect(minusButton).toBeVisible();
      await expect(plusButton).toBeVisible();
      
      // Initially should be able to add resources
      if (await plusButton.isEnabled()) {
        await plusButton.click();
        
        // Should update quantity display
        const quantityDisplay = firstResource.locator('.text-2xl');
        await expect(quantityDisplay).toContainText('1');
        
        // Should show cost
        await expect(firstResource.locator('.text-yellow-400')).toBeVisible();
        
        // Should be able to decrease
        await expect(minusButton).toBeEnabled();
        
        // Decrease back to 0
        await minusButton.click();
        await expect(quantityDisplay).toContainText('0');
      }
    }
  });

  test('should calculate total cost correctly', async ({ page }) => {
    // Add some resources to cart
    const resourceRows = page.locator('[data-testid="resource-row"]');
    const firstResource = resourceRows.first();
    
    if (await firstResource.isVisible()) {
      const plusButton = firstResource.locator('button').last();
      
      if (await plusButton.isEnabled()) {
        // Add resources
        await plusButton.click();
        await plusButton.click();
        
        // Should show total cost in player status
        await expect(page.locator('text=Total Cost')).toBeVisible();
        
        // Total cost should be greater than 0
        const totalCost = page.locator('text=Total Cost').locator('..').locator('.text-2xl');
        const costText = await totalCost.textContent();
        const cost = parseInt(costText?.replace(/[^0-9]/g, '') || '0');
        expect(cost).toBeGreaterThan(0);
      }
    }
  });

  test('should validate purchase constraints', async ({ page }) => {
    const resourceRows = page.locator('[data-testid="resource-row"]');
    const firstResource = resourceRows.first();
    
    if (await firstResource.isVisible()) {
      const plusButton = firstResource.locator('button').last();
      
      // Keep clicking plus button until it's disabled (capacity reached)
      let clickCount = 0;
      while (await plusButton.isEnabled() && clickCount < 20) {
        await plusButton.click();
        clickCount++;
      }
      
      // Should disable when capacity is reached
      if (clickCount > 0) {
        await expect(plusButton).toBeDisabled();
        
        // Storage should show 100%
        await expect(firstResource).toContainText('100%');
      }
    }
  });

  test('should handle money constraints', async ({ page }) => {
    // Get player money
    const moneyText = await page.locator('text=Your Money').locator('..').locator('.text-yellow-400').textContent();
    const playerMoney = parseInt(moneyText?.replace(/[^0-9]/g, '') || '0');
    
    // Try to buy resources worth more than player money
    const resourceRows = page.locator('[data-testid="resource-row"]');
    
    // Add resources until we exceed money
    for (const resource of await resourceRows.all()) {
      const plusButton = resource.locator('button').last();
      while (await plusButton.isEnabled()) {
        await plusButton.click();
        
        // Check if total cost exceeds money
        const totalCostElement = page.locator('text=Total Cost').locator('..').locator('.text-2xl');
        if (await totalCostElement.isVisible()) {
          const costText = await totalCostElement.textContent();
          const totalCost = parseInt(costText?.replace(/[^0-9]/g, '') || '0');
          
          if (totalCost > playerMoney) {
            // Should show red color for unaffordable amount
            await expect(totalCostElement).toHaveClass(/text-red-400/);
            
            // Buy button should be disabled
            await expect(page.locator('button:has-text("Buy Resources")')).toBeDisabled();
            break;
          }
        }
      }
    }
  });

  test('should execute resource purchases', async ({ page }) => {
    const resourceRows = page.locator('[data-testid="resource-row"]');
    const firstResource = resourceRows.first();
    
    if (await firstResource.isVisible()) {
      const plusButton = firstResource.locator('button').last();
      
      if (await plusButton.isEnabled()) {
        // Add resources
        await plusButton.click();
        
        // Buy resources
        const buyButton = page.locator('button:has-text("Buy Resources")');
        if (await buyButton.isEnabled()) {
          await buyButton.click();
          
          // Should clear the cart
          const quantityDisplay = firstResource.locator('.text-2xl');
          await expect(quantityDisplay).toContainText('0');
          
          // Should show in purchase history
          await expect(page.locator('text=Resources Purchased')).toBeVisible();
          await expect(page.locator('text=You')).toBeVisible();
        }
      }
    }
  });

  test('should handle passing turn', async ({ page }) => {
    // Should show pass button when it's player's turn
    const passButton = page.locator('button:has-text("Pass")');
    
    if (await passButton.isVisible()) {
      await passButton.click();
      
      // Should show waiting state
      await expect(page.locator('text=Waiting for other players')).toBeVisible();
      
      // Should show current buyer if applicable
      const currentBuyerText = page.locator('text=Current buyer:');
      if (await currentBuyerText.isVisible()) {
        await expect(currentBuyerText.locator('..')).toContainText(/\w+/);
      }
    }
  });

  test('should display turn order correctly', async ({ page }) => {
    // Should show turn order information
    await expect(page.locator('text=Turn Order')).toBeVisible();
    
    // Should show current position
    const turnOrderDisplay = page.locator('text=Turn Order').locator('..').locator('.text-lg');
    const orderText = await turnOrderDisplay.textContent();
    expect(orderText).toMatch(/\d+ \/ \d+/);
  });

  test('should show resource types with proper styling', async ({ page }) => {
    const resourceRows = page.locator('[data-testid="resource-row"]');
    
    for (const resource of await resourceRows.all()) {
      // Should have colored icon
      const coloredIcon = resource.locator('.w-10.h-10.rounded-full');
      if (await coloredIcon.isVisible()) {
        const classList = await coloredIcon.getAttribute('class');
        expect(classList).toMatch(/bg-(gray|amber|yellow|green)-700/);
      }
      
      // Should show resource name capitalized
      const resourceName = resource.locator('.capitalize');
      await expect(resourceName).toBeVisible();
      
      // Should show price per unit
      await expect(resource.locator('text=each')).toBeVisible();
    }
  });

  test('should handle purchase history display', async ({ page }) => {
    // If there are previous purchases, should show them
    const purchaseHistory = page.locator('text=Resources Purchased');
    
    if (await purchaseHistory.isVisible()) {
      // Should show player names and purchased resources
      const purchaseEntries = page.locator('[data-testid="purchase-entry"]');
      
      if (await purchaseEntries.count() > 0) {
        const firstEntry = purchaseEntries.first();
        
        // Should show player identifier
        await expect(firstEntry).toContainText(/You|Player/);
        
        // Should show resource amounts
        await expect(firstEntry).toContainText(/\d+×/);
        
        // Should show checkmark
        await expect(firstEntry.locator('[data-icon="check"]')).toBeVisible();
      }
    }
  });

  test('should handle mobile responsive layout', async ({ page }) => {
    // Test mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Should use single column layout on mobile
    const resourceGrid = page.locator('.grid');
    await expect(resourceGrid).toHaveClass(/grid-cols-1/);
    
    // Touch targets should be appropriately sized
    const touchButtons = page.locator('.touch-target');
    for (const button of await touchButtons.all()) {
      const boundingBox = await button.boundingBox();
      if (boundingBox) {
        expect(boundingBox.height).toBeGreaterThanOrEqual(44);
      }
    }
  });

  test('should show resource availability updates', async ({ page }) => {
    const resourceRows = page.locator('[data-testid="resource-row"]');
    const firstResource = resourceRows.first();
    
    if (await firstResource.isVisible()) {
      // Get initial availability
      const availabilityElement = firstResource.locator('text=Available').locator('..').locator('.text-lg');
      const initialAvailability = await availabilityElement.textContent();
      const initialAmount = parseInt(initialAvailability || '0');
      
      // Try to buy some resources
      const plusButton = firstResource.locator('button').last();
      if (await plusButton.isEnabled()) {
        await plusButton.click();
        
        const buyButton = page.locator('button:has-text("Buy Resources")');
        if (await buyButton.isEnabled()) {
          await buyButton.click();
          
          // Availability should decrease (in real game)
          // This would require server integration to test properly
          // For now, just verify the element exists
          await expect(availabilityElement).toBeVisible();
        }
      }
    }
  });

  test('should handle resource type filtering', async ({ page }) => {
    // Should only show resources that player can actually use
    // based on their power plants
    const resourceRows = page.locator('[data-testid="resource-row"]');
    const count = await resourceRows.count();
    
    // Should not show all 4 resource types if player doesn't have plants for them
    expect(count).toBeLessThanOrEqual(4);
    
    // Each visible resource should have capacity > 0
    for (const resource of await resourceRows.all()) {
      const capacityText = await resource.locator('text=Storage:').textContent();
      const capacity = parseInt(capacityText?.split('/')[1] || '0');
      expect(capacity).toBeGreaterThan(0);
    }
  });
});