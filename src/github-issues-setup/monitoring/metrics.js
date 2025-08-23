/**
 * Metrics Collection System for GitHub Issues Setup
 * Tracks auto-labeling accuracy, API usage, performance, and user engagement
 */

const EventEmitter = require('events');

class MetricsCollector extends EventEmitter {
  constructor(options = {}) {
    super();
    this.options = {
      retentionDays: options.retentionDays || 30,
      aggregationInterval: options.aggregationInterval || 300000, // 5 minutes
      enablePerformanceTracking: options.enablePerformanceTracking !== false,
      ...options
    };

    this.metrics = {
      autoLabeling: new Map(),
      apiUsage: new Map(),
      performance: new Map(),
      userEngagement: new Map(),
      errors: new Map(),
      system: new Map()
    };

    this.aggregatedData = {
      hourly: new Map(),
      daily: new Map()
    };

    this.startTime = Date.now();
    this.setupAggregation();
  }

  /**
   * Track auto-labeling performance
   * @param {Object} labelingEvent Labeling event data
   */
  trackAutoLabeling(labelingEvent) {
    const timestamp = Date.now();
    const key = this.getTimeKey(timestamp, 'minute');
    
    const event = {
      timestamp,
      issueId: labelingEvent.issueId,
      accuracy: labelingEvent.accuracy,
      confidence: labelingEvent.confidence,
      componentsDetected: labelingEvent.componentsDetected || [],
      priorityDetected: labelingEvent.priorityDetected,
      securityDetected: labelingEvent.securityDetected || false,
      processingTime: labelingEvent.processingTime,
      labelsApplied: labelingEvent.labelsApplied || [],
      manualOverride: labelingEvent.manualOverride || false
    };

    if (!this.metrics.autoLabeling.has(key)) {
      this.metrics.autoLabeling.set(key, []);
    }
    this.metrics.autoLabeling.get(key).push(event);

    this.emit('autoLabelingEvent', event);
    this.cleanup();
  }

  /**
   * Track GitHub API usage
   * @param {Object} apiEvent API usage event data
   */
  trackApiUsage(apiEvent) {
    const timestamp = Date.now();
    const key = this.getTimeKey(timestamp, 'minute');
    
    const event = {
      timestamp,
      endpoint: apiEvent.endpoint,
      method: apiEvent.method || 'GET',
      responseTime: apiEvent.responseTime,
      statusCode: apiEvent.statusCode,
      rateLimitRemaining: apiEvent.rateLimitRemaining,
      rateLimitReset: apiEvent.rateLimitReset,
      success: apiEvent.success !== false,
      errorType: apiEvent.errorType || null,
      retryCount: apiEvent.retryCount || 0
    };

    if (!this.metrics.apiUsage.has(key)) {
      this.metrics.apiUsage.set(key, []);
    }
    this.metrics.apiUsage.get(key).push(event);

    this.emit('apiUsageEvent', event);
    this.cleanup();
  }

  /**
   * Track system performance metrics
   * @param {Object} performanceEvent Performance event data
   */
  trackPerformance(performanceEvent) {
    if (!this.options.enablePerformanceTracking) return;

    const timestamp = Date.now();
    const key = this.getTimeKey(timestamp, 'minute');
    
    const event = {
      timestamp,
      operation: performanceEvent.operation,
      duration: performanceEvent.duration,
      memoryUsage: process.memoryUsage(),
      cpuUsage: process.cpuUsage(),
      concurrentOperations: performanceEvent.concurrentOperations || 1,
      success: performanceEvent.success !== false,
      errorType: performanceEvent.errorType || null
    };

    if (!this.metrics.performance.has(key)) {
      this.metrics.performance.set(key, []);
    }
    this.metrics.performance.get(key).push(event);

    this.emit('performanceEvent', event);
    this.cleanup();
  }

  /**
   * Track user engagement metrics
   * @param {Object} engagementEvent User engagement event data
   */
  trackUserEngagement(engagementEvent) {
    const timestamp = Date.now();
    const key = this.getTimeKey(timestamp, 'hour');
    
    const event = {
      timestamp,
      type: engagementEvent.type, // 'issue_created', 'template_used', 'label_override', etc.
      userId: engagementEvent.userId,
      repository: engagementEvent.repository,
      template: engagementEvent.template || null,
      completedFields: engagementEvent.completedFields || [],
      timeToComplete: engagementEvent.timeToComplete || null,
      satisfaction: engagementEvent.satisfaction || null // 1-5 rating if available
    };

    if (!this.metrics.userEngagement.has(key)) {
      this.metrics.userEngagement.set(key, []);
    }
    this.metrics.userEngagement.get(key).push(event);

    this.emit('userEngagementEvent', event);
    this.cleanup();
  }

