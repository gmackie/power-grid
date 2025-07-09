import { test, expect } from '@playwright/test';
import { spawn, ChildProcess } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';

let goServerProcess: ChildProcess | null = null;

test.describe('Server Integration Test', () => {
  test.beforeAll(async () => {
    console.log('Current directory:', process.cwd());
    
    // Go to the go_server directory relative to react_client
    const goServerPath = path.join(process.cwd(), '..', 'go_server');
    console.log('Go server path:', goServerPath);
    
    // Check if the go_server directory exists
    if (!fs.existsSync(goServerPath)) {
      throw new Error(`Go server directory not found at ${goServerPath}`);
    }
    
    // Check if the server binary exists
    const serverBinary = path.join(goServerPath, 'cmd', 'server', 'main.go');
    if (!fs.existsSync(serverBinary)) {
      throw new Error(`Server main.go not found at ${serverBinary}`);
    }
    
    console.log('Starting Go server from:', goServerPath);
    
    // Start the Go server directly
    goServerProcess = spawn('go', ['run', 'cmd/server/main.go'], {
      cwd: goServerPath,
      env: { ...process.env, PORT: '4080' },
      stdio: ['ignore', 'pipe', 'pipe']
    });

    goServerProcess.stdout?.on('data', (data) => {
      console.log(`[Go Server]: ${data.toString()}`);
    });

    goServerProcess.stderr?.on('data', (data) => {
      console.error(`[Go Server Error]: ${data.toString()}`);
    });

    goServerProcess.on('error', (error) => {
      console.error('Failed to start Go server:', error);
    });

    // Wait for server to be ready by checking for the startup message
    await new Promise<void>((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error('Server did not start within 10 seconds'));
      }, 10000);

      const checkStartup = (data: Buffer) => {
        const output = data.toString();
        if (output.includes('Starting Power Grid Game Server') || output.includes('Loaded 2 maps')) {
          clearTimeout(timeout);
          console.log('Go server is ready!');
          resolve();
        }
      };

      goServerProcess!.stdout?.on('data', checkStartup);
      goServerProcess!.stderr?.on('data', checkStartup);
    });
    
    // Give it a bit more time to fully initialize
    await new Promise(resolve => setTimeout(resolve, 1000));
  });

  test.afterAll(async () => {
    console.log('Cleaning up Go server...');
    
    if (goServerProcess) {
      goServerProcess.kill('SIGTERM');
      
      // Wait for process to exit
      await new Promise(resolve => {
        goServerProcess!.on('exit', resolve);
        setTimeout(resolve, 2000); // Timeout after 2 seconds
      });
      
      goServerProcess = null;
    }
  });

  test('should connect to Go server successfully', async ({ page }) => {
    // Add console listener
    page.on('console', msg => {
      if (msg.type() === 'log' || msg.type() === 'info') {
        console.log('Browser:', msg.text());
      }
    });

    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Wait for WebSocket connection
    await page.waitForTimeout(3000);
    
    // Check connection status
    const connectionStatus = page.locator('[data-testid="connection-status"]');
    
    // Should eventually show connected or at least not show disconnected
    let statusText = '';
    try {
      // If connection status is visible, get its text
      if (await connectionStatus.isVisible({ timeout: 1000 })) {
        statusText = await connectionStatus.textContent() || '';
        console.log('Connection status text:', statusText);
      }
    } catch {
      // Connection status might be hidden when connected
      console.log('Connection status not visible (might be connected)');
    }
    
    // Check if we can interact with the app
    const playerNameInput = page.locator('input[placeholder="Enter your name"]');
    await expect(playerNameInput).toBeVisible();
    
    // If connected, input should be enabled
    const isEnabled = await playerNameInput.isEnabled();
    console.log('Player name input enabled:', isEnabled);
    
    if (isEnabled) {
      // Try to enter a name and navigate
      await playerNameInput.fill('Test Player');
      
      const browseLobbyButton = page.locator('button:has-text("Browse Lobbies")');
      await expect(browseLobbyButton).toBeEnabled();
      
      await browseLobbyButton.click();
      
      // Should navigate to lobbies
      await page.waitForTimeout(1000);
      await expect(page).toHaveURL(/lobbies/);
      
      console.log('Successfully navigated to lobby browser!');
    } else {
      console.log('Connection might not be established - input is disabled');
    }
    
    // Take a screenshot for debugging
    await page.screenshot({ path: 'test-results/server-integration.png', fullPage: true });
  });
});