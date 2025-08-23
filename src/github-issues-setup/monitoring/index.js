/**
 * Main Monitoring System Integration
 * Orchestrates health checking, metrics collection, alerting, and dashboard
 */

const HealthCheckSystem = require('./health-check');
const MetricsCollector = require('./metrics');
const AlertingSystem = require('./alerts');
const DashboardSystem = require('./dashboard');

class MonitoringSystem {
  constructor(options = {}) {
    this.options = {
      healthCheckInterval: options.healthCheckInterval || 60000, // 1 minute
      metricsRetentionDays: options.metricsRetentionDays || 30,
      alertCooldownPeriod: options.alertCooldownPeriod || 300000, // 5 minutes
      enableDashboard: options.enableDashboard !== false,
      ...options
    };

    // Initialize subsystems
    this.healthChecker = new HealthCheckSystem({
      timeout: this.options.healthCheckTimeout,
      apiThresholds: this.options.apiThresholds,
      labelingThresholds: this.options.labelingThresholds
    });

    this.metricsCollector = new MetricsCollector({
      retentionDays: this.options.metricsRetentionDays,
      enablePerformanceTracking: this.options.enablePerformanceTracking
    });

    this.alertingSystem = new AlertingSystem({
      errorRateThreshold: this.options.errorRateThreshold,
      responseTimeThreshold: this.options.responseTimeThreshold,
      rateLimitThreshold: this.options.rateLimitThreshold,
      accuracyThreshold: this.options.accuracyThreshold,
      cooldownPeriod: this.options.alertCooldownPeriod,
      emailConfig: this.options.emailConfig,
      slackConfig: this.options.slackConfig,
      webhookConfig: this.options.webhookConfig
    });

    if (this.options.enableDashboard) {
      this.dashboard = new DashboardSystem(
        this.healthChecker,
        this.metricsCollector,
        this.alertingSystem,
        this.options.dashboardConfig
      );
    }

    this.isRunning = false;
    this.monitoringInterval = null;
    this.setupEventListeners();
  }

  /**
   * Start the monitoring system
   * @param {string} githubToken GitHub API token
   */
  async start(githubToken) {
    if (this.isRunning) {
      console.warn('Monitoring system is already running');
      return;
    }

    console.log('Starting GitHub Issues Setup monitoring system...');
    
    try {
      // Perform initial health check
      const initialHealth = await this.healthChecker.performHealthCheck(githubToken);
      console.log(`Initial system status: ${initialHealth.overall}`);

      // Start periodic monitoring
      this.monitoringInterval = setInterval(async () => {
        await this.performMonitoringCycle(githubToken);
      }, this.options.healthCheckInterval);

      // Record system startup
      this.metricsCollector.trackSystem({
        metric: 'startup',
        value: 'success',
        metadata: {
          timestamp: new Date().toISOString(),
          options: this.options
        }
      });

      this.isRunning = true;
      console.log('Monitoring system started successfully');
      
    } catch (error) {
      console.error('Failed to start monitoring system:', error);
      throw error;
    }
  }

  /**
   * Stop the monitoring system
   */
  async stop() {
    if (!this.isRunning) {
      console.warn('Monitoring system is not running');
      return;
    }

    console.log('Stopping monitoring system...');

    // Clear monitoring interval
    if (this.monitoringInterval) {
      clearInterval(this.monitoringInterval);
      this.monitoringInterval = null;
    }

    // Record system shutdown
    this.metricsCollector.trackSystem({
      metric: 'shutdown',
      value: 'graceful',
      metadata: {
        timestamp: new Date().toISOString(),
        uptime: this.healthChecker.getUptime()
      }
    });

    this.isRunning = false;
    console.log('Monitoring system stopped');
  }

