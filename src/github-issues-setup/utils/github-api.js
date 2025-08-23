/**
 * GitHub API Client for Issues Setup
 * Provides rate-limited, authenticated access to GitHub API
 */

const { Octokit } = require('@octokit/rest');

class GitHubApiClient {
  constructor(token, options = {}) {
    this.octokit = new Octokit({ 
      auth: token,
      ...options
    });
    this.rateLimitBuffer = 0.2; // 20% buffer
  }

  /**
   * Check current rate limit status
   * @returns {Promise<Object>} Rate limit information
   */
  async checkRateLimit() {
    try {
      const { data } = await this.octokit.rest.rateLimit.get();
      return data.rate;
    } catch (error) {
      console.error('Failed to check rate limit:', error.message);
      throw error;
    }
  }

  /**
   * Check if we're within rate limit buffer
   * @returns {Promise<boolean>} True if within safe limits
   */
  async isWithinRateLimit() {
    const rateLimit = await this.checkRateLimit();
    const bufferThreshold = rateLimit.limit * (1 - this.rateLimitBuffer);
    return (rateLimit.limit - rateLimit.remaining) < bufferThreshold;
  }

  /**
   * Wait for rate limit reset if needed
   */
  async waitIfRateLimited() {
    const rateLimit = await this.checkRateLimit();
    if (rateLimit.remaining < 10) {
      const waitTime = (rateLimit.reset - Date.now() / 1000) * 1000 + 1000; // Add 1 second buffer
      if (waitTime > 0) {
        console.log(`Rate limited. Waiting ${Math.ceil(waitTime / 1000)} seconds...`);
        await new Promise(resolve => setTimeout(resolve, waitTime));
      }
    }
  }

  /**
   * Get authenticated user information
   * @returns {Promise<Object>} User data
   */
  async getAuthenticatedUser() {
    await this.waitIfRateLimited();
    const { data } = await this.octokit.rest.users.getAuthenticated();
    return data;
  }

