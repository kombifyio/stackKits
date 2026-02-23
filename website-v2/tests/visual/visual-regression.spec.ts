import { test, expect } from '@playwright/test';

const VISUAL_THRESHOLD = 0.1;

const DISABLE_ANIMATIONS_CSS = `*, *::before, *::after {
  animation-duration: 0s !important;
  animation-delay: 0s !important;
  transition-duration: 0s !important;
  transition-delay: 0s !important;
}`;

// -- Public Pages --

test.describe('Visual Regression - Public Pages', () => {
  test.beforeEach(async ({ page }) => {
    await page.addStyleTag({ content: DISABLE_ANIMATIONS_CSS });
  });

  test('Homepage', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(1000);
    await expect(page).toHaveScreenshot('homepage.png', {
      fullPage: true,
      threshold: VISUAL_THRESHOLD,
      maxDiffPixelRatio: 0.01,
    });
  });
});

// -- Dark Mode --

test.describe('Visual Regression - Dark Mode', () => {
  test.beforeEach(async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'dark' });
    await page.addStyleTag({ content: DISABLE_ANIMATIONS_CSS });
  });

  test('Homepage - Dark', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(1000);
    await expect(page).toHaveScreenshot('homepage-dark.png', {
      fullPage: true,
      threshold: VISUAL_THRESHOLD,
      maxDiffPixelRatio: 0.01,
    });
  });
});

// -- Components --

test.describe('Visual Regression - Components', () => {
  test.beforeEach(async ({ page }) => {
    await page.addStyleTag({ content: DISABLE_ANIMATIONS_CSS });
  });

  test('Navigation Header', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(1000);

    const nav = page.locator('nav, [data-testid="nav"], header');
    if (await nav.first().isVisible()) {
      await expect(nav.first()).toHaveScreenshot('nav-header.png', {
        threshold: VISUAL_THRESHOLD,
        maxDiffPixelRatio: 0.01,
      });
    }
  });

  test('Footer', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(1000);

    const footer = page.locator('footer, [data-testid="footer"]');
    if (await footer.first().isVisible()) {
      await expect(footer.first()).toHaveScreenshot('footer.png', {
        threshold: VISUAL_THRESHOLD,
        maxDiffPixelRatio: 0.01,
      });
    }
  });

  test('Hero Section', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(1000);

    const hero = page.locator('[data-testid="hero"], section:first-of-type, .hero');
    if (await hero.first().isVisible()) {
      await expect(hero.first()).toHaveScreenshot('hero.png', {
        threshold: VISUAL_THRESHOLD,
        maxDiffPixelRatio: 0.01,
      });
    }
  });
});
