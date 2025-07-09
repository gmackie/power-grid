import { test, expect } from '@playwright/test';

test.describe('Debug Lobby Browser', () => {
  test('check lobby browser UI', async ({ page }) => {
    console.log('=== Debugging Lobby Browser ===');

    await page.goto('http://localhost:5173');
    
    // Wait for name input and fill it
    const nameInput = page.locator('input[placeholder="Enter your name"]');
    await nameInput.waitFor({ state: 'visible', timeout: 5000 });
    
    // Wait for WebSocket connection
    let attempts = 0;
    while (!(await nameInput.isEnabled()) && attempts < 15) {
      await page.waitForTimeout(1000);
      attempts++;
    }
    
    await nameInput.fill('TestPlayer');
    await page.waitForTimeout(2000);
    
    // Navigate to lobby browser
    await page.click('button:has-text("Browse Lobbies")');
    await page.waitForSelector('h1:has-text("Lobbies")');
    
    // Take a screenshot to see what's actually displayed
    await page.screenshot({ 
      path: 'test-results/lobby-browser-debug.png',
      fullPage: true 
    });

    // Check what buttons are visible
    const buttons = page.locator('button');
    const buttonCount = await buttons.count();
    console.log('Number of buttons found:', buttonCount);

    for (let i = 0; i < buttonCount; i++) {
      const buttonText = await buttons.nth(i).textContent();
      const isVisible = await buttons.nth(i).isVisible();
      console.log(`Button ${i}: "${buttonText}" (visible: ${isVisible})`);
    }

    // Check for headings
    const headings = page.locator('h1, h2, h3');
    const headingCount = await headings.count();
    console.log('Number of headings found:', headingCount);

    for (let i = 0; i < headingCount; i++) {
      const headingText = await headings.nth(i).textContent();
      console.log(`Heading ${i}: "${headingText}"`);
    }

    // Check for any forms or inputs
    const inputs = page.locator('input');
    const inputCount = await inputs.count();
    console.log('Number of inputs found:', inputCount);

    for (let i = 0; i < inputCount; i++) {
      const placeholder = await inputs.nth(i).getAttribute('placeholder');
      const type = await inputs.nth(i).getAttribute('type');
      console.log(`Input ${i}: placeholder="${placeholder}" type="${type}"`);
    }

    expect(true).toBeTruthy(); // Always pass, this is just for debugging
  });
});