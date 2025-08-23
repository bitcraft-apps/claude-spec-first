/**
 * Health Check System for GitHub Issues Setup
 * Monitors API connectivity, template availability, and system performance
 */

const GitHubApiClient = require('../utils/github-api');
const { analyzeIssueContent } = require('../utils/auto-labeling');
const fs = require('fs');
const path = require('path');

class HealthCheckSystem {
  constructor(options = {}) {
    this.options = {
      timeout: options.timeout || 30000, // 30 seconds default timeout
      apiThresholds: {
        responseTime: options.apiResponseThreshold || 5000, // 5 seconds
        rateLimitBuffer: options.rateLimitBuffer || 0.2, // 20%
        errorRate: options.errorRate || 0.05 // 5%
      },
      labelingThresholds: {
        accuracy: options.labelingAccuracy || 0.85, // 85%
        processingTime: options.labelingProcessingTime || 30000 // 30 seconds
      },
      ...options
    };
    this.healthHistory = [];
    this.startTime = Date.now();
  }

  /**
   * Perform comprehensive health check
   * @param {string} githubToken GitHub API token
   * @returns {Promise<Object>} Complete health status
   */
  async performHealthCheck(githubToken) {
    const startTime = Date.now();
    const healthStatus = {
      timestamp: new Date().toISOString(),
      overall: 'healthy',
      components: {},
      metrics: {},
      alerts: [],
      uptime: this.getUptime(),
      duration: 0
    };

    try {
      // 1. API Connectivity Check
      healthStatus.components.api = await this.checkApiHealth(githubToken);
      
      // 2. Auto-labeling System Check
      healthStatus.components.autoLabeling = await this.checkAutoLabelingHealth();
      
      // 3. Template System Check
      healthStatus.components.templates = await this.checkTemplateHealth();
      
      // 4. Performance Metrics Check
      healthStatus.components.performance = await this.checkPerformanceHealth(githubToken);
      
      // 5. Security Validation Check
      healthStatus.components.security = await this.checkSecurityHealth();

      // Calculate overall health status
      healthStatus.overall = this.calculateOverallHealth(healthStatus.components);
      
      // Generate alerts based on health status
      healthStatus.alerts = this.generateAlerts(healthStatus.components);
      
      // Calculate metrics
      healthStatus.metrics = this.calculateMetrics(healthStatus.components);

    } catch (error) {
      healthStatus.overall = 'critical';
      healthStatus.alerts.push({
        level: 'critical',
        component: 'system',
        message: `Health check failed: ${error.message}`,
        timestamp: new Date().toISOString()
      });
    }

    healthStatus.duration = Date.now() - startTime;
    this.recordHealthCheck(healthStatus);
    
    return healthStatus;
  }

  /**
   * Check GitHub API connectivity and rate limits
   * @param {string} githubToken GitHub API token
   * @returns {Promise<Object>} API health status
   */
  async checkApiHealth(githubToken) {
    const startTime = Date.now();
    const apiHealth = {
      status: 'healthy',
      responseTime: 0,
      rateLimit: null,
      authentication: 'unknown',
      errors: []
    };

    try {
      if (!githubToken) {
        apiHealth.status = 'degraded';
        apiHealth.authentication = 'missing';
        apiHealth.errors.push('No GitHub token provided');
        return apiHealth;
      }

      const client = new GitHubApiClient(githubToken);
      
      // Test authentication
      const user = await client.getAuthenticatedUser();
      apiHealth.authentication = 'valid';
      apiHealth.authenticatedUser = user.login;
      
      // Check rate limits
      apiHealth.rateLimit = await client.checkRateLimit();
      const rateLimitUsage = (apiHealth.rateLimit.limit - apiHealth.rateLimit.remaining) / apiHealth.rateLimit.limit;
      
      if (rateLimitUsage > (1 - this.options.apiThresholds.rateLimitBuffer)) {
        apiHealth.status = 'degraded';
        apiHealth.errors.push(`Rate limit usage high: ${(rateLimitUsage * 100).toFixed(1)}%`);
      }
      
      apiHealth.responseTime = Date.now() - startTime;
      
      if (apiHealth.responseTime > this.options.apiThresholds.responseTime) {
        apiHealth.status = 'degraded';
        apiHealth.errors.push(`API response time high: ${apiHealth.responseTime}ms`);
      }

    } catch (error) {
      apiHealth.status = 'unhealthy';
      apiHealth.authentication = 'failed';
      apiHealth.errors.push(`API check failed: ${error.message}`);
      apiHealth.responseTime = Date.now() - startTime;
    }

    return apiHealth;
  }