  /**
   * Track error events
   * @param {Object} errorEvent Error event data
   */
  trackError(errorEvent) {
    const timestamp = Date.now();
    const key = this.getTimeKey(timestamp, 'minute');
    
    const event = {
      timestamp,
      component: errorEvent.component,
      errorType: errorEvent.errorType,
      errorMessage: errorEvent.errorMessage,
      stack: errorEvent.stack,
      severity: errorEvent.severity || 'error',
      context: errorEvent.context || {},
      resolved: false,
      resolvedAt: null
    };

    if (!this.metrics.errors.has(key)) {
      this.metrics.errors.set(key, []);
    }
    this.metrics.errors.get(key).push(event);

    this.emit('errorEvent', event);
    this.cleanup();
  }

  /**
   * Track system metrics
   * @param {Object} systemEvent System event data
   */
  trackSystem(systemEvent) {
    const timestamp = Date.now();
    const key = this.getTimeKey(timestamp, 'minute');
    
    const event = {
      timestamp,
      metric: systemEvent.metric, // 'startup', 'shutdown', 'health_check', etc.
      value: systemEvent.value,
      unit: systemEvent.unit || null,
      tags: systemEvent.tags || {},
      metadata: systemEvent.metadata || {}
    };

    if (!this.metrics.system.has(key)) {
      this.metrics.system.set(key, []);
    }
    this.metrics.system.get(key).push(event);

    this.emit('systemEvent', event);
    this.cleanup();
  }

  /**
   * Get auto-labeling accuracy metrics
   * @param {Object} options Query options
   * @returns {Object} Auto-labeling metrics
   */
  getAutoLabelingMetrics(options = {}) {
    const timeRange = this.getTimeRange(options);
    const events = this.getEventsInRange('autoLabeling', timeRange);

    if (events.length === 0) {
      return {
        totalEvents: 0,
        averageAccuracy: null,
        averageConfidence: null,
        averageProcessingTime: null,
        componentDetectionRate: null,
        securityDetectionRate: null,
        manualOverrideRate: null
      };
    }

    const accuracyValues = events.map(e => e.accuracy).filter(a => a !== null && a !== undefined);
    const confidenceValues = events.map(e => e.confidence).filter(c => c !== null && c !== undefined);
    const processingTimes = events.map(e => e.processingTime).filter(p => p !== null && p !== undefined);
    const componentsDetected = events.filter(e => e.componentsDetected && e.componentsDetected.length > 0);
    const securityDetected = events.filter(e => e.securityDetected === true);
    const manualOverrides = events.filter(e => e.manualOverride === true);

    return {
      totalEvents: events.length,
      averageAccuracy: accuracyValues.length > 0 ? accuracyValues.reduce((a, b) => a + b, 0) / accuracyValues.length : null,
      averageConfidence: confidenceValues.length > 0 ? confidenceValues.reduce((a, b) => a + b, 0) / confidenceValues.length : null,
      averageProcessingTime: processingTimes.length > 0 ? processingTimes.reduce((a, b) => a + b, 0) / processingTimes.length : null,
      componentDetectionRate: componentsDetected.length / events.length,
      securityDetectionRate: securityDetected.length / events.length,
      manualOverrideRate: manualOverrides.length / events.length,
      timeRange
    };
  }

  /**
   * Get API usage metrics
   * @param {Object} options Query options
   * @returns {Object} API usage metrics
   */
  getApiUsageMetrics(options = {}) {
    const timeRange = this.getTimeRange(options);
    const events = this.getEventsInRange('apiUsage', timeRange);

    if (events.length === 0) {
      return {
        totalRequests: 0,
        successRate: null,
        averageResponseTime: null,
        rateLimitUtilization: null,
        errorBreakdown: {}
      };
    }

    const successfulRequests = events.filter(e => e.success);
    const responseTimes = events.map(e => e.responseTime).filter(r => r !== null && r !== undefined);
    const rateLimits = events.map(e => e.rateLimitRemaining).filter(r => r !== null && r !== undefined);
    
    const errorBreakdown = {};
    events.filter(e => !e.success).forEach(e => {
      const errorType = e.errorType || 'unknown';
      errorBreakdown[errorType] = (errorBreakdown[errorType] || 0) + 1;
    });

    return {
      totalRequests: events.length,
      successRate: successfulRequests.length / events.length,
      averageResponseTime: responseTimes.length > 0 ? responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length : null,
      rateLimitUtilization: rateLimits.length > 0 ? Math.min(...rateLimits) : null,
      errorBreakdown,
      timeRange
    };
  }

