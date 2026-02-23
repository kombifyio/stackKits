/**
 * Retry Utilities with Exponential Backoff
 *
 * Implements retry logic from old admin's crawl job handling.
 * Features:
 *   - Exponential backoff with jitter
 *   - Max retry limits
 *   - Retry state tracking
 *   - CrawlSource failure counting
 *
 * Usage:
 *   import { withRetry, updateCrawlSourceFailures } from './retry';
 *
 *   const result = await withRetry(
 *     () => firecrawlSearch(query),
 *     { maxAttempts: 3, baseDelayMs: 1000 }
 *   );
 */

import { PrismaClient, CrawlSource } from '@prisma/client';

// ---------------------------------------------------------------------------
// Retry Configuration
// ---------------------------------------------------------------------------

export interface RetryOptions {
  /** Maximum number of retry attempts (default: 3) */
  maxAttempts?: number;
  /** Base delay in milliseconds (default: 1000) */
  baseDelayMs?: number;
  /** Maximum delay in milliseconds (default: 30000) */
  maxDelayMs?: number;
  /** Multiplier for exponential backoff (default: 2) */
  backoffMultiplier?: number;
  /** Add randomized jitter? (default: true) */
  jitter?: boolean;
  /** Callback for each retry attempt */
  onRetry?: (error: Error, attempt: number, delayMs: number) => void;
  /** Should retry for this error? (default: always retry) */
  shouldRetry?: (error: Error) => boolean;
}

const DEFAULT_OPTIONS: Required<RetryOptions> = {
  maxAttempts: 3,
  baseDelayMs: 1000,
  maxDelayMs: 30000,
  backoffMultiplier: 2,
  jitter: true,
  onRetry: () => {},
  shouldRetry: () => true,
};

// ---------------------------------------------------------------------------
// Core Retry Function
// ---------------------------------------------------------------------------

/**
 * Execute an async function with exponential backoff retry.
 *
 * @param fn - Async function to execute
 * @param options - Retry configuration
 * @returns Result of the function or throws after max attempts
 *
 * @example
 * const data = await withRetry(
 *   () => fetch('https://api.example.com/data').then(r => r.json()),
 *   {
 *     maxAttempts: 5,
 *     baseDelayMs: 500,
 *     onRetry: (err, attempt) => console.log(`Retry ${attempt}: ${err.message}`)
 *   }
 * );
 */
export async function withRetry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {}
): Promise<T> {
  const opts = { ...DEFAULT_OPTIONS, ...options };
  let lastError: Error | undefined;

  for (let attempt = 1; attempt <= opts.maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;

      // Check if we should retry this error
      if (!opts.shouldRetry(lastError)) {
        throw lastError;
      }

      // Last attempt - don't retry
      if (attempt === opts.maxAttempts) {
        break;
      }

      // Calculate delay with exponential backoff
      let delayMs = Math.min(
        opts.baseDelayMs * Math.pow(opts.backoffMultiplier, attempt - 1),
        opts.maxDelayMs
      );

      // Add jitter (±25% randomization)
      if (opts.jitter) {
        const jitterFactor = 0.75 + Math.random() * 0.5; // 0.75 to 1.25
        delayMs = Math.floor(delayMs * jitterFactor);
      }

      // Notify callback
      opts.onRetry(lastError, attempt, delayMs);

      // Wait before retry
      await sleep(delayMs);
    }
  }

  throw lastError || new Error('Max retry attempts exceeded');
}

/**
 * Sleep for specified milliseconds.
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ---------------------------------------------------------------------------
// CrawlSource Failure Tracking
// ---------------------------------------------------------------------------

/**
 * Update consecutive failure count for a CrawlSource.
 * Pauses the source if failures exceed maxRetries.
 *
 * @param prisma - Prisma client
 * @param crawlSourceId - CrawlSource ID
 * @param failed - Whether the job failed
 * @returns Updated CrawlSource
 */
export async function updateCrawlSourceFailures(
  prisma: PrismaClient,
  crawlSourceId: string,
  failed: boolean
): Promise<CrawlSource> {
  const source = await prisma.crawlSource.findUnique({
    where: { id: crawlSourceId },
  });

  if (!source) {
    throw new Error(`CrawlSource not found: ${crawlSourceId}`);
  }

  if (failed) {
    const newFailureCount = source.consecutiveFailures + 1;
    const shouldPause = newFailureCount >= source.maxRetries;

    return prisma.crawlSource.update({
      where: { id: crawlSourceId },
      data: {
        consecutiveFailures: newFailureCount,
        isPaused: shouldPause,
        lastRunAt: new Date(),
      },
    });
  } else {
    // Success - reset failure count
    return prisma.crawlSource.update({
      where: { id: crawlSourceId },
      data: {
        consecutiveFailures: 0,
        isPaused: false,
        lastRunAt: new Date(),
      },
    });
  }
}

