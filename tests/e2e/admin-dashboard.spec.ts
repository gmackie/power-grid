import { test, expect } from '@playwright/test';
import { getRandomName, waitForWebSocket } from './helpers/test-utils';

test.describe('Admin Dashboard Navigation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForWebSocket(page);
  });

  test('should navigate to admin dashboard from main menu', async ({ page }) => {
    // Click on Admin Dashboard button
    await page.click('button:has-text("Admin Dashboard")');
    
    // Verify admin dashboard loaded
    await expect(page.getByRole('heading', { name: 'Admin Dashboard' })).toBeVisible();
    await expect(page.getByText('Manage your Power Grid game server')).toBeVisible();
    
    // Verify navigation tabs are present
    await expect(page.getByRole('button', { name: 'Overview' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Players' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Analytics' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Leaderboards' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'System' })).toBeVisible();
  });

  test('should display server status on overview page', async ({ page }) => {
    await page.click('button:has-text("Admin Dashboard")');
    
    // Wait for data to load
    await page.waitForLoadState('networkidle');
    
    // Check server status card
    const serverStatusCard = page.locator('h3:has-text("Server Status")').locator('..');
    await expect(serverStatusCard.getByText('Status:')).toBeVisible();
    await expect(serverStatusCard.getByText('Version:')).toBeVisible();
    await expect(serverStatusCard.getByText('Uptime:')).toBeVisible();
    
    // Check for healthy status (assuming server is running)
    await expect(serverStatusCard.getByText('healthy')).toBeVisible();
  });

  test('should display game activity metrics', async ({ page }) => {
    await page.click('button:has-text("Admin Dashboard")');
    
    // Wait for data to load
    await page.waitForLoadState('networkidle');
    
    // Check game activity card
    const gameActivityCard = page.locator('h3:has-text("Game Activity (7 days)")').locator('..');
    await expect(gameActivityCard.getByText('Total Games:')).toBeVisible();
    await expect(gameActivityCard.getByText('Unique Players:')).toBeVisible();
    await expect(gameActivityCard.getByText('Avg Duration:')).toBeVisible();
  });

  test('should navigate between admin sections', async ({ page }) => {
    await page.click('button:has-text("Admin Dashboard")');
    
    // Navigate to Players section
    await page.click('button:has-text("Players")');
    await expect(page.getByRole('heading', { name: 'Player Management' })).toBeVisible();
    
    // Navigate to Analytics section
    await page.click('button:has-text("Analytics")');
    await expect(page.getByRole('heading', { name: 'Game Analytics' })).toBeVisible();
    
    // Navigate to Leaderboards section
    await page.click('button:has-text("Leaderboards")');
    await expect(page.getByRole('heading', { name: 'Leaderboards' })).toBeVisible();
    
    // Navigate to System section
    await page.click('button:has-text("System")');
    await expect(page.getByRole('heading', { name: 'System Status' })).toBeVisible();
    
    // Navigate back to Overview
    await page.click('button:has-text("Overview")');
    await expect(page.locator('h3:has-text("Server Status")')).toBeVisible();
  });

  test('should handle API errors gracefully', async ({ page, context }) => {
    // Block API requests to simulate errors
    await context.route('**/api/**', route => route.abort());
    
    await page.click('button:has-text("Admin Dashboard")');
    
    // Should show error messages instead of crashing
    await expect(page.getByText('Failed to fetch data')).toBeVisible({ timeout: 10000 });
  });
});

test.describe('Admin Quick Actions', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForWebSocket(page);
    await page.click('button:has-text("Admin Dashboard")');
  });

  test('should navigate to sections using quick action buttons', async ({ page }) => {
    // Click Manage Players quick action
    await page.click('button:has-text("Manage Players")');
    await expect(page.getByRole('heading', { name: 'Player Management' })).toBeVisible();
    
    // Go back to overview
    await page.click('button:has-text("Overview")');
    
    // Click View Analytics quick action
    await page.click('button:has-text("View Analytics")');
    await expect(page.getByRole('heading', { name: 'Game Analytics' })).toBeVisible();
    
    // Go back to overview
    await page.click('button:has-text("Overview")');
    
    // Click System Status quick action
    await page.click('button:has-text("System Status")');
    await expect(page.getByRole('heading', { name: 'System Status' })).toBeVisible();
  });
});

test.describe('Admin Dashboard Responsiveness', () => {
  test('should display properly on mobile viewport', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');
    await waitForWebSocket(page);
    
    await page.click('button:has-text("Admin Dashboard")');
    
    // Check that content is still accessible
    await expect(page.getByRole('heading', { name: 'Admin Dashboard' })).toBeVisible();
    
    // Navigation should still work
    await page.click('button:has-text("Players")');
    await expect(page.getByRole('heading', { name: 'Player Management' })).toBeVisible();
  });

  test('should display properly on tablet viewport', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto('/');
    await waitForWebSocket(page);
    
    await page.click('button:has-text("Admin Dashboard")');
    
    // Check layout on tablet
    await expect(page.getByRole('heading', { name: 'Admin Dashboard' })).toBeVisible();
    await expect(page.locator('.grid').first()).toBeVisible();
  });
});