  /**
   * Perform a complete monitoring cycle
   * @private
   * @param {string} githubToken GitHub API token
   */
  async performMonitoringCycle(githubToken) {
    const cycleStartTime = Date.now();

    try {
      // 1. Health check
      const health = await this.healthChecker.performHealthCheck(githubToken);
      
      // 2. Get metrics summary
      const metrics = this.metricsCollector.getSystemSummary({
        start: Date.now() - (60 * 60 * 1000), // Last hour
        end: Date.now()
      });

      // 3. Process alerts
      this.alertingSystem.processHealthAlerts(health);
      this.alertingSystem.processMetricsAlerts(metrics);

      // 4. Record monitoring cycle performance
      this.metricsCollector.trackPerformance({
        operation: 'monitoring_cycle',
        duration: Date.now() - cycleStartTime,
        success: true
      });

      // 5. Log cycle completion (debug level)
      if (this.options.debug) {
        console.log(`Monitoring cycle completed in ${Date.now() - cycleStartTime}ms - Status: ${health.overall}`);
      }

    } catch (error) {
      console.error('Monitoring cycle failed:', error);
      
      // Record failure
      this.metricsCollector.trackError({
        component: 'monitoring_system',
        errorType: 'monitoring_cycle_failed',
        errorMessage: error.message,
        severity: 'error'
      });

      // Alert on monitoring failure
      this.alertingSystem.triggerAlert({
        level: 'critical',
        component: 'monitoring_system',
        metric: 'cycle_failure',
        message: `Monitoring cycle failed: ${error.message}`
      });
    }
  }

  /**
   * Set up event listeners for system integration
   * @private
   */
  setupEventListeners() {
    // Listen for metrics events and forward to alerting
    this.metricsCollector.on('errorEvent', (event) => {
      this.alertingSystem.processMetricsAlerts({
        errors: { errorRate: 1, totalErrors: 1 } // Simplified for individual error
      });
    });

    // Listen for alert events and log them
    this.alertingSystem.on('alert', (alert) => {
      console.log(`ALERT [${alert.level.toUpperCase()}]: ${alert.component}/${alert.metric} - ${alert.message}`);
    });

    this.alertingSystem.on('alertResolved', (alert) => {
      console.log(`RESOLVED: ${alert.component}/${alert.metric}`);
    });
  }

  /**
   * Get current system status
   * @param {string} githubToken GitHub API token
   * @returns {Promise<Object>} Current system status
   */
  async getStatus(githubToken) {
    try {
      const [health, metrics] = await Promise.all([
        this.healthChecker.performHealthCheck(githubToken),
        this.metricsCollector.getSystemSummary({
          start: Date.now() - (60 * 60 * 1000),
          end: Date.now()
        })
      ]);

      const alerts = {
        active: this.alertingSystem.getActiveAlerts(),
        recent: this.alertingSystem.getAlertHistory({ limit: 5 })
      };

      return {
        timestamp: new Date().toISOString(),
        isMonitoring: this.isRunning,
        uptime: this.healthChecker.getUptime(),
        health,
        metrics,
        alerts
      };

    } catch (error) {
      return {
        timestamp: new Date().toISOString(),
        isMonitoring: this.isRunning,
        error: error.message,
        health: { overall: 'unknown' },
        metrics: {},
        alerts: { active: [], recent: [] }
      };
    }
  }

  /**
   * Generate dashboard
   * @param {string} githubToken GitHub API token
   * @param {string} format Output format ('html', 'json', 'text')
   * @returns {Promise<string|Object>} Dashboard in requested format
   */
  async getDashboard(githubToken, format = 'html') {
    if (!this.dashboard) {
      throw new Error('Dashboard is not enabled');
    }

    switch (format.toLowerCase()) {
      case 'html':
        return await this.dashboard.generateHTMLDashboard(githubToken);
      case 'json':
        return await this.dashboard.generateJSONDashboard(githubToken);
      case 'text':
        return await this.dashboard.generateTextSummary(githubToken);
      default:
        throw new Error(`Unsupported dashboard format: ${format}`);
    }
  }

