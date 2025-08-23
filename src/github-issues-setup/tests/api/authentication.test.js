/**
 * Authentication Tests
 * Tests GitHub API authentication scenarios, token management, and security
 */

const GitHubApiClient = require('../../utils/github-api');
const { Octokit } = require('@octokit/rest');

// Mock the Octokit library
jest.mock('@octokit/rest');

describe('GitHub API Authentication', () => {
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
          get: jest.fn()
        }
      }
    };

    Octokit.mockImplementation(() => mockOctokit);
  });

  describe('Token Validation', () => {
    test('should accept valid personal access token', () => {
      const validToken = 'ghp_1234567890abcdefghijklmnopqrstuvwxyz';
      const client = new GitHubApiClient(validToken);
      
      expect(Octokit).toHaveBeenCalledWith({
        auth: validToken
      });
    });

    test('should accept valid GitHub App installation token', () => {
      const appToken = 'ghs_1234567890abcdefghijklmnopqrstuvwxyz';
      const client = new GitHubApiClient(appToken);
      
      expect(Octokit).toHaveBeenCalledWith({
        auth: appToken
      });
    });

    test('should accept valid fine-grained personal access token', () => {
      const fineGrainedToken = 'github_pat_11ABCDEFG0123456789_abcdefghijklmnopqrstuvwxyz';
      const client = new GitHubApiClient(fineGrainedToken);
      
      expect(Octokit).toHaveBeenCalledWith({
        auth: fineGrainedToken
      });
    });

    test('should handle missing token gracefully', () => {
      expect(() => new GitHubApiClient()).not.toThrow();
      expect(Octokit).toHaveBeenCalledWith({
        auth: undefined
      });
    });

    test('should handle empty string token', () => {
      expect(() => new GitHubApiClient('')).not.toThrow();
      expect(Octokit).toHaveBeenCalledWith({
        auth: ''
      });
    });

    test('should handle null token', () => {
      expect(() => new GitHubApiClient(null)).not.toThrow();
      expect(Octokit).toHaveBeenCalledWith({
        auth: null
      });
    });
  });

  describe('Authentication Verification', () => {
    test('should successfully authenticate with valid token', async () => {
      const client = new GitHubApiClient('valid_token');
      const mockUser = {
        login: 'testuser',
        id: 12345,
        name: 'Test User',
        email: 'test@example.com',
        type: 'User'
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.users.getAuthenticated.mockResolvedValue({
        data: mockUser
      });

      const user = await client.getAuthenticatedUser();
      
      expect(user).toEqual(mockUser);
      expect(mockOctokit.rest.users.getAuthenticated).toHaveBeenCalledTimes(1);
    });

    test('should handle invalid token (401 Unauthorized)', async () => {
      const client = new GitHubApiClient('invalid_token');
      const authError = new Error('Bad credentials');
      authError.status = 401;
      authError.response = {
        status: 401,
        data: {
          message: 'Bad credentials'
        }
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.users.getAuthenticated.mockRejectedValue(authError);

      await expect(client.getAuthenticatedUser()).rejects.toThrow('Bad credentials');
      expect(authError.status).toBe(401);
    });

    test('should handle expired token', async () => {
      const client = new GitHubApiClient('expired_token');
      const expiredError = new Error('Token has expired');
      expiredError.status = 401;
      expiredError.response = {
        status: 401,
        data: {
          message: 'Token has expired'
        }
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.users.getAuthenticated.mockRejectedValue(expiredError);

      await expect(client.getAuthenticatedUser()).rejects.toThrow('Token has expired');
    });

    test('should handle revoked token', async () => {
      const client = new GitHubApiClient('revoked_token');
      const revokedError = new Error('Token has been revoked');
      revokedError.status = 401;
      revokedError.response = {
        status: 401,
        data: {
          message: 'Token has been revoked'
        }
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.users.getAuthenticated.mockRejectedValue(revokedError);

      await expect(client.getAuthenticatedUser()).rejects.toThrow('Token has been revoked');
    });
  });

  describe('Permission Scopes', () => {
    test('should handle insufficient permissions (403 Forbidden)', async () => {
      const client = new GitHubApiClient('limited_token');
      const permissionError = new Error('Insufficient permissions');
      permissionError.status = 403;
      permissionError.response = {
        status: 403,
        data: {
          message: 'Resource not accessible by integration'
        }
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockRejectedValue(permissionError);

      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();

      await expect(client.createIssue('owner', 'repo', 'Title', 'Body'))
        .rejects.toThrow('Insufficient permissions');
      
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        'Failed to create issue: Insufficient permissions'
      );
      
      consoleErrorSpy.mockRestore();
    });

    test('should handle read-only token attempting write operations', async () => {
      const client = new GitHubApiClient('readonly_token');
      const readOnlyError = new Error('Resource not accessible by integration');
      readOnlyError.status = 403;
      readOnlyError.response = {
        status: 403,
        data: {
          message: 'Resource not accessible by integration',
          documentation_url: 'https://docs.github.com/rest'
        }
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.create.mockRejectedValue(readOnlyError);

      await expect(client.createIssue('owner', 'repo', 'Title', 'Body'))
        .rejects.toThrow('Resource not accessible by integration');
    });

    test('should allow read operations with read-only token', async () => {
      const client = new GitHubApiClient('readonly_token');
      const mockIssue = {
        number: 123,
        title: 'Test Issue',
        body: 'Test body'
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.issues.get.mockResolvedValue({
        data: mockIssue
      });

      const result = await client.getIssue('owner', 'repo', 123);
      
      expect(result).toEqual(mockIssue);
    });
  });

  describe('Token Security', () => {
    test('should not expose token in error messages', async () => {
      const sensitiveToken = 'ghp_sensitive_token_12345';
      const client = new GitHubApiClient(sensitiveToken);
      
      const authError = new Error('Bad credentials');
      authError.status = 401;
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.users.getAuthenticated.mockRejectedValue(authError);

      try {
        await client.getAuthenticatedUser();
      } catch (error) {
        expect(error.message).not.toContain(sensitiveToken);
        expect(error.message).not.toContain('sensitive_token');
      }
    });

    test('should not log token in console output', async () => {
      const sensitiveToken = 'ghp_secret_token_67890';
      const client = new GitHubApiClient(sensitiveToken);
      
      const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();
      
      const authError = new Error('Authentication failed');
      mockOctokit.rest.rateLimit.get.mockRejectedValue(authError);

      try {
        await client.checkRateLimit();
      } catch (error) {
        // Verify no console output contains the token
        const logCalls = consoleLogSpy.mock.calls.flat();
        const errorCalls = consoleErrorSpy.mock.calls.flat();
        const allOutput = [...logCalls, ...errorCalls].join(' ');
        
        expect(allOutput).not.toContain(sensitiveToken);
        expect(allOutput).not.toContain('secret_token');
      }
      
      consoleLogSpy.mockRestore();
      consoleErrorSpy.mockRestore();
    });

    test('should handle malformed tokens gracefully', async () => {
      const malformedTokens = [
        'not-a-token',
        'ghp_',
        'ghp_short',
        'bearer ghp_token123',
        '<script>alert("xss")</script>',
        '../../etc/passwd'
      ];

      for (const token of malformedTokens) {
        expect(() => new GitHubApiClient(token)).not.toThrow();
        
        const client = new GitHubApiClient(token);
        expect(Octokit).toHaveBeenCalledWith({
          auth: token
        });
      }
    });
  });

  describe('Authentication State Management', () => {
    test('should maintain authentication state across multiple operations', async () => {
      const client = new GitHubApiClient('persistent_token');
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.users.getAuthenticated.mockResolvedValue({
        data: { login: 'testuser' }
      });
      mockOctokit.rest.issues.get.mockResolvedValue({
        data: { number: 123 }
      });

      // Perform multiple authenticated operations
      await client.getAuthenticatedUser();
      await client.getIssue('owner', 'repo', 123);
      
      // Should use the same Octokit instance with same auth
      expect(Octokit).toHaveBeenCalledTimes(1);
      expect(Octokit).toHaveBeenCalledWith({
        auth: 'persistent_token'
      });
    });

    test('should handle authentication errors consistently', async () => {
      const client = new GitHubApiClient('inconsistent_token');
      
      const authError = new Error('Bad credentials');
      authError.status = 401;
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.users.getAuthenticated.mockRejectedValue(authError);
      mockOctokit.rest.issues.get.mockRejectedValue(authError);

      // Both operations should fail with same authentication error
      await expect(client.getAuthenticatedUser()).rejects.toThrow('Bad credentials');
      await expect(client.getIssue('owner', 'repo', 123)).rejects.toThrow('Bad credentials');
    });
  });

  describe('Enterprise GitHub Authentication', () => {
    test('should work with GitHub Enterprise Server', () => {
      const enterpriseOptions = {
        baseUrl: 'https://github.enterprise.com/api/v3'
      };
      
      const client = new GitHubApiClient('enterprise_token', enterpriseOptions);
      
      expect(Octokit).toHaveBeenCalledWith({
        auth: 'enterprise_token',
        baseUrl: 'https://github.enterprise.com/api/v3'
      });
    });

    test('should handle enterprise-specific authentication errors', async () => {
      const client = new GitHubApiClient('enterprise_token', {
        baseUrl: 'https://github.enterprise.com/api/v3'
      });
      
      const enterpriseError = new Error('LDAP authentication failed');
      enterpriseError.status = 401;
      enterpriseError.response = {
        status: 401,
        data: {
          message: 'LDAP authentication failed'
        }
      };
      
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      mockOctokit.rest.users.getAuthenticated.mockRejectedValue(enterpriseError);

      await expect(client.getAuthenticatedUser()).rejects.toThrow('LDAP authentication failed');
    });
  });

  describe('Authentication Integration with Rate Limiting', () => {
    test('should check authentication before checking rate limits', async () => {
      const client = new GitHubApiClient('auth_rate_token');
      
      const authError = new Error('Bad credentials');
      authError.status = 401;
      
      mockOctokit.rest.rateLimit.get.mockRejectedValue(authError);

      await expect(client.checkRateLimit()).rejects.toThrow('Bad credentials');
      
      // Rate limit check should fail due to auth error
      expect(mockOctokit.rest.rateLimit.get).toHaveBeenCalledTimes(1);
    });

    test('should handle auth errors in rate-limited operations', async () => {
      const client = new GitHubApiClient('auth_limited_token');
      
      // First call succeeds (rate limit check)
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 1000 } }
      });
      
      // Second call fails (actual operation)
      const authError = new Error('Token expired during operation');
      authError.status = 401;
      mockOctokit.rest.issues.create.mockRejectedValue(authError);

      await expect(client.createIssue('owner', 'repo', 'Title', 'Body'))
        .rejects.toThrow('Token expired during operation');
    });
  });

  describe('Token Refresh and Rotation', () => {
    test('should handle token that becomes invalid during operation', async () => {
      const client = new GitHubApiClient('rotating_token');
      
      // First few calls succeed
      mockOctokit.rest.rateLimit.get
        .mockResolvedValueOnce({ data: { rate: { remaining: 1000 } } })
        .mockResolvedValueOnce({ data: { rate: { remaining: 999 } } });
      
      mockOctokit.rest.issues.create.mockResolvedValueOnce({
        data: { number: 123 }
      });
      
      // Later call fails due to token rotation
      const expiredError = new Error('Token has expired');
      expiredError.status = 401;
      mockOctokit.rest.issues.get.mockRejectedValue(expiredError);

      // First operation succeeds
      await expect(client.createIssue('owner', 'repo', 'Title', 'Body'))
        .resolves.toEqual({ number: 123 });
      
      // Second operation fails due to expired token
      await expect(client.getIssue('owner', 'repo', 123))
        .rejects.toThrow('Token has expired');
    });

    test('should provide consistent behavior with same token throughout session', () => {
      const token = 'session_token_123';
      const client = new GitHubApiClient(token);
      
      // Token should be passed to Octokit once during initialization
      expect(Octokit).toHaveBeenCalledTimes(1);
      expect(Octokit).toHaveBeenCalledWith({
        auth: token
      });
      
      // All subsequent operations should use the same authenticated client
      expect(client.octokit).toBeDefined();
    });
  });
});