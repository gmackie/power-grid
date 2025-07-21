import { test, expect } from '@playwright/test';
import { waitForWebSocket } from './helpers/test-utils';

test.describe('Admin Analytics Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForWebSocket(page);
    await page.click('button:has-text("Admin Dashboard")');
    await page.waitForLoadState('networkidle');
  });

  test('should display game analytics overview', async ({ page }) => {
    // Navigate to Analytics section
    await page.click('button:has-text("Analytics")');
    
    // Verify analytics page loaded
    await expect(page.getByRole('heading', { name: 'Game Analytics' })).toBeVisible();
    
    // Check for time range selector
    await expect(page.getByText('Time Range:')).toBeVisible();
    await expect(page.locator('select[name="timeRange"]')).toBeVisible();
    
    // Check for key metrics
    await expect(page.getByText('Total Games Played')).toBeVisible();
    await expect(page.getByText('Active Players')).toBeVisible();
    await expect(page.getByText('Average Game Duration')).toBeVisible();
    await expect(page.getByText('Games In Progress')).toBeVisible();
  });

  test('should filter analytics by date range', async ({ page }) => {
    await page.click('button:has-text("Analytics")');
    
    // Select different time ranges
    await page.selectOption('select[name="timeRange"]', '7days');
    await page.waitForLoadState('networkidle');
    await expect(page.getByText('Last 7 Days')).toBeVisible();
    
    await page.selectOption('select[name="timeRange"]', '30days');
    await page.waitForLoadState('networkidle');
    await expect(page.getByText('Last 30 Days')).toBeVisible();
    
    // Custom date range
    await page.selectOption('select[name="timeRange"]', 'custom');
    await expect(page.getByLabel('Start Date')).toBeVisible();
    await expect(page.getByLabel('End Date')).toBeVisible();
    
    // Set custom dates
    await page.fill('input[name="startDate"]', '2025-01-01');
    await page.fill('input[name="endDate"]', '2025-01-15');
    await page.click('button:has-text("Apply")');
    
    await page.waitForLoadState('networkidle');
    await expect(page.getByText('Jan 1, 2025 - Jan 15, 2025')).toBeVisible();
  });

  test('should display game phase distribution chart', async ({ page }) => {
    await page.click('button:has-text("Analytics")');
    
    // Look for phase distribution section
    await expect(page.getByText('Game Phase Distribution')).toBeVisible();
    
    // Should have a chart container
    await expect(page.locator('.phase-distribution-chart')).toBeVisible();
    
    // Should show phase legends
    await expect(page.getByText('Auction Phase')).toBeVisible();
    await expect(page.getByText('Resource Phase')).toBeVisible();
    await expect(page.getByText('Building Phase')).toBeVisible();
    await expect(page.getByText('Bureaucracy Phase')).toBeVisible();
  });

  test('should show player statistics', async ({ page }) => {
    await page.click('button:has-text("Analytics")');
    
    // Navigate to player stats tab
    await page.click('button:has-text("Player Statistics")');
    
    // Should show player metrics
    await expect(page.getByText('New Players')).toBeVisible();
    await expect(page.getByText('Returning Players')).toBeVisible();
    await expect(page.getByText('Average Games per Player')).toBeVisible();
    await expect(page.getByText('Player Retention Rate')).toBeVisible();
    
    // Should have a player activity chart
    await expect(page.locator('.player-activity-chart')).toBeVisible();
  });

  test('should display resource usage analytics', async ({ page }) => {
    await page.click('button:has-text("Analytics")');
    
    // Navigate to resource analytics
    await page.click('button:has-text("Resource Analytics")');
    
    // Should show resource usage stats
    await expect(page.getByText('Resource Usage Statistics')).toBeVisible();
    await expect(page.getByText('Coal Usage')).toBeVisible();
    await expect(page.getByText('Oil Usage')).toBeVisible();
    await expect(page.getByText('Garbage Usage')).toBeVisible();
    await expect(page.getByText('Uranium Usage')).toBeVisible();
    
    // Should show average prices
    await expect(page.getByText('Average Resource Prices')).toBeVisible();
  });

  test('should export analytics data', async ({ page }) => {
    await page.click('button:has-text("Analytics")');
    
    // Click export button
    await page.click('button:has-text("Export Analytics")');
    
    // Should show export modal
    await expect(page.getByRole('heading', { name: 'Export Analytics Data' })).toBeVisible();
    
    // Select export format
    await page.click('input[value="csv"]');
    
    // Select data to include
    await page.check('input[name="includeGameStats"]');
    await page.check('input[name="includePlayerStats"]');
    await page.check('input[name="includeResourceStats"]');
    
    // Download the export
    const downloadPromise = page.waitForEvent('download');
    await page.click('button:has-text("Export")');
    const download = await downloadPromise;
    
    // Verify download
    expect(download.suggestedFilename()).toContain('analytics_export');
    expect(download.suggestedFilename()).toContain('.csv');
  });
});