  /**
   * Track auto-labeling event
   * @param {Object} event Auto-labeling event data
   */
  trackAutoLabeling(event) {
    this.metricsCollector.trackAutoLabeling(event);
  }

  /**
   * Track API usage event
   * @param {Object} event API usage event data
   */
  trackApiUsage(event) {
    this.metricsCollector.trackApiUsage(event);
  }

  /**
   * Track performance event
   * @param {Object} event Performance event data
   */
  trackPerformance(event) {
    this.metricsCollector.trackPerformance(event);
  }

  /**
   * Track user engagement event
   * @param {Object} event User engagement event data
   */
  trackUserEngagement(event) {
    this.metricsCollector.trackUserEngagement(event);
  }

  /**
   * Track error event
   * @param {Object} event Error event data
   */
  trackError(event) {
    this.metricsCollector.trackError(event);
  }

  /**
   * Get monitoring statistics
   * @returns {Object} Monitoring system statistics
   */
  getMonitoringStats() {
    return {
      isRunning: this.isRunning,
      uptime: this.isRunning ? this.healthChecker.getUptime() : 0,
      totalEvents: this.metricsCollector.getTotalEventCount(),
      activeAlerts: this.alertingSystem.getActiveAlerts().length,
      systemLoad: this.getSystemLoad(),
      configuration: {
        healthCheckInterval: this.options.healthCheckInterval,
        metricsRetentionDays: this.options.metricsRetentionDays,
        alertCooldownPeriod: this.options.alertCooldownPeriod,
        dashboardEnabled: this.options.enableDashboard
      }
    };
  }

  /**
   * Export all monitoring data
   * @param {Object} options Export options
   * @returns {Object} Complete monitoring data export
   */
  exportMonitoringData(options = {}) {
    return {
      timestamp: new Date().toISOString(),
      systemStats: this.getMonitoringStats(),
      healthHistory: this.healthChecker.getHealthHistory(),
      metrics: this.metricsCollector.exportMetrics(options),
      alerts: {
        active: this.alertingSystem.getActiveAlerts(),
        history: this.alertingSystem.getAlertHistory(options),
        stats: this.alertingSystem.getAlertStats(options)
      }
    };
  }

  /**
   * Configure notification settings
   * @param {Object} config Notification configuration
   */
  configureNotifications(config) {
    this.alertingSystem.configureNotifications(config);
  }

  /**
   * Test monitoring system
   * @param {string} githubToken GitHub API token
   */
  async testMonitoring(githubToken) {
    console.log('Testing monitoring system...');
    
    try {
      // Test health check
      console.log('Testing health check...');
      const health = await this.healthChecker.getQuickHealth(githubToken);
      console.log(`Health check: ${health.status}`);

      // Test metrics collection
      console.log('Testing metrics collection...');
      this.metricsCollector.trackSystem({
        metric: 'test',
        value: 'monitoring_test',
        unit: 'test'
      });

      // Test alerting
      console.log('Testing alerting system...');
      this.alertingSystem.testAlerts();

      // Test dashboard (if enabled)
      if (this.dashboard) {
        console.log('Testing dashboard generation...');
        const summary = await this.dashboard.generateTextSummary(githubToken);
        console.log('Dashboard test successful');
      }

      console.log('All monitoring tests passed');
      return true;

    } catch (error) {
      console.error('Monitoring test failed:', error);
      return false;
    }
  }

  /**
   * Get current system load indicator
   * @private
   * @returns {number} System load (0-1 scale)
   */
  getSystemLoad() {
    const activeAlerts = this.alertingSystem.getActiveAlerts();
    const criticalAlerts = activeAlerts.filter(a => a.level === 'critical').length;
    const warningAlerts = activeAlerts.filter(a => a.level === 'warning').length;
    
    return Math.min(1, (criticalAlerts * 0.5 + warningAlerts * 0.3) / 10);
  }
}

module.exports = MonitoringSystem;