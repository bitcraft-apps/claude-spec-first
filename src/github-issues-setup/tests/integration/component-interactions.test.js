/**
 * Component Interaction Tests
 * Tests interaction between auto-labeling, API client, and template processing
 */

const GitHubApiClient = require('../../utils/github-api');
const { analyzeIssueContent, generateLabelExplanation, testAccuracy } = require('../../utils/auto-labeling');
const { Octokit } = require('@octokit/rest');

// Mock the Octokit library
jest.mock('@octokit/rest');

describe('Component Interactions', () => {
  let mockOctokit;
  let client;

  beforeEach(() => {
    jest.clearAllMocks();
    
    mockOctokit = {
      rest: {
        rateLimit: {
          get: jest.fn().mockResolvedValue({
            data: { rate: { remaining: 1000, reset: Date.now() / 1000 + 3600 } }
          })
        },
        issues: {
          create: jest.fn(),
          addLabels: jest.fn(),
          createComment: jest.fn(),
          updateLabel: jest.fn(),
          createLabel: jest.fn()
        }
      }
    };

    Octokit.mockImplementation(() => mockOctokit);
    client = new GitHubApiClient('test_token');
  });

  describe('Auto-Labeling and API Client Integration', () => {
    test('should create issue with auto-detected labels in single workflow', async () => {
      const title = 'Critical bug in spec-analyst agent processing';
      const body = 'The spec-analyst agent fails when processing large requirements files. This is urgent.';

      // Step 1: Auto-labeling analysis
      const analysis = analyzeIssueContent(title, body);
      
      expect(analysis.labels).toContain('component:agent-spec-analyst');
      expect(analysis.labels).toContain('priority:critical');
      expect(analysis.confidence).toBeGreaterThan(0.7);

      // Step 2: Create issue via API
      const mockIssue = {
        number: 100,
        title,
        body,
        labels: []
      };

      mockOctokit.rest.issues.create.mockResolvedValue({ data: mockIssue });

      const issue = await client.createIssue('owner', 'repo', title, body, analysis.labels);
      
      expect(issue.number).toBe(100);
      expect(mockOctokit.rest.issues.create).toHaveBeenCalledWith({
        owner: 'owner',
        repo: 'repo',
        title,
        body,
        labels: analysis.labels
      });

      // Step 3: Generate explanation for applied labels
      const explanation = generateLabelExplanation(analysis.labels, analysis.analysis);
      
      expect(explanation).toContain('spec analyst');
      expect(explanation).toContain('critical');
    });

    test('should handle auto-labeling failures gracefully', async () => {
      const title = '';  // Empty title
      const body = null; // Null body

      // Auto-labeling should handle edge cases
      const analysis = analyzeIssueContent(title, body);
      
      expect(analysis.labels).toBeDefined();
      expect(analysis.analysis).toBeDefined();
      expect(analysis.confidence).toBeDefined();

      // API client should handle empty content
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { number: 101, title: '', body: null }
      });

      const issue = await client.createIssue('owner', 'repo', title, body, analysis.labels);
      
      expect(issue.number).toBe(101);
    });

    test('should sync detected labels with repository', async () => {
      const issueContent = [
        'spec-analyst agent issues',
        'test-designer not working',
        'impl-specialist crashes',
        'qa-validator fails validation'
      ];

      // Collect all detected labels
      const allDetectedLabels = new Set();
      
      for (const content of issueContent) {
        const analysis = analyzeIssueContent(content, '');
        analysis.labels.forEach(label => allDetectedLabels.add(label));
      }

      // Convert to label definitions for sync
      const labelDefinitions = Array.from(allDetectedLabels).map(label => ({
        name: label,
        color: label.startsWith('priority:') ? 'ff0000' : 
               label.startsWith('component:') ? '0052cc' : '6e5494',
        description: `Auto-generated label: ${label}`
      }));

      // Mock sync operations
      mockOctokit.rest.issues.updateLabel.mockImplementation((params) => {
        if (Math.random() > 0.5) {  // Simulate some labels exist
          return Promise.resolve({ data: params });
        } else {
          const error = new Error('Not Found');
          error.status = 404;
          return Promise.reject(error);
        }
      });

      mockOctokit.rest.issues.createLabel.mockImplementation((params) => {
        return Promise.resolve({ data: params });
      });

      const syncResults = await client.syncLabels('owner', 'repo', labelDefinitions);
      
      expect(syncResults).toHaveLength(labelDefinitions.length);
      
      const successful = syncResults.filter(r => r.action !== 'failed').length;
      expect(successful).toBe(labelDefinitions.length);
    });
  });

  describe('Rate Limiting and Auto-Labeling Coordination', () => {
    test('should handle rate limiting during batch label operations', async () => {
      const batchIssues = Array.from({ length: 20 }, (_, i) => ({
        title: `Issue ${i} with spec-analyst`,
        body: `Description ${i} for spec-analyst bug`
      }));

      let rateLimitCalls = 0;
      mockOctokit.rest.rateLimit.get.mockImplementation(() => {
        rateLimitCalls++;
        const remaining = Math.max(100 - rateLimitCalls * 2, 0);
        return Promise.resolve({
          data: { 
            rate: { 
              remaining,
              reset: Date.now() / 1000 + 3600 
            }
          }
        });
      });

      mockOctokit.rest.issues.create.mockImplementation((params) => {
        return Promise.resolve({
          data: { 
            number: Math.floor(Math.random() * 1000),
            title: params.title,
            body: params.body
          }
        });
      });

      // Process all issues with auto-labeling
      const results = [];
      for (const issueData of batchIssues) {
        const analysis = analyzeIssueContent(issueData.title, issueData.body);
        const issue = await client.createIssue('owner', 'repo', issueData.title, issueData.body, analysis.labels);
        results.push({ issue, analysis });
      }

      expect(results).toHaveLength(20);
      
      // All should have detected spec-analyst component
      const detectedComponents = results.filter(r => 
        r.analysis.labels.includes('component:agent-spec-analyst')
      );
      expect(detectedComponents).toHaveLength(20);

      // Rate limiting should have been checked for each operation
      expect(rateLimitCalls).toBeGreaterThanOrEqual(20);
    });

    test('should coordinate rate limiting across multiple API operations', async () => {
      const workflowIssue = {
        title: 'Complex workflow issue affecting test-designer',
        body: 'This is a high priority issue affecting the test-designer agent with security implications'
      };

      // Simulate decreasing rate limit
      let remainingCalls = 50;
      mockOctokit.rest.rateLimit.get.mockImplementation(() => {
        remainingCalls -= 5;
        return Promise.resolve({
          data: { 
            rate: { 
              remaining: remainingCalls,
              reset: Date.now() / 1000 + 3600 
            }
          }
        });
      });

      // Step 1: Analyze and create issue
      const analysis = analyzeIssueContent(workflowIssue.title, workflowIssue.body);
      
      expect(analysis.labels).toContain('component:agent-test-designer');
      expect(analysis.labels).toContain('priority:high');
      expect(analysis.labels).toContain('type:security');

      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { number: 200, ...workflowIssue }
      });

      const issue = await client.createIssue('owner', 'repo', workflowIssue.title, workflowIssue.body);

      // Step 2: Apply labels
      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: analysis.labels.map(name => ({ name, color: 'red' }))
      });

      await client.addLabels('owner', 'repo', issue.number, analysis.labels);

      // Step 3: Add explanatory comment
      const explanation = generateLabelExplanation(analysis.labels, analysis.analysis);
      const explanatoryComment = `Auto-labeling applied: ${explanation}`;

      mockOctokit.rest.issues.createComment.mockResolvedValue({
        data: { id: 300, body: explanatoryComment }
      });

      await client.createComment('owner', 'repo', issue.number, explanatoryComment);

      // All operations should have checked rate limits
      expect(mockOctokit.rest.rateLimit.get).toHaveBeenCalledTimes(3);
      expect(remainingCalls).toBeLessThan(50); // Rate limit consumed
    });
  });

  describe('Error Handling Across Components', () => {
    test('should handle auto-labeling errors without breaking API operations', async () => {
      const problematicContent = {
        title: 'A'.repeat(100000), // Very long title
        body: 'B'.repeat(1000000)  // Very long body
      };

      // Auto-labeling should handle large content
      const analysis = analyzeIssueContent(problematicContent.title, problematicContent.body);
      
      expect(analysis.labels).toBeDefined();
      expect(analysis.analysis).toBeDefined();
      expect(analysis.confidence).toBeDefined();

      // API should handle large content too
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { number: 400, ...problematicContent }
      });

      const issue = await client.createIssue('owner', 'repo', problematicContent.title, problematicContent.body);
      
      expect(issue.number).toBe(400);
    });

    test('should handle API errors without breaking auto-labeling', async () => {
      const title = 'API error test with spec-analyst';
      const body = 'Testing error resilience';

      // Auto-labeling should work regardless of API state
      const analysis = analyzeIssueContent(title, body);
      
      expect(analysis.labels).toContain('component:agent-spec-analyst');
      expect(analysis.confidence).toBeGreaterThan(0);

      // API operation fails
      const apiError = new Error('GitHub API error');
      apiError.status = 500;

      mockOctokit.rest.issues.create.mockRejectedValue(apiError);

      // API failure shouldn't affect auto-labeling results
      await expect(client.createIssue('owner', 'repo', title, body)).rejects.toThrow('GitHub API error');
      
      // Auto-labeling still works independently
      const secondAnalysis = analyzeIssueContent(title, body);
      expect(secondAnalysis.labels).toEqual(analysis.labels);
    });

    test('should recover from partial component failures', async () => {
      const issues = [
        { title: 'Working issue with spec-analyst', body: 'This should work fine' },
        { title: 'Failing issue', body: 'This will fail' },
        { title: 'Another working issue with test-designer', body: 'This should also work' }
      ];

      const results = [];
      
      for (let i = 0; i < issues.length; i++) {
        const issueData = issues[i];
        
        // Auto-labeling always works
        const analysis = analyzeIssueContent(issueData.title, issueData.body);
        
        // API fails for middle issue only
        if (i === 1) {
          const apiError = new Error('Temporary API failure');
          mockOctokit.rest.issues.create.mockRejectedValueOnce(apiError);
          
          try {
            await client.createIssue('owner', 'repo', issueData.title, issueData.body);
          } catch (error) {
            results.push({ error: true, analysis });
          }
        } else {
          mockOctokit.rest.issues.create.mockResolvedValueOnce({
            data: { number: 500 + i, ...issueData }
          });
          
          const issue = await client.createIssue('owner', 'repo', issueData.title, issueData.body);
          results.push({ issue, analysis });
        }
      }

      // Should have processed all three issues
      expect(results).toHaveLength(3);
      
      // Two should have succeeded
      const successful = results.filter(r => !r.error);
      expect(successful).toHaveLength(2);
      
      // One should have failed
      const failed = results.filter(r => r.error);
      expect(failed).toHaveLength(1);
      
      // All should have auto-labeling analysis
      expect(results.every(r => r.analysis)).toBe(true);
    });
  });

  describe('Performance and Scalability Integration', () => {
    test('should handle high-volume operations efficiently', async () => {
      const startTime = Date.now();
      
      // Generate 100 test issues
      const testIssues = Array.from({ length: 100 }, (_, i) => ({
        title: `Performance test issue ${i} with spec-analyst`,
        body: `Body content ${i} for performance testing`
      }));

      // Mock consistent API responses
      mockOctokit.rest.issues.create.mockImplementation((params) => {
        return Promise.resolve({
          data: { 
            number: Math.floor(Math.random() * 10000),
            title: params.title,
            body: params.body
          }
        });
      });

      // Process all issues with auto-labeling
      const processedIssues = [];
      
      for (const issueData of testIssues) {
        const analysis = analyzeIssueContent(issueData.title, issueData.body);
        const issue = await client.createIssue('owner', 'repo', issueData.title, issueData.body, analysis.labels);
        
        processedIssues.push({
          issue,
          analysis,
          hasSpecAnalyst: analysis.labels.includes('component:agent-spec-analyst')
        });
      }

      const endTime = Date.now();
      const duration = endTime - startTime;

      // Performance assertions
      expect(processedIssues).toHaveLength(100);
      expect(duration).toBeLessThan(10000); // Should complete in under 10 seconds
      
      // All issues should have detected spec-analyst component
      const detectedComponents = processedIssues.filter(p => p.hasSpecAnalyst);
      expect(detectedComponents).toHaveLength(100);

      // Average processing time per issue should be reasonable
      const avgTimePerIssue = duration / 100;
      expect(avgTimePerIssue).toBeLessThan(100); // Under 100ms per issue
    });

    test('should maintain accuracy under load', async () => {
      // Create test cases with known expected labels
      const accuracyTestCases = [
        {
          title: 'spec-analyst agent broken',
          body: 'Critical issue',
          expected: ['component:agent-spec-analyst', 'priority:critical']
        },
        {
          title: 'scripts/install.sh fails',
          body: 'Installation problem',
          expected: ['component:installation']
        },
        {
          title: 'Documentation needs update',
          body: 'Minor improvement needed',
          expected: ['component:docs', 'priority:low']
        },
        {
          title: 'Security vulnerability found',
          body: 'XSS attack possible',
          expected: ['type:security', 'priority:high']
        },
        {
          title: '/qa-check command errors',
          body: 'Command not working',
          expected: ['component:command-qa-check']
        }
      ];

      // Process test cases multiple times to simulate load
      const iterations = 20;
      const allResults = [];
      
      for (let i = 0; i < iterations; i++) {
        for (const testCase of accuracyTestCases) {
          const analysis = analyzeIssueContent(testCase.title, testCase.body);
          allResults.push({
            expected: testCase.expected,
            detected: analysis.labels,
            correct: testCase.expected.every(label => analysis.labels.includes(label))
          });
        }
      }

      // Calculate accuracy across all iterations
      const totalTests = allResults.length;
      const correctTests = allResults.filter(r => r.correct).length;
      const accuracy = correctTests / totalTests;

      expect(totalTests).toBe(accuracyTestCases.length * iterations);
      expect(accuracy).toBeGreaterThan(0.85); // Maintain >85% accuracy under load
    });
  });

  describe('Configuration and Customization Integration', () => {
    test('should handle custom label configurations', async () => {
      // Simulate custom label mappings
      const customLabels = [
        { name: 'custom:urgent', color: 'ff0000', description: 'Custom urgent label' },
        { name: 'team:frontend', color: '00ff00', description: 'Frontend team label' },
        { name: 'area:performance', color: '0000ff', description: 'Performance related' }
      ];

      // Test label synchronization with custom labels
      mockOctokit.rest.issues.updateLabel.mockImplementation((params) => {
        const error = new Error('Not Found');
        error.status = 404;
        return Promise.reject(error); // All labels are new
      });

      mockOctokit.rest.issues.createLabel.mockImplementation((params) => {
        return Promise.resolve({ data: params });
      });

      const syncResults = await client.syncLabels('owner', 'repo', customLabels);
      
      expect(syncResults).toHaveLength(3);
      expect(syncResults.every(r => r.action === 'created')).toBe(true);
      
      // Verify all custom labels were created
      expect(mockOctokit.rest.issues.createLabel).toHaveBeenCalledTimes(3);
      expect(mockOctokit.rest.issues.createLabel).toHaveBeenCalledWith(
        expect.objectContaining({ name: 'custom:urgent' })
      );
    });

    test('should integrate with different GitHub API configurations', async () => {
      // Test with custom API configuration
      const customClient = new GitHubApiClient('custom_token', {
        baseUrl: 'https://github.enterprise.com/api/v3',
        timeout: 10000
      });

      expect(Octokit).toHaveBeenCalledWith({
        auth: 'custom_token',
        baseUrl: 'https://github.enterprise.com/api/v3',
        timeout: 10000
      });

      // Auto-labeling should work with custom API client
      const analysis = analyzeIssueContent('Enterprise issue with spec-analyst', 'Enterprise testing');
      
      expect(analysis.labels).toContain('component:agent-spec-analyst');
      expect(analysis.confidence).toBeGreaterThan(0);

      // API operations should work with custom configuration
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { number: 999, title: 'Enterprise issue with spec-analyst' }
      });

      const issue = await customClient.createIssue('enterprise', 'repo', 'Enterprise issue with spec-analyst', 'Enterprise testing');
      
      expect(issue.number).toBe(999);
    });
  });

  describe('Data Flow and State Management', () => {
    test('should maintain consistent state across component interactions', async () => {
      const workflowState = {
        issueNumber: null,
        appliedLabels: [],
        comments: [],
        analysis: null
      };

      const title = 'Stateful workflow test with impl-specialist';
      const body = 'Testing state management across components';

      // Step 1: Initial analysis and issue creation
      workflowState.analysis = analyzeIssueContent(title, body);
      
      expect(workflowState.analysis.labels).toContain('component:agent-impl-specialist');

      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { number: 777, title, body }
      });

      const issue = await client.createIssue('owner', 'repo', title, body);
      workflowState.issueNumber = issue.number;

      expect(workflowState.issueNumber).toBe(777);

      // Step 2: Apply labels and track state
      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: workflowState.analysis.labels.map(name => ({ name, color: 'blue' }))
      });

      const appliedLabels = await client.addLabels('owner', 'repo', workflowState.issueNumber, workflowState.analysis.labels);
      workflowState.appliedLabels = appliedLabels.map(l => l.name);

      expect(workflowState.appliedLabels).toContain('component:agent-impl-specialist');

      // Step 3: Add comments and maintain state
      const statusComment = `Applied labels: ${workflowState.appliedLabels.join(', ')}`;
      
      mockOctokit.rest.issues.createComment.mockResolvedValue({
        data: { id: 888, body: statusComment }
      });

      const comment = await client.createComment('owner', 'repo', workflowState.issueNumber, statusComment);
      workflowState.comments.push(comment);

      expect(workflowState.comments).toHaveLength(1);
      expect(workflowState.comments[0].body).toContain('component:agent-impl-specialist');

      // Verify complete workflow state
      expect(workflowState.issueNumber).toBe(777);
      expect(workflowState.appliedLabels).toHaveLength(workflowState.analysis.labels.length);
      expect(workflowState.comments).toHaveLength(1);
      expect(workflowState.analysis.confidence).toBeGreaterThan(0);
    });

    test('should handle concurrent workflows without state interference', async () => {
      const workflows = [
        { id: 1, title: 'Concurrent issue 1 with spec-analyst', body: 'First concurrent issue' },
        { id: 2, title: 'Concurrent issue 2 with test-designer', body: 'Second concurrent issue' },
        { id: 3, title: 'Concurrent issue 3 with qa-validator', body: 'Third concurrent issue' }
      ];

      const workflowResults = [];

      // Process workflows concurrently
      const promises = workflows.map(async (workflow) => {
        const analysis = analyzeIssueContent(workflow.title, workflow.body);
        
        mockOctokit.rest.issues.create.mockResolvedValue({
          data: { number: 1000 + workflow.id, ...workflow }
        });

        const issue = await client.createIssue('owner', 'repo', workflow.title, workflow.body);
        
        return {
          workflowId: workflow.id,
          issue,
          analysis,
          detectedComponent: analysis.labels.find(l => l.startsWith('component:'))
        };
      });

      const results = await Promise.all(promises);
      
      // Verify each workflow maintained independent state
      expect(results).toHaveLength(3);
      
      const specAnalyst = results.find(r => r.detectedComponent === 'component:agent-spec-analyst');
      const testDesigner = results.find(r => r.detectedComponent === 'component:agent-test-designer');
      const qaValidator = results.find(r => r.detectedComponent === 'component:agent-qa-validator');

      expect(specAnalyst).toBeDefined();
      expect(testDesigner).toBeDefined();
      expect(qaValidator).toBeDefined();

      expect(specAnalyst.workflowId).toBe(1);
      expect(testDesigner.workflowId).toBe(2);
      expect(qaValidator.workflowId).toBe(3);
    });
  });
});