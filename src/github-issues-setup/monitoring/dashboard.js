/**
 * Dashboard System for GitHub Issues Setup
 * Real-time metrics display and historical trend analysis
 */

class DashboardSystem {
  constructor(healthChecker, metricsCollector, alertingSystem, options = {}) {
    this.healthChecker = healthChecker;
    this.metricsCollector = metricsCollector;
    this.alertingSystem = alertingSystem;
    
    this.options = {
      refreshInterval: options.refreshInterval || 30000, // 30 seconds
      historyHours: options.historyHours || 24,
      maxDataPoints: options.maxDataPoints || 100,
      enableRealtime: options.enableRealtime !== false,
      port: options.port || 3000,
      ...options
    };

    this.dashboardData = {
      timestamp: new Date().toISOString(),
      health: null,
      metrics: null,
      alerts: null,
      trends: null
    };

    if (this.options.enableRealtime) {
      this.setupRealtimeUpdates();
    }
  }

  /**
   * Get complete dashboard data
   * @param {string} githubToken GitHub API token
   * @returns {Promise<Object>} Dashboard data
   */
  async getDashboardData(githubToken) {
    const startTime = Date.now();
    
    try {
      // Get current health status
      const health = await this.healthChecker.performHealthCheck(githubToken);
      
      // Get metrics summary
      const metrics = this.metricsCollector.getSystemSummary({
        start: Date.now() - (this.options.historyHours * 60 * 60 * 1000),
        end: Date.now()
      });
      
      // Get alert information
      const alerts = {
        active: this.alertingSystem.getActiveAlerts(),
        recent: this.alertingSystem.getAlertHistory({ limit: 10 }),
        stats: this.alertingSystem.getAlertStats({
          startTime: new Date(Date.now() - (24 * 60 * 60 * 1000)).toISOString()
        })
      };
      
      // Get trend data
      const trends = await this.generateTrendData(githubToken);
      
      this.dashboardData = {
        timestamp: new Date().toISOString(),
        generationTime: Date.now() - startTime,
        health,
        metrics,
        alerts,
        trends,
        summary: this.generateSummary(health, metrics, alerts)
      };

      return this.dashboardData;

    } catch (error) {
      console.error('Failed to generate dashboard data:', error);
      return {
        timestamp: new Date().toISOString(),
        generationTime: Date.now() - startTime,
        error: error.message,
        health: { overall: 'unknown' },
        metrics: {},
        alerts: { active: [], recent: [], stats: {} },
        trends: {}
      };
    }
  }

