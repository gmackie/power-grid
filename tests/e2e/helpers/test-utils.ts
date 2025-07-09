import { Page, expect } from '@playwright/test';

/**
 * Common test utilities for Power Grid E2E tests
 */

export class TestUtils {
  constructor(private page: Page) {}

  /**
   * Navigate to a specific game phase by setting up a lobby and starting a game
   */
  async navigateToPhase(phase: 'auction' | 'resource' | 'building' | 'bureaucracy') {
    await this.page.goto('/');
    await this.page.click('text=Browse Lobbies');
    await this.page.click('text=Create Lobby');
    await this.page.fill('input[placeholder="Enter lobby name"]', `${phase} Test`);
    await this.page.selectOption('select[name="maxPlayers"]', '2');
    await this.page.click('button[type="submit"]');
    await this.page.fill('input[placeholder="Enter your name"]', 'Test Player');
    await this.page.click('[data-testid="start-game"]');
    
    // Wait for the specific phase
    await this.page.waitForSelector(`text=${this.capitalizeFirst(phase)} Phase`);
  }

  /**
   * Create a lobby with specific configuration
   */
  async createLobby(options: {
    name?: string;
    maxPlayers?: number;
    map?: string;
    playerName?: string;
  } = {}) {
    const {
      name = 'Test Lobby',
      maxPlayers = 2,
      map = 'usa',
      playerName = 'Test Player'
    } = options;

    await this.page.goto('/');
    await this.page.click('text=Browse Lobbies');
    await this.page.click('text=Create Lobby');
    await this.page.fill('input[placeholder="Enter lobby name"]', name);
    await this.page.selectOption('select[name="maxPlayers"]', maxPlayers.toString());
    
    if (map !== 'usa') {
      await this.page.selectOption('select[name="mapName"]', map);
    }
    
    await this.page.click('button[type="submit"]');
    await this.page.fill('input[placeholder="Enter your name"]', playerName);
    
    return {
      name,
      maxPlayers,
      map,
      playerName
    };
  }

  /**
   * Wait for WebSocket connection to be established
   */
  async waitForConnection() {
    await expect(this.page.locator('[data-testid="connection-status"]')).toContainText('Connected');
  }

  /**
   * Select a power plant in auction phase
   */
  async selectPowerPlant(plantIndex = 0) {
    await this.page.waitForSelector('[data-testid="power-plant"]');
    const plants = this.page.locator('[data-testid="power-plant"]');
    await plants.nth(plantIndex).click();
    
    // Verify selection
    await expect(plants.nth(plantIndex)).toHaveClass(/border-blue-500/);
  }

  /**
   * Place a bid in auction phase
   */
  async placeBid(amount: number) {
    await this.page.fill('input[label="Bid Amount"]', amount.toString());
    await this.page.click('button:has-text("Place Bid")');
  }

  /**
   * Buy resources in resource phase
   */
  async buyResources(resources: Record<string, number>) {
    for (const [resourceType, amount] of Object.entries(resources)) {
      const resourceRow = this.page.locator(`[data-testid="resource-row-${resourceType}"]`);
      if (await resourceRow.isVisible()) {
        const plusButton = resourceRow.locator('button').last();
        
        for (let i = 0; i < amount; i++) {
          if (await plusButton.isEnabled()) {
            await plusButton.click();
          }
        }
      }
    }
    
    const buyButton = this.page.locator('button:has-text("Buy Resources")');
    if (await buyButton.isEnabled()) {
      await buyButton.click();
    }
  }

  /**
   * Build in a city during building phase
   */
  async buildInCity(cityIndex = 0) {
    await this.page.waitForSelector('[data-testid="city"]');
    const cities = this.page.locator('[data-testid="city"]');
    await cities.nth(cityIndex).click();
    
    const buildButton = this.page.locator('button:has-text("Build in")');
    if (await buildButton.isEnabled()) {
      await buildButton.click();
    }
  }

  /**
   * Power cities in bureaucracy phase
   */
  async powerCities(plantIndices: number[] = [0]) {
    for (const index of plantIndices) {
      const plants = this.page.locator('[data-testid="power-plant"]');
      if (await plants.nth(index).isVisible()) {
        await plants.nth(index).click();
      }
    }
    
    const powerButton = this.page.locator('button:has-text("Power")');
    if (await powerButton.isEnabled()) {
      await powerButton.click();
    }
  }