  /**
   * Get performance metrics
   * @param {Object} options Query options
   * @returns {Object} Performance metrics
   */
  getPerformanceMetrics(options = {}) {
    const timeRange = this.getTimeRange(options);
    const events = this.getEventsInRange('performance', timeRange);

    if (events.length === 0) {
      return {
        totalOperations: 0,
        averageDuration: null,
        operationBreakdown: {},
        memoryStats: null,
        throughput: null
      };
    }

    const durations = events.map(e => e.duration).filter(d => d !== null && d !== undefined);
    const operationBreakdown = {};
    const memoryUsages = events.map(e => e.memoryUsage.heapUsed).filter(m => m !== null && m !== undefined);

    events.forEach(e => {
      const operation = e.operation || 'unknown';
      if (!operationBreakdown[operation]) {
        operationBreakdown[operation] = { count: 0, totalDuration: 0 };
      }
      operationBreakdown[operation].count++;
      if (e.duration) {
        operationBreakdown[operation].totalDuration += e.duration;
      }
    });

    // Calculate throughput (operations per minute)
    const timeRangeMinutes = (timeRange.end - timeRange.start) / (1000 * 60);
    const throughput = timeRangeMinutes > 0 ? events.length / timeRangeMinutes : null;

    return {
      totalOperations: events.length,
      averageDuration: durations.length > 0 ? durations.reduce((a, b) => a + b, 0) / durations.length : null,
      operationBreakdown,
      memoryStats: memoryUsages.length > 0 ? {
        average: memoryUsages.reduce((a, b) => a + b, 0) / memoryUsages.length,
        max: Math.max(...memoryUsages),
        min: Math.min(...memoryUsages)
      } : null,
      throughput,
      timeRange
    };
  }

  /**
   * Get error metrics
   * @param {Object} options Query options
   * @returns {Object} Error metrics
   */
  getErrorMetrics(options = {}) {
    const timeRange = this.getTimeRange(options);
    const events = this.getEventsInRange('errors', timeRange);

    if (events.length === 0) {
      return {
        totalErrors: 0,
        errorRate: 0,
        severityBreakdown: {},
        componentBreakdown: {},
        topErrors: []
      };
    }

    const severityBreakdown = {};
    const componentBreakdown = {};
    const errorTypeCount = {};

    events.forEach(e => {
      const severity = e.severity || 'unknown';
      const component = e.component || 'unknown';
      const errorType = e.errorType || 'unknown';

      severityBreakdown[severity] = (severityBreakdown[severity] || 0) + 1;
      componentBreakdown[component] = (componentBreakdown[component] || 0) + 1;
      errorTypeCount[errorType] = (errorTypeCount[errorType] || 0) + 1;
    });

    const topErrors = Object.entries(errorTypeCount)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([errorType, count]) => ({ errorType, count }));

