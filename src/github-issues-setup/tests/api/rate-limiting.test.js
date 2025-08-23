/**
 * Rate Limiting Tests
 * Tests GitHub API rate limiting behavior, quota management, and compliance
 */

const GitHubApiClient = require('../../utils/github-api');
const { Octokit } = require('@octokit/rest');

// Mock the Octokit library
jest.mock('@octokit/rest');

describe('Rate Limiting Behavior', () => {
  let mockOctokit;
  let client;

  beforeEach(() => {
    jest.clearAllMocks();
    
    mockOctokit = {
      rest: {
        rateLimit: {
          get: jest.fn()
        },
        issues: {
          create: jest.fn(),
          get: jest.fn(),
          addLabels: jest.fn()
        }
      }
    };

    Octokit.mockImplementation(() => mockOctokit);
    client = new GitHubApiClient('test_token');
  });

  describe('Rate Limit Buffer Management', () => {
    test('should respect 20% buffer by default', () => {
      expect(client.rateLimitBuffer).toBe(0.2);
    });

    test('should calculate buffer threshold correctly', async () => {
      const mockRateLimit = {
        limit: 5000,
        remaining: 1000, // 80% used, exactly at buffer threshold
        reset: Date.now() / 1000 + 3600
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: mockRateLimit }
      });

      const withinLimit = await client.isWithinRateLimit();
      
      // At exactly 80% usage (buffer threshold), should return false
      expect(withinLimit).toBe(false);
    });

    test('should allow operations when well within buffer', async () => {
      const mockRateLimit = {
        limit: 5000,
        remaining: 4500, // Only 10% used, well within buffer
        reset: Date.now() / 1000 + 3600
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: mockRateLimit }
      });

      const withinLimit = await client.isWithinRateLimit();
      
      expect(withinLimit).toBe(true);
    });

    test('should prevent operations when outside buffer', async () => {
      const mockRateLimit = {
        limit: 5000,
        remaining: 500, // 90% used, outside buffer
        reset: Date.now() / 1000 + 3600
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: mockRateLimit }
      });

      const withinLimit = await client.isWithinRateLimit();
      
      expect(withinLimit).toBe(false);
    });
  });

  describe('Rate Limit Wait Logic', () => {
    test('should not wait when remaining > 10', async () => {
      const mockRateLimit = {
        limit: 5000,
        remaining: 100,
        reset: Date.now() / 1000 + 3600
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: mockRateLimit }
      });

      const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();
      const setTimeoutSpy = jest.spyOn(global, 'setTimeout');

      await client.waitIfRateLimited();
      
      expect(consoleLogSpy).not.toHaveBeenCalled();
      expect(setTimeoutSpy).not.toHaveBeenCalled();
      
      consoleLogSpy.mockRestore();
      setTimeoutSpy.mockRestore();
    });

    test('should wait when remaining <= 10 with future reset time', async () => {
      const futureResetTime = Date.now() / 1000 + 120; // 2 minutes in future
      const mockRateLimit = {
        limit: 5000,
        remaining: 5,
        reset: futureResetTime
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: mockRateLimit }
      });

      const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();
      
      // Mock setTimeout to resolve immediately
      const setTimeoutSpy = jest.spyOn(global, 'setTimeout').mockImplementation((callback) => {
        setTimeout(callback, 0);
        return 123;
      });

      await client.waitIfRateLimited();
      
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringMatching(/Rate limited\. Waiting \d+ seconds\.\.\./)
      );
      expect(setTimeoutSpy).toHaveBeenCalledWith(
        expect.any(Function),
        expect.any(Number)
      );
      
      consoleLogSpy.mockRestore();
      setTimeoutSpy.mockRestore();
    });

    test('should not wait when reset time is in the past', async () => {
      const pastResetTime = Date.now() / 1000 - 60; // 1 minute ago
      const mockRateLimit = {
        limit: 5000,
        remaining: 5,
        reset: pastResetTime
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: mockRateLimit }
      });

      const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();
      const setTimeoutSpy = jest.spyOn(global, 'setTimeout');

      await client.waitIfRateLimited();
      
      expect(consoleLogSpy).not.toHaveBeenCalled();
      expect(setTimeoutSpy).not.toHaveBeenCalled();
      
      consoleLogSpy.mockRestore();
      setTimeoutSpy.mockRestore();
    });

    test('should calculate wait time correctly with 1 second buffer', async () => {
      const resetTime = Date.now() / 1000 + 30; // 30 seconds in future
      const mockRateLimit = {
        limit: 5000,
        remaining: 3,
        reset: resetTime
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: mockRateLimit }
      });

      const setTimeoutSpy = jest.spyOn(global, 'setTimeout').mockImplementation((callback, delay) => {
        // Should wait for reset time + 1 second buffer
        expect(delay).toBeGreaterThanOrEqual(30000);
        expect(delay).toBeLessThanOrEqual(32000); // Allow some timing variance
        setTimeout(callback, 0);
        return 123;
      });

      await client.waitIfRateLimited();
      
      expect(setTimeoutSpy).toHaveBeenCalled();
      setTimeoutSpy.mockRestore();
    });
  });

  describe('Rate Limiting Integration with Operations', () => {
    test('should check rate limit before each operation', async () => {
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { number: 123 }
      });

      await client.createIssue('owner', 'repo', 'Title', 'Body');
      
      expect(mockOctokit.rest.rateLimit.get).toHaveBeenCalledBefore(
        mockOctokit.rest.issues.create
      );
    });

    test('should wait if rate limited before operation', async () => {
      const futureResetTime = Date.now() / 1000 + 60;
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { 
          rate: { 
            remaining: 2, // Below threshold
            reset: futureResetTime 
          } 
        }
      });
      mockOctokit.rest.issues.get.mockResolvedValue({
        data: { number: 123 }
      });

      const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();
      const setTimeoutSpy = jest.spyOn(global, 'setTimeout').mockImplementation((callback) => {
        setTimeout(callback, 0);
        return 123;
      });

      await client.getIssue('owner', 'repo', 123);
      
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringContaining('Rate limited')
      );
      expect(mockOctokit.rest.issues.get).toHaveBeenCalled();
      
      consoleLogSpy.mockRestore();
      setTimeoutSpy.mockRestore();
    });

    test('should handle multiple operations with rate limiting', async () => {
      // Simulate decreasing rate limit with each call
      let remainingCalls = 15;
      mockOctokit.rest.rateLimit.get.mockImplementation(() => {
        remainingCalls--;
        return Promise.resolve({
          data: { 
            rate: { 
              remaining: remainingCalls,
              reset: Date.now() / 1000 + 3600 
            }
          }
        });
      });

      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { number: 123 }
      });

      const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();
      const setTimeoutSpy = jest.spyOn(global, 'setTimeout').mockImplementation((callback) => {
        setTimeout(callback, 0);
        return 123;
      });

      // Perform multiple operations
      const operations = [];
      for (let i = 0; i < 10; i++) {
        operations.push(client.createIssue('owner', 'repo', `Issue ${i}`, 'Body'));
      }

      await Promise.all(operations);

      // Should have triggered rate limit wait when remaining dropped below 10
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringContaining('Rate limited')
      );
      
      consoleLogSpy.mockRestore();
      setTimeoutSpy.mockRestore();
    });
  });

  describe('Rate Limit Error Handling', () => {
    test('should handle rate limit check failures gracefully', async () => {
      const rateLimitError = new Error('Rate limit API unavailable');
      mockOctokit.rest.rateLimit.get.mockRejectedValue(rateLimitError);

      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();

      await expect(client.checkRateLimit()).rejects.toThrow('Rate limit API unavailable');
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        'Failed to check rate limit:', 'Rate limit API unavailable'
      );
      
      consoleErrorSpy.mockRestore();
    });

    test('should handle GitHub API rate limit errors (403)', async () => {
      const rateLimitExceededError = new Error('API rate limit exceeded');
      rateLimitExceededError.status = 403;
      rateLimitExceededError.response = {
        headers: {
          'x-ratelimit-remaining': '0',
          'x-ratelimit-reset': (Date.now() / 1000 + 3600).toString()
        }
      };

      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockRejectedValue(rateLimitExceededError);

      await expect(client.createIssue('owner', 'repo', 'Title', 'Body'))
        .rejects.toThrow('API rate limit exceeded');
    });

    test('should handle secondary rate limits (abuse detection)', async () => {
      const abuseError = new Error('You have triggered an abuse detection mechanism');
      abuseError.status = 403;
      abuseError.response = {
        data: {
          message: 'You have triggered an abuse detection mechanism'
        }
      };

      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.addLabels.mockRejectedValue(abuseError);

      await expect(client.addLabels('owner', 'repo', 123, ['label']))
        .rejects.toThrow('You have triggered an abuse detection mechanism');
    });
  });

  describe('Concurrent Operations Rate Limiting', () => {
    test('should handle concurrent operations correctly', async () => {
      let rateLimitCalls = 0;
      mockOctokit.rest.rateLimit.get.mockImplementation(() => {
        rateLimitCalls++;
        return Promise.resolve({
          data: { 
            rate: { 
              remaining: Math.max(1000 - rateLimitCalls, 0),
              reset: Date.now() / 1000 + 3600 
            }
          }
        });
      });

      mockOctokit.rest.issues.create.mockImplementation(() => 
        Promise.resolve({ data: { number: Math.random() * 1000 } })
      );

      // Launch multiple concurrent operations
      const concurrentOperations = Array.from({ length: 5 }, (_, i) =>
        client.createIssue('owner', 'repo', `Concurrent Issue ${i}`, 'Body')
      );

      const results = await Promise.all(concurrentOperations);

      expect(results).toHaveLength(5);
      expect(mockOctokit.rest.rateLimit.get).toHaveBeenCalledTimes(5);
      expect(mockOctokit.rest.issues.create).toHaveBeenCalledTimes(5);
    });

    test('should serialize operations when rate limited', async () => {
      let operationCount = 0;
      const operationOrder = [];

      mockOctokit.rest.rateLimit.get.mockImplementation(() => {
        const remaining = Math.max(15 - operationCount, 0);
        return Promise.resolve({
          data: { 
            rate: { 
              remaining,
              reset: Date.now() / 1000 + 60 
            }
          }
        });
      });

      mockOctokit.rest.issues.create.mockImplementation(() => {
        operationCount++;
        operationOrder.push(operationCount);
        return Promise.resolve({ data: { number: operationCount } });
      });

      const setTimeoutSpy = jest.spyOn(global, 'setTimeout').mockImplementation((callback) => {
        setTimeout(callback, 0);
        return 123;
      });

      // This should trigger rate limiting after a few operations
      const operations = Array.from({ length: 12 }, (_, i) =>
        client.createIssue('owner', 'repo', `Issue ${i}`, 'Body')
      );

      await Promise.all(operations);

      expect(operationOrder).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      
      setTimeoutSpy.mockRestore();
    });
  });

  describe('Performance Under Rate Limiting', () => {
    test('should complete operations within reasonable time when not rate limited', async () => {
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { number: 123 }
      });

      const startTime = Date.now();
      
      await client.createIssue('owner', 'repo', 'Title', 'Body');
      
      const endTime = Date.now();
      const duration = endTime - startTime;

      // Should complete quickly when not rate limited (under 100ms)
      expect(duration).toBeLessThan(100);
    });

    test('should add appropriate delay when rate limited', async () => {
      const resetTime = Date.now() / 1000 + 2; // 2 seconds in future
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { 
          rate: { 
            remaining: 1, // Will trigger wait
            reset: resetTime 
          }
        }
      });

      let timeoutDuration;
      const setTimeoutSpy = jest.spyOn(global, 'setTimeout').mockImplementation((callback, delay) => {
        timeoutDuration = delay;
        setTimeout(callback, 0); // Complete immediately for test
        return 123;
      });

      await client.waitIfRateLimited();

      // Should wait for at least the reset time (2000ms) plus buffer (1000ms)
      expect(timeoutDuration).toBeGreaterThanOrEqual(2000);
      expect(timeoutDuration).toBeLessThanOrEqual(4000);
      
      setTimeoutSpy.mockRestore();
    });
  });

  describe('Rate Limit Monitoring and Reporting', () => {
    test('should provide rate limit information', async () => {
      const mockRateLimit = {
        limit: 5000,
        remaining: 4000,
        reset: Date.now() / 1000 + 3600,
        used: 1000
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: mockRateLimit }
      });

      const rateLimit = await client.checkRateLimit();
      
      expect(rateLimit).toEqual(mockRateLimit);
      expect(rateLimit.limit).toBe(5000);
      expect(rateLimit.remaining).toBe(4000);
      expect(rateLimit.reset).toBeCloseTo(Date.now() / 1000 + 3600, 0);
    });

    test('should track rate limit usage over time', async () => {
      let remaining = 1000;
      
      mockOctokit.rest.rateLimit.get.mockImplementation(() => {
        remaining -= 10; // Simulate decreasing rate limit
        return Promise.resolve({
          data: { 
            rate: { 
              limit: 5000,
              remaining,
              reset: Date.now() / 1000 + 3600 
            }
          }
        });
      });

      const limits = [];
      for (let i = 0; i < 5; i++) {
        const limit = await client.checkRateLimit();
        limits.push(limit.remaining);
      }

      expect(limits).toEqual([990, 980, 970, 960, 950]);
    });
  });
});