test.describe('Player Management', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForWebSocket(page);
    await page.click('button:has-text("Admin Dashboard")');
    await page.click('button:has-text("Players")');
    await page.waitForLoadState('networkidle');
  });

  test('should display player list', async ({ page }) => {
    // Verify player management page loaded
    await expect(page.getByRole('heading', { name: 'Player Management' })).toBeVisible();
    
    // Should have search functionality
    await expect(page.getByPlaceholder('Search players...')).toBeVisible();
    
    // Should show player table headers
    await expect(page.getByText('Player Name')).toBeVisible();
    await expect(page.getByText('Games Played')).toBeVisible();
    await expect(page.getByText('Win Rate')).toBeVisible();
    await expect(page.getByText('Last Active')).toBeVisible();
    await expect(page.getByText('Status')).toBeVisible();
  });

  test('should search and filter players', async ({ page }) => {
    // Search for a player
    await page.fill('input[placeholder="Search players..."]', 'test');
    await page.waitForLoadState('networkidle');
    
    // Filter by status
    await page.selectOption('select[name="statusFilter"]', 'active');
    await page.waitForLoadState('networkidle');
    
    // Filter by activity
    await page.selectOption('select[name="activityFilter"]', 'last7days');
    await page.waitForLoadState('networkidle');
  });

  test('should view player details', async ({ page }) => {
    // Click on a player row
    await page.click('tr[data-player-id]').first();
    
    // Should show player details modal
    await expect(page.getByRole('heading', { name: 'Player Details' })).toBeVisible();
    
    // Should display player stats
    await expect(page.getByText('Total Games:')).toBeVisible();
    await expect(page.getByText('Wins:')).toBeVisible();
    await expect(page.getByText('Average Score:')).toBeVisible();
    await expect(page.getByText('Favorite Map:')).toBeVisible();
    
    // Should show recent games
    await expect(page.getByText('Recent Games')).toBeVisible();
    
    // Should show achievements
    await expect(page.getByText('Achievements')).toBeVisible();
  });
});

