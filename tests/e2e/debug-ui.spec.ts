import { test, expect } from '@playwright/test';

test.describe('Debug UI', () => {
  test('check what appears on the homepage', async ({ page }) => {
    console.log('=== Debugging UI State ===');

    await page.goto('http://localhost:5173');
    await page.waitForTimeout(3000);

    // Take a screenshot to see what's actually displayed
    await page.screenshot({ 
      path: 'test-results/homepage-debug.png',
      fullPage: true 
    });

    // Get page title and any visible text
    const title = await page.title();
    console.log('Page title:', title);

    // Check what buttons are visible
    const buttons = page.locator('button');
    const buttonCount = await buttons.count();
    console.log('Number of buttons found:', buttonCount);

    for (let i = 0; i < buttonCount; i++) {
      const buttonText = await buttons.nth(i).textContent();
      console.log(`Button ${i}: "${buttonText}"`);
    }

    // Check for headings
    const headings = page.locator('h1, h2, h3');
    const headingCount = await headings.count();
    console.log('Number of headings found:', headingCount);

    for (let i = 0; i < headingCount; i++) {
      const headingText = await headings.nth(i).textContent();
      console.log(`Heading ${i}: "${headingText}"`);
    }

    // Check if there are any errors in console
    let hasErrors = false;
    page.on('console', msg => {
      if (msg.type() === 'error') {
        console.log('Console error:', msg.text());
        hasErrors = true;
      }
    });

    // Wait a bit to catch any console errors
    await page.waitForTimeout(2000);

    console.log('Has console errors:', hasErrors);

    // Check if page has loaded
    const bodyText = await page.locator('body').textContent();
    console.log('Body contains "Power Grid":', bodyText?.includes('Power Grid'));
    console.log('Body contains "Play Online":', bodyText?.includes('Play Online'));

    expect(true).toBeTruthy(); // Always pass, this is just for debugging
  });
});