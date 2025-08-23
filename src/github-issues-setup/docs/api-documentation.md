# GitHub Issues Setup - API Documentation

## Overview

This document provides comprehensive API documentation for all utilities, classes, and functions in the GitHub Issues Setup system. The system is organized into several modules, each with specific responsibilities.

## Table of Contents

- [GitHub API Client](#github-api-client)
- [Auto-labeling System](#auto-labeling-system)
- [Monitoring System](#monitoring-system)
- [Health Check System](#health-check-system)  
- [Metrics Collector](#metrics-collector)
- [Alerting System](#alerting-system)
- [Dashboard System](#dashboard-system)
- [Utility Scripts](#utility-scripts)

## GitHub API Client

**File**: `utils/github-api.js`

### Class: GitHubApiClient

A rate-limited, authenticated GitHub API client with comprehensive error handling.

#### Constructor

```javascript
const client = new GitHubApiClient(token, options = {})
```

**Parameters:**
- `token` (string): GitHub Personal Access Token
- `options` (object): Optional configuration
  - `rateLimitBuffer` (number): Buffer percentage for rate limiting (default: 0.2)

**Example:**
```javascript
const GitHubApiClient = require('./utils/github-api');
const client = new GitHubApiClient(process.env.GITHUB_TOKEN, {
  rateLimitBuffer: 0.3  // 30% buffer
});
```

#### Methods

##### `checkRateLimit()`

Check current GitHub API rate limit status.

**Returns:** Promise<Object>
- `limit` (number): Total rate limit
- `remaining` (number): Remaining requests
- `reset` (number): Reset timestamp

**Example:**
```javascript
const rateLimit = await client.checkRateLimit();
console.log(`${rateLimit.remaining}/${rateLimit.limit} requests remaining`);
```

##### `isWithinRateLimit()`

Check if current usage is within the configured buffer.

**Returns:** Promise<boolean>

**Example:**
```javascript
if (await client.isWithinRateLimit()) {
  // Safe to make requests
}
```

##### `getAuthenticatedUser()`

Get authenticated user information.

**Returns:** Promise<Object> - GitHub user data

**Example:**
```javascript
const user = await client.getAuthenticatedUser();
console.log(`Authenticated as: ${user.login}`);
```

##### `createIssue(owner, repo, title, body, labels = [])`

Create a new GitHub issue.

**Parameters:**
- `owner` (string): Repository owner
- `repo` (string): Repository name  
- `title` (string): Issue title
- `body` (string): Issue body
- `labels` (array): Initial labels

**Returns:** Promise<Object> - Created issue data

**Example:**
```javascript
const issue = await client.createIssue('owner', 'repo', 'Bug Report', 'Description', ['bug', 'priority:high']);
console.log(`Created issue #${issue.number}`);
```

##### `getIssue(owner, repo, issueNumber)`

Get issue details by number.

**Parameters:**
- `owner` (string): Repository owner
- `repo` (string): Repository name
- `issueNumber` (number): Issue number

**Returns:** Promise<Object> - Issue data

##### `addLabels(owner, repo, issueNumber, labels)`

Add labels to an existing issue.

**Parameters:**
- `owner` (string): Repository owner
- `repo` (string): Repository name
- `issueNumber` (number): Issue number
- `labels` (array): Labels to add

**Returns:** Promise<Object> - Updated issue data

##### `syncLabels(owner, repo, labels)`

Create or update repository labels.

**Parameters:**
- `owner` (string): Repository owner
- `repo` (string): Repository name
- `labels` (array): Label definitions with name, color, description

**Returns:** Promise<Array> - Sync results

**Example:**
```javascript
const labels = [
  { name: 'bug', color: 'dc3545', description: 'Something is not working' },
  { name: 'enhancement', color: '28a745', description: 'New feature or request' }
];
const results = await client.syncLabels('owner', 'repo', labels);
```

## Auto-labeling System

**File**: `utils/auto-labeling.js`

### Functions

#### `analyzeIssueContent(title, body)`

Analyze issue content and return appropriate labels with confidence scores.

**Parameters:**
- `title` (string): Issue title
- `body` (string): Issue body

**Returns:** Object
- `labels` (array): Recommended labels
- `analysis` (object): Detailed analysis
  - `components` (array): Detected components
  - `priority` (string): Detected priority
  - `security` (boolean): Security issue flag
- `confidence` (number): Overall confidence score (0-1)

**Example:**
```javascript
const { analyzeIssueContent } = require('./utils/auto-labeling');

const analysis = analyzeIssueContent(
  'Bug in spec-analyst component',
  'The framework/agents/spec-analyst.md file has critical issues'
);

console.log('Labels:', analysis.labels);
console.log('Confidence:', analysis.confidence);
```

#### `detectComponents(content)`

Detect framework components mentioned in content.

**Parameters:**
- `content` (string): Combined title and body text

**Returns:** Array<string> - Component labels

#### `detectPriority(content)`

Detect priority level based on content keywords.

**Parameters:**
- `content` (string): Combined title and body text

**Returns:** string - Priority label

#### `isSecurityRelated(content)`

Check if issue is security-related.

**Parameters:**
- `content` (string): Combined title and body text

**Returns:** boolean

#### `generateLabelExplanation(labels, analysis)`

Generate human-readable explanation for applied labels.

**Parameters:**
- `labels` (array): Applied labels
- `analysis` (object): Analysis results

**Returns:** string - Explanation text

#### `testAccuracy(testCases)`

Test labeling accuracy against known test cases.

**Parameters:**
- `testCases` (array): Array of test objects with `title`, `body`, and `expected` labels

**Returns:** Object
- `accuracy` (number): Overall accuracy (0-1)
- `totalTests` (number): Number of tests
- `correctPredictions` (number): Number of correct predictions
- `results` (array): Detailed test results

**Example:**
```javascript
const testCases = [
  {
    title: 'Installation problem',
    body: 'install.sh script fails',
    expected: ['component:installation', 'priority:normal']
  }
];

const results = testAccuracy(testCases);
console.log(`Accuracy: ${(results.accuracy * 100).toFixed(1)}%`);
```

### Constants

#### `componentMappings`

Object mapping component labels to detection keywords.

#### `filePathMappings`

Object mapping component labels to file path patterns (higher priority).

#### `priorityKeywords`

Object mapping priority labels to detection keywords.

#### `securityKeywords`

Array of security-related keywords.

## Monitoring System

**File**: `monitoring/index.js`

### Class: MonitoringSystem

Main orchestration class for health checking, metrics collection, alerting, and dashboard generation.

#### Constructor

```javascript
const monitoring = new MonitoringSystem(options = {})
```

**Parameters:**
- `options` (object): Configuration options
  - `healthCheckInterval` (number): Health check interval in ms (default: 60000)
  - `metricsRetentionDays` (number): Metrics retention period (default: 30)
  - `alertCooldownPeriod` (number): Alert cooldown in ms (default: 300000)
  - `enableDashboard` (boolean): Enable dashboard generation (default: true)

#### Methods

##### `start(githubToken)`

Start the monitoring system with periodic health checks.

**Parameters:**
- `githubToken` (string): GitHub API token

**Returns:** Promise<void>

**Example:**
```javascript
const MonitoringSystem = require('./monitoring');
const monitoring = new MonitoringSystem({
  healthCheckInterval: 30000,  // 30 seconds
  enableDashboard: true
});

await monitoring.start(process.env.GITHUB_TOKEN);
```

##### `stop()`

Stop the monitoring system gracefully.

**Returns:** Promise<void>

##### `getStatus(githubToken)`

Get current system status including health, metrics, and alerts.

**Parameters:**
- `githubToken` (string): GitHub API token

**Returns:** Promise<Object>
- `timestamp` (string): Status timestamp
- `isMonitoring` (boolean): Monitoring system status
- `uptime` (number): System uptime in ms
- `health` (object): Health check results
- `metrics` (object): System metrics
- `alerts` (object): Active and recent alerts

##### `getDashboard(githubToken, format = 'html')`

Generate dashboard in specified format.

**Parameters:**
- `githubToken` (string): GitHub API token
- `format` (string): Output format ('html', 'json', 'text')

**Returns:** Promise<string|Object> - Dashboard data

##### `trackAutoLabeling(event)`

Track an auto-labeling event for metrics.

**Parameters:**
- `event` (object): Event data
  - `issueId` (string): Issue identifier
  - `accuracy` (number): Labeling accuracy
  - `confidence` (number): Confidence score
  - `processingTime` (number): Processing time in ms
  - `labelsApplied` (array): Applied labels

**Example:**
```javascript
monitoring.trackAutoLabeling({
  issueId: 'issue-123',
  accuracy: 0.95,
  confidence: 0.87,
  processingTime: 250,
  labelsApplied: ['component:api', 'priority:high']
});
```

##### `trackApiUsage(event)`

Track GitHub API usage event.

**Parameters:**
- `event` (object): API event data
  - `endpoint` (string): API endpoint
  - `responseTime` (number): Response time in ms
  - `statusCode` (number): HTTP status code
  - `success` (boolean): Success flag

##### `trackError(event)`

Track error event.

**Parameters:**
- `event` (object): Error event data
  - `component` (string): Component name
  - `errorType` (string): Error type
  - `errorMessage` (string): Error message
  - `severity` (string): Error severity

##### `testMonitoring(githubToken)`

Test all monitoring components.

**Parameters:**
- `githubToken` (string): GitHub API token

**Returns:** Promise<boolean> - Test success

## Health Check System

**File**: `monitoring/health-check.js`

### Class: HealthCheckSystem

Comprehensive system health monitoring with configurable thresholds.

#### Constructor

```javascript
const healthChecker = new HealthCheckSystem(options = {})
```

**Parameters:**
- `options` (object): Configuration options
  - `timeout` (number): Health check timeout (default: 30000)
  - `apiThresholds` (object): API performance thresholds
  - `labelingThresholds` (object): Auto-labeling thresholds

#### Methods

##### `performHealthCheck(githubToken)`

Perform comprehensive system health check.

**Parameters:**
- `githubToken` (string): GitHub API token

**Returns:** Promise<Object>
- `timestamp` (string): Check timestamp
- `overall` (string): Overall health status
- `components` (object): Individual component health
- `metrics` (object): Performance metrics
- `alerts` (array): Generated alerts
- `duration` (number): Check duration in ms

**Example:**
```javascript
const HealthCheckSystem = require('./monitoring/health-check');
const healthChecker = new HealthCheckSystem();

const health = await healthChecker.performHealthCheck(token);
console.log(`System status: ${health.overall}`);
```

##### `getQuickHealth(githubToken)`

Get quick health summary with minimal checks.

**Parameters:**
- `githubToken` (string): GitHub API token

**Returns:** Promise<Object> - Quick health summary

##### `getHealthHistory()`

Get historical health check data.

**Returns:** Array<Object> - Health check history

## Metrics Collector

**File**: `monitoring/metrics.js`

### Class: MetricsCollector

Comprehensive metrics collection and analysis system.

#### Constructor

```javascript
const metrics = new MetricsCollector(options = {})
```

**Parameters:**
- `options` (object): Configuration options
  - `retentionDays` (number): Data retention period (default: 30)
  - `enablePerformanceTracking` (boolean): Enable performance tracking

#### Methods

##### `getSystemSummary(options = {})`

Get comprehensive system metrics summary.

**Parameters:**
- `options` (object): Query options
  - `start` (number): Start timestamp
  - `end` (number): End timestamp

**Returns:** Object
- `timeRange` (object): Query time range
- `autoLabeling` (object): Auto-labeling metrics
- `apiUsage` (object): API usage metrics
- `performance` (object): Performance metrics
- `errors` (object): Error metrics

**Example:**
```javascript
const MetricsCollector = require('./monitoring/metrics');
const metrics = new MetricsCollector();

const summary = metrics.getSystemSummary({
  start: Date.now() - (24 * 60 * 60 * 1000),  // Last 24 hours
  end: Date.now()
});

console.log('API Success Rate:', summary.apiUsage.successRate);
```

##### `getAutoLabelingMetrics(options = {})`

Get detailed auto-labeling performance metrics.

**Returns:** Object
- `totalEvents` (number): Total labeling events
- `averageAccuracy` (number): Average accuracy
- `averageProcessingTime` (number): Average processing time
- `componentDetectionRate` (number): Component detection rate
- `manualOverrideRate` (number): Manual override rate

##### `exportMetrics(options = {})`

Export metrics data for external analysis.

**Parameters:**
- `options` (object): Export options
  - `format` (string): Export format ('json', 'csv')
  - `start` (number): Start timestamp
  - `end` (number): End timestamp

**Returns:** Object - Exportable metrics data

## Alerting System

**File**: `monitoring/alerts.js`

### Class: AlertingSystem

Intelligent alerting with configurable thresholds and notification channels.

#### Constructor

```javascript
const alerts = new AlertingSystem(options = {})
```

**Parameters:**
- `options` (object): Alert configuration
  - `errorRateThreshold` (number): Error rate threshold (default: 0.05)
  - `responseTimeThreshold` (number): Response time threshold in ms (default: 5000)
  - `accuracyThreshold` (number): Accuracy threshold (default: 0.85)
  - `cooldownPeriod` (number): Alert cooldown in ms (default: 300000)

#### Methods

##### `processHealthAlerts(healthStatus)`

Process health check results and generate alerts.

**Parameters:**
- `healthStatus` (object): Health check results

##### `processMetricsAlerts(metricsData)`

Process metrics data and generate alerts.

**Parameters:**
- `metricsData` (object): Metrics summary data

##### `getActiveAlerts()`

Get all currently active alerts.

**Returns:** Array<Object> - Active alerts

##### `getAlertHistory(options = {})`

Get alert history with filtering.

**Parameters:**
- `options` (object): Query options
  - `limit` (number): Maximum results
  - `component` (string): Filter by component
  - `level` (string): Filter by alert level

**Returns:** Array<Object> - Historical alerts

**Example:**
```javascript
const AlertingSystem = require('./monitoring/alerts');
const alerts = new AlertingSystem({
  errorRateThreshold: 0.03,  // 3% error rate
  responseTimeThreshold: 3000  // 3 seconds
});

const activeAlerts = alerts.getActiveAlerts();
console.log(`${activeAlerts.length} active alerts`);
```

##### `configureNotifications(config)`

Configure notification channels.

**Parameters:**
- `config` (object): Notification configuration
  - `email` (object): Email settings
  - `slack` (object): Slack settings
  - `webhook` (object): Webhook settings

## Dashboard System

**File**: `monitoring/dashboard.js`

### Class: DashboardSystem

Real-time dashboard generation with multiple output formats.

#### Constructor

```javascript
const dashboard = new DashboardSystem(healthChecker, metricsCollector, alertingSystem, options = {})
```

**Parameters:**
- `healthChecker` (HealthCheckSystem): Health check system instance
- `metricsCollector` (MetricsCollector): Metrics collector instance
- `alertingSystem` (AlertingSystem): Alerting system instance
- `options` (object): Dashboard options

#### Methods

##### `generateHTMLDashboard(githubToken)`

Generate full HTML dashboard with CSS and JavaScript.

**Parameters:**
- `githubToken` (string): GitHub API token

**Returns:** Promise<string> - Complete HTML dashboard

##### `generateJSONDashboard(githubToken)`

Generate dashboard data as JSON.

**Parameters:**
- `githubToken` (string): GitHub API token

**Returns:** Promise<Object> - Dashboard data

##### `generateTextSummary(githubToken)`

Generate text-based dashboard summary for CLI.

**Parameters:**
- `githubToken` (string): GitHub API token

**Returns:** Promise<string> - Text summary

**Example:**
```javascript
const DashboardSystem = require('./monitoring/dashboard');
const dashboard = new DashboardSystem(healthChecker, metrics, alerts);

// Generate HTML dashboard
const htmlDashboard = await dashboard.generateHTMLDashboard(token);

// Get JSON data
const jsonData = await dashboard.generateJSONDashboard(token);

// CLI summary
const textSummary = await dashboard.generateTextSummary(token);
console.log(textSummary);
```

## Utility Scripts

### Template Validation

**File**: `scripts/validate-templates.js`

Validates YAML issue templates for syntax and structure.

**Usage:**
```bash
npm run validate-templates
```

### Label Synchronization  

**File**: `scripts/sync-labels.js`

Synchronizes repository labels with defined label schema.

**Usage:**
```bash
GITHUB_TOKEN=token npm run sync-labels owner repo
```

**Example:**
```javascript
const GitHubApiClient = require('../utils/github-api');
const client = new GitHubApiClient(process.env.GITHUB_TOKEN);

const labels = [
  { name: 'component:api', color: '0052CC', description: 'API-related issues' },
  { name: 'priority:high', color: 'FF6B6B', description: 'High priority issues' }
];

await client.syncLabels('owner', 'repo', labels);
```

## Error Handling

All API methods implement comprehensive error handling:

```javascript
try {
  const result = await client.createIssue(owner, repo, title, body);
  // Handle success
} catch (error) {
  if (error.status === 401) {
    // Authentication error
  } else if (error.status === 403) {
    // Rate limit or permissions error
  } else if (error.status === 422) {
    // Validation error
  }
  // Handle error appropriately
}
```

## Rate Limiting

The GitHub API client automatically handles rate limiting:

- Maintains 20% buffer by default
- Automatically waits when rate limit is approaching
- Provides rate limit status in all responses
- Implements exponential backoff for retries

## Performance Considerations

### Memory Usage

- Metrics data is automatically cleaned up based on retention settings
- Health check history is limited to last 100 entries
- Alert history is capped at 1000 entries

### API Efficiency

- Batch operations where possible
- Implement caching for frequently accessed data
- Use conditional requests when supported

### Monitoring Overhead

- Health checks run every 60 seconds by default
- Metrics aggregation runs every 5 minutes
- Alert processing has built-in cooldown periods

## Examples

### Complete Monitoring Setup

```javascript
const MonitoringSystem = require('./monitoring');

// Initialize monitoring with custom thresholds
const monitoring = new MonitoringSystem({
  healthCheckInterval: 30000,
  apiThresholds: {
    responseTime: 3000,
    rateLimitBuffer: 0.3
  },
  labelingThresholds: {
    accuracy: 0.9,
    processingTime: 20000
  }
});

// Configure notifications
monitoring.configureNotifications({
  email: {
    enabled: true,
    recipients: ['admin@example.com']
  },
  slack: {
    enabled: true,
    webhook: 'https://hooks.slack.com/...'
  }
});

// Start monitoring
await monitoring.start(process.env.GITHUB_TOKEN);

// Track events
monitoring.trackAutoLabeling({
  issueId: '123',
  accuracy: 0.95,
  processingTime: 150
});

// Get dashboard
const dashboard = await monitoring.getDashboard(
  process.env.GITHUB_TOKEN, 
  'html'
);
```

### Auto-labeling Integration

```javascript
const { analyzeIssueContent } = require('./utils/auto-labeling');
const GitHubApiClient = require('./utils/github-api');

const client = new GitHubApiClient(process.env.GITHUB_TOKEN);

// Analyze and apply labels
async function processNewIssue(owner, repo, issueNumber) {
  const issue = await client.getIssue(owner, repo, issueNumber);
  const analysis = analyzeIssueContent(issue.title, issue.body);
  
  if (analysis.confidence > 0.8) {
    await client.addLabels(owner, repo, issueNumber, analysis.labels);
    console.log(`Applied labels: ${analysis.labels.join(', ')}`);
  }
  
  return analysis;
}
```

---

**API Version**: 1.0  
**Last Updated**: 2025-08-23  
**Compatible with**: Node.js 18.0.0+