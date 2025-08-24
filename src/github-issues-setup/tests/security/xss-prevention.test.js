/**
 * XSS Prevention Tests
 * Tests Cross-Site Scripting prevention in issue content processing,
 * auto-labeling, and template validation
 */

const { analyzeIssueContent, generateLabelExplanation } = require('../../utils/auto-labeling');
const GitHubApiClient = require('../../utils/github-api');
const { Octokit } = require('@octokit/rest');

// Mock the Octokit library
jest.mock('@octokit/rest');

describe('XSS Prevention', () => {
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
          createComment: jest.fn(),
          addLabels: jest.fn()
        }
      }
    };

    Octokit.mockImplementation(() => mockOctokit);
    client = new GitHubApiClient('test_token');
  });

  describe('Script Tag Injection Prevention', () => {
    test('should handle basic script tag injection in issue title', async () => {
      const xssPayload = '<script>alert("XSS")</script>Issue Title';
      
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123,
          title: xssPayload,
          body: 'Clean body'
        }
      });

      const result = await client.createIssue('owner', 'repo', xssPayload, 'Clean body');
      
      expect(result.title).toBe(xssPayload);
      expect(mockOctokit.rest.issues.create).toHaveBeenCalledWith({
        owner: 'owner',
        repo: 'repo',
        title: xssPayload,
        body: 'Clean body',
        labels: []
      });
    });

    test('should handle script tags with various attributes in body', async () => {
      const scriptVariations = [
        '<script>alert("basic")</script>',
        '<script type="text/javascript">alert("typed")</script>',
        '<script src="evil.js"></script>',
        '<script async defer>alert("async")</script>',
        '<script>document.cookie="stolen"</script>',
        '<SCRIPT>alert("uppercase")</SCRIPT>',
        '<ScRiPt>alert("mixedcase")</ScRiPt>'
      ];
      
      for (const payload of scriptVariations) {
        const body = `Issue description ${payload} continues here`;
        
        mockOctokit.rest.issues.create.mockResolvedValue({
          data: { 
            number: 123,
            title: 'XSS Test',
            body: body
          }
        });

        const result = await client.createIssue('owner', 'repo', 'XSS Test', body);
        
        expect(result.body).toBe(body);
      }
    });

    test('should handle obfuscated script tags', async () => {
      const obfuscatedPayloads = [
        '<sc<script>ript>alert("nested")</sc</script>ript>',
        '<%73%63%72%69%70%74>alert("encoded")</%73%63%72%69%70%74>',
        '<script<!--comment-->/>alert("comment")</script>',
        '<script\x20type="text/javascript">alert("nullbyte")</script>',
        '<script\x0D\x0A>alert("newline")</script>'
      ];
      
      for (const payload of obfuscatedPayloads) {
        const result = analyzeIssueContent(`Issue with ${payload}`, '');
        
        // Auto-labeling should still work despite XSS attempts
        expect(result.labels).toBeDefined();
        expect(result.confidence).toBeDefined();
      }
    });
  });

  describe('Event Handler Injection Prevention', () => {
    test('should handle various event handlers in issue content', async () => {
      const eventHandlers = [
        '<img src="x" onerror="alert(\'XSS\')">',
        '<div onclick="alert(\'click\')">Click me</div>',
        '<input type="text" onchange="alert(\'change\')">',
        '<body onload="alert(\'load\')">',
        '<a href="#" onmouseover="alert(\'hover\')">Link</a>',
        '<form onsubmit="alert(\'submit\')">',
        '<iframe onload="alert(\'iframe\')"></iframe>',
        '<svg onload="alert(\'svg\')"></svg>'
      ];
      
      for (const handler of eventHandlers) {
        const body = `Bug report: ${handler} affects the system`;
        
        mockOctokit.rest.issues.createComment.mockResolvedValue({
          data: { 
            id: 456,
            body: body
          }
        });

        const result = await client.createComment('owner', 'repo', 123, body);
        
        expect(result.body).toBe(body);
      }
    });

    test('should handle event handlers in auto-labeling analysis', () => {
      const maliciousContent = 'spec-analyst <img src="x" onerror="alert(\'XSS\')""> broken';
      
      const result = analyzeIssueContent(maliciousContent, '');
      
      // Should detect component despite XSS attempt
      expect(result.labels).toContain('component:agent-spec-analyst');
      expect(result.confidence).toBeGreaterThan(0);
    });

    test('should handle multiple event handlers in single content', () => {
      const multiEventContent = `
        The spec-analyst <img src="x" onerror="steal()"> component
        has issues <div onclick="more_xss()">when processing</div>
        requirements with <a href="#" onmouseover="final_xss()">special chars</a>
      `;
      
      const result = analyzeIssueContent(multiEventContent, '');
      
      expect(result.labels).toContain('component:agent-spec-analyst');
      expect(result.analysis).toBeDefined();
    });
  });

  describe('JavaScript URL Injection Prevention', () => {
    test('should handle javascript: protocol URLs', async () => {
      const jsUrls = [
        'javascript:alert("XSS")',
        'JAVASCRIPT:void(0);alert("uppercase")',
        'javascript:document.location="http://evil.com"',
        'javascript:eval(String.fromCharCode(97,108,101,114,116,40,39,88,83,83,39,41))',
        'javascript&#x3a;alert("encoded")'
      ];
      
      for (const jsUrl of jsUrls) {
        const body = `Click [here](${jsUrl}) for more information`;
        
        mockOctokit.rest.issues.create.mockResolvedValue({
          data: { 
            number: 123,
            title: 'JavaScript URL Test',
            body: body
          }
        });

        const result = await client.createIssue('owner', 'repo', 'JavaScript URL Test', body);
        
        expect(result.body).toBe(body);
      }
    });

    test('should handle data URLs with JavaScript', async () => {
      const dataUrls = [
        'data:text/html,<script>alert("data")</script>',
        'data:text/html;base64,PHNjcmlwdD5hbGVydCgiYmFzZTY0Iik8L3NjcmlwdD4=',
        'data:application/x-javascript,alert("js")'
      ];
      
      for (const dataUrl of dataUrls) {
        const body = `Reference: ${dataUrl}`;
        
        const result = analyzeIssueContent(body, '');
        
        expect(result.labels).toBeDefined();
        expect(result.confidence).toBeDefined();
      }
    });

    test('should handle vbscript: and other protocol injections', async () => {
      const protocols = [
        'vbscript:MsgBox("VBScript")',
        'livescript:alert("LiveScript")',
        'mocha:alert("Mocha")',
        'view-source:javascript:alert("ViewSource")',
        'about:javascript:alert("About")'
      ];
      
      for (const protocol of protocols) {
        const title = `Issue with ${protocol} reference`;
        
        const result = analyzeIssueContent(title, '');
        
        expect(result.labels).toBeDefined();
        expect(result.analysis).toBeDefined();
      }
    });
  });

  describe('HTML Entity and Encoding Attacks', () => {
    test('should handle HTML entity encoded XSS', () => {
      const encodedPayloads = [
        '&lt;script&gt;alert("entities")&lt;/script&gt;',
        '&#x3C;script&#x3E;alert("hex")&#x3C;/script&#x3E;',
        '&#60;script&#62;alert("decimal")&#60;/script&#62;',
        '&amp;lt;script&amp;gt;alert("double")&amp;lt;/script&amp;gt;'
      ];
      
      for (const payload of encodedPayloads) {
        const content = `spec-analyst issue ${payload} needs fixing`;
        
        const result = analyzeIssueContent(content, '');
        
        expect(result.labels).toContain('component:agent-spec-analyst');
      }
    });

    test('should handle URL encoded XSS attempts', async () => {
      const urlEncodedPayloads = [
        '%3Cscript%3Ealert(%22url%22)%3C/script%3E',
        '%3Cimg%20src=x%20onerror=alert(%22img%22)%3E',
        '%3Cbody%20onload=alert(%22body%22)%3E'
      ];
      
      for (const payload of urlEncodedPayloads) {
        const body = `URL parameter issue: ${payload}`;
        
        mockOctokit.rest.issues.createComment.mockResolvedValue({
          data: { 
            id: 456,
            body: body
          }
        });

        const result = await client.createComment('owner', 'repo', 123, body);
        
        expect(result.body).toBe(body);
      }
    });

    test('should handle Unicode encoded XSS', () => {
      // <script> and </script> tags using character codes for obfuscation testing
      const SCRIPT_OPEN_TAG = String.fromCharCode(60, 115, 99, 114, 105, 112, 116, 62); // "<script>"
      const SCRIPT_CLOSE_TAG = String.fromCharCode(60, 47, 115, 99, 114, 105, 112, 116, 62); // "</script>"

      const unicodePayloads = [
        '\\u003Cscript\\u003Ealert("unicode")\\u003C/script\\u003E',  // Unicode encoded script tags
        '\\x3Cscript\\x3Ealert("hex")\\x3C/script\\x3E',              // Hex encoded script tags
        SCRIPT_OPEN_TAG + 'alert("charcode")' + SCRIPT_CLOSE_TAG        // Character code constructed tags
      ];
      
      for (const payload of unicodePayloads) {
        const content = `Unicode test: ${payload}`;
        
        const result = analyzeIssueContent(content, '');
        
        expect(result.labels).toBeDefined();
        expect(result.confidence).toBeGreaterThanOrEqual(0);
      }
    });
  });

  describe('Template and Expression Injection', () => {
    test('should handle template expression injection', () => {
      const templatePayloads = [
        '{{constructor.constructor("alert(\\"template\\")")()}}',
        '${alert("template")}',
        '#{7*7}',
        '<%= alert("erb") %>',
        '{%raw%}{{alert("liquid")}}{%endraw%}',
        '[[${alert("thymeleaf")}]]'
      ];
      
      for (const payload of templatePayloads) {
        const content = `Template issue with spec-analyst: ${payload}`;
        
        const result = analyzeIssueContent(content, '');
        
        // Should still detect component despite template injection
        expect(result.labels).toContain('component:agent-spec-analyst');
      }
    });

    test('should handle server-side template injection', async () => {
      const sstiPayloads = [
        '{{7*7}}',
        '${7*7}',
        '<%=7*7%>',
        '{{config.items}}',
        '${T(java.lang.Runtime).getRuntime().exec("id")}'
      ];
      
      for (const payload of sstiPayloads) {
        const body = `SSTI test: ${payload}`;
        
        mockOctokit.rest.issues.create.mockResolvedValue({
          data: { 
            number: 123,
            title: 'SSTI Test',
            body: body
          }
        });

        const result = await client.createIssue('owner', 'repo', 'SSTI Test', body);
        
        expect(result.body).toBe(body);
      }
    });
  });

  describe('CSS Injection Prevention', () => {
    test('should handle CSS-based XSS attempts', () => {
      const cssPayloads = [
        '<style>body{background:url("javascript:alert(\'CSS\')")}</style>',
        '<div style="background:url(javascript:alert(\'inline\'))">Text</div>',
        '<link rel="stylesheet" href="javascript:alert(\'link\')">',
        '<style>@import url("javascript:alert(\'import\')")</style>'
      ];
      
      for (const payload of cssPayloads) {
        const content = `CSS issue in spec-analyst: ${payload}`;
        
        const result = analyzeIssueContent(content, '');
        
        expect(result.labels).toContain('component:agent-spec-analyst');
      }
    });

    test('should handle CSS expression() attacks', () => {
      const expressionPayloads = [
        '<div style="width:expression(alert(\'expr\'))">',
        '<style>div{width:expression(alert("style"))}</style>',
        '<div style="color:expression(document.cookie=\'stolen\')">',
        '<style>*{background:expression(eval(\'alert(1)\'))}</style>'
      ];
      
      for (const payload of expressionPayloads) {
        const content = `Expression test: ${payload}`;
        
        const result = analyzeIssueContent(content, '');
        
        expect(result.labels).toBeDefined();
      }
    });
  });

  describe('Markdown-Specific XSS Prevention', () => {
    test('should handle XSS in Markdown links', async () => {
      const markdownXss = [
        '[Click here](javascript:alert("md"))',
        '[XSS](data:text/html,<script>alert("data")</script>)',
        '![Alt](javascript:alert("img"))',
        '[Text](javascript:void(0);alert("void"))',
        '<a href="javascript:alert(\'direct\')">Direct HTML</a>'
      ];
      
      for (const payload of markdownXss) {
        const body = `Markdown XSS test: ${payload}`;
        
        mockOctokit.rest.issues.create.mockResolvedValue({
          data: { 
            number: 123,
            title: 'Markdown XSS',
            body: body
          }
        });

        const result = await client.createIssue('owner', 'repo', 'Markdown XSS', body);
        
        expect(result.body).toBe(body);
      }
    });

    test('should handle XSS in Markdown HTML blocks', () => {
      const htmlBlocks = [
        '```html\n<script>alert("code")</script>\n```',
        '<details>\n<summary onclick="alert(\'summary\')">Summary</summary>\n</details>',
        '<iframe src="javascript:alert(\'iframe\')"></iframe>',
        '<embed src="data:text/html,<script>alert(\'embed\')</script>">'
      ];
      
      for (const block of htmlBlocks) {
        const content = `HTML block issue with spec-analyst:\n${block}`;
        
        const result = analyzeIssueContent(content, '');
        
        expect(result.labels).toContain('component:agent-spec-analyst');
      }
    });

    test('should handle XSS in code blocks and inline code', () => {
      const codeXss = [
        '`<script>alert("inline")</script>`',
        '```javascript\nalert("block");\n```',
        '```html\n<img src="x" onerror="alert(\'img\')">\n```',
        '~~<script>alert("strike")</script>~~'
      ];
      
      for (const code of codeXss) {
        const content = `Code XSS in spec-analyst: ${code}`;
        
        const result = analyzeIssueContent(content, '');
        
        expect(result.labels).toContain('component:agent-spec-analyst');
      }
    });
  });

  describe('Label Explanation XSS Prevention', () => {
    test('should handle XSS in label explanation generation', () => {
      const maliciousLabels = [
        'component:<script>alert("label")</script>',
        'priority:<img src="x" onerror="alert(\'priority\')">',
        'type:<svg onload="alert(\'type\')"></svg>'
      ];
      
      const analysis = {
        components: maliciousLabels.filter(l => l.startsWith('component:')),
        priority: maliciousLabels.find(l => l.startsWith('priority:')),
        security: false
      };
      
      const explanation = generateLabelExplanation(maliciousLabels, analysis);
      
      // Should generate explanation without executing XSS
      expect(explanation).toContain('component');
      expect(typeof explanation).toBe('string');
    });

    test('should handle XSS in component name extraction', () => {
      const xssComponent = 'component:agent-<script>alert("component")</script>-analyst';
      const analysis = {
        components: [xssComponent],
        priority: 'priority:normal',
        security: false
      };
      
      const explanation = generateLabelExplanation([xssComponent], analysis);
      
      expect(explanation).toContain('agent');
      expect(typeof explanation).toBe('string');
    });
  });

  describe('Context-Specific XSS Prevention', () => {
    test('should handle XSS in different issue contexts', async () => {
      const contexts = [
        { field: 'title', payload: '<script>alert("title")</script>Issue' },
        { field: 'body', payload: 'Body content <img src="x" onerror="alert(\'body\')">' },
        { field: 'labels', payload: ['<script>alert("label")</script>', 'normal-label'] }
      ];
      
      for (const context of contexts) {
        if (context.field === 'labels') {
          mockOctokit.rest.issues.addLabels.mockResolvedValue({
            data: context.payload.map(name => ({ name }))
          });

          const result = await client.addLabels('owner', 'repo', 123, context.payload);
          
          expect(result[0].name).toBe('<script>alert("label")</script>');
        } else {
          const args = context.field === 'title' 
            ? [context.payload, 'Clean body']
            : ['Clean title', context.payload];
          
          mockOctokit.rest.issues.create.mockResolvedValue({
            data: { 
              number: 123,
              title: args[0],
              body: args[1]
            }
          });

          const result = await client.createIssue('owner', 'repo', args[0], args[1]);
          
          expect(result[context.field]).toBe(context.payload);
        }
      }
    });

    test('should handle XSS across multiple operations', async () => {
      const xssPayload = '<script>alert("persistent")</script>';
      
      // Create issue with XSS
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { 
          number: 123,
          title: `XSS Test ${xssPayload}`,
          body: `Body with ${xssPayload}`
        }
      });

      // Add comment with XSS
      mockOctokit.rest.issues.createComment.mockResolvedValue({
        data: { 
          id: 456,
          body: `Comment ${xssPayload}`
        }
      });

      const issueResult = await client.createIssue('owner', 'repo', `XSS Test ${xssPayload}`, `Body with ${xssPayload}`);
      const commentResult = await client.createComment('owner', 'repo', 123, `Comment ${xssPayload}`);
      
      expect(issueResult.title).toContain(xssPayload);
      expect(issueResult.body).toContain(xssPayload);
      expect(commentResult.body).toContain(xssPayload);
    });
  });

  describe('Browser-Specific XSS Vectors', () => {
    test('should handle IE-specific XSS vectors', () => {
      const ieVectors = [
        '<img dynsrc="javascript:alert(\'ie\')" />',
        '<img lowsrc="javascript:alert(\'lowsrc\')" />',
        '<bgsound src="javascript:alert(\'bgsound\')" />',
        '<br size="&{alert(\'br\')}">'
      ];
      
      for (const vector of ieVectors) {
        const content = `IE-specific XSS in spec-analyst: ${vector}`;
        
        const result = analyzeIssueContent(content, '');
        
        expect(result.labels).toContain('component:agent-spec-analyst');
      }
    });

    test('should handle Firefox-specific vectors', () => {
      const firefoxVectors = [
        '<meta http-equiv="refresh" content="0;url=javascript:alert(\'meta\')" />',
        '<link rel="stylesheet" href="javascript:alert(\'link\')" />',
        '<style>@import"javascript:alert(\'import\')";</style>'
      ];
      
      for (const vector of firefoxVectors) {
        const content = `Firefox XSS test: ${vector}`;
        
        const result = analyzeIssueContent(content, '');
        
        expect(result.labels).toBeDefined();
      }
    });

    test('should handle Chrome/Safari-specific vectors', () => {
      const webkitVectors = [
        '<embed src="javascript:alert(\'embed\')" />',
        '<object data="javascript:alert(\'object\')" />',
        '<applet code="javascript:alert(\'applet\')" />'
      ];
      
      for (const vector of webkitVectors) {
        const content = `WebKit XSS in spec-analyst: ${vector}`;
        
        const result = analyzeIssueContent(content, '');
        
        expect(result.labels).toContain('component:agent-spec-analyst');
      }
    });
  });
});