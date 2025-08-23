/**
 * Alerting System for GitHub Issues Setup
 * Monitors thresholds and sends notifications for critical issues
 */

const EventEmitter = require('events');

class AlertingSystem extends EventEmitter {
  constructor(options = {}) {
    super();
    this.options = {
      // Alert thresholds
      errorRateThreshold: options.errorRateThreshold || 0.05, // 5% error rate
      responseTimeThreshold: options.responseTimeThreshold || 5000, // 5 seconds
      rateLimitThreshold: options.rateLimitThreshold || 100, // 100 remaining requests
      accuracyThreshold: options.accuracyThreshold || 0.85, // 85% accuracy
      memoryThreshold: options.memoryThreshold || 500 * 1024 * 1024, // 500MB
      
      // Alert configuration
      cooldownPeriod: options.cooldownPeriod || 300000, // 5 minutes
      maxAlertsPerHour: options.maxAlertsPerHour || 10,
      enableEmailAlerts: options.enableEmailAlerts || false,
      enableSlackAlerts: options.enableSlackAlerts || false,
      enableWebhooks: options.enableWebhooks || false,
      
      // Notification settings
      emailConfig: options.emailConfig || {},
      slackConfig: options.slackConfig || {},
      webhookConfig: options.webhookConfig || {},
      
      ...options
    };

    this.activeAlerts = new Map();
    this.alertHistory = [];
    this.cooldownTimers = new Map();
    this.alertCounts = new Map(); // For rate limiting
    
    this.setupAlertTracking();
  }

  /**
   * Process system health and generate alerts
   * @param {Object} healthStatus System health status from health check
   */
  processHealthAlerts(healthStatus) {
    const alerts = [];

    // Check component health
    Object.entries(healthStatus.components || {}).forEach(([component, health]) => {
      if (health.status === 'unhealthy') {
        alerts.push(this.createAlert({
          level: 'critical',
          component,
          metric: 'component_health',
          message: `${component} is unhealthy: ${health.errors.join(', ')}`,
          value: health.status,
          threshold: 'healthy'
        }));
      } else if (health.status === 'degraded') {
        alerts.push(this.createAlert({
          level: 'warning',
          component,
          metric: 'component_health',
          message: `${component} is degraded: ${health.errors.join(', ')}`,
          value: health.status,
          threshold: 'healthy'
        }));
      }

      // Check specific component metrics
      if (health.responseTime && health.responseTime > this.options.responseTimeThreshold) {
        alerts.push(this.createAlert({
          level: 'warning',
          component,
          metric: 'response_time',
          message: `${component} response time is high: ${health.responseTime}ms`,
          value: health.responseTime,
          threshold: this.options.responseTimeThreshold
        }));
      }

      if (health.rateLimit && health.rateLimit.remaining < this.options.rateLimitThreshold) {
        alerts.push(this.createAlert({
          level: 'warning',
          component: 'api',
          metric: 'rate_limit',
          message: `GitHub API rate limit low: ${health.rateLimit.remaining} remaining`,
          value: health.rateLimit.remaining,
          threshold: this.options.rateLimitThreshold
        }));
      }

      if (health.accuracy && health.accuracy < this.options.accuracyThreshold) {
        alerts.push(this.createAlert({
          level: 'warning',
          component: 'auto_labeling',
          metric: 'accuracy',
          message: `Auto-labeling accuracy below threshold: ${(health.accuracy * 100).toFixed(1)}%`,
          value: health.accuracy,
          threshold: this.options.accuracyThreshold
        }));
      }
    });

    // Process alerts
    alerts.forEach(alert => this.processAlert(alert));
  }