/**
 * Calculate next run time for a CrawlSource based on schedule.
 *
 * @param source - CrawlSource with schedule configuration
 * @returns Next run timestamp or null if manual
 */
export function calculateNextRunAt(source: {
  scheduleType: string;
  scheduleValue: string | null;
}): Date | null {
  if (source.scheduleType === 'manual' || !source.scheduleValue) {
    return null;
  }

  const now = new Date();

  if (source.scheduleType === 'interval') {
    // Parse interval like "1d", "6h", "30m"
    const match = source.scheduleValue.match(/^(\d+)(m|h|d|w)$/);
    if (!match) {
      console.warn(`Invalid interval format: ${source.scheduleValue}`);
      return null;
    }

    const amount = parseInt(match[1], 10);
    const unit = match[2];

    const msPerUnit: Record<string, number> = {
      m: 60 * 1000,
      h: 60 * 60 * 1000,
      d: 24 * 60 * 60 * 1000,
      w: 7 * 24 * 60 * 60 * 1000,
    };

    return new Date(now.getTime() + amount * msPerUnit[unit]);
  }

  if (source.scheduleType === 'cron') {
    // Cron parsing would require a library like node-cron
    // For now, default to 24h if cron is specified
    console.warn('Cron scheduling not yet implemented, defaulting to 24h');
    return new Date(now.getTime() + 24 * 60 * 60 * 1000);
  }

  return null;
}

/**
 * Update CrawlSource with next scheduled run time.
 */
export async function scheduleNextRun(
  prisma: PrismaClient,
  crawlSourceId: string
): Promise<CrawlSource | null> {
  const source = await prisma.crawlSource.findUnique({
    where: { id: crawlSourceId },
  });

  if (!source) {
    throw new Error(`CrawlSource not found: ${crawlSourceId}`);
  }

  const nextRunAt = calculateNextRunAt(source);

  if (!nextRunAt) {
    return source; // Manual source, no scheduling needed
  }

  return prisma.crawlSource.update({
    where: { id: crawlSourceId },
    data: { nextRunAt },
  });
}

// ---------------------------------------------------------------------------
// HTTP Error Classification
// ---------------------------------------------------------------------------

/**
 * Determine if an error is retryable.
 *
 * Retryable errors:
 *   - Network errors (ECONNRESET, ETIMEDOUT, etc.)
 *   - 429 Too Many Requests
 *   - 5xx Server Errors
 *
 * Non-retryable errors:
 *   - 4xx Client Errors (except 429)
 *   - Validation errors
 */
export function isRetryableError(error: Error): boolean {
  const message = error.message.toLowerCase();

  // Network errors
  if (
    message.includes('econnreset') ||
    message.includes('etimedout') ||
    message.includes('econnrefused') ||
    message.includes('socket hang up') ||
    message.includes('network')
  ) {
    return true;
  }

  // HTTP status in error message
  const statusMatch = message.match(/\b(4\d\d|5\d\d)\b/);
  if (statusMatch) {
    const status = parseInt(statusMatch[1], 10);
    // Retry on 429 and 5xx
    return status === 429 || status >= 500;
  }

  // Default: retry unknown errors
  return true;
}

/**
 * Pre-configured retry options for Firecrawl API calls.
 */
export const FIRECRAWL_RETRY_OPTIONS: RetryOptions = {
  maxAttempts: 3,
  baseDelayMs: 2000,
  maxDelayMs: 30000,
  backoffMultiplier: 2,
  jitter: true,
  shouldRetry: isRetryableError,
  onRetry: (error, attempt, delayMs) => {
    console.log(`  [RETRY] Attempt ${attempt} failed: ${error.message}. Retrying in ${delayMs}ms...`);
  },
};

/**
 * Pre-configured retry options for GitHub API calls.
 */
export const GITHUB_RETRY_OPTIONS: RetryOptions = {
  maxAttempts: 5,
  baseDelayMs: 1000,
  maxDelayMs: 60000,
  backoffMultiplier: 2,
  jitter: true,
  shouldRetry: (error) => {
    const message = error.message.toLowerCase();
    // GitHub rate limiting
    if (message.includes('rate limit') || message.includes('403')) {
      return true;
    }
    return isRetryableError(error);
  },
  onRetry: (error, attempt, delayMs) => {
    console.log(`  [RETRY] GitHub attempt ${attempt} failed: ${error.message}. Retrying in ${delayMs}ms...`);
  },
};
