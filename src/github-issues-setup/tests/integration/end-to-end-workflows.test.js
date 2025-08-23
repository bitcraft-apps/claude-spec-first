/**
 * End-to-End Workflow Tests
 * Tests complete user workflows from issue creation to resolution,
 * including auto-labeling, milestone assignment, and template processing
 */

const GitHubApiClient = require('../../utils/github-api');
const { analyzeIssueContent } = require('../../utils/auto-labeling');
const { Octokit } = require('@octokit/rest');

// Mock the Octokit library
jest.mock('@octokit/rest');

describe('End-to-End Workflows', () => {
  let mockOctokit;
  let client;

  beforeEach(() => {
    jest.clearAllMocks();
    
    mockOctokit = {
      rest: {
        rateLimit: {
          get: jest.fn().mockResolvedValue({
            data: { rate: { remaining: 1000, reset: Date.now() / 1000 + 3600 } }
          })
        },
        users: {
          getAuthenticated: jest.fn().mockResolvedValue({
            data: { login: 'testuser', id: 12345 }
          })
        },
        issues: {
          create: jest.fn(),
          get: jest.fn(),
          update: jest.fn(),
          addLabels: jest.fn(),
          removeLabel: jest.fn(),
          createComment: jest.fn(),
          listComments: jest.fn(),
          listMilestones: jest.fn(),
          updateLabel: jest.fn(),
          createLabel: jest.fn()
        }
      }
    };

    Octokit.mockImplementation(() => mockOctokit);
    client = new GitHubApiClient('test_token');
  });

  describe('Bug Report Workflow', () => {
    test('should complete full bug report lifecycle', async () => {
      // Step 1: User creates bug report
      const bugTitle = 'Critical bug in spec-analyst agent';
      const bugBody = `
        The spec-analyst agent crashes when processing large requirements files.
        
        **Steps to reproduce:**
        1. Run spec-analyst on 500+ line requirements
        2. Agent fails with memory error
        3. System becomes unresponsive
        
        This is blocking our current sprint.
      `;

      const createdIssue = {
        number: 123,
        title: bugTitle,
        body: bugBody,
        labels: [],
        state: 'open',
        milestone: null
      };

      mockOctokit.rest.issues.create.mockResolvedValue({ data: createdIssue });

      // Step 2: Auto-labeling analysis
      const labelAnalysis = analyzeIssueContent(bugTitle, bugBody);
      
      expect(labelAnalysis.labels).toContain('component:agent-spec-analyst');
      expect(labelAnalysis.labels).toContain('priority:critical');
      expect(labelAnalysis.confidence).toBeGreaterThan(0.7);

      // Step 3: Create issue
      const issue = await client.createIssue('owner', 'repo', bugTitle, bugBody);
      
      expect(issue.number).toBe(123);
      expect(issue.title).toBe(bugTitle);

      // Step 4: Apply auto-detected labels
      const labelsToAdd = labelAnalysis.labels;
      const labeledIssue = {
        ...createdIssue,
        labels: labelsToAdd.map(name => ({ name, color: 'red' }))
      };

      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: labeledIssue.labels
      });

      const appliedLabels = await client.addLabels('owner', 'repo', 123, labelsToAdd);
      
      expect(appliedLabels).toHaveLength(labelsToAdd.length);
      expect(appliedLabels.some(label => label.name === 'component:agent-spec-analyst')).toBe(true);

      // Step 5: Assign to milestone (current sprint)
      const milestones = [
        { number: 1, title: 'Current Sprint', state: 'open' },
        { number: 2, title: 'Next Sprint', state: 'open' }
      ];

      mockOctokit.rest.issues.listMilestones.mockResolvedValue({
        data: milestones
      });

      const issueWithMilestone = {
        ...labeledIssue,
        milestone: milestones[0]
      };

      mockOctokit.rest.issues.update.mockResolvedValue({
        data: issueWithMilestone
      });

      const milestoneAssigned = await client.assignToMilestone('owner', 'repo', 123, 'Current Sprint');
      
      expect(milestoneAssigned.milestone.title).toBe('Current Sprint');

      // Step 6: Developer adds investigation comment
      const investigationComment = 'Investigating memory usage in spec-analyst. Initial findings suggest issue with large file parsing.';
      
      mockOctokit.rest.issues.createComment.mockResolvedValue({
        data: {
          id: 456,
          body: investigationComment,
          user: { login: 'developer' }
        }
      });

      const comment = await client.createComment('owner', 'repo', 123, investigationComment);
      
      expect(comment.body).toBe(investigationComment);
      expect(comment.user.login).toBe('developer');

      // Step 7: Resolution and closure
      const resolvedIssue = {
        ...issueWithMilestone,
        state: 'closed'
      };

      mockOctokit.rest.issues.update.mockResolvedValue({
        data: resolvedIssue
      });

      const closedIssue = await client.closeIssue('owner', 'repo', 123);
      
      expect(closedIssue.state).toBe('closed');
      expect(closedIssue.milestone.title).toBe('Current Sprint');
      expect(closedIssue.labels.some(label => label.name === 'component:agent-spec-analyst')).toBe(true);
    });

    test('should handle bug report with multiple component mentions', async () => {
      const complexBugTitle = 'Installation script breaks test-designer and impl-specialist';
      const complexBugBody = `
        Running scripts/install.sh causes issues with both test-designer and impl-specialist agents.
        The problem appears to be in the framework/validate-framework.sh script.
      `;

      // Auto-labeling should prioritize file path detection
      const analysis = analyzeIssueContent(complexBugTitle, complexBugBody);
      
      expect(analysis.labels).toContain('component:installation');
      expect(analysis.labels).not.toContain('component:agent-test-designer');
      expect(analysis.labels).not.toContain('component:agent-impl-specialist');
      expect(analysis.confidence).toBeGreaterThan(0.5);

      // Create issue with detected labels
      const issue = {
        number: 124,
        title: complexBugTitle,
        body: complexBugBody
      };

      mockOctokit.rest.issues.create.mockResolvedValue({ data: issue });

      const createdIssue = await client.createIssue('owner', 'repo', complexBugTitle, complexBugBody);
      
      expect(createdIssue.number).toBe(124);
      expect(mockOctokit.rest.issues.create).toHaveBeenCalledWith({
        owner: 'owner',
        repo: 'repo',
        title: complexBugTitle,
        body: complexBugBody,
        labels: []
      });
    });
  });

  describe('Feature Request Workflow', () => {
    test('should complete feature request from proposal to implementation', async () => {
      // Step 1: User submits feature request
      const featureTitle = 'Add TypeScript support to test-designer agent';
      const featureBody = `
        ## Feature Request: TypeScript Support
        
        **Problem Statement:**
        Currently, test-designer only generates JavaScript tests. We need TypeScript support for better type safety.
        
        **Proposed Solution:**
        - Add TypeScript template support
        - Generate .test.ts files
        - Include type definitions
        
        **Acceptance Criteria:**
        - [ ] TypeScript test templates
        - [ ] Type safety validation
        - [ ] Jest configuration for TS
        
        This would significantly improve our development workflow.
      `;

      // Step 2: Auto-labeling detects feature request
      const analysis = analyzeIssueContent(featureTitle, featureBody);
      
      expect(analysis.labels).toContain('component:agent-test-designer');
      expect(analysis.labels).toContain('priority:high'); // Due to "significantly"
      expect(analysis.confidence).toBeGreaterThan(0.6);

      // Step 3: Create issue
      const featureIssue = {
        number: 125,
        title: featureTitle,
        body: featureBody,
        labels: []
      };

      mockOctokit.rest.issues.create.mockResolvedValue({ data: featureIssue });

      const issue = await client.createIssue('owner', 'repo', featureTitle, featureBody);
      
      expect(issue.number).toBe(125);

      // Step 4: Apply labels and milestone
      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: analysis.labels.map(name => ({ name, color: 'blue' }))
      });

      await client.addLabels('owner', 'repo', 125, analysis.labels);

      const milestones = [
        { number: 3, title: 'v2.0 Features', state: 'open' }
      ];

      mockOctokit.rest.issues.listMilestones.mockResolvedValue({ data: milestones });
      mockOctokit.rest.issues.update.mockResolvedValue({
        data: { ...featureIssue, milestone: milestones[0] }
      });

      const withMilestone = await client.assignToMilestone('owner', 'repo', 125, 'v2.0 Features');
      
      expect(withMilestone.milestone.title).toBe('v2.0 Features');

      // Step 5: Development discussion
      const discussionComment = `
        Great idea! I'll start working on this. Planning to:
        1. Extend template system for TypeScript
        2. Add type definition generation
        3. Update Jest configuration
        
        ETA: End of sprint
      `;

      mockOctokit.rest.issues.createComment.mockResolvedValue({
        data: { id: 789, body: discussionComment, user: { login: 'maintainer' } }
      });

      const discussion = await client.createComment('owner', 'repo', 125, discussionComment);
      
      expect(discussion.body).toContain('ETA: End of sprint');

      // Step 6: Implementation tracking via labels
      const implementationLabels = ['status:in-progress', 'needs:testing'];
      
      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: implementationLabels.map(name => ({ name, color: 'yellow' }))
      });

      await client.addLabels('owner', 'repo', 125, implementationLabels);

      expect(mockOctokit.rest.issues.addLabels).toHaveBeenCalledWith({
        owner: 'owner',
        repo: 'repo',
        issue_number: 125,
        labels: implementationLabels
      });
    });
  });

  describe('Security Issue Workflow', () => {
    test('should handle security vulnerability with elevated priority', async () => {
      const securityTitle = 'XSS vulnerability in template processing';
      const securityBody = `
        **Security Vulnerability Report**
        
        I found a cross-site scripting (XSS) vulnerability in the template processing system.
        User input is not properly sanitized, allowing malicious scripts to be executed.
        
        **Impact:** High - Could lead to credential theft
        **CVSS Score:** 8.5
        
        This needs urgent attention.
      `;

      // Step 1: Auto-labeling detects security issue
      const analysis = analyzeIssueContent(securityTitle, securityBody);
      
      expect(analysis.labels).toContain('type:security');
      expect(analysis.labels).toContain('priority:high'); // Security override
      expect(analysis.analysis.security).toBe(true);

      // Step 2: Create security issue
      const securityIssue = {
        number: 126,
        title: securityTitle,
        body: securityBody,
        labels: []
      };

      mockOctokit.rest.issues.create.mockResolvedValue({ data: securityIssue });

      const issue = await client.createIssue('owner', 'repo', securityTitle, securityBody);
      
      expect(issue.number).toBe(126);

      // Step 3: Apply security labels immediately
      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: analysis.labels.map(name => ({ name, color: 'red' }))
      });

      await client.addLabels('owner', 'repo', 126, analysis.labels);

      // Step 4: Assign to security milestone
      const securityMilestones = [
        { number: 4, title: 'Security Fixes', state: 'open' },
        { number: 5, title: 'Next Release', state: 'open' }
      ];

      mockOctokit.rest.issues.listMilestones.mockResolvedValue({ data: securityMilestones });
      mockOctokit.rest.issues.update.mockResolvedValue({
        data: { ...securityIssue, milestone: securityMilestones[0] }
      });

      const withSecurityMilestone = await client.assignToMilestone('owner', 'repo', 126, 'Security Fixes');
      
      expect(withSecurityMilestone.milestone.title).toBe('Security Fixes');

      // Step 5: Security team response
      const securityResponse = `
        Thank you for the security report. We take security issues very seriously.
        
        **Initial Assessment:**
        - Confirmed XSS vulnerability
        - Affects template processing system
        - Working on immediate patch
        
        **Next Steps:**
        1. Patch development
        2. Security testing
        3. Coordinated disclosure
        
        ETA for fix: 24 hours
      `;

      mockOctokit.rest.issues.createComment.mockResolvedValue({
        data: { id: 999, body: securityResponse, user: { login: 'security-team' } }
      });

      const response = await client.createComment('owner', 'repo', 126, securityResponse);
      
      expect(response.body).toContain('24 hours');
      expect(response.user.login).toBe('security-team');

      // Step 6: Add additional security labels
      const additionalLabels = ['needs:security-review', 'priority:critical'];
      
      // Remove old priority label first
      mockOctokit.rest.issues.removeLabel.mockResolvedValue({});
      await client.removeLabels('owner', 'repo', 126, ['priority:high']);

      // Add new labels
      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: additionalLabels.map(name => ({ name, color: 'red' }))
      });

      await client.addLabels('owner', 'repo', 126, additionalLabels);

      expect(mockOctokit.rest.issues.removeLabel).toHaveBeenCalledWith({
        owner: 'owner',
        repo: 'repo',
        issue_number: 126,
        name: 'priority:high'
      });
    });
  });

  describe('Documentation Update Workflow', () => {
    test('should handle documentation improvement requests', async () => {
      const docsTitle = 'Update documentation for qa-validator agent';
      const docsBody = `
        The current documentation for the qa-validator agent is outdated and missing examples.
        
        **Issues:**
        - Missing usage examples
        - Outdated configuration options
        - No troubleshooting section
        
        **Proposed Changes:**
        - Add comprehensive examples
        - Update configuration docs
        - Add troubleshooting guide
        
        This is a minor improvement for better developer experience.
      `;

      // Step 1: Auto-labeling detects documentation issue
      const analysis = analyzeIssueContent(docsTitle, docsBody);
      
      expect(analysis.labels).toContain('component:agent-qa-validator');
      expect(analysis.labels).toContain('priority:low'); // Due to "minor improvement"
      expect(analysis.confidence).toBeGreaterThan(0.5);

      // Step 2: Create documentation issue
      const docsIssue = {
        number: 127,
        title: docsTitle,
        body: docsBody
      };

      mockOctokit.rest.issues.create.mockResolvedValue({ data: docsIssue });

      const issue = await client.createIssue('owner', 'repo', docsTitle, docsBody);
      
      expect(issue.number).toBe(127);

      // Step 3: Apply appropriate labels
      const docsLabels = [...analysis.labels, 'type:documentation'];
      
      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: docsLabels.map(name => ({ name, color: 'green' }))
      });

      await client.addLabels('owner', 'repo', 127, docsLabels);

      // Step 4: Assign to documentation milestone
      const docsMilestones = [
        { number: 6, title: 'Documentation Improvements', state: 'open' }
      ];

      mockOctokit.rest.issues.listMilestones.mockResolvedValue({ data: docsMilestones });
      mockOctokit.rest.issues.update.mockResolvedValue({
        data: { ...docsIssue, milestone: docsMilestones[0] }
      });

      await client.assignToMilestone('owner', 'repo', 127, 'Documentation Improvements');

      expect(mockOctokit.rest.issues.update).toHaveBeenCalledWith({
        owner: 'owner',
        repo: 'repo',
        issue_number: 127,
        milestone: 6
      });
    });
  });

  describe('Label Synchronization Workflow', () => {
    test('should synchronize repository labels with standard set', async () => {
      // Step 1: Define standard label set
      const standardLabels = [
        { name: 'component:agent-spec-analyst', color: 'blue', description: 'Issues related to spec-analyst agent' },
        { name: 'component:installation', color: 'yellow', description: 'Installation and setup issues' },
        { name: 'priority:critical', color: 'red', description: 'Critical priority issues' },
        { name: 'priority:high', color: 'orange', description: 'High priority issues' },
        { name: 'type:bug', color: 'red', description: 'Bug reports' },
        { name: 'type:feature', color: 'green', description: 'Feature requests' }
      ];

      // Step 2: Mock label operations (some exist, some don't)
      const existingLabels = ['component:agent-spec-analyst', 'priority:critical'];
      const newLabels = standardLabels.filter(l => !existingLabels.includes(l.name));
      const updateLabels = standardLabels.filter(l => existingLabels.includes(l.name));

      // Mock update existing labels
      mockOctokit.rest.issues.updateLabel.mockImplementation((params) => {
        const label = updateLabels.find(l => l.name === params.name);
        if (label) {
          return Promise.resolve({ data: label });
        } else {
          const error = new Error('Not Found');
          error.status = 404;
          return Promise.reject(error);
        }
      });

      // Mock create new labels
      mockOctokit.rest.issues.createLabel.mockImplementation((params) => {
        return Promise.resolve({ data: params });
      });

      // Step 3: Sync labels
      const results = await client.syncLabels('owner', 'repo', standardLabels);
      
      expect(results).toHaveLength(standardLabels.length);
      
      const updatedCount = results.filter(r => r.action === 'updated').length;
      const createdCount = results.filter(r => r.action === 'created').length;
      
      expect(updatedCount).toBe(existingLabels.length);
      expect(createdCount).toBe(newLabels.length);

      // Step 4: Verify all operations succeeded
      const failedCount = results.filter(r => r.action === 'failed').length;
      expect(failedCount).toBe(0);

      expect(mockOctokit.rest.issues.updateLabel).toHaveBeenCalledTimes(standardLabels.length);
      expect(mockOctokit.rest.issues.createLabel).toHaveBeenCalledTimes(newLabels.length);
    });
  });

  describe('Cross-Component Issue Workflow', () => {
    test('should handle issues affecting multiple components', async () => {
      const crossComponentTitle = 'Framework update breaks multiple agents';
      const crossComponentBody = `
        After updating the framework, several agents are failing:
        - spec-analyst crashes on startup
        - test-designer generates invalid tests  
        - impl-specialist produces malformed code
        
        The common factor appears to be changes in framework/agents/ directory.
        All agents are affected when processing large inputs.
        
        This is a critical regression blocking all development.
      `;

      // Step 1: Auto-labeling chooses primary component
      const analysis = analyzeIssueContent(crossComponentTitle, crossComponentBody);
      
      // Should detect one primary component (first mentioned)
      expect(analysis.labels).toContain('component:agent-spec-analyst');
      expect(analysis.labels).toContain('priority:critical');
      expect(analysis.confidence).toBeGreaterThan(0.7);

      // Step 2: Create issue
      const crossIssue = {
        number: 128,
        title: crossComponentTitle,
        body: crossComponentBody
      };

      mockOctokit.rest.issues.create.mockResolvedValue({ data: crossIssue });

      const issue = await client.createIssue('owner', 'repo', crossComponentTitle, crossComponentBody);
      
      expect(issue.number).toBe(128);

      // Step 3: Apply initial labels
      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: analysis.labels.map(name => ({ name, color: 'red' }))
      });

      await client.addLabels('owner', 'repo', 128, analysis.labels);

      // Step 4: Maintainer adds additional context labels
      const additionalLabels = [
        'affects:multiple-components',
        'type:regression',
        'needs:investigation'
      ];

      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: additionalLabels.map(name => ({ name, color: 'purple' }))
      });

      await client.addLabels('owner', 'repo', 128, additionalLabels);

      // Step 5: Investigation comment
      const investigationComment = `
        Confirmed regression affecting multiple agents. Root cause analysis:
        
        **Affected Components:**
        - spec-analyst: Startup crash due to config changes
        - test-designer: Template parsing issues
        - impl-specialist: Code generation failures
        
        **Root Cause:** Breaking changes in framework/agents/base.md
        
        **Fix Plan:**
        1. Revert breaking changes
        2. Update agents for compatibility
        3. Add regression tests
        
        Working on hotfix - ETA 2 hours
      `;

      mockOctokit.rest.issues.createComment.mockResolvedValue({
        data: { 
          id: 1001, 
          body: investigationComment, 
          user: { login: 'maintainer' } 
        }
      });

      const comment = await client.createComment('owner', 'repo', 128, investigationComment);
      
      expect(comment.body).toContain('ETA 2 hours');

      // Step 6: Update priority and add hotfix label
      mockOctokit.rest.issues.addLabels.mockResolvedValue({
        data: [{ name: 'hotfix:urgent', color: 'red' }]
      });

      await client.addLabels('owner', 'repo', 128, ['hotfix:urgent']);

      expect(mockOctokit.rest.issues.addLabels).toHaveBeenLastCalledWith({
        owner: 'owner',
        repo: 'repo',
        issue_number: 128,
        labels: ['hotfix:urgent']
      });
    });
  });

  describe('Error Recovery Workflows', () => {
    test('should handle workflow with intermittent API failures', async () => {
      const resilientTitle = 'Test resilient workflow';
      const resilientBody = 'Testing error recovery in spec-analyst';

      // Step 1: First operation fails
      const networkError = new Error('Network timeout');
      networkError.code = 'ETIMEDOUT';

      mockOctokit.rest.issues.create
        .mockRejectedValueOnce(networkError)  // First attempt fails
        .mockResolvedValueOnce({               // Second attempt succeeds
          data: { number: 129, title: resilientTitle, body: resilientBody }
        });

      // Should retry and succeed
      try {
        await client.createIssue('owner', 'repo', resilientTitle, resilientBody);
      } catch (error) {
        // First call should fail
        expect(error.code).toBe('ETIMEDOUT');
      }

      // Retry should succeed
      const issue = await client.createIssue('owner', 'repo', resilientTitle, resilientBody);
      expect(issue.number).toBe(129);

      // Step 2: Label operation with rate limit hit
      const rateLimitError = new Error('API rate limit exceeded');
      rateLimitError.status = 403;

      mockOctokit.rest.rateLimit.get
        .mockResolvedValueOnce({ data: { rate: { remaining: 0 } } })   // Rate limited
        .mockResolvedValueOnce({ data: { rate: { remaining: 1000 } } }); // Recovered

      mockOctokit.rest.issues.addLabels
        .mockRejectedValueOnce(rateLimitError)  // Rate limit hit
        .mockResolvedValueOnce({                 // Success after wait
          data: [{ name: 'component:agent-spec-analyst', color: 'blue' }]
        });

      try {
        await client.addLabels('owner', 'repo', 129, ['component:agent-spec-analyst']);
      } catch (error) {
        expect(error.status).toBe(403);
      }

      // Retry after rate limit recovery
      const labels = await client.addLabels('owner', 'repo', 129, ['component:agent-spec-analyst']);
      expect(labels[0].name).toBe('component:agent-spec-analyst');
    });

    test('should handle partial workflow completion', async () => {
      const partialTitle = 'Partial workflow test';
      const partialBody = 'Testing partial completion with qa-validator';

      // Step 1: Issue creation succeeds
      mockOctokit.rest.issues.create.mockResolvedValue({
        data: { number: 130, title: partialTitle, body: partialBody }
      });

      const issue = await client.createIssue('owner', 'repo', partialTitle, partialBody);
      expect(issue.number).toBe(130);

      // Step 2: Label application partially fails
      const validationError = new Error('Validation failed');
      validationError.status = 422;

      mockOctokit.rest.issues.addLabels.mockRejectedValue(validationError);

      try {
        await client.addLabels('owner', 'repo', 130, ['component:agent-qa-validator', 'priority:normal']);
      } catch (error) {
        expect(error.status).toBe(422);
      }

      // Step 3: Comment addition succeeds despite label failure
      mockOctokit.rest.issues.createComment.mockResolvedValue({
        data: { 
          id: 2001, 
          body: 'Issue created successfully, labels failed to apply', 
          user: { login: 'system' } 
        }
      });

      const comment = await client.createComment('owner', 'repo', 130, 'Issue created successfully, labels failed to apply');
      expect(comment.body).toContain('labels failed to apply');

      // Workflow partially completed - issue exists with comment but no labels
      expect(issue.number).toBe(130);
      expect(comment.id).toBe(2001);
    });
  });
});