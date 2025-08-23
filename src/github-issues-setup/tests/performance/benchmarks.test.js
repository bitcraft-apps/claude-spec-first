/**
 * Benchmark Tests
 * Performance benchmarks for auto-labeling accuracy, API response times,
 * and memory usage validation
 */

const GitHubApiClient = require('../../utils/github-api');
const { analyzeIssueContent, testAccuracy } = require('../../utils/auto-labeling');
const { Octokit } = require('@octokit/rest');

// Mock the Octokit library
jest.mock('@octokit/rest');

// Increase timeout for benchmark tests
jest.setTimeout(60000);

describe('Performance Benchmarks', () => {
  let mockOctokit;
  let client;

  beforeEach(() => {
    jest.clearAllMocks();
    
    mockOctokit = {
      rest: {
        rateLimit: {
          get: jest.fn().mockResolvedValue({
            data: { rate: { remaining: 5000, reset: Date.now() / 1000 + 3600 } }
          })
        },
        issues: {
          create: jest.fn(),
          addLabels: jest.fn(),
          createComment: jest.fn(),
          get: jest.fn()
        }
      }
    };

    Octokit.mockImplementation(() => mockOctokit);
    client = new GitHubApiClient('benchmark_token');
  });

  describe('Auto-Labeling Performance Benchmarks', () => {
    test('should meet accuracy requirements (>85%) at scale', async () => {
      const accuracyTestSuite = [
        // Component detection tests
        { content: 'spec-analyst agent broken', expected: ['component:agent-spec-analyst'] },
        { content: 'test-designer not generating tests', expected: ['component:agent-test-designer'] },
        { content: 'impl-specialist crashes', expected: ['component:agent-impl-specialist'] },
        { content: 'qa-validator fails', expected: ['component:agent-qa-validator'] },
        { content: 'arch-designer issues', expected: ['component:agent-arch-designer'] },
        
        // File path detection tests
        { content: 'scripts/install.sh permission error', expected: ['component:installation'] },
        { content: 'framework/validate-framework.sh fails', expected: ['component:validation'] },
        { content: 'README.md needs update', expected: ['component:docs'] },
        
        // Command detection tests
        { content: '/spec-init command not working', expected: ['component:command-spec-init'] },
        { content: '/qa-check produces errors', expected: ['component:command-qa-check'] },
        { content: 'spec-review fails', expected: ['component:command-spec-review'] },
        { content: '/impl-plan command broken', expected: ['component:command-impl-plan'] },
        { content: '/spec-workflow automation fails', expected: ['component:command-spec-workflow'] },
        
        // Priority detection tests
        { content: 'Critical system failure', expected: ['priority:critical'] },
        { content: 'Urgent fix needed', expected: ['priority:critical'] },
        { content: 'Breaking change detected', expected: ['priority:critical'] },
        { content: 'Important feature request', expected: ['priority:high'] },
        { content: 'Significantly affects productivity', expected: ['priority:high'] },
        { content: 'Blocking current sprint', expected: ['priority:high'] },
        { content: 'Nice to have feature', expected: ['priority:low'] },
        { content: 'Minor cosmetic improvement', expected: ['priority:low'] },
        { content: 'Trivial documentation fix', expected: ['priority:low'] },
        
        // Security detection tests
        { content: 'Security vulnerability found', expected: ['type:security', 'priority:high'] },
        { content: 'XSS attack possible', expected: ['type:security', 'priority:high'] },
        { content: 'SQL injection detected', expected: ['type:security', 'priority:high'] },
        { content: 'Credentials exposed', expected: ['type:security', 'priority:high'] },
        { content: 'CVE-2024-1234 affects system', expected: ['type:security', 'priority:high'] },
        
        // Complex multi-label tests
        { content: 'Critical spec-analyst security issue', expected: ['component:agent-spec-analyst', 'priority:critical', 'type:security'] },
        { content: 'Important test-designer enhancement', expected: ['component:agent-test-designer', 'priority:high'] },
        { content: 'Minor documentation update needed', expected: ['component:docs', 'priority:low'] },
        { content: 'Installation script security vulnerability', expected: ['component:installation', 'type:security', 'priority:high'] }
      ];

      const iterations = 100; // Test each case 100 times
      const startTime = performance.now();
      
      // Run comprehensive accuracy test
      const allTestCases = [];
      for (let i = 0; i < iterations; i++) {
        allTestCases.push(...accuracyTestSuite);
      }

      const results = testAccuracy(allTestCases);
      const endTime = performance.now();
      const duration = endTime - startTime;

      // Accuracy requirements
      expect(results.accuracy).toBeGreaterThan(0.85);
      expect(results.totalTests).toBe(accuracyTestSuite.length * iterations);
      expect(results.correctPredictions).toBeGreaterThan(results.totalTests * 0.85);

      // Performance requirements
      const avgTimePerTest = duration / results.totalTests;
      expect(avgTimePerTest).toBeLessThan(1); // Under 1ms per analysis
      expect(duration).toBeLessThan(10000); // Complete in under 10 seconds

      console.log(`Accuracy Benchmark Results:`);
      console.log(`  Accuracy: ${(results.accuracy * 100).toFixed(2)}%`);
      console.log(`  Total Tests: ${results.totalTests}`);
      console.log(`  Correct Predictions: ${results.correctPredictions}`);
      console.log(`  Duration: ${duration.toFixed(2)}ms`);
      console.log(`  Average Time per Test: ${avgTimePerTest.toFixed(3)}ms`);
    });

    test('should maintain performance with varying content sizes', () => {
      const contentSizes = [
        { name: 'tiny', length: 10 },
        { name: 'small', length: 100 },
        { name: 'medium', length: 1000 },
        { name: 'large', length: 10000 },
        { name: 'huge', length: 100000 }
      ];

      const benchmarkResults = {};

      for (const size of contentSizes) {
        const testContent = `spec-analyst issue ${'A'.repeat(size.length)}`;
        const iterations = 1000;
        
        const startTime = performance.now();
        
        for (let i = 0; i < iterations; i++) {
          analyzeIssueContent(testContent, 'Additional context');
        }
        
        const endTime = performance.now();
        const duration = endTime - startTime;
        
        benchmarkResults[size.name] = {
          length: size.length,
          duration,
          avgTime: duration / iterations,
          throughput: iterations / (duration / 1000)
        };
      }

      // Performance should degrade gracefully with size
      expect(benchmarkResults.tiny.avgTime).toBeLessThan(0.1); // <0.1ms
      expect(benchmarkResults.small.avgTime).toBeLessThan(0.5); // <0.5ms
      expect(benchmarkResults.medium.avgTime).toBeLessThan(2); // <2ms
      expect(benchmarkResults.large.avgTime).toBeLessThan(10); // <10ms
      expect(benchmarkResults.huge.avgTime).toBeLessThan(50); // <50ms

      console.log('Content Size Performance Benchmark:');
      Object.entries(benchmarkResults).forEach(([size, data]) => {
        console.log(`  ${size} (${data.length} chars): ${data.avgTime.toFixed(3)}ms avg, ${data.throughput.toFixed(0)} ops/sec`);
      });
    });

    test('should handle edge cases efficiently', () => {
      const edgeCases = [
        { name: 'empty', title: '', body: '' },
        { name: 'null', title: null, body: null },
        { name: 'undefined', title: undefined, body: undefined },
        { name: 'whitespace', title: '   \n\t\r   ', body: '   \n\t\r   ' },
        { name: 'unicode', title: '🚀 émojis and spëcial chars', body: 'Unicode test αβγδε' },
        { name: 'html', title: '<script>alert("xss")</script>', body: '<img src="x" onerror="alert()">' },
        { name: 'mixed', title: 'spec-analyst\x00null\xFF\xFE', body: 'Mixed content\r\n\t' },
        { name: 'repeated', title: 'spec-analyst '.repeat(1000), body: 'repeated content '.repeat(1000) }
      ];

      const edgeResults = {};
      
      for (const edgeCase of edgeCases) {
        const iterations = 100;
        const startTime = performance.now();
        
        let allSuccessful = true;
        for (let i = 0; i < iterations; i++) {
          try {
            const result = analyzeIssueContent(edgeCase.title, edgeCase.body);
            if (!result || !result.labels || !result.analysis) {
              allSuccessful = false;
            }
          } catch (error) {
            allSuccessful = false;
          }
        }
        
        const endTime = performance.now();
        const duration = endTime - startTime;
        
        edgeResults[edgeCase.name] = {
          successful: allSuccessful,
          duration,
          avgTime: duration / iterations
        };
      }

      // All edge cases should be handled successfully
      Object.entries(edgeResults).forEach(([caseName, result]) => {
        expect(result.successful).toBe(true);
        expect(result.avgTime).toBeLessThan(10); // <10ms even for edge cases
      });

      console.log('Edge Case Performance Benchmark:');
      Object.entries(edgeResults).forEach(([caseName, data]) => {
        console.log(`  ${caseName}: ${data.avgTime.toFixed(3)}ms avg, ${data.successful ? 'OK' : 'FAILED'}`);
      });
    });
  });

  describe('API Client Performance Benchmarks', () => {
    test('should meet API response time requirements', async () => {
      const operationBenchmarks = {};
      const iterations = 100;

      // Benchmark different API operations
      const operations = [
        {
          name: 'createIssue',
          setup: () => {
            mockOctokit.rest.issues.create.mockResolvedValue({
              data: { number: 123, title: 'Test', body: 'Body' }
            });
          },
          operation: () => client.createIssue('owner', 'repo', 'Test Issue', 'Test Body')
        },
        {
          name: 'addLabels',
          setup: () => {
            mockOctokit.rest.issues.addLabels.mockResolvedValue({
              data: [{ name: 'label1' }, { name: 'label2' }]
            });
          },
          operation: () => client.addLabels('owner', 'repo', 123, ['label1', 'label2'])
        },
        {
          name: 'createComment',
          setup: () => {
            mockOctokit.rest.issues.createComment.mockResolvedValue({
              data: { id: 456, body: 'Comment' }
            });
          },
          operation: () => client.createComment('owner', 'repo', 123, 'Test Comment')
        },
        {
          name: 'getIssue',
          setup: () => {
            mockOctokit.rest.issues.get.mockResolvedValue({
              data: { number: 123, title: 'Test' }
            });
          },
          operation: () => client.getIssue('owner', 'repo', 123)
        }
      ];

      for (const op of operations) {
        op.setup();
        
        const startTime = performance.now();
        
        const promises = Array.from({ length: iterations }, () => op.operation());
        await Promise.all(promises);
        
        const endTime = performance.now();
        const duration = endTime - startTime;
        
        operationBenchmarks[op.name] = {
          duration,
          avgTime: duration / iterations,
          throughput: iterations / (duration / 1000)
        };
      }

      // Performance requirements
      expect(operationBenchmarks.createIssue.avgTime).toBeLessThan(50); // <50ms
      expect(operationBenchmarks.addLabels.avgTime).toBeLessThan(30); // <30ms
      expect(operationBenchmarks.createComment.avgTime).toBeLessThan(30); // <30ms
      expect(operationBenchmarks.getIssue.avgTime).toBeLessThan(20); // <20ms

      console.log('API Operation Performance Benchmark:');
      Object.entries(operationBenchmarks).forEach(([operation, data]) => {
        console.log(`  ${operation}: ${data.avgTime.toFixed(2)}ms avg, ${data.throughput.toFixed(0)} ops/sec`);
      });
    });

    test('should handle concurrent operations efficiently', async () => {
      const concurrencyLevels = [1, 5, 10, 25, 50];
      const concurrencyResults = {};

      mockOctokit.rest.issues.create.mockImplementation(() => {
        const delay = Math.random() * 20 + 5; // 5-25ms random delay
        return new Promise(resolve => {
          setTimeout(() => {
            resolve({
              data: { 
                number: Math.floor(Math.random() * 1000),
                title: 'Concurrent test'
              }
            });
          }, delay);
        });
      });

      for (const concurrency of concurrencyLevels) {
        const totalOperations = 200;
        const startTime = performance.now();
        
        // Create batches of concurrent operations
        const batches = [];
        for (let i = 0; i < totalOperations; i += concurrency) {
          const batchSize = Math.min(concurrency, totalOperations - i);
          const batch = Array.from({ length: batchSize }, () => 
            client.createIssue('owner', 'repo', 'Concurrent Test', 'Testing concurrency')
          );
          batches.push(Promise.all(batch));
        }

        await Promise.all(batches);
        
        const endTime = performance.now();
        const duration = endTime - startTime;
        
        concurrencyResults[concurrency] = {
          duration,
          throughput: totalOperations / (duration / 1000),
          avgLatency: duration / totalOperations
        };
      }

      // Throughput should improve with reasonable concurrency
      expect(concurrencyResults[5].throughput).toBeGreaterThan(concurrencyResults[1].throughput);
      expect(concurrencyResults[10].throughput).toBeGreaterThan(concurrencyResults[5].throughput);

      console.log('Concurrency Performance Benchmark:');
      Object.entries(concurrencyResults).forEach(([level, data]) => {
        console.log(`  ${level} concurrent: ${data.throughput.toFixed(1)} ops/sec, ${data.avgLatency.toFixed(2)}ms latency`);
      });
    });

    test('should maintain performance under rate limiting pressure', async () => {
      const rateLimitScenarios = [
        { name: 'generous', remaining: 1000, resetTime: Date.now() / 1000 + 3600 },
        { name: 'moderate', remaining: 100, resetTime: Date.now() / 1000 + 1800 },
        { name: 'limited', remaining: 10, resetTime: Date.now() / 1000 + 600 },
        { name: 'critical', remaining: 2, resetTime: Date.now() / 1000 + 300 }
      ];

      const rateLimitResults = {};

      for (const scenario of rateLimitScenarios) {
        mockOctokit.rest.rateLimit.get.mockResolvedValue({
          data: { rate: scenario }
        });

        mockOctokit.rest.issues.create.mockResolvedValue({
          data: { number: 123, title: 'Rate limit test' }
        });

        // Mock setTimeout for rate limit waits
        const setTimeoutSpy = jest.spyOn(global, 'setTimeout').mockImplementation((callback) => {
          process.nextTick(callback); // Execute immediately for testing
          return 123;
        });

        const operations = 20;
        const startTime = performance.now();
        
        const promises = Array.from({ length: operations }, () => 
          client.createIssue('owner', 'repo', 'Rate Limit Test', 'Testing rate limiting')
        );
        
        await Promise.all(promises);
        
        const endTime = performance.now();
        const duration = endTime - startTime;
        
        rateLimitResults[scenario.name] = {
          duration,
          avgTime: duration / operations,
          waitCalls: setTimeoutSpy.mock.calls.length
        };

        setTimeoutSpy.mockRestore();
      }

      // Should handle all scenarios gracefully
      Object.values(rateLimitResults).forEach(result => {
        expect(result.avgTime).toBeLessThan(1000); // <1s per operation even under pressure
      });

      console.log('Rate Limiting Performance Benchmark:');
      Object.entries(rateLimitResults).forEach(([scenario, data]) => {
        console.log(`  ${scenario}: ${data.avgTime.toFixed(2)}ms avg, ${data.waitCalls} waits`);
      });
    });
  });

  describe('Memory Usage Benchmarks', () => {
    test('should maintain reasonable memory usage under load', async () => {
      const initialMemory = process.memoryUsage();
      const operationCount = 1000;
      
      // Setup consistent API responses
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { number: 123, title: 'Memory test', body: 'Testing memory usage' }
      });

      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: [{ name: 'test-label' }]
      });

      // Perform memory-intensive operations
      const operations = [];
      
      for (let i = 0; i < operationCount; i++) {
        const title = `Memory test issue ${i} with spec-analyst agent`;
        const body = `Issue ${i} testing memory usage under load with additional content`.repeat(10);
        
        // Auto-labeling analysis (creates objects)
        const analysis = analyzeIssueContent(title, body);
        
        // API operations (creates promises and responses)
        const issuePromise = client.createIssue('owner', 'repo', title, body);
        const labelPromise = issuePromise.then(() => 
          client.addLabels('owner', 'repo', 123, analysis.labels)
        );
        
        operations.push(labelPromise);
        
        // Check memory every 100 operations
        if (i % 100 === 0) {
          const currentMemory = process.memoryUsage();
          const memoryIncrease = (currentMemory.heapUsed - initialMemory.heapUsed) / 1024 / 1024;
          
          // Memory should not grow excessively (less than 1MB per 100 operations)
          expect(memoryIncrease).toBeLessThan((i / 100 + 1) * 1);
        }
      }

      await Promise.all(operations);

      const finalMemory = process.memoryUsage();
      const totalMemoryIncrease = (finalMemory.heapUsed - initialMemory.heapUsed) / 1024 / 1024;
      
      // Total memory increase should be reasonable
      expect(totalMemoryIncrease).toBeLessThan(50); // Less than 50MB for 1000 operations

      console.log(`Memory Usage Benchmark:`);
      console.log(`  Operations: ${operationCount}`);
      console.log(`  Initial Memory: ${(initialMemory.heapUsed / 1024 / 1024).toFixed(2)}MB`);
      console.log(`  Final Memory: ${(finalMemory.heapUsed / 1024 / 1024).toFixed(2)}MB`);
      console.log(`  Memory Increase: ${totalMemoryIncrease.toFixed(2)}MB`);
      console.log(`  Memory per Operation: ${(totalMemoryIncrease / operationCount * 1024).toFixed(2)}KB`);
    });

    test('should handle garbage collection efficiently', async () => {
      if (!global.gc) {
        console.log('Skipping GC test - garbage collection not available');
        return;
      }

      const gcBenchmark = {};
      const iterations = [100, 500, 1000, 2000];

      for (const iterationCount of iterations) {
        // Force GC before test
        global.gc();
        const preGCMemory = process.memoryUsage();

        // Perform operations that create garbage
        const operations = [];
        for (let i = 0; i < iterationCount; i++) {
          const largeContent = 'A'.repeat(1000);
          const analysis = analyzeIssueContent(`spec-analyst ${largeContent}`, `body ${largeContent}`);
          operations.push(analysis);
          
          // Create temporary objects that should be collected
          const tempData = {
            id: i,
            content: largeContent,
            analysis: analysis,
            timestamp: Date.now(),
            metadata: { processed: true, iteration: i }
          };
        }

        const beforeGCMemory = process.memoryUsage();
        
        // Force garbage collection
        global.gc();
        
        const afterGCMemory = process.memoryUsage();
        
        gcBenchmark[iterationCount] = {
          beforeGC: beforeGCMemory.heapUsed / 1024 / 1024,
          afterGC: afterGCMemory.heapUsed / 1024 / 1024,
          collected: (beforeGCMemory.heapUsed - afterGCMemory.heapUsed) / 1024 / 1024,
          efficiency: (beforeGCMemory.heapUsed - afterGCMemory.heapUsed) / beforeGCMemory.heapUsed
        };
      }

      // GC should be collecting garbage efficiently
      Object.values(gcBenchmark).forEach(result => {
        expect(result.collected).toBeGreaterThan(0); // Should collect some memory
        expect(result.efficiency).toBeGreaterThan(0.1); // Should collect at least 10%
      });

      console.log('Garbage Collection Benchmark:');
      Object.entries(gcBenchmark).forEach(([iterations, data]) => {
        console.log(`  ${iterations} operations: ${data.collected.toFixed(2)}MB collected (${(data.efficiency*100).toFixed(1)}% efficiency)`);
      });
    });
  });

  describe('Scalability Benchmarks', () => {
    test('should scale linearly with input size', () => {
      const scalabilityData = {};
      const inputSizes = [10, 50, 100, 500, 1000, 5000];

      for (const size of inputSizes) {
        const startTime = performance.now();
        
        // Process batch of issues
        for (let i = 0; i < size; i++) {
          const title = `Scalability test ${i} with spec-analyst`;
          const body = `Issue ${i} for scalability testing`;
          analyzeIssueContent(title, body);
        }
        
        const endTime = performance.now();
        const duration = endTime - startTime;
        
        scalabilityData[size] = {
          duration,
          avgTime: duration / size,
          throughput: size / (duration / 1000)
        };
      }

      // Performance should scale reasonably
      const baselineAvgTime = scalabilityData[10].avgTime;
      
      // Average time shouldn't increase dramatically with scale
      expect(scalabilityData[100].avgTime).toBeLessThan(baselineAvgTime * 2);
      expect(scalabilityData[1000].avgTime).toBeLessThan(baselineAvgTime * 5);
      expect(scalabilityData[5000].avgTime).toBeLessThan(baselineAvgTime * 10);

      console.log('Scalability Benchmark:');
      Object.entries(scalabilityData).forEach(([size, data]) => {
        console.log(`  ${size} issues: ${data.avgTime.toFixed(3)}ms avg, ${data.throughput.toFixed(0)} ops/sec`);
      });
    });

    test('should maintain quality under scale', () => {
      const qualityBenchmark = {};
      const scaleFactors = [1, 10, 100, 500];
      
      const baseTestCases = [
        { content: 'spec-analyst broken', expected: ['component:agent-spec-analyst'] },
        { content: 'Critical security issue', expected: ['priority:critical'] },
        { content: 'scripts/install.sh fails', expected: ['component:installation'] },
        { content: 'Important feature request', expected: ['priority:high'] }
      ];

      for (const scaleFactor of scaleFactors) {
        const testCases = [];
        
        // Multiply test cases by scale factor
        for (let i = 0; i < scaleFactor; i++) {
          testCases.push(...baseTestCases);
        }
        
        const startTime = performance.now();
        const results = testAccuracy(testCases);
        const endTime = performance.now();
        
        qualityBenchmark[scaleFactor] = {
          accuracy: results.accuracy,
          totalTests: results.totalTests,
          duration: endTime - startTime,
          avgTime: (endTime - startTime) / results.totalTests
        };
      }

      // Quality should remain consistent across scales
      const baselineAccuracy = qualityBenchmark[1].accuracy;
      
      Object.values(qualityBenchmark).forEach(result => {
        expect(result.accuracy).toBeGreaterThan(0.85); // Minimum accuracy requirement
        expect(Math.abs(result.accuracy - baselineAccuracy)).toBeLessThan(0.05); // Within 5% of baseline
      });

      console.log('Quality at Scale Benchmark:');
      Object.entries(qualityBenchmark).forEach(([scale, data]) => {
        console.log(`  ${scale}x scale: ${(data.accuracy*100).toFixed(1)}% accuracy, ${data.avgTime.toFixed(3)}ms avg`);
      });
    });
  });

  describe('Production Readiness Benchmarks', () => {
    test('should meet all production performance requirements', async () => {
      const productionBenchmarks = {
        autoLabelingSpeed: { requirement: 'Under 10ms per analysis', target: 10 },
        apiResponseTime: { requirement: 'Under 100ms per API call', target: 100 },
        accuracyRate: { requirement: 'Over 85% accuracy', target: 0.85 },
        concurrentOperations: { requirement: 'Handle 100 concurrent ops', target: 100 },
        memoryUsage: { requirement: 'Under 100MB for 1000 operations', target: 100 },
        errorRate: { requirement: 'Under 1% error rate', target: 0.01 }
      };

      const results = {};

      // Test auto-labeling speed
      const labelingStart = performance.now();
      for (let i = 0; i < 1000; i++) {
        analyzeIssueContent('spec-analyst issue', 'test content');
      }
      const labelingEnd = performance.now();
      results.autoLabelingSpeed = (labelingEnd - labelingStart) / 1000;

      // Test API response time
      mockOctokit.rest.issues.create.mockImplementation(() => {
        const delay = Math.random() * 50; // 0-50ms delay
        return new Promise(resolve => {
          setTimeout(() => {
            resolve({ data: { number: 123, title: 'Test' } });
          }, delay);
        });
      });

      const apiStart = performance.now();
      const apiPromises = Array.from({ length: 100 }, () => 
        client.createIssue('owner', 'repo', 'API Test', 'Testing API speed')
      );
      await Promise.all(apiPromises);
      const apiEnd = performance.now();
      results.apiResponseTime = (apiEnd - apiStart) / 100;

      // Test accuracy rate
      const accuracyTestCases = [
        { content: 'spec-analyst broken', expected: ['component:agent-spec-analyst'] },
        { content: 'Critical issue', expected: ['priority:critical'] },
        { content: 'Security vulnerability', expected: ['type:security', 'priority:high'] }
      ];
      const accuracyResults = testAccuracy(Array(100).fill(accuracyTestCases).flat());
      results.accuracyRate = accuracyResults.accuracy;

      // Test concurrent operations
      const concurrentStart = performance.now();
      const concurrentPromises = Array.from({ length: 100 }, () => 
        Promise.resolve(analyzeIssueContent('concurrent test', 'testing concurrency'))
      );
      await Promise.all(concurrentPromises);
      const concurrentEnd = performance.now();
      results.concurrentOperations = concurrentEnd - concurrentStart < 1000 ? 100 : 0;

      // Test memory usage
      const initialMem = process.memoryUsage().heapUsed;
      for (let i = 0; i < 1000; i++) {
        analyzeIssueContent(`memory test ${i}`, `content ${i}`);
      }
      const finalMem = process.memoryUsage().heapUsed;
      results.memoryUsage = (finalMem - initialMem) / 1024 / 1024;

      // Test error rate
      let errors = 0;
      const errorTests = 1000;
      for (let i = 0; i < errorTests; i++) {
        try {
          analyzeIssueContent(i % 10 === 0 ? null : 'test', i % 7 === 0 ? undefined : 'content');
        } catch (error) {
          errors++;
        }
      }
      results.errorRate = errors / errorTests;

      // Validate all requirements
      expect(results.autoLabelingSpeed).toBeLessThan(productionBenchmarks.autoLabelingSpeed.target);
      expect(results.apiResponseTime).toBeLessThan(productionBenchmarks.apiResponseTime.target);
      expect(results.accuracyRate).toBeGreaterThan(productionBenchmarks.accuracyRate.target);
      expect(results.concurrentOperations).toBeGreaterThanOrEqual(productionBenchmarks.concurrentOperations.target);
      expect(results.memoryUsage).toBeLessThan(productionBenchmarks.memoryUsage.target);
      expect(results.errorRate).toBeLessThan(productionBenchmarks.errorRate.target);

      console.log('Production Readiness Benchmark Results:');
      console.log(`  Auto-labeling Speed: ${results.autoLabelingSpeed.toFixed(3)}ms (target: <${productionBenchmarks.autoLabelingSpeed.target}ms)`);
      console.log(`  API Response Time: ${results.apiResponseTime.toFixed(2)}ms (target: <${productionBenchmarks.apiResponseTime.target}ms)`);
      console.log(`  Accuracy Rate: ${(results.accuracyRate*100).toFixed(1)}% (target: >${productionBenchmarks.accuracyRate.target*100}%)`);
      console.log(`  Concurrent Operations: ${results.concurrentOperations} (target: >=${productionBenchmarks.concurrentOperations.target})`);
      console.log(`  Memory Usage: ${results.memoryUsage.toFixed(2)}MB (target: <${productionBenchmarks.memoryUsage.target}MB)`);
      console.log(`  Error Rate: ${(results.errorRate*100).toFixed(2)}% (target: <${productionBenchmarks.errorRate.target*100}%)`);

      // Overall production readiness assessment
      const allPassed = Object.entries(results).every(([key, value]) => {
        const benchmark = productionBenchmarks[key];
        if (key === 'accuracyRate' || key === 'concurrentOperations') {
          return value >= benchmark.target;
        } else {
          return value < benchmark.target;
        }
      });

      expect(allPassed).toBe(true);
      console.log(`\n🎯 Production Readiness: ${allPassed ? 'PASS' : 'FAIL'}`);
    });
  });
});