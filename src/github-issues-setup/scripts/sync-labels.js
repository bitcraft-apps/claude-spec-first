#!/usr/bin/env node
/**
 * Label Sync Script
 * Synchronizes GitHub repository labels with configuration
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const GitHubApiClient = require('../utils/github-api');

const LABELS_CONFIG = path.join(__dirname, '../../../.github/labels.yml');

/**
 * Load label configuration from YAML file
 */
function loadLabelsConfig() {
  try {
    const content = fs.readFileSync(LABELS_CONFIG, 'utf8');
    return yaml.load(content);
  } catch (error) {
    console.error(`Failed to load labels configuration: ${error.message}`);
    throw error;
  }
}

/**
 * Validate label configuration
 */
function validateLabels(labels) {
  const errors = [];
  
  if (!Array.isArray(labels)) {
    errors.push('Labels configuration must be an array');
    return errors;
  }

  labels.forEach((label, index) => {
    if (!label.name || typeof label.name !== 'string') {
      errors.push(`Label ${index}: missing or invalid name`);
    }
    
    if (!label.color || typeof label.color !== 'string' || !/^[0-9A-Fa-f]{6}$/.test(label.color)) {
      errors.push(`Label ${index} (${label.name}): missing or invalid color (must be 6-digit hex)`);
    }
    
    if (!label.description || typeof label.description !== 'string') {
      errors.push(`Label ${index} (${label.name}): missing or invalid description`);
    }
  });

  return errors;
}

/**
 * Get repository information from command line or environment
 */
function getRepositoryInfo() {
  const owner = process.env.GITHUB_REPOSITORY_OWNER || process.argv[2];
  const repo = process.env.GITHUB_REPOSITORY_NAME || process.argv[3];
  
  if (!owner || !repo) {
    console.error('Usage: sync-labels.js <owner> <repo>');
    console.error('Or set GITHUB_REPOSITORY_OWNER and GITHUB_REPOSITORY_NAME environment variables');
    process.exit(1);
  }
  
  return { owner, repo };
}

/**
 * Get GitHub token from environment
 */
function getGitHubToken() {
  const token = process.env.GITHUB_TOKEN;
  
  if (!token) {
    console.error('GITHUB_TOKEN environment variable is required');
    process.exit(1);
  }
  
  return token;
}

/**
 * Sync labels with repository
 */
async function syncLabels() {
  console.log('🏷️  Syncing GitHub Labels...\n');

  try {
    // Load and validate configuration
    const labels = loadLabelsConfig();
    console.log(`📄 Loaded ${labels.length} labels from configuration`);

    const validationErrors = validateLabels(labels);
    if (validationErrors.length > 0) {
      console.error('❌ Label configuration validation failed:');
      validationErrors.forEach(error => console.error(`  - ${error}`));
      process.exit(1);
    }
    console.log('✅ Label configuration is valid');

    // Get repository info and initialize API client
    const { owner, repo } = getRepositoryInfo();
    const token = getGitHubToken();
    const apiClient = new GitHubApiClient(token);

    console.log(`📂 Target repository: ${owner}/${repo}`);

    // Verify authentication and permissions
    try {
      const user = await apiClient.getAuthenticatedUser();
      console.log(`👤 Authenticated as: ${user.login}`);
    } catch (error) {
      console.error(`❌ Authentication failed: ${error.message}`);
      process.exit(1);
    }

    // Check rate limits
    const rateLimit = await apiClient.checkRateLimit();
    console.log(`⏱️  Rate limit: ${rateLimit.remaining}/${rateLimit.limit} remaining`);

    if (rateLimit.remaining < labels.length * 2) {
      console.error('❌ Insufficient rate limit remaining for label sync');
      process.exit(1);
    }

    // Sync labels
    console.log('\n🔄 Syncing labels...');
    const results = await apiClient.syncLabels(owner, repo, labels);

    // Report results
    const created = results.filter(r => r.action === 'created').length;
    const updated = results.filter(r => r.action === 'updated').length;
    const failed = results.filter(r => r.action === 'failed').length;

    console.log('\n📊 Sync Results:');
    console.log(`✅ Created: ${created}`);
    console.log(`🔄 Updated: ${updated}`);
    console.log(`❌ Failed: ${failed}`);

    if (failed > 0) {
      console.log('\n❌ Failed labels:');
      results.filter(r => r.action === 'failed').forEach(result => {
        console.log(`  - ${result.label}: ${result.error}`);
      });
    }

    // Show detailed results if verbose
    if (process.argv.includes('--verbose') || process.env.VERBOSE === 'true') {
      console.log('\n📋 Detailed Results:');
      results.forEach(result => {
        const status = result.action === 'failed' ? '❌' : '✅';
        const labelName = result.label?.name || result.label;
        console.log(`  ${status} ${labelName} (${result.action})`);
      });
    }

    const success = failed === 0;
    console.log(success ? '\n🎉 Label sync completed successfully!' : '\n⚠️  Label sync completed with errors');
    
    return success;

  } catch (error) {
    console.error(`❌ Label sync failed: ${error.message}`);
    if (process.env.DEBUG === 'true') {
      console.error(error.stack);
    }
    return false;
  }
}

// Run sync if called directly
if (require.main === module) {
  syncLabels().then(success => {
    process.exit(success ? 0 : 1);
  });
}

module.exports = { syncLabels };