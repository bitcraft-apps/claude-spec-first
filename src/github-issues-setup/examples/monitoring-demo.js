#!/usr/bin/env node

/**
 * GitHub Issues Setup - Monitoring System Demo
 * Demonstrates the monitoring and observability features
 */

const MonitoringSystem = require('../monitoring');
const { analyzeIssueContent } = require('../utils/auto-labeling');
const GitHubApiClient = require('../utils/github-api');

async function demonstrateMonitoring() {
  console.log('🚀 GitHub Issues Setup - Monitoring System Demo');
  console.log('=' .repeat(60));

  // Check for GitHub token
  const githubToken = process.env.GITHUB_TOKEN;
  if (!githubToken) {
    console.log('⚠️  No GITHUB_TOKEN environment variable found');
    console.log('   Some features will be limited without API access');
    console.log('   Set GITHUB_TOKEN=your_token to enable full demo\n');
  }

  try {
    // 1. Initialize monitoring system
    console.log('📊 Initializing monitoring system...');
    const monitoring = new MonitoringSystem({
      healthCheckInterval: 10000, // 10 seconds for demo
      enableDashboard: true,
      debug: true
    });

    // 2. Test auto-labeling system
    console.log('\n🏷️  Testing auto-labeling system...');
    const testCases = [
      {
        title: 'Critical bug in spec-analyst',
        body: 'The framework/agents/spec-analyst.md file has a critical security vulnerability that needs immediate attention.'
      },
      {
        title: 'Installation script fails',
        body: 'The install.sh script is not working on Ubuntu 22.04. This is affecting many users.'
      },
      {
        title: 'Documentation update needed',
        body: 'The README.md file needs to be updated with the latest API changes.'
      }
    ];

    for (const testCase of testCases) {
      const startTime = Date.now();
      const analysis = analyzeIssueContent(testCase.title, testCase.body);
      const processingTime = Date.now() - startTime;

      console.log(`\n  📋 Issue: "${testCase.title}"`);
      console.log(`     Labels: ${analysis.labels.join(', ')}`);
      console.log(`     Confidence: ${(analysis.confidence * 100).toFixed(1)}%`);
      console.log(`     Processing time: ${processingTime}ms`);

      // Track the labeling event
      monitoring.trackAutoLabeling({
        issueId: `demo-${Date.now()}`,
        accuracy: Math.random() > 0.2 ? 0.9 : 0.7, // Simulate mostly good accuracy
        confidence: analysis.confidence,
        processingTime,
        labelsApplied: analysis.labels,
        componentsDetected: analysis.analysis.components,
        priorityDetected: analysis.analysis.priority,
        securityDetected: analysis.analysis.security
      });
    }

    // 3. Test GitHub API (if token available)
    if (githubToken) {
      console.log('\n🔗 Testing GitHub API client...');
      const apiClient = new GitHubApiClient(githubToken);
      
      try {
        const startTime = Date.now();
        const user = await apiClient.getAuthenticatedUser();
        const responseTime = Date.now() - startTime;

        console.log(`     ✅ Authenticated as: ${user.login}`);
        console.log(`     Response time: ${responseTime}ms`);

        // Track API usage
        monitoring.trackApiUsage({
          endpoint: '/user',
          method: 'GET',
          responseTime,
          statusCode: 200,
          success: true
        });

        // Check rate limits
        const rateLimit = await apiClient.checkRateLimit();
        console.log(`     Rate limit: ${rateLimit.remaining}/${rateLimit.limit} remaining`);

      } catch (error) {
        console.log(`     ❌ API test failed: ${error.message}`);
        monitoring.trackApiUsage({
          endpoint: '/user',
          responseTime: 0,
          statusCode: error.status || 0,
          success: false,
          errorType: error.message
        });
      }
    }

    // 4. Start monitoring system
    console.log('\n⚡ Starting monitoring system...');
    await monitoring.start(githubToken);

    // 5. Generate some test metrics
    console.log('\n📈 Generating test metrics...');
    
    // Simulate some performance events
    for (let i = 0; i < 5; i++) {
      monitoring.trackPerformance({
        operation: 'demo_operation',
        duration: Math.floor(Math.random() * 1000) + 100,
        success: Math.random() > 0.1 // 90% success rate
      });
    }

    // Simulate some errors
    monitoring.trackError({
      component: 'demo',
      errorType: 'test_error',
      errorMessage: 'This is a demo error for testing purposes',
      severity: 'warning'
    });

    // 6. Wait a moment for data collection
    console.log('\n⏳ Collecting metrics data...');
    await new Promise(resolve => setTimeout(resolve, 2000));

    // 7. Show system status
    console.log('\n📊 Current system status:');
    const status = await monitoring.getStatus(githubToken);
    
    console.log(`     Overall health: ${status.health.overall}`);
    console.log(`     Components checked: ${Object.keys(status.health.components || {}).length}`);
    console.log(`     Active alerts: ${status.alerts.active.length}`);
    console.log(`     System uptime: ${Math.floor(status.uptime / 1000)}s`);

    // 8. Generate dashboard
    console.log('\n📋 Generating dashboard...');
    
    // Text summary for console
    const textDashboard = await monitoring.getDashboard(githubToken, 'text');
    console.log('\n' + '─'.repeat(60));
    console.log(textDashboard);
    console.log('─'.repeat(60));

    // 9. Show metrics summary
    console.log('\n📊 Metrics summary:');
    const metricsData = monitoring.metricsCollector.getSystemSummary();
    
    if (metricsData.autoLabeling.totalEvents > 0) {
      console.log(`     Auto-labeling events: ${metricsData.autoLabeling.totalEvents}`);
      console.log(`     Average accuracy: ${(metricsData.autoLabeling.averageAccuracy * 100).toFixed(1)}%`);
      console.log(`     Average processing time: ${metricsData.autoLabeling.averageProcessingTime.toFixed(0)}ms`);
    }

    if (metricsData.apiUsage.totalRequests > 0) {
      console.log(`     API requests: ${metricsData.apiUsage.totalRequests}`);
      console.log(`     API success rate: ${(metricsData.apiUsage.successRate * 100).toFixed(1)}%`);
    }

    if (metricsData.performance.totalOperations > 0) {
      console.log(`     Performance events: ${metricsData.performance.totalOperations}`);
      console.log(`     Average duration: ${metricsData.performance.averageDuration.toFixed(0)}ms`);
    }

    // 10. Export data example
    console.log('\n💾 Data export example:');
    const exportData = monitoring.exportMonitoringData();
    console.log(`     Total events collected: ${Object.values(exportData.autoLabeling).flat().length + Object.values(exportData.performance).flat().length}`);
    console.log(`     Data size: ${JSON.stringify(exportData).length} bytes`);

    // 11. Test alerting (optional)
    if (process.argv.includes('--test-alerts')) {
      console.log('\n🚨 Testing alerting system...');
      monitoring.alertingSystem.testAlerts();
      
      // Wait to see alert
      await new Promise(resolve => setTimeout(resolve, 1000));
      const alerts = monitoring.alertingSystem.getActiveAlerts();
      console.log(`     Generated ${alerts.length} test alert(s)`);
    }

    // 12. Cleanup
    console.log('\n🛑 Stopping monitoring system...');
    await monitoring.stop();

    console.log('\n✅ Demo completed successfully!');
    console.log('\nTo run the monitoring system in production:');
    console.log('   npm run start:monitoring');
    console.log('\nTo view the dashboard:');
    console.log('   npm run dashboard');
    console.log('\nTo check system health:');
    console.log('   npm run health-check');

    if (!githubToken) {
      console.log('\n💡 Pro tip: Set GITHUB_TOKEN environment variable for full API testing');
    }

  } catch (error) {
    console.error('\n❌ Demo failed:', error.message);
    if (error.stack) {
      console.error('Stack trace:', error.stack);
    }
    process.exit(1);
  }
}

// Handle cleanup on exit
process.on('SIGINT', () => {
  console.log('\n\n👋 Demo interrupted by user');
  process.exit(0);
});

// Run the demo
if (require.main === module) {
  demonstrateMonitoring().catch(error => {
    console.error('Demo failed:', error);
    process.exit(1);
  });
}

module.exports = { demonstrateMonitoring };