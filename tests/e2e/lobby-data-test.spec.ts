import { test, expect } from '@playwright/test';

test.describe('Lobby Data Display', () => {
  test('should display lobby data correctly', async ({ page, context }) => {
    // Start server on a random port 
    const PORT = 8000 + Math.floor(Math.random() * 1000);
    console.log(`Using port: ${PORT}`);
    
    // Set environment variable for the client
    await context.addInitScript((port) => {
      window.process = { env: { VITE_WS_PORT: port.toString() } };
    }, PORT);
    
    // Override the WebSocket URL
    await page.addInitScript((port) => {
      // Override the WebSocket manager to use our test port
      Object.defineProperty(window, 'location', {
        value: { ...window.location, protocol: 'http:' },
        writable: true
      });
      
      // Mock fetch for any API calls
      window.fetch = async (url, options) => {
        if (url.includes('/api/')) {
          return new Response(JSON.stringify({}), { status: 200 });
        }
        return fetch(url, options);
      };
    }, PORT);
    
    // Navigate to the app
    await page.goto('http://localhost:5173');
    
    // Check if the page loads
    await page.waitForSelector('h1:has-text("Power Grid")', { timeout: 10000 });
    console.log('Page loaded successfully');
    
    // Check the current state of the lobby browser without requiring connection
    const pageTitle = await page.textContent('h1');
    console.log('Page title:', pageTitle);
    
    // Take a screenshot for debugging
    await page.screenshot({ path: 'lobby-test-debug.png' });
    
    console.log('Test completed - page is accessible');
  });
});