    return {
      totalErrors: events.length,
      errorRate: events.length / Math.max(1, (timeRange.end - timeRange.start) / (1000 * 60)), // errors per minute
      severityBreakdown,
      componentBreakdown,
      topErrors,
      timeRange
    };
  }

  /**
   * Get comprehensive system summary
   * @param {Object} options Query options
   * @returns {Object} System metrics summary
   */
  getSystemSummary(options = {}) {
    const timeRange = this.getTimeRange(options);
    
    return {
      timeRange,
      uptime: Date.now() - this.startTime,
      autoLabeling: this.getAutoLabelingMetrics(options),
      apiUsage: this.getApiUsageMetrics(options),
      performance: this.getPerformanceMetrics(options),
      errors: this.getErrorMetrics(options),
      dataRetention: {
        totalEvents: this.getTotalEventCount(),
        oldestEvent: this.getOldestEventTimestamp(),
        dataSize: this.getDataSize()
      }
    };
  }

  /**
   * Export metrics data for external analysis
   * @param {Object} options Export options
   * @returns {Object} Exportable metrics data
   */
  exportMetrics(options = {}) {
    const format = options.format || 'json';
    const timeRange = this.getTimeRange(options);
    
    const exportData = {
      metadata: {
        exportedAt: new Date().toISOString(),
        timeRange,
        format,
        systemUptime: Date.now() - this.startTime
      },
      autoLabeling: this.getEventsInRange('autoLabeling', timeRange),
      apiUsage: this.getEventsInRange('apiUsage', timeRange),
      performance: this.getEventsInRange('performance', timeRange),
      userEngagement: this.getEventsInRange('userEngagement', timeRange),
      errors: this.getEventsInRange('errors', timeRange),
      system: this.getEventsInRange('system', timeRange)
    };

    if (format === 'csv') {
      return this.convertToCSV(exportData);
    }

    return exportData;
  }

  /**
   * Set up data aggregation for long-term storage
   * @private
   */
  setupAggregation() {
    setInterval(() => {
      this.aggregateData();
    }, this.options.aggregationInterval);
  }

  /**
   * Aggregate raw data into hourly and daily summaries
   * @private
   */
  aggregateData() {
    const now = Date.now();
    const hourKey = this.getTimeKey(now, 'hour');
    const dayKey = this.getTimeKey(now, 'day');

    // Aggregate hourly data
    if (!this.aggregatedData.hourly.has(hourKey)) {
      const hourStart = now - (now % (1000 * 60 * 60));
      const hourEnd = hourStart + (1000 * 60 * 60);
      
      this.aggregatedData.hourly.set(hourKey, {
        timestamp: hourStart,
        autoLabeling: this.getAutoLabelingMetrics({ start: hourStart, end: hourEnd }),
        apiUsage: this.getApiUsageMetrics({ start: hourStart, end: hourEnd }),
        performance: this.getPerformanceMetrics({ start: hourStart, end: hourEnd }),
        errors: this.getErrorMetrics({ start: hourStart, end: hourEnd })
      });
    }

    // Aggregate daily data
    if (!this.aggregatedData.daily.has(dayKey)) {
      const dayStart = now - (now % (1000 * 60 * 60 * 24));
      const dayEnd = dayStart + (1000 * 60 * 60 * 24);
      
      this.aggregatedData.daily.set(dayKey, {
        timestamp: dayStart,
        autoLabeling: this.getAutoLabelingMetrics({ start: dayStart, end: dayEnd }),
        apiUsage: this.getApiUsageMetrics({ start: dayStart, end: dayEnd }),
        performance: this.getPerformanceMetrics({ start: dayStart, end: dayEnd }),
        errors: this.getErrorMetrics({ start: dayStart, end: dayEnd })
      });
    }

    this.cleanup();
  }

  /**
   * Clean up old data based on retention policy
   * @private
   */
  cleanup() {
    const cutoffTime = Date.now() - (this.options.retentionDays * 24 * 60 * 60 * 1000);
    
    for (const [category, dataMap] of Object.entries(this.metrics)) {
      for (const [timeKey, events] of dataMap.entries()) {
        if (events.length > 0 && events[0].timestamp < cutoffTime) {
          dataMap.delete(timeKey);
        }
      }
    }

    // Clean up aggregated data
    for (const [timeKey, data] of this.aggregatedData.hourly.entries()) {
      if (data.timestamp < cutoffTime) {
        this.aggregatedData.hourly.delete(timeKey);
      }
    }

    for (const [timeKey, data] of this.aggregatedData.daily.entries()) {
      if (data.timestamp < cutoffTime) {
        this.aggregatedData.daily.delete(timeKey);
      }
    }
  }

  /**
   * Generate time key for data organization
   * @private
   */
  getTimeKey(timestamp, granularity) {
    const date = new Date(timestamp);
    
    switch (granularity) {
      case 'minute':
        return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
      case 'hour':
        return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')} ${String(date.getHours()).padStart(2, '0')}:00`;
      case 'day':
        return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
      default:
        return String(timestamp);
    }
  }

  /**
   * Get time range for queries
   * @private
   */
  getTimeRange(options) {
    const end = options.end || Date.now();
    const start = options.start || (end - (24 * 60 * 60 * 1000)); // Default to last 24 hours
    
    return { start, end };
  }

  /**
   * Get events within time range
   * @private
   */
  getEventsInRange(category, timeRange) {
    const events = [];
    const dataMap = this.metrics[category];
    
    if (!dataMap) return events;
    
    for (const eventList of dataMap.values()) {
      for (const event of eventList) {
        if (event.timestamp >= timeRange.start && event.timestamp <= timeRange.end) {
          events.push(event);
        }
      }
    }
    
    return events.sort((a, b) => a.timestamp - b.timestamp);
  }

  /**
   * Get total event count across all categories
   * @private
   */
  getTotalEventCount() {
    let total = 0;
    for (const dataMap of Object.values(this.metrics)) {
      for (const eventList of dataMap.values()) {
        total += eventList.length;
      }
    }
    return total;
  }

  /**
   * Get oldest event timestamp
   * @private
   */
  getOldestEventTimestamp() {
    let oldest = Date.now();
    for (const dataMap of Object.values(this.metrics)) {
      for (const eventList of dataMap.values()) {
        for (const event of eventList) {
          if (event.timestamp < oldest) {
            oldest = event.timestamp;
          }
        }
      }
    }
    return oldest;
  }

  /**
   * Get approximate data size in bytes
   * @private
   */
  getDataSize() {
    return JSON.stringify(this.metrics).length;
  }

  /**
   * Convert data to CSV format
   * @private
   */
  convertToCSV(data) {
    // Implementation for CSV conversion would go here
    // This is a simplified placeholder
    return {
      message: 'CSV export not implemented in this version',
      data: data
    };
  }
}

module.exports = MetricsCollector;