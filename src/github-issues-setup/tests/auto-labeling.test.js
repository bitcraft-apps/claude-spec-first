/**
 * Auto-Labeling Logic Tests
 * Tests the accuracy and functionality of automatic label assignment
 */

const { 
  detectComponents, 
  detectPriority, 
  isSecurityRelated, 
  analyzeIssueContent,
  testAccuracy
} = require('../utils/auto-labeling');

describe('Auto-Labeling Logic Tests', () => {
  describe('Component Detection', () => {
    test('should detect spec-analyst component from content', () => {
      const content = 'The spec-analyst agent fails to parse requirements properly';
      const components = detectComponents(content);
      expect(components).toContain('component:agent-spec-analyst');
    });

    test('should detect installation component from file paths', () => {
      const content = 'Error in scripts/install.sh when running on macOS';
      const components = detectComponents(content);
      expect(components).toContain('component:installation');
    });

    test('should detect validation component from script references', () => {
      const content = 'framework/validate-framework.sh returns error code 1';
      const components = detectComponents(content);
      expect(components).toContain('component:validation');
    });

    test('should detect command components from command references', () => {
      const testCases = [
        { content: '/spec-init command not working', expected: 'component:command-spec-init' },
        { content: 'spec-review fails with error', expected: 'component:command-spec-review' },
        { content: '/qa-check command produces no output', expected: 'component:command-qa-check' }
      ];

      for (const testCase of testCases) {
        const components = detectComponents(testCase.content);
        expect(components).toContain(testCase.expected);
      }
    });

    test('should handle case-insensitive detection', () => {
      const content = 'SPEC-ANALYST Agent Not Working';
      const components = detectComponents(content);
      expect(components).toContain('component:agent-spec-analyst');
    });

    test('should return empty array for unrecognized content', () => {
      const content = 'Some random text that doesnt match any component';
      const components = detectComponents(content);
      expect(components).toHaveLength(0);
    });

    test('should prioritize file path detection over content', () => {
      const content = 'Issue with spec-analyst when running scripts/install.sh';
      const components = detectComponents(content);
      // Should detect installation component due to file path match
      expect(components).toContain('component:installation');
      expect(components).not.toContain('component:agent-spec-analyst');
    });
  });

  describe('Priority Detection', () => {
    test('should detect critical priority from keywords', () => {
      const testCases = [
        'Critical: System completely broken, urgent fix needed',
        'Breaking change causes fatal errors',
        'Production down due to this issue',
        'Urgent: Data corruption detected'
      ];

      for (const content of testCases) {
        const priority = detectPriority(content);
        expect(priority).toBe('priority:critical');
      }
    });

    test('should detect high priority appropriately', () => {
      const testCases = [
        'This is important and affects productivity',
        'Blocking issue for current sprint',
        'Major bug affecting many users',
        'High priority feature request'
      ];

      for (const content of testCases) {
        const priority = detectPriority(content);
        expect(priority).toBe('priority:high');
      }
    });

    test('should detect low priority', () => {
      const testCases = [
        'Nice to have feature for convenience',
        'Minor cosmetic improvement',
        'Low priority polish item',
        'Trivial documentation fix'
      ];

      for (const content of testCases) {
        const priority = detectPriority(content);
        expect(priority).toBe('priority:low');
      }
    });

    test('should default to normal priority for unclear content', () => {
      const content = 'This would be useful to implement';
      const priority = detectPriority(content);
      expect(priority).toBe('priority:normal');
    });
  });

  describe('Security Detection', () => {
    test('should detect security-related content', () => {
      const testCases = [
        'Security vulnerability in authentication',
        'XSS attack vector found',
        'SQL injection possible',
        'Credentials exposed in logs',
        'CVE-2024-1234 affects this component'
      ];

      for (const content of testCases) {
        const isSecure = isSecurityRelated(content);
        expect(isSecure).toBe(true);
      }
    });

    test('should not flag non-security content', () => {
      const testCases = [
        'Feature request for better UI',
        'Bug in calculation logic',
        'Documentation needs update',
        'Performance improvement needed'
      ];

      for (const content of testCases) {
        const isSecure = isSecurityRelated(content);
        expect(isSecure).toBe(false);
      }
    });
  });

  describe('Complete Issue Analysis', () => {
    test('should analyze comprehensive issue content', () => {
      const title = 'Critical bug in spec-analyst agent';
      const body = `The spec-analyst agent crashes when processing large requirements files.
        
        Steps to reproduce:
        1. Run spec-analyst on 500+ line requirements
        2. Agent fails with memory error
        3. System becomes unresponsive
        
        This is blocking our current project.`;

      const result = analyzeIssueContent(title, body);

      expect(result.labels).toContain('component:agent-spec-analyst');
      expect(result.labels).toContain('priority:critical');
      expect(result.analysis.components).toContain('component:agent-spec-analyst');
      expect(result.analysis.priority).toBe('priority:critical');
      expect(result.confidence).toBeGreaterThan(0.5);
    });

    test('should handle security issues with priority override', () => {
      const title = 'Security vulnerability in authentication';
      const body = 'Found XSS vulnerability that exposes user credentials. Nice to have fix.';

      const result = analyzeIssueContent(title, body);

      expect(result.labels).toContain('type:security');
      expect(result.labels).toContain('priority:high'); // Should override "nice to have"
      expect(result.analysis.security).toBe(true);
    });

    test('should analyze feature requests', () => {
      const title = 'Add TypeScript support to framework';
      const body = `As a developer, I want TypeScript support for better type safety.
        
        This would significantly improve productivity and catch errors early.`;

      const result = analyzeIssueContent(title, body);

      expect(result.labels).toContain('priority:high'); // Due to "significantly"
      expect(result.confidence).toBeGreaterThan(0);
    });
  });

  describe('Accuracy Requirements', () => {
    test('should achieve >85% accuracy on test dataset', () => {
      const testCases = [
        {
          content: 'spec-analyst agent broken',
          expected: ['component:agent-spec-analyst']
        },
        {
          content: 'installation fails on macOS',
          expected: ['component:installation']
        },
        {
          content: '/qa-check command errors',
          expected: ['component:command-qa-check']
        },
        {
          content: 'Critical security vulnerability',
          expected: ['priority:critical', 'type:security']
        },
        {
          content: 'Documentation needs minor update',
          expected: ['component:docs', 'priority:low']
        },
        {
          content: 'scripts/install.sh permission error',
          expected: ['component:installation']
        },
        {
          content: 'test-designer not generating proper tests',
          expected: ['component:agent-test-designer']
        },
        {
          content: 'Important: impl-specialist crashes frequently',
          expected: ['component:agent-impl-specialist', 'priority:high']
        }
      ];

      const results = testAccuracy(testCases);
      
      expect(results.accuracy).toBeGreaterThan(0.85);
      expect(results.totalTests).toBe(testCases.length);
      expect(results.correctPredictions).toBeGreaterThan(testCases.length * 0.85);
    });

    test('should provide confidence scores', () => {
      const testCases = [
        {
          title: 'scripts/install.sh fails', // High confidence - file path
          body: 'The installation script crashes',
          expectedConfidence: 0.7
        },
        {
          title: 'Some issue', // Low confidence - vague
          body: 'Something is not working properly',
          expectedConfidence: 0.3
        }
      ];

      for (const testCase of testCases) {
        const result = analyzeIssueContent(testCase.title, testCase.body);
        if (testCase.expectedConfidence > 0.5) {
          expect(result.confidence).toBeGreaterThan(0.5);
        } else {
          expect(result.confidence).toBeLessThan(0.8);
        }
      }
    });
  });

  describe('Edge Cases', () => {
    test('should handle empty or null content', () => {
      const results = [
        analyzeIssueContent('', ''),
        analyzeIssueContent(null, null),
        analyzeIssueContent(undefined, undefined)
      ];

      for (const result of results) {
        expect(result.labels).toBeDefined();
        expect(result.analysis).toBeDefined();
        expect(result.confidence).toBeDefined();
      }
    });

    test('should handle very long content', () => {
      const longContent = 'a'.repeat(10000) + ' spec-analyst ' + 'b'.repeat(10000);
      const result = analyzeIssueContent(longContent, '');
      
      expect(result.labels).toContain('component:agent-spec-analyst');
    });

    test('should handle special characters and unicode', () => {
      const content = '🚀 spec-analyst agent fails with émojis and spëcial chars';
      const result = analyzeIssueContent(content, '');
      
      expect(result.labels).toContain('component:agent-spec-analyst');
    });

    test('should handle multiple component mentions correctly', () => {
      const content = 'Issue affects spec-analyst and test-designer and installation script';
      const result = analyzeIssueContent(content, '');
      
      // Should only return one component (first match)
      const componentLabels = result.labels.filter(label => label.startsWith('component:'));
      expect(componentLabels).toHaveLength(1);
    });
  });
});