  /**
   * Process metrics and generate alerts
   * @param {Object} metricsData Metrics data from metrics collector
   */
  processMetricsAlerts(metricsData) {
    const alerts = [];

    // API usage alerts
    if (metricsData.apiUsage) {
      const { successRate, averageResponseTime, rateLimitUtilization } = metricsData.apiUsage;
      
      if (successRate !== null && successRate < (1 - this.options.errorRateThreshold)) {
        alerts.push(this.createAlert({
          level: 'critical',
          component: 'api',
          metric: 'error_rate',
          message: `API error rate high: ${((1 - successRate) * 100).toFixed(1)}%`,
          value: 1 - successRate,
          threshold: this.options.errorRateThreshold
        }));
      }

      if (averageResponseTime && averageResponseTime > this.options.responseTimeThreshold) {
        alerts.push(this.createAlert({
          level: 'warning',
          component: 'api',
          metric: 'response_time',
          message: `API average response time high: ${averageResponseTime.toFixed(0)}ms`,
          value: averageResponseTime,
          threshold: this.options.responseTimeThreshold
        }));
      }

      if (rateLimitUtilization !== null && rateLimitUtilization < this.options.rateLimitThreshold) {
        alerts.push(this.createAlert({
          level: 'warning',
          component: 'api',
          metric: 'rate_limit',
          message: `GitHub API rate limit low: ${rateLimitUtilization} remaining`,
          value: rateLimitUtilization,
          threshold: this.options.rateLimitThreshold
        }));
      }
    }

    // Auto-labeling alerts
    if (metricsData.autoLabeling && metricsData.autoLabeling.averageAccuracy !== null) {
      const { averageAccuracy, averageProcessingTime, manualOverrideRate } = metricsData.autoLabeling;
      
      if (averageAccuracy < this.options.accuracyThreshold) {
        alerts.push(this.createAlert({
          level: 'warning',
          component: 'auto_labeling',
          metric: 'accuracy',
          message: `Auto-labeling accuracy declining: ${(averageAccuracy * 100).toFixed(1)}%`,
          value: averageAccuracy,
          threshold: this.options.accuracyThreshold
        }));
      }

      if (averageProcessingTime && averageProcessingTime > 30000) {
        alerts.push(this.createAlert({
          level: 'warning',
          component: 'auto_labeling',
          metric: 'processing_time',
          message: `Auto-labeling processing time high: ${(averageProcessingTime / 1000).toFixed(1)}s`,
          value: averageProcessingTime,
          threshold: 30000
        }));
      }

      if (manualOverrideRate > 0.3) { // 30% override rate
        alerts.push(this.createAlert({
          level: 'info',
          component: 'auto_labeling',
          metric: 'override_rate',
          message: `High manual override rate: ${(manualOverrideRate * 100).toFixed(1)}%`,
          value: manualOverrideRate,
          threshold: 0.3
        }));
      }
    }

    // Performance alerts
    if (metricsData.performance && metricsData.performance.memoryStats) {
      const { memoryStats, averageDuration } = metricsData.performance;
      
      if (memoryStats.max > this.options.memoryThreshold) {
        alerts.push(this.createAlert({
          level: 'warning',
          component: 'system',
          metric: 'memory_usage',
          message: `High memory usage: ${(memoryStats.max / 1024 / 1024).toFixed(1)}MB`,
          value: memoryStats.max,
          threshold: this.options.memoryThreshold
        }));
      }

      if (averageDuration && averageDuration > 10000) { // 10 seconds
        alerts.push(this.createAlert({
          level: 'warning',
          component: 'performance',
          metric: 'operation_duration',
          message: `Operations running slowly: ${(averageDuration / 1000).toFixed(1)}s average`,
          value: averageDuration,
          threshold: 10000
        }));
      }
    }

    // Error rate alerts
    if (metricsData.errors && metricsData.errors.errorRate > this.options.errorRateThreshold) {
      alerts.push(this.createAlert({
        level: 'critical',
        component: 'system',
        metric: 'error_rate',
        message: `System error rate high: ${metricsData.errors.errorRate.toFixed(2)} errors/minute`,
        value: metricsData.errors.errorRate,
        threshold: this.options.errorRateThreshold
      }));
    }

    // Process alerts
    alerts.forEach(alert => this.processAlert(alert));
  }

