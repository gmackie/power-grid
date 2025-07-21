import { test, expect } from '@playwright/test';
import { waitForWebSocket } from './helpers/test-utils';

test.describe('AI Client Behavior Observation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForWebSocket(page);
    await page.click('button:has-text("Admin Dashboard")');
    await page.waitForLoadState('networkidle');
  });

  test('should observe AI decision-making in auction phase', async ({ page }) => {
    // Create a simulated game
    await page.click('button:has-text("System")');
    await page.click('button:has-text("Create Simulated Game")');
    
    await page.fill('input[placeholder="Game name"]', 'AI Auction Test');
    await page.selectOption('select[name="aiPlayerCount"]', '4');
    await page.selectOption('select[name="aiDifficulty"]', 'hard');
    await page.click('button:has-text("Create Game")');
    
    // Wait for game to start
    await expect(page.getByText('Status: Running')).toBeVisible();
    
    // Navigate to AI decisions view
    await page.click('button:has-text("AI Decisions")');
    
    // Filter for auction phase
    await page.selectOption('select[name="phaseFilter"]', 'auction');
    
    // Should show AI bidding behavior
    await expect(page.getByText(/AI Player \d+ evaluating power plant/)).toBeVisible();
    await expect(page.getByText(/Bid calculation:/)).toBeVisible();
    await expect(page.getByText(/Plant value:/)).toBeVisible();
    await expect(page.getByText(/Max bid:/)).toBeVisible();
    await expect(page.getByText(/Decision: (Bid|Pass)/)).toBeVisible();
    
    // Should show decision factors
    await expect(page.getByText('Decision Factors:')).toBeVisible();
    await expect(page.getByText(/Current money:/)).toBeVisible();
    await expect(page.getByText(/Plant efficiency:/)).toBeVisible();
    await expect(page.getByText(/Resource availability:/)).toBeVisible();
  });

  test('should track AI resource purchasing strategies', async ({ page }) => {
    // Navigate to a running simulated game
    await page.click('button:has-text("Analytics")');
    await page.click('a:has-text("Simulated Games")');
    await page.click('button:has-text("View Game")').first();
    
    // Open AI decisions panel
    await page.click('button:has-text("AI Decisions")');
    
    // Filter for resource phase
    await page.selectOption('select[name="phaseFilter"]', 'resource');
    
    // Should show resource purchasing decisions
    await expect(page.getByText(/AI Player \d+ resource planning/)).toBeVisible();
    await expect(page.getByText('Resource Needs Analysis:')).toBeVisible();
    await expect(page.getByText(/Coal needed:/)).toBeVisible();
    await expect(page.getByText(/Oil needed:/)).toBeVisible();
    await expect(page.getByText(/Purchase priority:/)).toBeVisible();
    
    // Should show cost-benefit analysis
    await expect(page.getByText('Cost Analysis:')).toBeVisible();
    await expect(page.getByText(/Total cost:/)).toBeVisible();
    await expect(page.getByText(/Cities to power:/)).toBeVisible();
    await expect(page.getByText(/Income potential:/)).toBeVisible();
  });

  test('should monitor AI city building patterns', async ({ page }) => {
    // Navigate to game monitor
    await page.click('button:has-text("Analytics")');
    await page.click('a:has-text("Simulated Games")');
    await page.click('button:has-text("View Game")').first();
    
    // Switch to map view
    await page.click('button:has-text("Map View")');
    
    // Enable AI overlay
    await page.click('button:has-text("Show AI Analysis")');
    
    // Should show city evaluation overlay
    await expect(page.locator('.ai-city-overlay')).toBeVisible();
    
    // Click on AI decisions for building phase
    await page.click('button:has-text("AI Decisions")');
    await page.selectOption('select[name="phaseFilter"]', 'building');
    
    // Should show city selection logic
    await expect(page.getByText(/AI Player \d+ evaluating cities/)).toBeVisible();
    await expect(page.getByText('City Evaluation:')).toBeVisible();
    await expect(page.getByText(/Connection cost:/)).toBeVisible();
    await expect(page.getByText(/Strategic value:/)).toBeVisible();
    await expect(page.getByText(/Expansion potential:/)).toBeVisible();
    
    // Should show selected city and reasoning
    await expect(page.getByText(/Selected: \w+/)).toBeVisible();
    await expect(page.getByText(/Reasoning:/)).toBeVisible();
  });

  test('should analyze AI power plant efficiency optimization', async ({ page }) => {
    // Navigate to AI analytics
    await page.click('button:has-text("Analytics")');
    await page.click('a:has-text("AI Performance")');
    
    // Select efficiency metrics tab
    await page.click('button:has-text("Efficiency Metrics")');
    
    // Should show power plant efficiency analysis
    await expect(page.getByText('Power Plant Efficiency Analysis')).toBeVisible();
    await expect(page.getByText('AI Optimization Strategies:')).toBeVisible();
    
    // Should display metrics
    await expect(page.getByText('Average Cities Powered per Plant')).toBeVisible();
    await expect(page.getByText('Resource Efficiency Score')).toBeVisible();
    await expect(page.getByText('Cost per City Powered')).toBeVisible();
    
    // Should show AI learning patterns
    await expect(page.getByText('AI Learning Patterns:')).toBeVisible();
    await expect(page.getByText(/Plant replacement frequency:/)).toBeVisible();
    await expect(page.getByText(/Preferred resource types:/)).toBeVisible();
  });

  test('should compare AI strategies across difficulty levels', async ({ page }) => {
    // Navigate to AI performance
    await page.click('button:has-text("Analytics")');
    await page.click('a:has-text("AI Performance")');
    
    // Click on strategy comparison
    await page.click('button:has-text("Strategy Comparison")');
    
    // Should show comparison table
    await expect(page.getByRole('heading', { name: 'AI Strategy Comparison' })).toBeVisible();
    
    // Should have difficulty level columns
    await expect(page.getByText('Easy AI')).toBeVisible();
    await expect(page.getByText('Medium AI')).toBeVisible();
    await expect(page.getByText('Hard AI')).toBeVisible();
    
    // Should show strategy metrics
    await expect(page.getByText('Auction Aggressiveness')).toBeVisible();
    await expect(page.getByText('Resource Hoarding')).toBeVisible();
    await expect(page.getByText('City Expansion Rate')).toBeVisible();
    await expect(page.getByText('Risk Tolerance')).toBeVisible();
    
    // Should show visual comparison charts
    await expect(page.locator('.strategy-comparison-chart')).toBeVisible();
  });

  test('should track AI adaptation to player strategies', async ({ page }) => {
    // Create a mixed game with AI and human players
    await page.click('button:has-text("System")');
    await page.click('button:has-text("Create Mixed Game")');
    
    await page.fill('input[placeholder="Game name"]', 'AI Adaptation Test');
    await page.selectOption('select[name="humanPlayers"]', '2');
    await page.selectOption('select[name="aiPlayers"]', '2');
    await page.selectOption('select[name="aiDifficulty"]', 'adaptive');
    await page.click('button:has-text("Create Game")');
    
    // Navigate to AI behavior analysis
    await page.click('button:has-text("AI Behavior Analysis")');
    
    // Should show adaptation metrics
    await expect(page.getByRole('heading', { name: 'AI Adaptation Analysis' })).toBeVisible();
    await expect(page.getByText('Strategy Adjustments:')).toBeVisible();
    
    // Should track changes over rounds
    await expect(page.getByText('Round-by-Round Analysis')).toBeVisible();
    await expect(page.locator('.adaptation-timeline')).toBeVisible();
    
    // Should show specific adaptations
    await expect(page.getByText(/Detected player tendency:/)).toBeVisible();
    await expect(page.getByText(/AI response:/)).toBeVisible();
    await expect(page.getByText(/Effectiveness:/)).toBeVisible();
  });

  test('should visualize AI decision trees', async ({ page }) => {
    // Navigate to a running game
    await page.click('button:has-text("Analytics")');
    await page.click('a:has-text("Simulated Games")');
    await page.click('button:has-text("View Game")').first();
    
    // Open AI analysis tools
    await page.click('button:has-text("AI Analysis Tools")');
    
    // Click on decision tree visualization
    await page.click('button:has-text("Decision Tree View")');
    
    // Should show decision tree modal
    await expect(page.getByRole('heading', { name: 'AI Decision Tree' })).toBeVisible();
    
    // Select an AI player
    await page.selectOption('select[name="aiPlayer"]', 'ai_player_1');
    
    // Select a decision point
    await page.selectOption('select[name="decisionPoint"]', 'auction_bid');
    
    // Should display decision tree
    await expect(page.locator('.decision-tree-container')).toBeVisible();
    await expect(page.getByText('Decision Node')).toBeVisible();
    await expect(page.getByText('Evaluation Criteria')).toBeVisible();
    await expect(page.getByText('Possible Outcomes')).toBeVisible();
    
    // Should allow expanding nodes
    await page.click('.tree-node-expand').first();
    await expect(page.locator('.tree-node-children')).toBeVisible();
  });

  test('should benchmark AI performance metrics', async ({ page }) => {
    // Navigate to AI benchmarks
    await page.click('button:has-text("Analytics")');
    await page.click('a:has-text("AI Benchmarks")');
    
    // Should show benchmark dashboard
    await expect(page.getByRole('heading', { name: 'AI Performance Benchmarks' })).toBeVisible();
    
    // Performance metrics
    await expect(page.getByText('Decision Speed (ms)')).toBeVisible();
    await expect(page.getByText('Memory Usage (MB)')).toBeVisible();
    await expect(page.getByText('CPU Usage (%)')).toBeVisible();
    
    // Game performance metrics
    await expect(page.getByText('Average Final Score')).toBeVisible();
    await expect(page.getByText('Win Rate vs Other AI')).toBeVisible();
    await expect(page.getByText('Strategic Efficiency')).toBeVisible();
    
    // Should show performance over time
    await expect(page.locator('.performance-timeline-chart')).toBeVisible();
    
    // Run new benchmark
    await page.click('button:has-text("Run Benchmark")');
    await expect(page.getByText('Benchmark in progress...')).toBeVisible();
  });

  test('should export AI behavior data for analysis', async ({ page }) => {
    // Navigate to AI analytics
    await page.click('button:has-text("Analytics")');
    await page.click('a:has-text("AI Performance")');
    
    // Click export AI data
    await page.click('button:has-text("Export AI Data")');
    
    // Should show export options
    await expect(page.getByRole('heading', { name: 'Export AI Behavior Data' })).toBeVisible();
    
    // Select data types
    await page.check('input[name="includeDecisionLogs"]');
    await page.check('input[name="includePerformanceMetrics"]');
    await page.check('input[name="includeStrategyPatterns"]');
    await page.check('input[name="includeAdaptationData"]');
    
    // Select format
    await page.click('input[value="json"]');
    
    // Set filters
    await page.selectOption('select[name="difficultyFilter"]', 'all');
    await page.fill('input[name="gameCount"]', '100');
    
    // Export data
    const downloadPromise = page.waitForEvent('download');
    await page.click('button:has-text("Export Data")');
    const download = await downloadPromise;
    
    // Verify download
    expect(download.suggestedFilename()).toContain('ai_behavior_data');
    expect(download.suggestedFilename()).toContain('.json');
  });

  test('should provide AI debugging tools', async ({ page }) => {
    // Navigate to a running game
    await page.click('button:has-text("Analytics")');
    await page.click('a:has-text("Simulated Games")');
    await page.click('button:has-text("View Game")').first();
    
    // Open debug panel
    await page.click('button:has-text("Debug AI")');
    
    // Should show debug interface
    await expect(page.getByRole('heading', { name: 'AI Debug Panel' })).toBeVisible();
    
    // Should have debug options
    await expect(page.getByText('Step Through Decisions')).toBeVisible();
    await expect(page.getByText('View Internal State')).toBeVisible();
    await expect(page.getByText('Force Decision')).toBeVisible();
    await expect(page.getByText('Modify Parameters')).toBeVisible();
    
    // Enable step-through mode
    await page.click('button:has-text("Enable Step Mode")');
    await expect(page.getByText('Step mode enabled')).toBeVisible();
    
    // Should show next decision preview
    await expect(page.getByText('Next Decision:')).toBeVisible();
    await expect(page.getByText('Current State:')).toBeVisible();
    await expect(page.locator('.ai-state-viewer')).toBeVisible();
    
    // Step to next decision
    await page.click('button:has-text("Step")');
    await expect(page.getByText('Decision executed')).toBeVisible();
  });
});