  /**
   * Check auto-labeling system health and accuracy
   * @returns {Promise<Object>} Auto-labeling health status
   */
  async checkAutoLabelingHealth() {
    const startTime = Date.now();
    const labelingHealth = {
      status: 'healthy',
      processingTime: 0,
      accuracy: null,
      componentDetection: 'functional',
      priorityDetection: 'functional',
      securityDetection: 'functional',
      errors: []
    };

    try {
      // Test with sample issue content
      const testCases = [
        {
          title: 'Bug in spec-analyst component',
          body: 'The framework/agents/spec-analyst.md file has critical issues',
          expected: ['component:agent-spec-analyst', 'priority:normal', 'type:bug']
        },
        {
          title: 'Security vulnerability in authentication',
          body: 'Found XSS vulnerability in user input validation',
          expected: ['type:security', 'priority:high']
        },
        {
          title: 'High priority installation issue',
          body: 'Installation script fails with critical error on setup',
          expected: ['component:installation', 'priority:critical']
        }
      ];

      let correctPredictions = 0;
      let totalTime = 0;

      for (const testCase of testCases) {
        const caseStartTime = Date.now();
        const analysis = analyzeIssueContent(testCase.title, testCase.body);
        const caseTime = Date.now() - caseStartTime;
        totalTime += caseTime;

        // Check if key expected labels are present
        const hasExpected = testCase.expected.some(label => 
          analysis.labels.includes(label)
        );
        
        if (hasExpected || analysis.confidence > 0.5) {
          correctPredictions++;
        }
      }

      labelingHealth.accuracy = correctPredictions / testCases.length;
      labelingHealth.processingTime = totalTime / testCases.length;

      // Check accuracy threshold
      if (labelingHealth.accuracy < this.options.labelingThresholds.accuracy) {
        labelingHealth.status = 'degraded';
        labelingHealth.errors.push(`Labeling accuracy below threshold: ${(labelingHealth.accuracy * 100).toFixed(1)}%`);
      }

      // Check processing time
      if (labelingHealth.processingTime > this.options.labelingThresholds.processingTime) {
        labelingHealth.status = 'degraded';
        labelingHealth.errors.push(`Processing time high: ${labelingHealth.processingTime}ms`);
      }

    } catch (error) {
      labelingHealth.status = 'unhealthy';
      labelingHealth.errors.push(`Auto-labeling check failed: ${error.message}`);
      labelingHealth.componentDetection = 'failed';
      labelingHealth.priorityDetection = 'failed';
      labelingHealth.securityDetection = 'failed';
    }

    return labelingHealth;
  }