  /**
   * Process individual alert
   * @param {Object} alert Alert object
   */
  async processAlert(alert) {
    const alertKey = `${alert.component}-${alert.metric}`;
    
    // Check if we're in cooldown period for this alert
    if (this.cooldownTimers.has(alertKey)) {
      return;
    }

    // Check alert rate limiting
    const hourKey = this.getHourKey(Date.now());
    const alertCount = this.alertCounts.get(hourKey) || 0;
    if (alertCount >= this.options.maxAlertsPerHour) {
      console.warn(`Alert rate limit exceeded for hour ${hourKey}`);
      return;
    }

    // Update active alerts
    this.activeAlerts.set(alertKey, alert);
    this.alertHistory.push(alert);
    
    // Increment alert count
    this.alertCounts.set(hourKey, alertCount + 1);

    // Send notifications
    await this.sendNotifications(alert);

    // Set cooldown timer
    this.cooldownTimers.set(alertKey, setTimeout(() => {
      this.cooldownTimers.delete(alertKey);
      this.activeAlerts.delete(alertKey);
    }, this.options.cooldownPeriod));

    // Emit alert event
    this.emit('alert', alert);

    // Clean up old alert history
    this.cleanup();
  }

  /**
   * Manually trigger an alert
   * @param {Object} alertData Alert data
   */
  triggerAlert(alertData) {
    const alert = this.createAlert(alertData);
    this.processAlert(alert);
  }

  /**
   * Resolve an active alert
   * @param {string} component Alert component
   * @param {string} metric Alert metric
   */
  resolveAlert(component, metric) {
    const alertKey = `${component}-${metric}`;
    const alert = this.activeAlerts.get(alertKey);
    
    if (alert) {
      alert.resolved = true;
      alert.resolvedAt = new Date().toISOString();
      
      this.activeAlerts.delete(alertKey);
      if (this.cooldownTimers.has(alertKey)) {
        clearTimeout(this.cooldownTimers.get(alertKey));
        this.cooldownTimers.delete(alertKey);
      }
      
      this.emit('alertResolved', alert);
    }
  }

  /**
   * Get all active alerts
   * @returns {Array} Array of active alerts
   */
  getActiveAlerts() {
    return Array.from(this.activeAlerts.values());
  }

  /**
   * Get alert history
   * @param {Object} options Query options
   * @returns {Array} Array of historical alerts
   */
  getAlertHistory(options = {}) {
    const { limit = 100, component, level, startTime, endTime } = options;
    
    let alerts = [...this.alertHistory];
    
    if (component) {
      alerts = alerts.filter(a => a.component === component);
    }
    
    if (level) {
      alerts = alerts.filter(a => a.level === level);
    }
    
    if (startTime) {
      alerts = alerts.filter(a => new Date(a.timestamp) >= new Date(startTime));
    }
    
    if (endTime) {
      alerts = alerts.filter(a => new Date(a.timestamp) <= new Date(endTime));
    }
    
    return alerts.slice(-limit);
  }

  /**
   * Get alert statistics
   * @param {Object} options Query options
   * @returns {Object} Alert statistics
   */
  getAlertStats(options = {}) {
    const alerts = this.getAlertHistory(options);
    
    const stats = {
      total: alerts.length,
      byLevel: {},
      byComponent: {},
      byMetric: {},
      resolved: 0,
      averageResolutionTime: null
    };
    
    const resolutionTimes = [];
    
    alerts.forEach(alert => {
      stats.byLevel[alert.level] = (stats.byLevel[alert.level] || 0) + 1;
      stats.byComponent[alert.component] = (stats.byComponent[alert.component] || 0) + 1;
      stats.byMetric[alert.metric] = (stats.byMetric[alert.metric] || 0) + 1;
      
      if (alert.resolved) {
        stats.resolved++;
        if (alert.resolvedAt) {
          const resolutionTime = new Date(alert.resolvedAt) - new Date(alert.timestamp);
          resolutionTimes.push(resolutionTime);
        }
      }
    });
    
    if (resolutionTimes.length > 0) {
      stats.averageResolutionTime = resolutionTimes.reduce((a, b) => a + b, 0) / resolutionTimes.length;
    }
    
    return stats;
  }

  /**
   * Send alert notifications
   * @private
   * @param {Object} alert Alert object
   */
  async sendNotifications(alert) {
    const notifications = [];
    
    // Console logging (always enabled)
    this.logAlert(alert);
    
    // Email notifications
    if (this.options.enableEmailAlerts && this.options.emailConfig.enabled) {
      notifications.push(this.sendEmailAlert(alert));
    }
    
    // Slack notifications
    if (this.options.enableSlackAlerts && this.options.slackConfig.enabled) {
      notifications.push(this.sendSlackAlert(alert));
    }
    
    // Webhook notifications
    if (this.options.enableWebhooks && this.options.webhookConfig.enabled) {
      notifications.push(this.sendWebhookAlert(alert));
    }
    
    try {
      await Promise.allSettled(notifications);
    } catch (error) {
      console.error('Failed to send some alert notifications:', error);
    }
  }

