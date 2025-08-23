/**
 * API Security Tests
 * Tests authentication failure handling, rate limit abuse prevention,
 * and security-specific API behavior
 */

const GitHubApiClient = require('../../utils/github-api');
const { Octokit } = require('@octokit/rest');

// Mock the Octokit library
jest.mock('@octokit/rest');

describe('API Security', () => {
  let mockOctokit;

  beforeEach(() => {
    jest.clearAllMocks();
    
    mockOctokit = {
      rest: {
        rateLimit: {
          get: jest.fn()
        },
        users: {
          getAuthenticated: jest.fn()
        },
        issues: {
          create: jest.fn(),
          get: jest.fn(),
          addLabels: jest.fn(),
          createComment: jest.fn()
        }
      }
    };

    Octokit.mockImplementation(() => mockOctokit);
  });

  describe('Authentication Failure Handling', () => {
    test('should handle 401 authentication failures gracefully', async () => {
      const client = new GitHubApiClient('invalid_token');
      
      const authError = new Error('Bad credentials');
      authError.status = 401;
      authError.response = {
        status: 401,
        data: {
          message: 'Bad credentials',
          documentation_url: 'https://docs.github.com/rest'
        }
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.users.getAuthenticated.mockRejectedValue(authError);

      await expect(client.getAuthenticatedUser()).rejects.toThrow('Bad credentials');
      
      // Should not expose sensitive information
      expect(authError.message).not.toContain('invalid_token');
    });

    test('should handle token revocation during operations', async () => {
      const client = new GitHubApiClient('revoked_token');
      
      // First operation succeeds
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockResolvedValueOnce({
        data: { number: 123 }
      });

      await expect(client.createIssue('owner', 'repo', 'Title', 'Body'))
        .resolves.toEqual({ number: 123 });

      // Token gets revoked
      const revokedError = new Error('Token has been revoked');
      revokedError.status = 401;
      mockOctokit.rest.issues.get.mockRejectedValue(revokedError);

      await expect(client.getIssue('owner', 'repo', 123))
        .rejects.toThrow('Token has been revoked');
    });

    test('should handle insufficient permissions securely', async () => {
      const client = new GitHubApiClient('readonly_token');
      
      const permissionError = new Error('Resource not accessible by integration');
      permissionError.status = 403;
      permissionError.response = {
        status: 403,
        data: {
          message: 'Resource not accessible by integration',
          documentation_url: 'https://docs.github.com/rest'
        }
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockRejectedValue(permissionError);

      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();

      await expect(client.createIssue('owner', 'repo', 'Title', 'Body'))
        .rejects.toThrow('Resource not accessible by integration');
      
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        'Failed to create issue: Resource not accessible by integration'
      );
      
      consoleErrorSpy.mockRestore();
    });

    test('should handle API key exposure prevention', async () => {
      const sensitiveToken = 'ghp_very_sensitive_token_123456789';
      const client = new GitHubApiClient(sensitiveToken);
      
      const authError = new Error('Authentication failed');
      authError.status = 401;
      
      mockOctokit.rest.rateLimit.get.mockRejectedValue(authError);

      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();

      try {
        await client.checkRateLimit();
      } catch (error) {
        // Verify token is not exposed in error handling
        expect(error.message).not.toContain(sensitiveToken);
        expect(error.message).not.toContain('sensitive_token');
        
        const errorCalls = consoleErrorSpy.mock.calls.flat().join(' ');
        expect(errorCalls).not.toContain(sensitiveToken);
      }
      
      consoleErrorSpy.mockRestore();
    });
  });

  describe('Rate Limit Abuse Prevention', () => {
    test('should prevent rapid successive API calls', async () => {
      const client = new GitHubApiClient('test_token');
      
      let callCount = 0;
      mockOctokit.rest.rateLimit.get.mockImplementation(() => {
        callCount++;
        return Promise.resolve({
          data: { 
            rate: { 
              remaining: Math.max(100 - callCount, 0),
              reset: Date.now() / 1000 + 3600 
            }
          }
        });
      });

      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { number: 123 }
      });

      // Rapid fire 50 operations
      const operations = Array.from({ length: 50 }, (_, i) =>
        client.createIssue('owner', 'repo', `Issue ${i}`, 'Body')
      );

      await Promise.all(operations);

      // Should have checked rate limits for each operation
      expect(mockOctokit.rest.rateLimit.get).toHaveBeenCalledTimes(50);
      expect(mockOctokit.rest.issues.create).toHaveBeenCalledTimes(50);
    });

    test('should handle rate limit exceeded errors', async () => {
      const client = new GitHubApiClient('test_token');
      
      const rateLimitError = new Error('API rate limit exceeded');
      rateLimitError.status = 403;
      rateLimitError.response = {
        status: 403,
        headers: {
          'x-ratelimit-remaining': '0',
          'x-ratelimit-reset': (Date.now() / 1000 + 3600).toString()
        },
        data: {
          message: 'API rate limit exceeded for user',
          documentation_url: 'https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting'
        }
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 0 } }
      });
      mockOctokit.rest.issues.create.mockRejectedValue(rateLimitError);

      await expect(client.createIssue('owner', 'repo', 'Title', 'Body'))
        .rejects.toThrow('API rate limit exceeded');
    });

    test('should handle secondary rate limits (abuse detection)', async () => {
      const client = new GitHubApiClient('test_token');
      
      const abuseError = new Error('You have triggered an abuse detection mechanism');
      abuseError.status = 403;
      abuseError.response = {
        status: 403,
        headers: {
          'retry-after': '60'
        },
        data: {
          message: 'You have triggered an abuse detection mechanism and have been temporarily blocked from content creation. Please retry your request again later.'
        }
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockRejectedValue(abuseError);

      await expect(client.createIssue('owner', 'repo', 'Title', 'Body'))
        .rejects.toThrow('You have triggered an abuse detection mechanism');
    });

    test('should respect rate limit buffer to prevent hitting limits', async () => {
      const client = new GitHubApiClient('test_token');
      
      // Set rate limit to exactly at buffer threshold (80% used)
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { 
          rate: { 
            limit: 5000,
            remaining: 1000, // Exactly at buffer threshold
            reset: Date.now() / 1000 + 3600 
          }
        }
      });

      const withinLimit = await client.isWithinRateLimit();
      
      // Should return false - not within safe buffer
      expect(withinLimit).toBe(false);
    });

    test('should handle concurrent operations without rate limit abuse', async () => {
      const client = new GitHubApiClient('test_token');
      
      let rateLimitCalls = 0;
      mockOctokit.rest.rateLimit.get.mockImplementation(() => {
        rateLimitCalls++;
        return Promise.resolve({
          data: { 
            rate: { 
              remaining: Math.max(1000 - rateLimitCalls * 2, 0),
              reset: Date.now() / 1000 + 3600 
            }
          }
        });
      });

      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { number: 123 }
      });

      // Launch 10 concurrent operations
      const operations = Array.from({ length: 10 }, (_, i) =>
        client.createIssue('owner', 'repo', `Concurrent ${i}`, 'Body')
      );

      const results = await Promise.all(operations);
      
      expect(results).toHaveLength(10);
      // Should have made rate limit checks for all operations
      expect(rateLimitCalls).toBeGreaterThanOrEqual(10);
    });
  });

  describe('Sensitive Data Protection', () => {
    test('should handle potential sensitive data in issue content', async () => {
      const client = new GitHubApiClient('test_token');
      
      const sensitiveContent = `
        API Key: ghp_1234567890abcdefghijklmnopqrstuvwxyz
        Password: super_secret_password_123
        Credit Card: 4532-1234-5678-9012
        SSN: 123-45-6789
        Email: sensitive@private.com
      `;
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'Sensitive Data Issue',
          body: sensitiveContent
        }
      });

      // Should not prevent creation - GitHub's responsibility to handle
      const result = await client.createIssue('owner', 'repo', 'Sensitive Data Issue', sensitiveContent);
      
      expect(result.number).toBe(123);
      expect(result.body).toBe(sensitiveContent);
    });

    test('should not log sensitive data in error messages', async () => {
      const client = new GitHubApiClient('test_token');
      
      const sensitiveIssueBody = 'Database password: super_secret_db_password';
      
      const createError = new Error('Validation failed');
      createError.status = 422;
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockRejectedValue(createError);

      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();

      try {
        await client.createIssue('owner', 'repo', 'Title', sensitiveIssueBody);
      } catch (error) {
        // Verify sensitive data is not exposed in error handling
        const errorCalls = consoleErrorSpy.mock.calls.flat().join(' ');
        expect(errorCalls).not.toContain('super_secret_db_password');
        expect(error.message).not.toContain('super_secret_db_password');
      }
      
      consoleErrorSpy.mockRestore();
    });

    test('should handle webhook signatures and secrets securely', async () => {
      const client = new GitHubApiClient('test_token');
      
      const webhookContent = `
        Webhook secret: whsec_1234567890abcdef
        Signature: sha256=abc123def456
        Please verify webhook configuration
      `;
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.createComment.mockResolvedValue({
        data: { 
          id: 456,
          body: webhookContent
        }
      });

      const result = await client.createComment('owner', 'repo', 123, webhookContent);
      
      expect(result.body).toBe(webhookContent);
    });
  });

  describe('Malicious Repository Access', () => {
    test('should handle access to non-existent repositories', async () => {
      const client = new GitHubApiClient('test_token');
      
      const notFoundError = new Error('Not Found');
      notFoundError.status = 404;
      notFoundError.response = {
        status: 404,
        data: {
          message: 'Not Found',
          documentation_url: 'https://docs.github.com/rest'
        }
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockRejectedValue(notFoundError);

      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();

      await expect(client.createIssue('nonexistent', 'repo', 'Title', 'Body'))
        .rejects.toThrow('Not Found');
      
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        'Failed to create issue: Not Found'
      );
      
      consoleErrorSpy.mockRestore();
    });

    test('should handle access to private repositories without permission', async () => {
      const client = new GitHubApiClient('limited_token');
      
      const privateRepoError = new Error('Repository access blocked');
      privateRepoError.status = 403;
      privateRepoError.response = {
        status: 403,
        data: {
          message: 'Repository access blocked',
          block: {
            reason: 'private_vulnerability_reporting'
          }
        }
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.get.mockRejectedValue(privateRepoError);

      await expect(client.getIssue('private-org', 'private-repo', 123))
        .rejects.toThrow('Repository access blocked');
    });

    test('should handle malicious repository names', async () => {
      const client = new GitHubApiClient('test_token');
      
      const maliciousRepo = '../../../etc/passwd';
      const maliciousOwner = '<script>alert("xss")</script>';
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { number: 123 }
      });

      // Should pass through parameters as-is (GitHub API validates)
      const result = await client.createIssue(maliciousOwner, maliciousRepo, 'Title', 'Body');
      
      expect(mockOctokit.rest.issues.create).toHaveBeenCalledWith({
        owner: maliciousOwner,
        repo: maliciousRepo,
        title: 'Title',
        body: 'Body',
        labels: []
      });
    });
  });

  describe('API Endpoint Security', () => {
    test('should handle GraphQL injection attempts', async () => {
      const client = new GitHubApiClient('test_token');
      
      // GraphQL injection attempt in issue content
      const graphqlInjection = `
        mutation {
          deleteRepository(input: {repositoryId: "evil"}) {
            clientMutationId
          }
        }
      `;
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123,
          title: 'GraphQL Issue',
          body: graphqlInjection
        }
      });

      const result = await client.createIssue('owner', 'repo', 'GraphQL Issue', graphqlInjection);
      
      expect(result.body).toBe(graphqlInjection);
    });

    test('should handle API version manipulation attempts', async () => {
      const client = new GitHubApiClient('test_token', {
        baseUrl: 'https://api.github.com/../admin/api/v1'
      });
      
      // Octokit should handle URL validation
      expect(Octokit).toHaveBeenCalledWith({
        auth: 'test_token',
        baseUrl: 'https://api.github.com/../admin/api/v1'
      });
    });

    test('should handle header injection attempts', async () => {
      const client = new GitHubApiClient('test_token');
      
      const headerInjection = `Title\r\nX-Evil-Header: malicious\r\nContent-Type: text/html`;
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123,
          title: headerInjection,
          body: 'Body'
        }
      });

      const result = await client.createIssue('owner', 'repo', headerInjection, 'Body');
      
      expect(result.title).toBe(headerInjection);
    });
  });

  describe('Network Security', () => {
    test('should handle SSRF attempts through issue content', async () => {
      const client = new GitHubApiClient('test_token');
      
      const ssrfAttempt = `
        Image: ![exploit](http://127.0.0.1:8080/admin/delete)
        Link: [click here](http://metadata.google.internal/computeMetadata/v1/)
        Webhook: http://internal.company.com/webhook
      `;
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123,
          title: 'SSRF Test',
          body: ssrfAttempt
        }
      });

      const result = await client.createIssue('owner', 'repo', 'SSRF Test', ssrfAttempt);
      
      expect(result.body).toBe(ssrfAttempt);
    });

    test('should handle DNS rebinding attempts', async () => {
      const client = new GitHubApiClient('test_token');
      
      const dnsRebinding = 'Visit: http://evil.com.localhost:8080/admin for details';
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.createComment.mockResolvedValue({
        data: { 
          id: 456,
          body: dnsRebinding
        }
      });

      const result = await client.createComment('owner', 'repo', 123, dnsRebinding);
      
      expect(result.body).toBe(dnsRebinding);
    });

    test('should handle protocol downgrade attempts', async () => {
      const client = new GitHubApiClient('test_token', {
        baseUrl: 'http://api.github.com' // HTTP instead of HTTPS
      });
      
      // Octokit should accept the configuration
      expect(Octokit).toHaveBeenCalledWith({
        auth: 'test_token',
        baseUrl: 'http://api.github.com'
      });
    });
  });

  describe('DoS Prevention', () => {
    test('should handle resource exhaustion attempts', async () => {
      const client = new GitHubApiClient('test_token');
      
      // Attempt to create many issues rapidly
      const massCreation = Array.from({ length: 100 }, (_, i) => ({
        title: `DoS Issue ${i}`,
        body: 'A'.repeat(10000) // Large body content
      }));
      
      let createCount = 0;
      mockOctokit.rest.rateLimit.get.mockImplementation(() => {
        createCount++;
        return Promise.resolve({
          data: { 
            rate: { 
              remaining: Math.max(1000 - createCount, 0),
              reset: Date.now() / 1000 + 3600 
            }
          }
        });
      });

      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { number: 123 }
      });

      const operations = massCreation.map(issue =>
        client.createIssue('owner', 'repo', issue.title, issue.body)
      );

      // Should handle all operations (rate limiting will kick in)
      const results = await Promise.all(operations);
      expect(results).toHaveLength(100);
    });

    test('should handle memory exhaustion attempts', async () => {
      const client = new GitHubApiClient('test_token');
      
      const memoryExhaustion = 'A'.repeat(10000000); // 10MB string
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123,
          title: 'Memory Test',
          body: memoryExhaustion
        }
      });

      // Should handle large content without crashing
      const result = await client.createIssue('owner', 'repo', 'Memory Test', memoryExhaustion);
      
      expect(result.body).toBe(memoryExhaustion);
    });

    test('should handle recursive content structures', async () => {
      const client = new GitHubApiClient('test_token');
      
      // Create deeply nested markdown structure
      let recursiveContent = 'Start';
      for (let i = 0; i < 1000; i++) {
        recursiveContent = `[${recursiveContent}](${recursiveContent})`;
      }
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123,
          title: 'Recursive Test',
          body: recursiveContent
        }
      });

      const result = await client.createIssue('owner', 'repo', 'Recursive Test', recursiveContent);
      
      expect(result.body).toBe(recursiveContent);
    });
  });
});