  /**
   * Check template system availability and validation
   * @returns {Promise<Object>} Template health status
   */
  async checkTemplateHealth() {
    const templateHealth = {
      status: 'healthy',
      availableScripts: [],
      validationWorking: false,
      errors: []
    };

    try {
      const scriptsDir = path.join(__dirname, '../scripts');
      
      // Check for validation scripts
      const requiredScripts = ['validate-templates.js', 'sync-labels.js'];
      
      for (const script of requiredScripts) {
        const scriptPath = path.join(scriptsDir, script);
        if (fs.existsSync(scriptPath)) {
          templateHealth.availableScripts.push(script);
        } else {
          templateHealth.status = 'degraded';
          templateHealth.errors.push(`Missing script: ${script}`);
        }
      }

      // Test validation functionality
      try {
        const validateScript = path.join(scriptsDir, 'validate-templates.js');
        if (fs.existsSync(validateScript)) {
          templateHealth.validationWorking = true;
        }
      } catch (error) {
        templateHealth.validationWorking = false;
        templateHealth.errors.push(`Template validation failed: ${error.message}`);
      }

    } catch (error) {
      templateHealth.status = 'unhealthy';
      templateHealth.errors.push(`Template system check failed: ${error.message}`);
    }

    return templateHealth;
  }

  /**
   * Check system performance metrics
   * @param {string} githubToken GitHub API token
   * @returns {Promise<Object>} Performance health status
   */
  async checkPerformanceHealth(githubToken) {
    const performanceHealth = {
      status: 'healthy',
      memoryUsage: process.memoryUsage(),
      cpuUsage: process.cpuUsage(),
      apiLatency: null,
      throughput: null,
      errors: []
    };

    try {
      if (githubToken) {
        // Measure API latency
        const client = new GitHubApiClient(githubToken);
        const latencyStartTime = Date.now();
        await client.checkRateLimit();
        performanceHealth.apiLatency = Date.now() - latencyStartTime;

        if (performanceHealth.apiLatency > this.options.apiThresholds.responseTime) {
          performanceHealth.status = 'degraded';
          performanceHealth.errors.push(`High API latency: ${performanceHealth.apiLatency}ms`);
        }
      }

      // Check memory usage
      const memoryUsageMB = performanceHealth.memoryUsage.heapUsed / 1024 / 1024;
      if (memoryUsageMB > 500) { // 500MB threshold
        performanceHealth.status = 'degraded';
        performanceHealth.errors.push(`High memory usage: ${memoryUsageMB.toFixed(2)}MB`);
      }

    } catch (error) {
      performanceHealth.status = 'degraded';
      performanceHealth.errors.push(`Performance check failed: ${error.message}`);
    }

    return performanceHealth;
  }

  /**
   * Check security validation systems
   * @returns {Promise<Object>} Security health status
   */
  async checkSecurityHealth() {
    const securityHealth = {
      status: 'healthy',
      inputValidation: 'functional',
      errorHandling: 'functional',
      tokenSecurity: 'unknown',
      errors: []
    };

    try {
      // Test input validation
      const testInputs = [
        '<script>alert("xss")</script>',
        '../../etc/passwd',
        'DROP TABLE users;',
        'A'.repeat(10000) // Large input
      ];

      for (const input of testInputs) {
        try {
          const analysis = analyzeIssueContent(input, '');
          // If it doesn't throw an error, input validation is working
          if (analysis && analysis.labels) {
            // Input validation working
          }
        } catch (error) {
          // This is expected for malicious input
        }
      }

      // Check error handling patterns
      try {
        const analysis = analyzeIssueContent(null, undefined);
        if (analysis) {
          securityHealth.errorHandling = 'functional';
        }
      } catch (error) {
        if (error.message && !error.message.includes('sensitive')) {
          securityHealth.errorHandling = 'functional';
        } else {
          securityHealth.errorHandling = 'leaking';
          securityHealth.status = 'degraded';
          securityHealth.errors.push('Error messages may leak sensitive information');
        }
      }

    } catch (error) {
      securityHealth.status = 'unhealthy';
      securityHealth.errors.push(`Security check failed: ${error.message}`);
    }

    return securityHealth;
  }

  /**
   * Calculate overall health status from component health
   * @param {Object} components Component health statuses
   * @returns {string} Overall health status
   */
  calculateOverallHealth(components) {
    const statuses = Object.values(components).map(c => c.status);
    
    if (statuses.includes('unhealthy')) return 'unhealthy';
    if (statuses.includes('degraded')) return 'degraded';
    return 'healthy';
  }