  /**
   * Generate HTML dashboard
   * @param {string} githubToken GitHub API token
   * @returns {Promise<string>} HTML dashboard
   */
  async generateHTMLDashboard(githubToken) {
    const data = await this.getDashboardData(githubToken);
    
    return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GitHub Issues Setup - System Dashboard</title>
    <style>
        ${this.getCSS()}
    </style>
</head>
<body>
    <div class="dashboard">
        ${this.generateHeader(data)}
        ${this.generateHealthSection(data.health)}
        ${this.generateMetricsSection(data.metrics)}
        ${this.generateAlertsSection(data.alerts)}
        ${this.generateTrendsSection(data.trends)}
        ${this.generateFooter(data)}
    </div>
    
    <script>
        ${this.getJavaScript()}
    </script>
</body>
</html>`;
  }

  /**
   * Generate system summary
   * @private
   * @param {Object} health Health data
   * @param {Object} metrics Metrics data
   * @param {Object} alerts Alert data
   * @returns {Object} System summary
   */
  generateSummary(health, metrics, alerts) {
    const summary = {
      overallStatus: health.overall || 'unknown',
      healthyComponents: 0,
      totalComponents: 0,
      activeAlerts: alerts.active ? alerts.active.length : 0,
      criticalAlerts: 0,
      keyMetrics: {},
      recommendations: []
    };

    // Analyze health
    if (health.components) {
      Object.values(health.components).forEach(component => {
        summary.totalComponents++;
        if (component.status === 'healthy') {
          summary.healthyComponents++;
        }
      });
    }

    // Count critical alerts
    if (alerts.active) {
      summary.criticalAlerts = alerts.active.filter(alert => alert.level === 'critical').length;
    }

    // Extract key metrics
    if (metrics.autoLabeling) {
      summary.keyMetrics.labelingAccuracy = metrics.autoLabeling.averageAccuracy;
      summary.keyMetrics.labelingProcessingTime = metrics.autoLabeling.averageProcessingTime;
    }

    if (metrics.apiUsage) {
      summary.keyMetrics.apiSuccessRate = metrics.apiUsage.successRate;
      summary.keyMetrics.apiResponseTime = metrics.apiUsage.averageResponseTime;
    }

    if (metrics.performance) {
      summary.keyMetrics.memoryUsage = metrics.performance.memoryStats ? metrics.performance.memoryStats.average : null;
      summary.keyMetrics.throughput = metrics.performance.throughput;
    }

    // Generate recommendations
    summary.recommendations = this.generateRecommendations(health, metrics, alerts);

    return summary;
  }

  /**
   * Generate system recommendations
   * @private
   * @param {Object} health Health data
   * @param {Object} metrics Metrics data
   * @param {Object} alerts Alert data
   * @returns {Array} Array of recommendations
   */
  generateRecommendations(health, metrics, alerts) {
    const recommendations = [];

    // Health-based recommendations
    if (health.overall === 'unhealthy') {
      recommendations.push({
        type: 'critical',
        title: 'System Health Issues',
        message: 'Multiple components are unhealthy. Immediate attention required.',
        action: 'Check component health details and error logs'
      });
    } else if (health.overall === 'degraded') {
      recommendations.push({
        type: 'warning',
        title: 'Performance Degradation',
        message: 'Some components are experiencing issues.',
        action: 'Review degraded components and optimize performance'
      });
    }

    // Metrics-based recommendations
    if (metrics.autoLabeling && metrics.autoLabeling.averageAccuracy !== null) {
      if (metrics.autoLabeling.averageAccuracy < 0.8) {
        recommendations.push({
          type: 'warning',
          title: 'Auto-labeling Accuracy Low',
          message: `Accuracy is ${(metrics.autoLabeling.averageAccuracy * 100).toFixed(1)}%`,
          action: 'Review training data and component mappings'
        });
      }

      if (metrics.autoLabeling.manualOverrideRate > 0.3) {
        recommendations.push({
          type: 'info',
          title: 'High Manual Override Rate',
          message: `${(metrics.autoLabeling.manualOverrideRate * 100).toFixed(1)}% of labels are manually overridden`,
          action: 'Analyze override patterns to improve automatic labeling'
        });
      }
    }

    if (metrics.apiUsage && metrics.apiUsage.successRate !== null) {
      if (metrics.apiUsage.successRate < 0.95) {
        recommendations.push({
          type: 'warning',
          title: 'API Reliability Issues',
          message: `API success rate is ${(metrics.apiUsage.successRate * 100).toFixed(1)}%`,
          action: 'Check GitHub API status and authentication'
        });
      }
    }

    // Alert-based recommendations
    if (alerts.active && alerts.active.length > 5) {
      recommendations.push({
        type: 'warning',
        title: 'Multiple Active Alerts',
        message: `${alerts.active.length} alerts are currently active`,
        action: 'Review and resolve active alerts to prevent cascading issues'
      });
    }

    // Performance recommendations
    if (metrics.performance && metrics.performance.memoryStats) {
      const memoryMB = metrics.performance.memoryStats.average / 1024 / 1024;
      if (memoryMB > 400) {
        recommendations.push({
          type: 'info',
          title: 'Memory Usage Elevated',
          message: `Average memory usage is ${memoryMB.toFixed(1)}MB`,
          action: 'Monitor memory usage trends and consider optimization'
        });
      }
    }

    return recommendations;
  }

  /**
   * Generate trend data for visualization
   * @private
   * @param {string} githubToken GitHub API token
   * @returns {Promise<Object>} Trend data
   */
  async generateTrendData(githubToken) {
    const trends = {
      healthHistory: [],
      metricsHistory: [],
      alertsHistory: [],
      timeRange: {
        start: Date.now() - (this.options.historyHours * 60 * 60 * 1000),
        end: Date.now()
      }
    };

    try {
      // Get health history
      trends.healthHistory = this.healthChecker.getHealthHistory()
        .slice(-this.options.maxDataPoints)
        .map(h => ({
          timestamp: h.timestamp,
          status: h.overall,
          components: Object.keys(h.components || {}).length,
          alerts: h.alerts ? h.alerts.length : 0
        }));

      // Generate metrics history (simplified for demo)
      const hoursBack = this.options.historyHours;
      const intervalMinutes = Math.max(1, Math.floor((hoursBack * 60) / this.options.maxDataPoints));
      
      for (let i = hoursBack; i >= 0; i -= (intervalMinutes / 60)) {
        const timestamp = Date.now() - (i * 60 * 60 * 1000);
        const timeRange = {
          start: timestamp - (intervalMinutes * 60 * 1000),
          end: timestamp
        };

        const metrics = this.metricsCollector.getSystemSummary(timeRange);
        
        trends.metricsHistory.push({
          timestamp: new Date(timestamp).toISOString(),
          autoLabeling: {
            accuracy: metrics.autoLabeling.averageAccuracy,
            processingTime: metrics.autoLabeling.averageProcessingTime
          },
          apiUsage: {
            successRate: metrics.apiUsage.successRate,
            responseTime: metrics.apiUsage.averageResponseTime,
            requestCount: metrics.apiUsage.totalRequests
          },
          performance: {
            throughput: metrics.performance.throughput,
            memoryUsage: metrics.performance.memoryStats ? metrics.performance.memoryStats.average : null
          }
        });
      }

      // Get alert trends
      const alertHistory = this.alertingSystem.getAlertHistory({
        startTime: new Date(trends.timeRange.start).toISOString(),
        limit: this.options.maxDataPoints * 2
      });

      // Group alerts by hour
      const alertsByHour = {};
      alertHistory.forEach(alert => {
        const hourKey = new Date(alert.timestamp).toISOString().substring(0, 13);
        if (!alertsByHour[hourKey]) {
          alertsByHour[hourKey] = { total: 0, critical: 0, warning: 0, info: 0 };
        }
        alertsByHour[hourKey].total++;
        alertsByHour[hourKey][alert.level]++;
      });

      trends.alertsHistory = Object.entries(alertsByHour)
        .map(([hour, counts]) => ({
          timestamp: hour + ':00:00.000Z',
          ...counts
        }))
        .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp))
        .slice(-this.options.maxDataPoints);

    } catch (error) {
      console.error('Failed to generate trend data:', error);
    }

    return trends;
  }

  /**
   * Set up real-time updates
   * @private
   */
  setupRealtimeUpdates() {
    setInterval(() => {
      // This would trigger dashboard refresh in a real implementation
      // For now, we just update the timestamp
      this.dashboardData.timestamp = new Date().toISOString();
    }, this.options.refreshInterval);
  }

  /**
   * Generate HTML header
   * @private
   */
  generateHeader(data) {
    const statusColor = data.health.overall === 'healthy' ? '#28a745' : 
                       data.health.overall === 'degraded' ? '#ffc107' : '#dc3545';

    return `
    <header class="header">
        <h1>GitHub Issues Setup - System Dashboard</h1>
        <div class="status-indicator">
            <div class="status-dot" style="background-color: ${statusColor}"></div>
            <span class="status-text">${data.health.overall.toUpperCase()}</span>
            <small class="timestamp">Last updated: ${new Date(data.timestamp).toLocaleString()}</small>
        </div>
    </header>`;
  }

  /**
   * Generate health section HTML
   * @private
   */
  generateHealthSection(health) {
    const components = Object.entries(health.components || {});
    
    return `
    <section class="health-section">
        <h2>System Health</h2>
        <div class="health-grid">
            ${components.map(([name, component]) => `
                <div class="health-card ${component.status}">
                    <h3>${name.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}</h3>
                    <div class="status">${component.status}</div>
                    ${component.errors && component.errors.length > 0 ? 
                        `<div class="errors">${component.errors.join('<br>')}</div>` : ''}
                    ${component.responseTime ? `<div class="metric">Response: ${component.responseTime}ms</div>` : ''}
                    ${component.accuracy ? `<div class="metric">Accuracy: ${(component.accuracy * 100).toFixed(1)}%</div>` : ''}
                </div>
            `).join('')}
        </div>
    </section>`;
  }

  /**
   * Generate metrics section HTML
   * @private
   */
  generateMetricsSection(metrics) {
    return `
    <section class="metrics-section">
        <h2>System Metrics</h2>
        <div class="metrics-grid">
            <div class="metric-card">
                <h3>Auto-labeling Performance</h3>
                <div class="metric-value">${metrics.autoLabeling.averageAccuracy ? (metrics.autoLabeling.averageAccuracy * 100).toFixed(1) + '%' : 'N/A'}</div>
                <div class="metric-label">Accuracy</div>
                <div class="metric-details">
                    <span>Processing Time: ${metrics.autoLabeling.averageProcessingTime ? (metrics.autoLabeling.averageProcessingTime / 1000).toFixed(1) + 's' : 'N/A'}</span>
                    <span>Override Rate: ${metrics.autoLabeling.manualOverrideRate ? (metrics.autoLabeling.manualOverrideRate * 100).toFixed(1) + '%' : 'N/A'}</span>
                </div>
            </div>
            
            <div class="metric-card">
                <h3>API Performance</h3>
                <div class="metric-value">${metrics.apiUsage.successRate ? (metrics.apiUsage.successRate * 100).toFixed(1) + '%' : 'N/A'}</div>
                <div class="metric-label">Success Rate</div>
                <div class="metric-details">
                    <span>Response Time: ${metrics.apiUsage.averageResponseTime ? metrics.apiUsage.averageResponseTime.toFixed(0) + 'ms' : 'N/A'}</span>
                    <span>Total Requests: ${metrics.apiUsage.totalRequests || 0}</span>
                </div>
            </div>
            
            <div class="metric-card">
                <h3>System Performance</h3>
                <div class="metric-value">${metrics.performance.throughput ? metrics.performance.throughput.toFixed(1) : 'N/A'}</div>
                <div class="metric-label">Ops/Min</div>
                <div class="metric-details">
                    <span>Memory: ${metrics.performance.memoryStats ? (metrics.performance.memoryStats.average / 1024 / 1024).toFixed(1) + 'MB' : 'N/A'}</span>
                    <span>Operations: ${metrics.performance.totalOperations || 0}</span>
                </div>
            </div>
            
            <div class="metric-card">
                <h3>Error Rate</h3>
                <div class="metric-value">${metrics.errors.errorRate ? metrics.errors.errorRate.toFixed(2) : '0.00'}</div>
                <div class="metric-label">Errors/Min</div>
                <div class="metric-details">
                    <span>Total Errors: ${metrics.errors.totalErrors || 0}</span>
                    <span>Critical: ${metrics.errors.severityBreakdown ? (metrics.errors.severityBreakdown.critical || 0) : 0}</span>
                </div>
            </div>
        </div>
    </section>`;
  }

  /**
   * Generate alerts section HTML
   * @private
   */
  generateAlertsSection(alerts) {
    return `
    <section class="alerts-section">
        <h2>Alerts</h2>
        <div class="alerts-summary">
            <div class="alert-count critical">Critical: ${alerts.active.filter(a => a.level === 'critical').length}</div>
            <div class="alert-count warning">Warning: ${alerts.active.filter(a => a.level === 'warning').length}</div>
            <div class="alert-count info">Info: ${alerts.active.filter(a => a.level === 'info').length}</div>
        </div>
        
        ${alerts.active.length > 0 ? `
            <div class="active-alerts">
                <h3>Active Alerts</h3>
                ${alerts.active.slice(0, 5).map(alert => `
                    <div class="alert-item ${alert.level}">
                        <div class="alert-header">
                            <span class="alert-component">${alert.component}</span>
                            <span class="alert-level">${alert.level}</span>
                            <span class="alert-time">${new Date(alert.timestamp).toLocaleTimeString()}</span>
                        </div>
                        <div class="alert-message">${alert.message}</div>
                    </div>
                `).join('')}
            </div>
        ` : '<div class="no-alerts">No active alerts</div>'}
    </section>`;
  }

  /**
   * Generate trends section HTML
   * @private
   */
  generateTrendsSection(trends) {
    return `
    <section class="trends-section">
        <h2>Trends</h2>
        <div class="trends-placeholder">
            <p>Trend visualization would be implemented here with a charting library like Chart.js or D3.js</p>
            <div class="trend-summary">
                <p>Health History: ${trends.healthHistory.length} data points</p>
                <p>Metrics History: ${trends.metricsHistory.length} data points</p>
                <p>Alerts History: ${trends.alertsHistory.length} data points</p>
                <p>Time Range: ${Math.floor((trends.timeRange.end - trends.timeRange.start) / (1000 * 60 * 60))} hours</p>
            </div>
        </div>
    </section>`;
  }

  /**
   * Generate footer HTML
   * @private
   */
  generateFooter(data) {
    return `
    <footer class="footer">
        <div class="footer-content">
            <p>Dashboard generated in ${data.generationTime}ms | System uptime: ${Math.floor(data.health.uptime / (1000 * 60))} minutes</p>
            <p>GitHub Issues Setup Monitoring System v1.0</p>
        </div>
    </footer>`;
  }

  /**
   * Get CSS styles for the dashboard
   * @private
   */
  getCSS() {
    return `
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f8f9fa;
        }
        