test.describe('Leaderboards', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForWebSocket(page);
    await page.click('button:has-text("Admin Dashboard")');
    await page.click('button:has-text("Leaderboards")');
    await page.waitForLoadState('networkidle');
  });

  test('should display global leaderboard', async ({ page }) => {
    // Verify leaderboards page loaded
    await expect(page.getByRole('heading', { name: 'Leaderboards' })).toBeVisible();
    
    // Should show leaderboard tabs
    await expect(page.getByRole('button', { name: 'Global' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Weekly' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Monthly' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'All Time' })).toBeVisible();
    
    // Should display rankings
    await expect(page.getByText('Rank')).toBeVisible();
    await expect(page.getByText('Player')).toBeVisible();
    await expect(page.getByText('Rating')).toBeVisible();
    await expect(page.getByText('Games')).toBeVisible();
    await expect(page.getByText('Win %')).toBeVisible();
  });

  test('should switch between leaderboard views', async ({ page }) => {
    // Switch to weekly view
    await page.click('button:has-text("Weekly")');
    await expect(page.getByText('Weekly Leaderboard')).toBeVisible();
    
    // Switch to monthly view
    await page.click('button:has-text("Monthly")');
    await expect(page.getByText('Monthly Leaderboard')).toBeVisible();
    
    // Switch to all time view
    await page.click('button:has-text("All Time")');
    await expect(page.getByText('All Time Leaderboard')).toBeVisible();
  });

  test('should filter leaderboard by map', async ({ page }) => {
    // Select map filter
    await page.selectOption('select[name="mapFilter"]', 'usa');
    await page.waitForLoadState('networkidle');
    await expect(page.getByText('USA Map Leaderboard')).toBeVisible();
    
    // Change to different map
    await page.selectOption('select[name="mapFilter"]', 'germany');
    await page.waitForLoadState('networkidle');
    await expect(page.getByText('Germany Map Leaderboard')).toBeVisible();
  });
});

test.describe('System Status', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForWebSocket(page);
    await page.click('button:has-text("Admin Dashboard")');
    await page.click('button:has-text("System")');
    await page.waitForLoadState('networkidle');
  });

  test('should display system health metrics', async ({ page }) => {
    // Verify system status page loaded
    await expect(page.getByRole('heading', { name: 'System Status' })).toBeVisible();
    
    // Should show server health
    await expect(page.getByText('Server Health')).toBeVisible();
    await expect(page.getByText('CPU Usage')).toBeVisible();
    await expect(page.getByText('Memory Usage')).toBeVisible();
    await expect(page.getByText('Disk Usage')).toBeVisible();
    await expect(page.getByText('Network I/O')).toBeVisible();
    
    // Should show uptime
    await expect(page.getByText('Uptime')).toBeVisible();
  });

  test('should display WebSocket connections', async ({ page }) => {
    // Look for WebSocket section
    await expect(page.getByText('WebSocket Connections')).toBeVisible();
    
    // Should show connection stats
    await expect(page.getByText('Active Connections:')).toBeVisible();
    await expect(page.getByText('Peak Connections:')).toBeVisible();
    await expect(page.getByText('Messages/sec:')).toBeVisible();
  });

  test('should show system logs', async ({ page }) => {
    // Navigate to logs tab
    await page.click('button:has-text("System Logs")');
    
    // Should show log viewer
    await expect(page.getByText('System Logs')).toBeVisible();
    
    // Should have log level filter
    await expect(page.locator('select[name="logLevel"]')).toBeVisible();
    
    // Should have search
    await expect(page.getByPlaceholder('Search logs...')).toBeVisible();
    
    // Should show log entries
    await expect(page.locator('.log-entry')).toBeVisible();
  });

  test('should manage server configuration', async ({ page }) => {
    // Navigate to configuration tab
    await page.click('button:has-text("Configuration")');
    
    // Should show configuration options
    await expect(page.getByText('Server Configuration')).toBeVisible();
    
    // Should have editable settings
    await expect(page.getByLabel('Max Players per Game')).toBeVisible();
    await expect(page.getByLabel('Game Timeout (minutes)')).toBeVisible();
    await expect(page.getByLabel('Enable AI Players')).toBeVisible();
    await expect(page.getByLabel('Debug Mode')).toBeVisible();
    
    // Save button should be visible
    await expect(page.getByRole('button', { name: 'Save Configuration' })).toBeVisible();
  });

  test('should perform system actions', async ({ page }) => {
    // Should have action buttons
    await expect(page.getByRole('button', { name: 'Restart Server' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Clear Cache' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Backup Data' })).toBeVisible();
    
    // Test clear cache action
    await page.click('button:has-text("Clear Cache")');
    
    // Should show confirmation dialog
    await expect(page.getByText('Are you sure you want to clear the cache?')).toBeVisible();
    await page.click('button:has-text("Cancel")');
  });
});