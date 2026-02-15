import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/visual',
  snapshotDir: './tests/visual/snapshots',
  updateSnapshots: 'none',
  timeout: 60_000,
  expect: {
    timeout: 10_000,
    toHaveScreenshot: {
      threshold: 0.2,
      maxDiffPixelRatio: 0.01,
      animations: 'disabled',
    },
  },
  fullyParallel: false,
  retries: 0,
  workers: 1,
  reporter: [
    ['html', { outputFolder: 'playwright-report-visual' }],
    ['json', { outputFile: 'test-results/visual-results.json' }],
    ['list'],
  ],
  use: {
    baseURL: 'http://localhost:5281',
    screenshot: 'on',
    trace: 'off',
    video: 'off',
    deviceScaleFactor: 1,
    locale: 'en-US',
    timezoneId: 'Europe/Berlin',
    launchOptions: {
      args: ['--disable-gpu', '--disable-animations'],
    },
  },
  projects: [
    {
      name: 'Desktop Chrome',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1920, height: 1080 },
      },
    },
    {
      name: 'Tablet iPad Pro 11',
      use: {
        ...devices['iPad Pro 11'],
        viewport: { width: 768, height: 1024 },
      },
    },
    {
      name: 'Mobile iPhone 14',
      use: {
        ...devices['iPhone 14'],
        viewport: { width: 375, height: 667 },
      },
    },
  ],
  outputDir: 'test-results-visual/',
  webServer: {
    command: 'bun run dev',
    url: 'http://localhost:5281',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