        .dashboard { max-width: 1200px; margin: 0 auto; padding: 20px; }
        
        .header {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .status-indicator {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .status-dot {
            width: 12px;
            height: 12px;
            border-radius: 50%;
        }
        
        .health-section, .metrics-section, .alerts-section, .trends-section {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        
        .health-grid, .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 15px;
        }
        
        .health-card, .metric-card {
            padding: 15px;
            border: 1px solid #ddd;
            border-radius: 6px;
            background: #f8f9fa;
        }
        
        .health-card.healthy { border-color: #28a745; }
        .health-card.degraded { border-color: #ffc107; }
        .health-card.unhealthy { border-color: #dc3545; }
        
        .metric-value {
            font-size: 2em;
            font-weight: bold;
            color: #007bff;
        }
        
        .alerts-summary {
            display: flex;
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .alert-count {
            padding: 10px 15px;
            border-radius: 6px;
            font-weight: bold;
        }
        
        .alert-count.critical { background: #ffe6e6; color: #dc3545; }
        .alert-count.warning { background: #fff8e1; color: #ffc107; }
        .alert-count.info { background: #e3f2fd; color: #007bff; }
        
        .alert-item {
            padding: 10px;
            margin-bottom: 10px;
            border-radius: 6px;
            border-left: 4px solid;
        }
        
        .alert-item.critical { border-color: #dc3545; background: #ffe6e6; }
        .alert-item.warning { border-color: #ffc107; background: #fff8e1; }
        .alert-item.info { border-color: #007bff; background: #e3f2fd; }
        
        .alert-header {
            display: flex;
            justify-content: space-between;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .trends-placeholder {
            text-align: center;
            padding: 40px;
            color: #666;
        }
        
        .footer {
            text-align: center;
            padding: 20px;
            color: #666;
            font-size: 0.9em;
        }
        
        @media (max-width: 768px) {
            .header { flex-direction: column; gap: 15px; }
            .health-grid, .metrics-grid { grid-template-columns: 1fr; }
            .alerts-summary { flex-direction: column; }
        }
    `;
  }

  /**
   * Get JavaScript for dashboard interactivity
   * @private
   */
  getJavaScript() {
    return `
        // Auto-refresh dashboard every 30 seconds
        setInterval(function() {
            if (window.location.hash !== '#no-refresh') {
                window.location.reload();
            }
        }, 30000);
        
        // Add click handlers for interactive elements
        document.addEventListener('DOMContentLoaded', function() {
            console.log('GitHub Issues Setup Dashboard loaded');
        });
    `;
  }

  /**
   * Generate JSON API response
   * @param {string} githubToken GitHub API token
   * @returns {Promise<Object>} JSON dashboard data
   */
  async generateJSONDashboard(githubToken) {
    return await this.getDashboardData(githubToken);
  }

  /**
   * Generate text summary for CLI
   * @param {string} githubToken GitHub API token
   * @returns {Promise<string>} Text summary
   */
  async generateTextSummary(githubToken) {
    const data = await this.getDashboardData(githubToken);
    
    let summary = `GitHub Issues Setup - System Status\n`;
    summary += `${'='.repeat(50)}\n\n`;
    
    summary += `Overall Status: ${data.health.overall.toUpperCase()}\n`;
    summary += `Last Updated: ${new Date(data.timestamp).toLocaleString()}\n\n`;
    
    // Health summary
    summary += `Health Status:\n`;
    Object.entries(data.health.components || {}).forEach(([name, component]) => {
      const status = component.status === 'healthy' ? '✅' : 
                    component.status === 'degraded' ? '⚠️' : '❌';
      summary += `  ${status} ${name}: ${component.status}\n`;
    });
    
    // Key metrics
    summary += `\nKey Metrics:\n`;
    if (data.metrics.autoLabeling.averageAccuracy !== null) {
      summary += `  Auto-labeling Accuracy: ${(data.metrics.autoLabeling.averageAccuracy * 100).toFixed(1)}%\n`;
    }
    if (data.metrics.apiUsage.successRate !== null) {
      summary += `  API Success Rate: ${(data.metrics.apiUsage.successRate * 100).toFixed(1)}%\n`;
    }
    
    // Active alerts
    summary += `\nActive Alerts: ${data.alerts.active.length}\n`;
    if (data.alerts.active.length > 0) {
      data.alerts.active.slice(0, 3).forEach(alert => {
        const level = alert.level === 'critical' ? '🔴' : 
                     alert.level === 'warning' ? '🟡' : '🔵';
        summary += `  ${level} ${alert.component}: ${alert.message}\n`;
      });
    }
    
    summary += `\nGenerated in ${data.generationTime}ms\n`;
    
    return summary;
  }
}

module.exports = DashboardSystem;