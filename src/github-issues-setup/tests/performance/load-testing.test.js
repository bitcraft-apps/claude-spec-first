/**
 * Load Testing Tests
 * Tests system performance under high load, concurrent operations,
 * and stress conditions
 */

const GitHubApiClient = require('../../utils/github-api');
const { analyzeIssueContent, testAccuracy } = require('../../utils/auto-labeling');
const { Octokit } = require('@octokit/rest');

// Mock the Octokit library
jest.mock('@octokit/rest');

// Increase timeout for performance tests
jest.setTimeout(30000);

describe('Load Testing', () => {
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
          addLabels: jest.fn(),
          createComment: jest.fn(),
          update: jest.fn(),
          listMilestones: jest.fn(),
          updateLabel: jest.fn(),
          createLabel: jest.fn()
        }
      }
    };

    Octokit.mockImplementation(() => mockOctokit);
    client = new GitHubApiClient('load_test_token');
  });

  describe('High Volume Issue Creation', () => {
    test('should handle 1000 concurrent issue creations', async () => {
      const startTime = performance.now();
      const issueCount = 1000;
      
      // Mock rate limiting to be generous
      let rateLimitCalls = 0;
      mockOctokit.rest.rateLimit.get.mockImplementation(() => {
        rateLimitCalls++;
        return Promise.resolve({
          data: { 
            rate: { 
              remaining: Math.max(5000 - rateLimitCalls, 100),
              reset: Date.now() / 1000 + 3600 
            }
          }
        });
      });

      // Mock issue creation with variable response time
      mockOctokit.rest.issues.create.mockImplementation((params) => {
        const delay = Math.random() * 50; // 0-50ms delay
        return new Promise(resolve => {
          setTimeout(() => {
            resolve({
              data: {
                number: Math.floor(Math.random() * 100000),
                title: params.title,
                body: params.body,
                created_at: new Date().toISOString()
              }
            });
          }, delay);
        });
      });

      // Generate test issues
      const testIssues = Array.from({ length: issueCount }, (_, i) => ({
        title: `Load test issue ${i} with spec-analyst`,
        body: `Generated issue ${i} for load testing. This is a critical priority issue.`
      }));

      // Process all issues concurrently
      const promises = testIssues.map(async (issueData, index) => {
        const analysis = analyzeIssueContent(issueData.title, issueData.body);
        
        try {
          const issue = await client.createIssue('owner', 'repo', issueData.title, issueData.body, analysis.labels);
          return {
            index,
            issue,
            analysis,
            success: true
          };
        } catch (error) {
          return {
            index,
            error: error.message,
            success: false
          };
        }
      });

      const results = await Promise.all(promises);
      const endTime = performance.now();
      const duration = endTime - startTime;

      // Performance assertions
      expect(results).toHaveLength(issueCount);
      
      const successful = results.filter(r => r.success);
      const failed = results.filter(r => !r.success);
      
      expect(successful.length).toBeGreaterThan(issueCount * 0.95); // >95% success rate
      expect(failed.length).toBeLessThan(issueCount * 0.05); // <5% failure rate
      
      // Timing assertions
      expect(duration).toBeLessThan(30000); // Under 30 seconds
      
      const avgTimePerIssue = duration / issueCount;
      expect(avgTimePerIssue).toBeLessThan(30); // Under 30ms average per issue
      
      console.log(`Load test results: ${successful.length}/${issueCount} successful in ${duration.toFixed(2)}ms`);
      console.log(`Average time per issue: ${avgTimePerIssue.toFixed(2)}ms`);
    });

    test('should maintain performance with varying issue sizes', async () => {
      const issueSizes = [
        { size: 'small', titleLength: 50, bodyLength: 200 },
        { size: 'medium', titleLength: 200, bodyLength: 2000 },
        { size: 'large', titleLength: 500, bodyLength: 10000 },
        { size: 'xlarge', titleLength: 1000, bodyLength: 50000 }
      ];

      const performanceResults = {};

      for (const sizeConfig of issueSizes) {
        const startTime = performance.now();
        const testCount = 100;

        // Generate issues of specific size
        const testIssues = Array.from({ length: testCount }, (_, i) => ({
          title: `spec-analyst issue ${'A'.repeat(sizeConfig.titleLength - 20)} ${i}`,
          body: `Test body ${'B'.repeat(sizeConfig.bodyLength - 10)} ${i}`
        }));

        mockOctokit.rest.rateLimit.get.mockResolvedValue({
          data: { rate: { remaining: 1000 } }
        });

        mockOctokit.rest.issues.create.mockImplementation((params) => {
          const processingTime = Math.log(params.title.length + params.body.length) * 2;
          return new Promise(resolve => {
            setTimeout(() => {
              resolve({
                data: { 
                  number: Math.floor(Math.random() * 1000),
                  title: params.title,
                  body: params.body
                }
              });
            }, processingTime);
          });
        });

        // Process issues
        const promises = testIssues.map(async (issueData) => {
          const analysis = analyzeIssueContent(issueData.title, issueData.body);
          const issue = await client.createIssue('owner', 'repo', issueData.title, issueData.body);
          return { issue, analysis };
        });

        await Promise.all(promises);
        const endTime = performance.now();
        
        performanceResults[sizeConfig.size] = {
          duration: endTime - startTime,
          avgPerIssue: (endTime - startTime) / testCount,
          titleLength: sizeConfig.titleLength,
          bodyLength: sizeConfig.bodyLength
        };
      }

      // Performance should degrade gracefully with size
      expect(performanceResults.small.avgPerIssue).toBeLessThan(20); // <20ms for small
      expect(performanceResults.medium.avgPerIssue).toBeLessThan(50); // <50ms for medium
      expect(performanceResults.large.avgPerIssue).toBeLessThan(100); // <100ms for large
      expect(performanceResults.xlarge.avgPerIssue).toBeLessThan(200); // <200ms for xlarge

      console.log('Performance by issue size:', performanceResults);
    });
  });

  describe('Concurrent Auto-Labeling Performance', () => {
    test('should handle 10000 concurrent auto-labeling operations', async () => {
      const startTime = performance.now();
      const labelingCount = 10000;

      // Generate diverse test content
      const testContent = [
        'spec-analyst agent broken',
        'test-designer not working properly',
        'impl-specialist crashes frequently',
        'qa-validator fails validation',
        'scripts/install.sh permission error',
        'Critical security vulnerability found',
        'Documentation needs minor update',
        '/qa-check command produces errors',
        'High priority feature request',
        'Installation script breaks on macOS'
      ];

      // Generate test cases
      const testCases = Array.from({ length: labelingCount }, (_, i) => {
        const content = testContent[i % testContent.length];
        return {
          title: `${content} - test ${i}`,
          body: `Issue description ${i} with additional context`
        };
      });

      // Process all labeling concurrently
      const promises = testCases.map(async (testCase) => {
        return analyzeIssueContent(testCase.title, testCase.body);
      });

      const results = await Promise.all(promises);
      const endTime = performance.now();
      const duration = endTime - startTime;

      // Performance assertions
      expect(results).toHaveLength(labelingCount);
      expect(duration).toBeLessThan(10000); // Under 10 seconds

      const avgTimePerAnalysis = duration / labelingCount;
      expect(avgTimePerAnalysis).toBeLessThan(1); // Under 1ms per analysis

      // Accuracy assertions
      const withLabels = results.filter(r => r.labels.length > 0);
      expect(withLabels.length).toBeGreaterThan(labelingCount * 0.8); // >80% should have labels

      const withComponents = results.filter(r => 
        r.labels.some(label => label.startsWith('component:'))
      );
      expect(withComponents.length).toBeGreaterThan(labelingCount * 0.7); // >70% should have components

      console.log(`Auto-labeling performance: ${labelingCount} analyses in ${duration.toFixed(2)}ms`);
      console.log(`Average time per analysis: ${avgTimePerAnalysis.toFixed(3)}ms`);
      console.log(`Labels applied: ${withLabels.length}/${labelingCount} (${(withLabels.length/labelingCount*100).toFixed(1)}%)`);
    });

    test('should maintain accuracy under concurrent load', async () => {
      const accuracyTestCases = [
        { content: 'spec-analyst agent broken', expected: ['component:agent-spec-analyst'] },
        { content: 'scripts/install.sh fails', expected: ['component:installation'] },
        { content: 'Critical security issue', expected: ['priority:critical'] },
        { content: 'Documentation update needed', expected: ['component:docs'] },
        { content: '/qa-check command error', expected: ['component:command-qa-check'] }
      ];

      const iterations = 1000;
      const startTime = performance.now();

      // Run accuracy tests many times concurrently
      const promises = Array.from({ length: iterations }, () => {
        return Promise.all(accuracyTestCases.map(testCase => {
          const analysis = analyzeIssueContent(testCase.content, '');
          const correct = testCase.expected.every(label => analysis.labels.includes(label));
          return { correct, analysis, expected: testCase.expected };
        }));
      });

      const allResults = await Promise.all(promises);
      const endTime = performance.now();

      // Flatten results
      const flatResults = allResults.flat();
      const totalTests = flatResults.length;
      const correctTests = flatResults.filter(r => r.correct).length;
      const accuracy = correctTests / totalTests;

      expect(totalTests).toBe(accuracyTestCases.length * iterations);
      expect(accuracy).toBeGreaterThan(0.95); // Maintain >95% accuracy under load
      
      const duration = endTime - startTime;
      expect(duration).toBeLessThan(5000); // Complete in under 5 seconds

      console.log(`Accuracy under load: ${correctTests}/${totalTests} (${(accuracy*100).toFixed(1)}%) in ${duration.toFixed(2)}ms`);
    });
  });

  describe('API Rate Limiting Under Load', () => {
    test('should handle rate limit pressure gracefully', async () => {
      const operationCount = 100;
      const startTime = performance.now();

      // Simulate aggressive rate limiting
      let remainingCalls = 200;
      mockOctokit.rest.rateLimit.get.mockImplementation(() => {
        remainingCalls -= 3; // Aggressive consumption
        const remaining = Math.max(remainingCalls, 0);
        
        return Promise.resolve({
          data: { 
            rate: { 
              remaining,
              reset: Date.now() / 1000 + (remaining === 0 ? 5 : 3600)
            }
          }
        });
      });

      // Mock operations with rate limiting
      let operationCount_tracking = 0;
      mockOctokit.rest.issues.create.mockImplementation(() => {
        operationCount_tracking++;
        
        if (remainingCalls <= 0) {
          const error = new Error('API rate limit exceeded');
          error.status = 403;
          return Promise.reject(error);
        }
        
        return Promise.resolve({
          data: { 
            number: operationCount_tracking,
            title: 'Rate limit test',
            body: 'Testing rate limiting'
          }
        });
      });

      // Attempt many operations
      const operations = Array.from({ length: operationCount }, (_, i) => 
        client.createIssue('owner', 'repo', `Rate limit test ${i}`, 'Testing rate limiting')
      );

      const results = await Promise.allSettled(operations);
      const endTime = performance.now();

      const successful = results.filter(r => r.status === 'fulfilled');
      const failed = results.filter(r => r.status === 'rejected');

      // Should handle rate limiting gracefully
      expect(results).toHaveLength(operationCount);
      expect(successful.length).toBeGreaterThan(0); // Some should succeed
      expect(failed.length).toBeGreaterThan(0); // Some should fail due to rate limiting

      // Rate limit errors should be proper API errors
      const rateLimitErrors = failed.filter(r => 
        r.reason.message.includes('rate limit')
      );
      expect(rateLimitErrors.length).toBeGreaterThan(0);

      const duration = endTime - startTime;
      console.log(`Rate limiting test: ${successful.length}/${operationCount} succeeded in ${duration.toFixed(2)}ms`);
    });

    test('should recover from rate limiting efficiently', async () => {
      const phases = [
        { name: 'normal', remaining: 1000, resetTime: Date.now() / 1000 + 3600 },
        { name: 'limited', remaining: 0, resetTime: Date.now() / 1000 + 2 },
        { name: 'recovered', remaining: 1000, resetTime: Date.now() / 1000 + 3600 }
      ];

      let phaseIndex = 0;
      let callCount = 0;

      mockOctokit.rest.rateLimit.get.mockImplementation(() => {
        callCount++;
        
        // Transition phases based on call count
        if (callCount > 20 && phaseIndex === 0) phaseIndex = 1; // Hit rate limit
        if (callCount > 25 && phaseIndex === 1) phaseIndex = 2; // Recover
        
        return Promise.resolve({
          data: { rate: phases[phaseIndex] }
        });
      });

      // Mock setTimeout to simulate wait behavior
      const originalSetTimeout = global.setTimeout;
      const setTimeoutCalls = [];
      global.setTimeout = jest.fn((callback, delay) => {
        setTimeoutCalls.push(delay);
        // Simulate immediate resolution for testing
        process.nextTick(callback);
        return 123;
      });

      // Simulate operations that will hit rate limit
      const operationResults = [];
      
      for (let i = 0; i < 30; i++) {
        try {
          await client.waitIfRateLimited();
          operationResults.push({ success: true, phase: phaseIndex });
        } catch (error) {
          operationResults.push({ success: false, error: error.message });
        }
      }

      global.setTimeout = originalSetTimeout;

      // Should have triggered rate limit wait
      expect(setTimeoutCalls.length).toBeGreaterThan(0);
      
      // Should have detected and waited for rate limit recovery
      const waitTimes = setTimeoutCalls.filter(delay => delay > 1000);
      expect(waitTimes.length).toBeGreaterThan(0);

      console.log(`Rate limit recovery: ${setTimeoutCalls.length} waits, max delay: ${Math.max(...setTimeoutCalls)}ms`);
    });
  });

  describe('Memory and Resource Usage', () => {
    test('should handle large content without memory leaks', async () => {
      const initialMemory = process.memoryUsage();
      const largeContentTests = 1000;

      // Generate very large content
      const largeTitle = 'A'.repeat(10000);
      const largeBody = 'B'.repeat(100000);

      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 2000 } }
      });

      mockOctokit.rest.issues.create.mockImplementation(() => {
        return Promise.resolve({
          data: { 
            number: Math.floor(Math.random() * 1000),
            title: largeTitle,
            body: largeBody
          }
        });
      });

      // Process many large issues
      const promises = Array.from({ length: largeContentTests }, async (_, i) => {
        const title = `${largeTitle} ${i}`;
        const body = `${largeBody} ${i}`;
        
        const analysis = analyzeIssueContent(title, body);
        const issue = await client.createIssue('owner', 'repo', title, body);
        
        return { analysis, issue };
      });

      await Promise.all(promises);

      const finalMemory = process.memoryUsage();
      const memoryIncrease = finalMemory.heapUsed - initialMemory.heapUsed;
      const memoryIncreaseKB = memoryIncrease / 1024;

      // Memory increase should be reasonable (less than 100MB)
      expect(memoryIncreaseKB).toBeLessThan(100 * 1024);

      console.log(`Memory usage: ${memoryIncreaseKB.toFixed(2)}KB increase for ${largeContentTests} large issues`);

      // Force garbage collection if available
      if (global.gc) {
        global.gc();
        const afterGCMemory = process.memoryUsage();
        console.log(`After GC: ${(afterGCMemory.heapUsed / 1024).toFixed(2)}KB heap used`);
      }
    });

    test('should handle concurrent processing efficiently', async () => {
      const concurrencyLevels = [1, 5, 10, 25, 50, 100];
      const performanceData = {};

      for (const concurrency of concurrencyLevels) {
        const startTime = performance.now();
        const operationsPerLevel = 200;

        mockOctokit.rest.rateLimit.get.mockResolvedValue({
          data: { rate: { remaining: 1000 } }
        });

        mockOctokit.rest.issues.create.mockImplementation(() => {
          const delay = Math.random() * 10; // 0-10ms random delay
          return new Promise(resolve => {
            setTimeout(() => {
              resolve({
                data: { 
                  number: Math.floor(Math.random() * 1000),
                  title: 'Concurrency test',
                  body: 'Testing concurrent processing'
                }
              });
            }, delay);
          });
        });

        // Create batches of concurrent operations
        const batches = [];
        for (let i = 0; i < operationsPerLevel; i += concurrency) {
          const batchSize = Math.min(concurrency, operationsPerLevel - i);
          const batch = Array.from({ length: batchSize }, (_, j) => 
            client.createIssue('owner', 'repo', `Concurrency test ${i + j}`, 'Test body')
          );
          batches.push(Promise.all(batch));
        }

        await Promise.all(batches);
        const endTime = performance.now();

        performanceData[concurrency] = {
          duration: endTime - startTime,
          throughput: operationsPerLevel / ((endTime - startTime) / 1000)
        };
      }

      // Throughput should generally increase with concurrency (up to a point)
      expect(performanceData[5].throughput).toBeGreaterThan(performanceData[1].throughput);
      expect(performanceData[10].throughput).toBeGreaterThan(performanceData[5].throughput);

      console.log('Concurrency performance data:');
      Object.entries(performanceData).forEach(([level, data]) => {
        console.log(`  ${level} concurrent: ${data.throughput.toFixed(2)} ops/sec`);
      });
    });
  });

  describe('End-to-End Performance', () => {
    test('should complete complex workflows under load', async () => {
      const workflowCount = 50;
      const startTime = performance.now();

      // Setup comprehensive mocks
      mockOctokit.rest.rateLimit.get.mockResolvedValue({
        data: { rate: { remaining: 2000 } }
      });

      let issueCounter = 0;
      mockOctokit.rest.issues.create.mockImplementation(() => {
        issueCounter++;
        return Promise.resolve({
          data: { 
            number: issueCounter,
            title: 'Workflow test',
            body: 'Testing complete workflow'
          }
        });
      });

      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: [{ name: 'component:agent-spec-analyst', color: 'blue' }]
      });

      mockOctokit.rest.issues.createComment.mockResolvedValue({
        data: { id: 999, body: 'Workflow comment' }
      });

      mockOctokit.rest.issues.listMilestones.mockResolvedValue({
        data: [{ number: 1, title: 'Test Milestone', state: 'open' }]
      });

      mockOctokit.rest.issues.update.mockResolvedValue({
        data: { number: 1, milestone: { title: 'Test Milestone' } }
      });

      // Execute complete workflows
      const workflows = Array.from({ length: workflowCount }, async (_, i) => {
        const title = `Workflow ${i} with spec-analyst agent`;
        const body = `Critical issue ${i} requiring immediate attention`;

        // Step 1: Analyze content
        const analysis = analyzeIssueContent(title, body);

        // Step 2: Create issue
        const issue = await client.createIssue('owner', 'repo', title, body);

        // Step 3: Apply labels
        await client.addLabels('owner', 'repo', issue.number, analysis.labels);

        // Step 4: Add comment
        await client.createComment('owner', 'repo', issue.number, 'Auto-labeled issue');

        // Step 5: Assign milestone
        await client.assignToMilestone('owner', 'repo', issue.number, 'Test Milestone');

        return {
          workflowId: i,
          issue,
          analysis,
          completed: true
        };
      });

      const results = await Promise.all(workflows);
      const endTime = performance.now();
      const duration = endTime - startTime;

      // Performance assertions
      expect(results).toHaveLength(workflowCount);
      expect(results.every(r => r.completed)).toBe(true);
      
      expect(duration).toBeLessThan(15000); // Under 15 seconds
      
      const avgWorkflowTime = duration / workflowCount;
      expect(avgWorkflowTime).toBeLessThan(300); // Under 300ms per workflow

      console.log(`Complete workflow performance: ${workflowCount} workflows in ${duration.toFixed(2)}ms`);
      console.log(`Average workflow time: ${avgWorkflowTime.toFixed(2)}ms`);

      // Verify all components worked together
      const withAnalysis = results.filter(r => r.analysis.labels.length > 0);
      expect(withAnalysis.length).toBe(workflowCount);

      const withComponents = results.filter(r => 
        r.analysis.labels.some(l => l.startsWith('component:'))
      );
      expect(withComponents.length).toBe(workflowCount);
    });
  });
});