  /**
   * Log alert to console
   * @private
   * @param {Object} alert Alert object
   */
  logAlert(alert) {
    const timestamp = new Date(alert.timestamp).toISOString();
    const logMethod = alert.level === 'critical' ? 'error' : 
                     alert.level === 'warning' ? 'warn' : 'info';
    
    console[logMethod](`[ALERT ${alert.level.toUpperCase()}] ${timestamp} - ${alert.component}/${alert.metric}: ${alert.message}`);
  }

  /**
   * Send email alert (placeholder implementation)
   * @private
   * @param {Object} alert Alert object
   */
  async sendEmailAlert(alert) {
    // This would integrate with an email service like SendGrid, AWS SES, etc.
    console.log(`Email alert would be sent: ${alert.message}`);
  }

  /**
   * Send Slack alert (placeholder implementation)
   * @private
   * @param {Object} alert Alert object
   */
  async sendSlackAlert(alert) {
    // This would integrate with Slack webhook or API
    console.log(`Slack alert would be sent: ${alert.message}`);
  }

  /**
   * Send webhook alert (placeholder implementation)
   * @private
   * @param {Object} alert Alert object
   */
  async sendWebhookAlert(alert) {
    // This would send HTTP POST to configured webhook URL
    console.log(`Webhook alert would be sent: ${alert.message}`);
  }

  /**
   * Create alert object with consistent structure
   * @private
   * @param {Object} alertData Alert data
   * @returns {Object} Standardized alert object
   */
  createAlert(alertData) {
    return {
      id: `${alertData.component}-${alertData.metric}-${Date.now()}`,
      timestamp: new Date().toISOString(),
      level: alertData.level || 'info',
      component: alertData.component || 'unknown',
      metric: alertData.metric || 'unknown',
      message: alertData.message || 'No message provided',
      value: alertData.value,
      threshold: alertData.threshold,
      context: alertData.context || {},
      resolved: false,
      resolvedAt: null
    };
  }

  /**
   * Set up alert tracking and cleanup
   * @private
   */
  setupAlertTracking() {
    // Clean up old alert counts every hour
    setInterval(() => {
      const cutoffTime = Date.now() - (2 * 60 * 60 * 1000); // 2 hours ago
      const cutoffHour = this.getHourKey(cutoffTime);
      
      for (const hourKey of this.alertCounts.keys()) {
        if (hourKey < cutoffHour) {
          this.alertCounts.delete(hourKey);
        }
      }
    }, 60 * 60 * 1000); // Every hour
  }

  /**
   * Clean up old alert history
   * @private
   */
  cleanup() {
    const maxHistorySize = 1000;
    
    if (this.alertHistory.length > maxHistorySize) {
      this.alertHistory = this.alertHistory.slice(-maxHistorySize);
    }
  }

  /**
   * Get hour key for rate limiting
   * @private
   * @param {number} timestamp Timestamp
   * @returns {string} Hour key
   */
  getHourKey(timestamp) {
    const date = new Date(timestamp);
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}-${String(date.getHours()).padStart(2, '0')}`;
  }

  /**
   * Configure notification settings
   * @param {Object} config Notification configuration
   */
  configureNotifications(config) {
    if (config.email) {
      this.options.enableEmailAlerts = true;
      this.options.emailConfig = { ...this.options.emailConfig, ...config.email };
    }
    
    if (config.slack) {
      this.options.enableSlackAlerts = true;
      this.options.slackConfig = { ...this.options.slackConfig, ...config.slack };
    }
    
    if (config.webhook) {
      this.options.enableWebhooks = true;
      this.options.webhookConfig = { ...this.options.webhookConfig, ...config.webhook };
    }
  }

  /**
   * Test alert system
   */
  testAlerts() {
    const testAlert = {
      level: 'info',
      component: 'test',
      metric: 'system_check',
      message: 'This is a test alert to verify the alerting system is working',
      value: 'test',
      threshold: 'none'
    };
    
    this.triggerAlert(testAlert);
  }
}

module.exports = AlertingSystem;