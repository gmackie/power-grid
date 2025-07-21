import { test, expect } from '@playwright/test';
import { getRandomName, waitForWebSocket } from './helpers/test-utils';

test.describe('Admin Simulated Games', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForWebSocket(page);
    await page.click('button:has-text("Admin Dashboard")');
    await page.waitForLoadState('networkidle');
  });

  test('should create simulated game with AI players', async ({ page }) => {
    // Navigate to create simulated game section
    await page.click('button:has-text("System")');
    
    // Look for create simulated game button
    await page.click('button:has-text("Create Simulated Game")');
    
    // Fill in game configuration
    await expect(page.getByRole('heading', { name: 'Create Simulated Game' })).toBeVisible();
    
    // Configure game settings
    await page.fill('input[placeholder="Game name"]', 'AI Test Game');
    
    // Select number of AI players
    await page.selectOption('select[name="aiPlayerCount"]', '4');
    
    // Select AI difficulty
    await page.selectOption('select[name="aiDifficulty"]', 'medium');
    
    // Select map
    await page.selectOption('select[name="mapId"]', 'usa');
    
    // Configure game speed
    await page.selectOption('select[name="gameSpeed"]', 'fast');
    
    // Create the game
    await page.click('button:has-text("Create Game")');
    
    // Verify game was created
    await expect(page.getByText('Simulated game created successfully')).toBeVisible();
    
    // Should redirect to game monitor
    await expect(page.getByRole('heading', { name: 'Game Monitor' })).toBeVisible();
    await expect(page.getByText('AI Test Game')).toBeVisible();
  });

  test('should display list of simulated games', async ({ page }) => {
    // Navigate to simulated games section
    await page.click('button:has-text("Analytics")');
    await page.click('a:has-text("Simulated Games")');
    
    // Should show list of simulated games
    await expect(page.getByRole('heading', { name: 'Simulated Games' })).toBeVisible();
    
    // Should have columns for game info
    await expect(page.getByText('Game ID')).toBeVisible();
    await expect(page.getByText('Status')).toBeVisible();
    await expect(page.getByText('AI Players')).toBeVisible();
    await expect(page.getByText('Duration')).toBeVisible();
    await expect(page.getByText('Actions')).toBeVisible();
  });

  test('should monitor AI game in real-time', async ({ page }) => {
    // Navigate to an existing simulated game
    await page.click('button:has-text("Analytics")');
    await page.click('a:has-text("Simulated Games")');
    
    // Click on a game to monitor
    await page.click('button:has-text("View Game")').first();
    
    // Should show game monitor view
    await expect(page.getByRole('heading', { name: 'Game Monitor' })).toBeVisible();
    
    // Should display game phase
    await expect(page.getByText(/Current Phase:/)).toBeVisible();
    
    // Should show AI players
    await expect(page.getByText('AI Players')).toBeVisible();
    
    // Should show game board visualization
    await expect(page.locator('.game-board-visualization')).toBeVisible();
    
    // Should show real-time updates
    await expect(page.getByText(/Last Update:/)).toBeVisible();
  });

  test('should display AI player decisions and strategies', async ({ page }) => {
    // Navigate to game monitor
    await page.click('button:has-text("Analytics")');
    await page.click('a:has-text("Simulated Games")');
    await page.click('button:has-text("View Game")').first();
    
    // Open AI decisions panel
    await page.click('button:has-text("AI Decisions")');
    
    // Should show decision log
    await expect(page.getByRole('heading', { name: 'AI Decision Log' })).toBeVisible();
    
    // Should display AI player actions
    await expect(page.getByText(/AI Player \d:/)).toBeVisible();
    
    // Should show decision reasoning
    await expect(page.getByText(/Decision:/)).toBeVisible();
    await expect(page.getByText(/Reasoning:/)).toBeVisible();
    
    // Should allow filtering by AI player
    await page.selectOption('select[name="aiPlayerFilter"]', 'ai_player_1');
    
    // Should update to show only selected player's decisions
    await expect(page.getByText('AI Player 1:')).toBeVisible();
  });

  test('should control game speed and pause/resume', async ({ page }) => {
    // Create a new simulated game first
    await page.click('button:has-text("System")');
    await page.click('button:has-text("Create Simulated Game")');
    
    await page.fill('input[placeholder="Game name"]', 'Speed Test Game');
    await page.selectOption('select[name="aiPlayerCount"]', '3');
    await page.click('button:has-text("Create Game")');
    
    // Should be in game monitor
    await expect(page.getByRole('heading', { name: 'Game Monitor' })).toBeVisible();
    
    // Game should start in running state
    await expect(page.getByText('Status: Running')).toBeVisible();
    
    // Pause the game
    await page.click('button:has-text("Pause")');
    await expect(page.getByText('Status: Paused')).toBeVisible();
    
    // Resume the game
    await page.click('button:has-text("Resume")');
    await expect(page.getByText('Status: Running')).toBeVisible();
    
    // Change game speed
    await page.selectOption('select[name="gameSpeed"]', 'slow');
    await expect(page.getByText('Speed: Slow')).toBeVisible();
    
    // Stop the game
    await page.click('button:has-text("Stop Game")');
    await expect(page.getByText('Status: Stopped')).toBeVisible();
  });

  test('should export game data and analytics', async ({ page }) => {
    // Navigate to a completed simulated game
    await page.click('button:has-text("Analytics")');
    await page.click('a:has-text("Simulated Games")');
    
    // Filter for completed games
    await page.selectOption('select[name="statusFilter"]', 'completed');
    
    // Click on a completed game
    await page.click('button:has-text("View Game")').first();
    
    // Click export button
    await page.click('button:has-text("Export Data")');
    
    // Should show export options
    await expect(page.getByRole('heading', { name: 'Export Game Data' })).toBeVisible();
    
    // Select export format
    await page.click('input[value="json"]');
    
    // Select data to export
    await page.check('input[name="includeDecisions"]');
    await page.check('input[name="includeMetrics"]');
    await page.check('input[name="includeTimeline"]');
    
    // Download the export
    const downloadPromise = page.waitForEvent('download');
    await page.click('button:has-text("Download")');
    const download = await downloadPromise;
    
    // Verify download
    expect(download.suggestedFilename()).toContain('game_export');
    expect(download.suggestedFilename()).toContain('.json');
  });

  test('should show AI performance metrics', async ({ page }) => {
    // Navigate to AI analytics
    await page.click('button:has-text("Analytics")');
    await page.click('a:has-text("AI Performance")');
    
    // Should show AI performance dashboard
    await expect(page.getByRole('heading', { name: 'AI Performance Analytics' })).toBeVisible();
    
    // Should display metrics
    await expect(page.getByText('Average Game Duration')).toBeVisible();
    await expect(page.getByText('Win Rate by AI Level')).toBeVisible();
    await expect(page.getByText('Average Final Score')).toBeVisible();
    await expect(page.getByText('Decision Time')).toBeVisible();
    
    // Should show charts
    await expect(page.locator('.performance-chart')).toBeVisible();
    
    // Filter by difficulty
    await page.selectOption('select[name="difficultyFilter"]', 'hard');
    
    // Should update metrics
    await expect(page.getByText('Hard AI Statistics')).toBeVisible();
  });

  test('should handle multiple concurrent simulated games', async ({ page }) => {
    // Create first game
    await page.click('button:has-text("System")');
    await page.click('button:has-text("Create Simulated Game")');
    
    await page.fill('input[placeholder="Game name"]', 'Concurrent Game 1');
    await page.selectOption('select[name="aiPlayerCount"]', '6');
    await page.click('button:has-text("Create Game")');
    
    // Go back to create another
    await page.click('button:has-text("Back to Dashboard")');
    await page.click('button:has-text("Create Simulated Game")');
    
    await page.fill('input[placeholder="Game name"]', 'Concurrent Game 2');
    await page.selectOption('select[name="aiPlayerCount"]', '4');
    await page.click('button:has-text("Create Game")');
    
    // Navigate to simulated games list
    await page.click('button:has-text("View All Games")');
    
    // Should show both games running
    await expect(page.getByText('Concurrent Game 1')).toBeVisible();
    await expect(page.getByText('Concurrent Game 2')).toBeVisible();
    
    // Both should show as running
    const runningGames = await page.locator('text=Status: Running').count();
    expect(runningGames).toBe(2);
  });

  test('should configure AI player personalities', async ({ page }) => {
    // Navigate to create simulated game
    await page.click('button:has-text("System")');
    await page.click('button:has-text("Create Simulated Game")');
    
    // Enable advanced AI configuration
    await page.click('button:has-text("Advanced AI Settings")');
    
    // Configure individual AI players
    await expect(page.getByText('AI Player Configuration')).toBeVisible();
    
    // Set AI player 1 personality
    await page.selectOption('select[name="ai1_personality"]', 'aggressive');
    await page.selectOption('select[name="ai1_strategy"]', 'power_plant_focused');
    
    // Set AI player 2 personality
    await page.selectOption('select[name="ai2_personality"]', 'conservative');
    await page.selectOption('select[name="ai2_strategy"]', 'city_expansion');
    
    // Set AI player 3 personality
    await page.selectOption('select[name="ai3_personality"]', 'balanced');
    await page.selectOption('select[name="ai3_strategy"]', 'resource_hoarding');
    
    // Create game with custom AI settings
    await page.fill('input[placeholder="Game name"]', 'Custom AI Game');
    await page.click('button:has-text("Create Game")');
    
    // Verify AI personalities are displayed in monitor
    await expect(page.getByText('AI Player 1 (Aggressive)')).toBeVisible();
    await expect(page.getByText('AI Player 2 (Conservative)')).toBeVisible();
    await expect(page.getByText('AI Player 3 (Balanced)')).toBeVisible();
  });

  test('should replay completed simulated games', async ({ page }) => {
    // Navigate to completed games
    await page.click('button:has-text("Analytics")');
    await page.click('a:has-text("Simulated Games")');
    await page.selectOption('select[name="statusFilter"]', 'completed');
    
    // Open a completed game
    await page.click('button:has-text("View Game")').first();
    
    // Click replay button
    await page.click('button:has-text("Replay Game")');
    
    // Should show replay controls
    await expect(page.getByRole('heading', { name: 'Game Replay' })).toBeVisible();
    await expect(page.locator('.replay-timeline')).toBeVisible();
    
    // Replay controls should be visible
    await expect(page.getByRole('button', { name: 'Play' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Pause' })).toBeVisible();
    await expect(page.getByRole('slider', { name: 'Replay progress' })).toBeVisible();
    
    // Speed controls
    await expect(page.getByText('Replay Speed:')).toBeVisible();
    await page.selectOption('select[name="replaySpeed"]', '2x');
    
    // Start replay
    await page.click('button[aria-label="Play"]');
    
    // Should show game state updating
    await expect(page.getByText(/Round \d+/)).toBeVisible();
    
    // Jump to specific round
    await page.fill('input[name="jumpToRound"]', '5');
    await page.click('button:has-text("Jump")');
    await expect(page.getByText('Round 5')).toBeVisible();
  });
});