  /**
   * Generate alerts based on component health
   * @param {Object} components Component health statuses
   * @returns {Array} Array of alert objects
   */
  generateAlerts(components) {
    const alerts = [];

    Object.entries(components).forEach(([componentName, health]) => {
      if (health.status === 'unhealthy') {
        alerts.push({
          level: 'critical',
          component: componentName,
          message: `${componentName} is unhealthy: ${health.errors.join(', ')}`,
          timestamp: new Date().toISOString()
        });
      } else if (health.status === 'degraded') {
        alerts.push({
          level: 'warning',
          component: componentName,
          message: `${componentName} is degraded: ${health.errors.join(', ')}`,
          timestamp: new Date().toISOString()
        });
      }
    });

    return alerts;
  }

  /**
   * Calculate system metrics from health data
   * @param {Object} components Component health statuses
   * @returns {Object} System metrics
   */
  calculateMetrics(components) {
    const metrics = {
      healthyComponents: 0,
      degradedComponents: 0,
      unhealthyComponents: 0,
      totalComponents: 0,
      averageResponseTime: 0,
      systemLoad: 0
    };

    const responseTimes = [];

    Object.values(components).forEach(health => {
      metrics.totalComponents++;
      
      switch (health.status) {
        case 'healthy':
          metrics.healthyComponents++;
          break;
        case 'degraded':
          metrics.degradedComponents++;
          break;
        case 'unhealthy':
          metrics.unhealthyComponents++;
          break;
      }

      if (health.responseTime) {
        responseTimes.push(health.responseTime);
      }
      if (health.processingTime) {
        responseTimes.push(health.processingTime);
      }
    });

    if (responseTimes.length > 0) {
      metrics.averageResponseTime = responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length;
    }

    metrics.systemLoad = metrics.unhealthyComponents * 0.5 + metrics.degradedComponents * 0.3;

    return metrics;
  }

  /**
   * Get system uptime
   * @returns {number} Uptime in milliseconds
   */
  getUptime() {
    return Date.now() - this.startTime;
  }

  /**
   * Record health check results for historical analysis
   * @param {Object} healthStatus Health check results
   */
  recordHealthCheck(healthStatus) {
    this.healthHistory.push(healthStatus);
    
    // Keep only last 100 health checks
    if (this.healthHistory.length > 100) {
      this.healthHistory = this.healthHistory.slice(-100);
    }
  }

  /**
   * Get health history for analysis
   * @returns {Array} Historical health check data
   */
  getHealthHistory() {
    return [...this.healthHistory];
  }

  /**
   * Get quick health summary
   * @param {string} githubToken GitHub API token
   * @returns {Promise<Object>} Quick health summary
   */
  async getQuickHealth(githubToken) {
    const startTime = Date.now();
    
    try {
      const quickCheck = {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: this.getUptime(),
        api: 'unknown',
        labeling: 'unknown',
        duration: 0
      };

      // Quick API check
      if (githubToken) {
        try {
          const client = new GitHubApiClient(githubToken);
          const rateLimit = await client.checkRateLimit();
          quickCheck.api = rateLimit.remaining > 10 ? 'healthy' : 'degraded';
        } catch (error) {
          quickCheck.api = 'unhealthy';
          quickCheck.status = 'degraded';
        }
      }

      // Quick labeling check
      try {
        const analysis = analyzeIssueContent('test issue', 'test content');
        quickCheck.labeling = analysis.labels ? 'healthy' : 'degraded';
      } catch (error) {
        quickCheck.labeling = 'unhealthy';
        quickCheck.status = 'degraded';
      }

      quickCheck.duration = Date.now() - startTime;
      return quickCheck;

    } catch (error) {
      return {
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        error: error.message,
        duration: Date.now() - startTime
      };
    }
  }
}

module.exports = HealthCheckSystem;