  /**
   * Create a new issue
   * @param {string} owner Repository owner
   * @param {string} repo Repository name
   * @param {string} title Issue title
   * @param {string} body Issue body
   * @param {Array<string>} labels Initial labels
   * @returns {Promise<Object>} Created issue data
   */
  async createIssue(owner, repo, title, body, labels = []) {
    await this.waitIfRateLimited();
    
    try {
      const { data } = await this.octokit.rest.issues.create({
        owner,
        repo,
        title,
        body,
        labels
      });
      return data;
    } catch (error) {
      console.error(`Failed to create issue: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get issue details
   * @param {string} owner Repository owner
   * @param {string} repo Repository name
   * @param {number} issueNumber Issue number
   * @returns {Promise<Object>} Issue data
   */
  async getIssue(owner, repo, issueNumber) {
    await this.waitIfRateLimited();
    
    try {
      const { data } = await this.octokit.rest.issues.get({
        owner,
        repo,
        issue_number: issueNumber
      });
      return data;
    } catch (error) {
      console.error(`Failed to get issue #${issueNumber}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Add labels to an issue
   * @param {string} owner Repository owner
   * @param {string} repo Repository name
   * @param {number} issueNumber Issue number
   * @param {Array<string>} labels Labels to add
   * @returns {Promise<Object>} Updated issue data
   */
  async addLabels(owner, repo, issueNumber, labels) {
    await this.waitIfRateLimited();
    
    try {
      const { data } = await this.octokit.rest.issues.addLabels({
        owner,
        repo,
        issue_number: issueNumber,
        labels
      });
      return data;
    } catch (error) {
      console.error(`Failed to add labels to issue #${issueNumber}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Remove labels from an issue
   * @param {string} owner Repository owner
   * @param {string} repo Repository name
   * @param {number} issueNumber Issue number
   * @param {Array<string>} labels Labels to remove
   * @returns {Promise<void>}
   */
  async removeLabels(owner, repo, issueNumber, labels) {
    await this.waitIfRateLimited();
    
    try {
      for (const label of labels) {
        await this.octokit.rest.issues.removeLabel({
          owner,
          repo,
          issue_number: issueNumber,
          name: label
        });
      }
    } catch (error) {
      console.error(`Failed to remove labels from issue #${issueNumber}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Create a comment on an issue
   * @param {string} owner Repository owner
   * @param {string} repo Repository name
   * @param {number} issueNumber Issue number
   * @param {string} body Comment body
   * @returns {Promise<Object>} Created comment data
   */
  async createComment(owner, repo, issueNumber, body) {
    await this.waitIfRateLimited();
    
    try {
      const { data } = await this.octokit.rest.issues.createComment({
        owner,
        repo,
        issue_number: issueNumber,
        body
      });
      return data;
    } catch (error) {
      console.error(`Failed to create comment on issue #${issueNumber}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get comments for an issue
   * @param {string} owner Repository owner
   * @param {string} repo Repository name
   * @param {number} issueNumber Issue number
   * @returns {Promise<Array>} Comments array
   */
  async getIssueComments(owner, repo, issueNumber) {
    await this.waitIfRateLimited();
    
    try {
      const { data } = await this.octokit.rest.issues.listComments({
        owner,
        repo,
        issue_number: issueNumber
      });
      return data;
    } catch (error) {
      console.error(`Failed to get comments for issue #${issueNumber}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Close an issue
   * @param {string} owner Repository owner
   * @param {string} repo Repository name
   * @param {number} issueNumber Issue number
   * @returns {Promise<Object>} Updated issue data
   */
  async closeIssue(owner, repo, issueNumber) {
    await this.waitIfRateLimited();
    
    try {
      const { data } = await this.octokit.rest.issues.update({
        owner,
        repo,
        issue_number: issueNumber,
        state: 'closed'
      });
      return data;
    } catch (error) {
      console.error(`Failed to close issue #${issueNumber}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Create or update labels in repository
   * @param {string} owner Repository owner
   * @param {string} repo Repository name
   * @param {Array<Object>} labels Label definitions
   * @returns {Promise<Array>} Created/updated labels
   */
  async syncLabels(owner, repo, labels) {
    const results = [];
    
    for (const label of labels) {
      try {
        await this.waitIfRateLimited();
        
        // Try to update existing label
        try {
          const { data } = await this.octokit.rest.issues.updateLabel({
            owner,
            repo,
            name: label.name,
            color: label.color,
            description: label.description
          });
          results.push({ action: 'updated', label: data });
        } catch (updateError) {
          if (updateError.status === 404) {
            // Label doesn't exist, create it
            const { data } = await this.octokit.rest.issues.createLabel({
              owner,
              repo,
              name: label.name,
              color: label.color,
              description: label.description
            });
            results.push({ action: 'created', label: data });
          } else {
            throw updateError;
          }
        }
      } catch (error) {
        console.error(`Failed to sync label ${label.name}: ${error.message}`);
        results.push({ action: 'failed', label: label.name, error: error.message });
      }
    }
    
    return results;
  }

  /**
   * Assign issue to milestone
   * @param {string} owner Repository owner
   * @param {string} repo Repository name
   * @param {number} issueNumber Issue number
   * @param {string} milestoneTitle Milestone title
   * @returns {Promise<Object>} Updated issue data
   */
  async assignToMilestone(owner, repo, issueNumber, milestoneTitle) {
    await this.waitIfRateLimited();
    
    try {
      // First, find the milestone by title
      const { data: milestones } = await this.octokit.rest.issues.listMilestones({
        owner,
        repo,
        state: 'open'
      });
      
      const milestone = milestones.find(m => m.title === milestoneTitle);
      if (!milestone) {
        throw new Error(`Milestone "${milestoneTitle}" not found`);
      }
      
      // Assign issue to milestone
      const { data } = await this.octokit.rest.issues.update({
        owner,
        repo,
        issue_number: issueNumber,
        milestone: milestone.number
      });
      
      return data;
    } catch (error) {
      console.error(`Failed to assign issue #${issueNumber} to milestone: ${error.message}`);
      throw error;
    }
  }
}

module.exports = GitHubApiClient;