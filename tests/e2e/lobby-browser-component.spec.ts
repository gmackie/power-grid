import { test, expect } from '@playwright/test';

test.describe('LobbyBrowser Component', () => {
  test('should handle lobby data correctly', async ({ page }) => {
    // Navigate to the app
    await page.goto('http://localhost:5173');
    
    // Mock the WebSocket to send lobby data
    await page.addInitScript(() => {
      // Mock lobby data that matches what the server sends
      const mockLobbyData = {
        type: 'LOBBIES_LISTED',
        data: {
          lobbies: [
            {
              id: '123-test-lobby',
              name: 'Test Lobby',
              status: 'waiting',
              players: [
                {
                  id: 'player1',
                  name: 'Alice',
                  color: '#ff0000',
                  ready: true,
                  is_host: true
                }
              ],
              max_players: 6,
              map_id: 'usa',
              has_password: false,
              created_at: new Date().toISOString(),
              host_id: 'player1'
            }
          ]
        }
      };
      
      // Override WebSocket to immediately send mock data
      window.WebSocket = class MockWebSocket {
        onopen: ((event: Event) => void) | null = null;
        onmessage: ((event: MessageEvent) => void) | null = null;
        onclose: ((event: CloseEvent) => void) | null = null;
        onerror: ((event: Event) => void) | null = null;
        
        constructor(url: string) {
          setTimeout(() => {
            if (this.onopen) {
              this.onopen(new Event('open'));
            }
            // Send connection confirmation
            if (this.onmessage) {
              this.onmessage(new MessageEvent('message', {
                data: JSON.stringify({ type: 'CONNECTED', data: { session_id: 'test-session' } })
              }));
            }
            // Send lobby data
            if (this.onmessage) {
              this.onmessage(new MessageEvent('message', {
                data: JSON.stringify(mockLobbyData)
              }));
            }
          }, 100);
        }
        
        send(data: string) {
          console.log('MockWebSocket send:', data);
        }
        
        close() {
          console.log('MockWebSocket close');
        }
      };
    });
    
    // Wait for connection
    await page.waitForTimeout(1000);
    
    // Fill in player name
    await page.fill('input[placeholder="Enter your name"]', 'TestPlayer');
    
    // Click Browse Lobbies
    await page.click('button:has-text("Browse Lobbies")');
    
    // Wait for lobby browser to load
    await page.waitForSelector('h1:has-text("Browse Lobbies")', { timeout: 10000 });
    
    // Check if the lobby is displayed correctly
    const lobbyCard = await page.locator('[data-testid="lobby-card"]').first();
    await expect(lobbyCard).toBeVisible();
    
    // Check lobby details
    await expect(page.locator('text=Test Lobby')).toBeVisible();
    await expect(page.locator('text=1/6 players')).toBeVisible();
    await expect(page.locator('text=Map: usa')).toBeVisible();
    
    // Log any console errors
    page.on('console', msg => {
      console.log(`[${msg.type()}] ${msg.text()}`);
    });
  });
});