  /**
   * Get player money amount
   */
  async getPlayerMoney(): Promise<number> {
    const moneyText = await this.page.locator('text=Your Money').locator('..').locator('.text-yellow-400').textContent();
    return parseInt(moneyText?.replace(/[^0-9]/g, '') || '0');
  }

  /**
   * Get number of cities owned by player
   */
  async getPlayerCities(): Promise<number> {
    const citiesText = await this.page.locator('text=Your Cities').locator('..').locator('.text-blue-400').textContent();
    return parseInt(citiesText || '0');
  }

  /**
   * Check if element is visible and enabled
   */
  async isInteractable(selector: string): Promise<boolean> {
    const element = this.page.locator(selector);
    return (await element.isVisible()) && (await element.isEnabled());
  }

  /**
   * Wait for phase transition
   */
  async waitForPhaseTransition(phaseName: string, timeout = 30000) {
    await this.page.waitForSelector(`text=${phaseName} Phase`, { timeout });
  }

  /**
   * Simulate mobile viewport
   */
  async setMobileViewport() {
    await this.page.setViewportSize({ width: 375, height: 667 });
  }

  /**
   * Validate touch target sizes for mobile
   */
  async validateTouchTargets(selector = '.touch-target') {
    const touchTargets = this.page.locator(selector);
    const count = await touchTargets.count();
    
    for (let i = 0; i < count; i++) {
      const target = touchTargets.nth(i);
      const boundingBox = await target.boundingBox();
      
      if (boundingBox) {
        expect(boundingBox.height).toBeGreaterThanOrEqual(44); // iOS minimum
        expect(boundingBox.width).toBeGreaterThanOrEqual(44);
      }
    }
  }

  /**
   * Take a screenshot with a descriptive name
   */
  async takeScreenshot(name: string) {
    await this.page.screenshot({ 
      path: `test-results/${name}-${Date.now()}.png`,
      fullPage: true 
    });
  }

  /**
   * Mock WebSocket connection failure
   */
  async mockConnectionFailure() {
    await this.page.route('**/ws', route => route.abort());
  }

  /**
   * Wait for loading states to complete
   */
  async waitForLoadingComplete() {
    // Wait for any loading spinners to disappear
    await this.page.waitForFunction(() => {
      const spinners = document.querySelectorAll('.loading, .spinner, [data-loading="true"]');
      return spinners.length === 0;
    }, { timeout: 10000 });
  }

  /**
   * Get text content safely (returns empty string if not found)
   */
  async getTextContent(selector: string): Promise<string> {
    try {
      const element = this.page.locator(selector);
      if (await element.isVisible()) {
        return await element.textContent() || '';
      }
      return '';
    } catch {
      return '';
    }
  }

  /**
   * Click element with retry logic
   */
  async clickWithRetry(selector: string, maxRetries = 3) {
    for (let i = 0; i < maxRetries; i++) {
      try {
        await this.page.click(selector, { timeout: 5000 });
        return;
      } catch (error) {
        if (i === maxRetries - 1) throw error;
        await this.page.waitForTimeout(1000);
      }
    }
  }

  /**
   * Capitalize first letter of string
   */
  private capitalizeFirst(str: string): string {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  /**
   * Generate random test data
   */
  static generateTestData() {
    return {
      lobbyName: `Test Lobby ${Math.random().toString(36).substr(2, 9)}`,
      playerName: `Player ${Math.random().toString(36).substr(2, 5)}`,
      bidAmount: Math.floor(Math.random() * 50) + 15, // 15-64
      resourceAmount: Math.floor(Math.random() * 5) + 1 // 1-5
    };
  }

  /**
   * Assert error message appears
   */
  async assertErrorMessage(expectedMessage?: string) {
    const errorNotification = this.page.locator('[data-testid="error-notification"]');
    await expect(errorNotification).toBeVisible();
    
    if (expectedMessage) {
      await expect(errorNotification).toContainText(expectedMessage);
    }
  }

  /**
   * Assert success message appears
   */
  async assertSuccessMessage(expectedMessage?: string) {
    const successNotification = this.page.locator('[data-testid="success-notification"]');
    await expect(successNotification).toBeVisible();
    
    if (expectedMessage) {
      await expect(successNotification).toContainText(expectedMessage);
    }
  }
}

/**
 * Create a TestUtils instance for a page
 */
export function createTestUtils(page: Page): TestUtils {
  return new TestUtils(page);
}