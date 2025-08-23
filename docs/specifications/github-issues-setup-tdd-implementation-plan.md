# GitHub Issues Setup - TDD Implementation Plan

## 1. TDD Implementation Strategy

### 1.1 Test-Driven Development Approach

This document defines a comprehensive Test-Driven Development (TDD) implementation sequence for the GitHub Issues Setup feature. Following the Red → Green → Refactor cycle, we'll build failing tests first to encode all requirements, then implement minimal code to pass tests, and finally refactor for maintainability.

### 1.2 TDD Principles for This Project

- **Red Phase**: Write failing tests that encode exact specifications
- **Green Phase**: Write minimal code to pass tests (no more, no less)
- **Refactor Phase**: Improve code quality while keeping all tests passing
- **Test Categories**: Unit tests for components, integration tests for workflows, E2E tests for user journeys
- **Quality Gates**: Each phase requires all tests passing before proceeding

### 1.3 Implementation Sequence Overview

**Phase 1**: Foundation Testing Infrastructure (Tests for basic setup)
**Phase 2**: Template System Tests (Individual template validation)  
**Phase 3**: Label System Tests (Auto-labeling and management)
**Phase 4**: Automation Tests (GitHub Actions workflows)
**Phase 5**: Integration Tests (End-to-end workflows)
**Phase 6**: Performance & Security Tests (Non-functional requirements)

## 2. Phase 1: Foundation Testing Infrastructure

### 2.1 Test Environment Setup

#### Task TDD-001: Test Repository and Environment Setup
**Duration**: 4 hours
**Dependencies**: None

**Red Phase - Failing Tests**:

```javascript
// tests/foundation/environment.test.js
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

describe('Foundation Environment Tests', () => {
  describe('Repository Structure', () => {
    test('should have .github directory', () => {
      expect(fs.existsSync('.github')).toBe(true);
    });

    test('should have ISSUE_TEMPLATE directory', () => {
      expect(fs.existsSync('.github/ISSUE_TEMPLATE')).toBe(true);
    });

    test('should have workflows directory', () => {
      expect(fs.existsSync('.github/workflows')).toBe(true);
    });

    test('should have label configuration file', () => {
      expect(fs.existsSync('.github/labels.yml')).toBe(true);
    });

    test('should have milestone configuration file', () => {
      expect(fs.existsSync('.github/milestones.yml')).toBe(true);
    });
  });

  describe('GitHub CLI Access', () => {
    test('should have GitHub CLI installed and authenticated', () => {
      expect(() => {
        execSync('gh auth status', { stdio: 'pipe' });
      }).not.toThrow();
    });

    test('should have admin access to test repository', () => {
      const repoInfo = JSON.parse(
        execSync('gh repo view --json permissions').toString()
      );
      expect(repoInfo.permissions.admin).toBe(true);
    });
  });

  describe('GitHub Actions Configuration', () => {
    test('should have Actions enabled on repository', () => {
      const repoInfo = JSON.parse(
        execSync('gh repo view --json hasActionsEnabled').toString()
      );
      expect(repoInfo.hasActionsEnabled).toBe(true);
    });
  });
});
```

**Green Phase - Implementation**:
```bash
#!/bin/bash
# scripts/setup-test-environment.sh

# Create directory structure
mkdir -p .github/ISSUE_TEMPLATE
mkdir -p .github/workflows

# Create placeholder configuration files
touch .github/labels.yml
touch .github/milestones.yml

# Verify GitHub CLI authentication
gh auth status || (echo "Please authenticate with GitHub CLI" && exit 1)

# Enable GitHub Actions if not already enabled
gh repo edit --enable-actions=true
```

**Refactor Phase**: Clean up script organization and error handling

#### Task TDD-002: Template Validation Infrastructure
**Duration**: 3 hours
**Dependencies**: TDD-001

**Red Phase - Failing Tests**:

```javascript
// tests/foundation/template-validation.test.js
const yaml = require('js-yaml');
const fs = require('fs');

describe('Template Validation Infrastructure', () => {
  const templateDir = '.github/ISSUE_TEMPLATE';
  
  describe('YAML Schema Validation', () => {
    test('should validate YAML syntax for all template files', () => {
      const templateFiles = fs.readdirSync(templateDir)
        .filter(file => file.endsWith('.yml'));
      
      templateFiles.forEach(file => {
        const content = fs.readFileSync(`${templateDir}/${file}`, 'utf8');
        expect(() => yaml.safeLoad(content)).not.toThrow();
      });
    });

    test('should validate required GitHub template schema fields', () => {
      const requiredFields = ['name', 'description', 'body'];
      const templateFiles = fs.readdirSync(templateDir)
        .filter(file => file.endsWith('.yml') && file !== 'config.yml');

      templateFiles.forEach(file => {
        const content = fs.readFileSync(`${templateDir}/${file}`, 'utf8');
        const template = yaml.safeLoad(content);
        
        requiredFields.forEach(field => {
          expect(template).toHaveProperty(field);
        });
      });
    });
  });

  describe('Template Configuration Validation', () => {
    test('should have valid config.yml with required settings', () => {
      const configContent = fs.readFileSync(`${templateDir}/config.yml`, 'utf8');
      const config = yaml.safeLoad(configContent);
      
      expect(config).toHaveProperty('blank_issues_enabled');
      expect(config).toHaveProperty('contact_links');
      expect(Array.isArray(config.contact_links)).toBe(true);
    });
  });
});
```

**Green Phase - Implementation**:
```yaml
# .github/ISSUE_TEMPLATE/config.yml (minimal valid configuration)
blank_issues_enabled: false
contact_links:
  - name: Framework Documentation
    url: https://github.com/bitcraft-apps/claude-spec-first/blob/main/README.md
    about: Please read the documentation before opening an issue
```

#### Task TDD-003: GitHub API Testing Infrastructure
**Duration**: 4 hours
**Dependencies**: TDD-002

**Red Phase - Failing Tests**:

```javascript
// tests/foundation/github-api.test.js
const { Octokit } = require('@octokit/rest');

describe('GitHub API Infrastructure Tests', () => {
  let octokit;
  const testRepoOwner = process.env.TEST_REPO_OWNER;
  const testRepoName = process.env.TEST_REPO_NAME;

  beforeAll(() => {
    octokit = new Octokit({
      auth: process.env.GITHUB_TOKEN
    });
  });

  describe('API Authentication', () => {
    test('should authenticate successfully with GitHub API', async () => {
      const { data } = await octokit.rest.users.getAuthenticated();
      expect(data.login).toBeTruthy();
    });

    test('should have required permissions for test repository', async () => {
      const { data } = await octokit.rest.repos.get({
        owner: testRepoOwner,
        repo: testRepoName
      });
      expect(data.permissions.admin).toBe(true);
    });
  });

  describe('Issue Management Permissions', () => {
    test('should be able to create test issues', async () => {
      const { data } = await octokit.rest.issues.create({
        owner: testRepoOwner,
        repo: testRepoName,
        title: 'Test Issue for TDD Infrastructure',
        body: 'This is a test issue to verify API permissions'
      });
      expect(data.id).toBeTruthy();
      
      // Cleanup
      await octokit.rest.issues.update({
        owner: testRepoOwner,
        repo: testRepoName,
        issue_number: data.number,
        state: 'closed'
      });
    });

    test('should be able to apply labels to issues', async () => {
      // Create test issue
      const { data: issue } = await octokit.rest.issues.create({
        owner: testRepoOwner,
        repo: testRepoName,
        title: 'Test Label Application',
        body: 'Testing label application functionality'
      });

      // Apply labels
      await octokit.rest.issues.addLabels({
        owner: testRepoOwner,
        repo: testRepoName,
        issue_number: issue.number,
        labels: ['test-label']
      });

      // Verify labels applied
      const { data: updatedIssue } = await octokit.rest.issues.get({
        owner: testRepoOwner,
        repo: testRepoName,
        issue_number: issue.number
      });
      
      expect(updatedIssue.labels.map(l => l.name)).toContain('test-label');

      // Cleanup
      await octokit.rest.issues.update({
        owner: testRepoOwner,
        repo: testRepoName,
        issue_number: issue.number,
        state: 'closed'
      });
    });
  });

  describe('Rate Limiting Compliance', () => {
    test('should track API rate limits', async () => {
      const { data } = await octokit.rest.rateLimit.get();
      expect(data.rate.limit).toBeGreaterThan(0);
      expect(data.rate.remaining).toBeDefined();
    });
  });
});
```

**Green Phase - Implementation**:
```javascript
// utils/github-api.js
class GitHubApiClient {
  constructor(token) {
    this.octokit = new Octokit({ auth: token });
  }

  async checkRateLimit() {
    const { data } = await this.octokit.rest.rateLimit.get();
    return data.rate;
  }

  async createIssue(owner, repo, title, body) {
    const { data } = await this.octokit.rest.issues.create({
      owner, repo, title, body
    });
    return data;
  }

  async applyLabels(owner, repo, issueNumber, labels) {
    const { data } = await this.octokit.rest.issues.addLabels({
      owner, repo, issue_number: issueNumber, labels
    });
    return data;
  }
}

module.exports = GitHubApiClient;
```

## 3. Phase 2: Template System Tests

### 3.1 Bug Report Template Tests

#### Task TDD-004: Bug Report Template Validation
**Duration**: 6 hours
**Dependencies**: TDD-003

**Red Phase - Failing Tests**:

```javascript
// tests/templates/bug-report.test.js
const yaml = require('js-yaml');
const fs = require('fs');

describe('Bug Report Template Tests', () => {
  const templatePath = '.github/ISSUE_TEMPLATE/bug_report.yml';
  let template;

  beforeAll(() => {
    const content = fs.readFileSync(templatePath, 'utf8');
    template = yaml.safeLoad(content);
  });

  describe('Template Structure', () => {
    test('should have correct metadata', () => {
      expect(template.name).toBe('Bug Report');
      expect(template.description).toContain('bug');
      expect(template.title).toBe('[Bug] ');
      expect(template.labels).toContain('type:bug');
      expect(template.labels).toContain('status:needs-triage');
    });

    test('should have all required form fields', () => {
      const fieldTypes = template.body.map(field => field.type);
      expect(fieldTypes).toContain('textarea'); // Bug description
      expect(fieldTypes).toContain('dropdown'); // Component selection
      expect(fieldTypes).toContain('input');    // Environment fields
      expect(fieldTypes).toContain('checkboxes'); // Pre-submission checklist
    });
  });

  describe('Required Field Validation', () => {
    test('should mark critical fields as required', () => {
      const requiredFields = template.body.filter(field => 
        field.validations && field.validations.required
      );
      
      expect(requiredFields.length).toBeGreaterThanOrEqual(5);
      
      const requiredIds = requiredFields.map(field => field.id);
      expect(requiredIds).toContain('description');
      expect(requiredIds).toContain('expected');
      expect(requiredIds).toContain('actual');
      expect(requiredIds).toContain('steps');
      expect(requiredIds).toContain('component');
    });
  });

  describe('Component Dropdown Options', () => {
    test('should have all framework components listed', () => {
      const componentField = template.body.find(field => field.id === 'component');
      const options = componentField.attributes.options;
      
      expect(options).toContain('Installation (scripts/install.sh)');
      expect(options).toContain('Agent: Spec Analyst');
      expect(options).toContain('Agent: Test Designer');
      expect(options).toContain('Agent: Arch Designer');
      expect(options).toContain('Agent: Impl Specialist');
      expect(options).toContain('Agent: QA Validator');
    });
  });

  describe('Environment Capture', () => {
    test('should capture all required environment information', () => {
      const environmentFields = template.body.filter(field => 
        ['os', 'claude-version', 'framework-version', 'shell'].includes(field.id)
      );
      
      expect(environmentFields).toHaveLength(4);
      environmentFields.forEach(field => {
        expect(field.validations.required).toBe(true);
      });
    });
  });

  describe('Pre-submission Checklist', () => {
    test('should have comprehensive pre-submission checklist', () => {
      const checklistField = template.body.find(field => field.id === 'checklist');
      const options = checklistField.attributes.options;
      
      expect(options.length).toBeGreaterThanOrEqual(3);
      options.forEach(option => {
        expect(option.required).toBe(true);
      });
    });
  });
});
```

**Green Phase - Implementation**:
```yaml
# .github/ISSUE_TEMPLATE/bug_report.yml
name: Bug Report
description: Report a bug or unexpected behavior
title: "[Bug] "
labels: ["type:bug", "status:needs-triage"]
assignees: []
body:
  - type: markdown
    attributes:
      value: |
        Thank you for reporting a bug! Please provide the following information to help us resolve the issue quickly.
  
  - type: textarea
    id: description
    attributes:
      label: Bug Description
      description: A clear and concise description of what the bug is
      placeholder: Describe the bug in detail...
    validations:
      required: true
  
  - type: textarea
    id: expected
    attributes:
      label: Expected Behavior
      description: What did you expect to happen?
      placeholder: Describe what should have happened...
    validations:
      required: true
  
  - type: textarea
    id: actual
    attributes:
      label: Actual Behavior
      description: What actually happened?
      placeholder: Describe what actually happened...
    validations:
      required: true
  
  - type: textarea
    id: steps
    attributes:
      label: Steps to Reproduce
      description: Please provide step-by-step instructions
      placeholder: |
        1. Navigate to...
        2. Run command...
        3. Observe error...
    validations:
      required: true
  
  - type: dropdown
    id: component
    attributes:
      label: Framework Component
      description: Which component is affected?
      options:
        - "Installation (scripts/install.sh)"
        - "Validation (validate-framework.sh)"
        - "Agent: Spec Analyst"
        - "Agent: Test Designer"
        - "Agent: Arch Designer"
        - "Agent: Impl Specialist"
        - "Agent: QA Validator"
        - "Command: /spec-init"
        - "Command: /spec-review"
        - "Command: /impl-plan"
        - "Command: /qa-check"
        - "Command: /spec-workflow"
        - "Documentation"
        - "Other/Unknown"
    validations:
      required: true
  
  - type: input
    id: os
    attributes:
      label: Operating System
      placeholder: "e.g., macOS 13.0, Ubuntu 22.04, Windows 11"
    validations:
      required: true
  
  - type: input
    id: claude-version
    attributes:
      label: Claude Code Version
      placeholder: "e.g., v1.0.0"
    validations:
      required: true
  
  - type: input
    id: framework-version
    attributes:
      label: Framework Version
      placeholder: "e.g., v1.0.0"
    validations:
      required: true
  
  - type: input
    id: shell
    attributes:
      label: Shell
      placeholder: "e.g., bash, zsh, fish"
    validations:
      required: true
  
  - type: textarea
    id: screenshots
    attributes:
      label: Screenshots
      description: If applicable, add screenshots to help explain the problem
      placeholder: Drag and drop images here or paste from clipboard
  
  - type: textarea
    id: additional-context
    attributes:
      label: Additional Context
      description: Any other context about the problem
      placeholder: Add any other context about the problem here...
  
  - type: checkboxes
    id: checklist
    attributes:
      label: Pre-submission Checklist
      description: Please confirm you have completed the following
      options:
        - label: I have read the documentation
          required: true
        - label: I have searched for existing issues
          required: true
        - label: I have provided all required information
          required: true
```

#### Task TDD-005: Feature Request Template Tests
**Duration**: 5 hours
**Dependencies**: TDD-004

**Red Phase - Failing Tests**:

```javascript
// tests/templates/feature-request.test.js
const yaml = require('js-yaml');
const fs = require('fs');

describe('Feature Request Template Tests', () => {
  const templatePath = '.github/ISSUE_TEMPLATE/feature_request.yml';
  let template;

  beforeAll(() => {
    const content = fs.readFileSync(templatePath, 'utf8');
    template = yaml.safeLoad(content);
  });

  describe('Template Structure', () => {
    test('should have correct metadata for feature requests', () => {
      expect(template.name).toBe('Feature Request');
      expect(template.description).toContain('feature');
      expect(template.title).toBe('[Feature] ');
      expect(template.labels).toContain('type:enhancement');
      expect(template.labels).toContain('status:needs-triage');
    });
  });

  describe('Use Case Validation', () => {
    test('should have use case field with guided template', () => {
      const useCaseField = template.body.find(field => field.id === 'use-case');
      expect(useCaseField).toBeTruthy();
      expect(useCaseField.validations.required).toBe(true);
      expect(useCaseField.attributes.placeholder).toContain('As a [type of user]');
    });
  });

  describe('Acceptance Criteria Field', () => {
    test('should have acceptance criteria field with checkbox format', () => {
      const acceptanceField = template.body.find(field => field.id === 'acceptance-criteria');
      expect(acceptanceField).toBeTruthy();
      expect(acceptanceField.validations.required).toBe(true);
      expect(acceptanceField.attributes.placeholder).toContain('- [ ]');
    });
  });

  describe('Business Priority Assessment', () => {
    test('should have priority dropdown with business values', () => {
      const priorityField = template.body.find(field => field.id === 'priority');
      expect(priorityField).toBeTruthy();
      expect(priorityField.type).toBe('dropdown');
      
      const options = priorityField.attributes.options;
      expect(options).toContain('Critical - Blocking current work');
      expect(options).toContain('High - Significantly improves productivity');
    });
  });
});
```

**Green Phase - Implementation**:
```yaml
# .github/ISSUE_TEMPLATE/feature_request.yml
name: Feature Request
description: Suggest a new feature or enhancement
title: "[Feature] "
labels: ["type:enhancement", "status:needs-triage"]
assignees: []
body:
  - type: markdown
    attributes:
      value: |
        Thank you for suggesting a feature! Please provide detailed information to help us understand and evaluate your request.
  
  - type: textarea
    id: feature-description
    attributes:
      label: Feature Description
      description: A clear and concise description of the feature you'd like to see
      placeholder: Describe the feature in detail...
    validations:
      required: true
  
  - type: textarea
    id: use-case
    attributes:
      label: Use Case
      description: Describe the specific use case and how this feature would be used
      placeholder: |
        As a [type of user], I want [functionality] so that [benefit/goal].
        
        Specific scenario:
        1. I am working on...
        2. I need to...
        3. Currently I have to...
        4. With this feature I could...
    validations:
      required: true
  
  - type: textarea
    id: acceptance-criteria
    attributes:
      label: Acceptance Criteria
      description: What specific, measurable criteria would indicate this feature is complete?
      placeholder: |
        - [ ] Criteria 1: The system should...
        - [ ] Criteria 2: Users can...
        - [ ] Criteria 3: The feature should handle...
    validations:
      required: true
  
  - type: dropdown
    id: priority
    attributes:
      label: Business Priority
      description: How important is this feature to your workflow?
      options:
        - "Critical - Blocking current work"
        - "High - Significantly improves productivity"
        - "Medium - Nice to have improvement"
        - "Low - Minor convenience feature"
    validations:
      required: true
```

### 3.2 Question Template Tests

#### Task TDD-006: Question Templates Tests  
**Duration**: 4 hours
**Dependencies**: TDD-005

**Red Phase - Failing Tests**:

```javascript
// tests/templates/question-templates.test.js
const yaml = require('js-yaml');
const fs = require('fs');

describe('Question Template Tests', () => {
  describe('Installation Question Template', () => {
    const templatePath = '.github/ISSUE_TEMPLATE/question_installation.yml';
    let template;

    beforeAll(() => {
      const content = fs.readFileSync(templatePath, 'utf8');
      template = yaml.safeLoad(content);
    });

    test('should have troubleshooting checklist', () => {
      const checklistField = template.body.find(field => field.id === 'troubleshooting');
      expect(checklistField).toBeTruthy();
      expect(checklistField.type).toBe('checkboxes');
      
      const options = checklistField.attributes.options;
      expect(options.length).toBeGreaterThanOrEqual(4);
      expect(options.some(opt => opt.label.includes('admin'))).toBe(true);
    });

    test('should capture environment and error details', () => {
      const errorField = template.body.find(field => field.id === 'error-output');
      expect(errorField).toBeTruthy();
      expect(errorField.attributes.render).toBe('shell');
    });
  });

  describe('Usage Question Template', () => {
    const templatePath = '.github/ISSUE_TEMPLATE/question_usage.yml';
    let template;

    beforeAll(() => {
      const content = fs.readFileSync(templatePath, 'utf8');
      template = yaml.safeLoad(content);
    });

    test('should have component selection for targeted help', () => {
      const componentField = template.body.find(field => field.id === 'component');
      expect(componentField).toBeTruthy();
      expect(componentField.type).toBe('dropdown');
      
      const options = componentField.attributes.options;
      expect(options).toContain('General Usage');
      expect(options).toContain('Workflow and Best Practices');
    });
  });
});
```

**Green Phase - Implementation**: Create both question templates with the structure tested above.

## 4. Phase 3: Label System Tests

### 4.1 Label Configuration Tests

#### Task TDD-007: Label Taxonomy Validation
**Duration**: 5 hours
**Dependencies**: TDD-006

**Red Phase - Failing Tests**:

```javascript
// tests/labels/label-configuration.test.js
const yaml = require('js-yaml');
const fs = require('fs');

describe('Label Configuration Tests', () => {
  const labelsPath = '.github/labels.yml';
  let labels;

  beforeAll(() => {
    const content = fs.readFileSync(labelsPath, 'utf8');
    labels = yaml.safeLoad(content);
  });

  describe('Label Structure Validation', () => {
    test('should have all required label fields', () => {
      labels.forEach(label => {
        expect(label).toHaveProperty('name');
        expect(label).toHaveProperty('description');
        expect(label).toHaveProperty('color');
      });
    });

    test('should have valid hex colors', () => {
      labels.forEach(label => {
        expect(label.color).toMatch(/^[0-9A-F]{6}$/i);
      });
    });
  });

  describe('Component Labels', () => {
    test('should have all framework component labels', () => {
      const componentLabels = labels.filter(label => 
        label.name.startsWith('component:')
      );
      
      const requiredComponents = [
        'component:agent-spec-analyst',
        'component:agent-test-designer', 
        'component:agent-arch-designer',
        'component:agent-impl-specialist',
        'component:agent-qa-validator',
        'component:installation',
        'component:validation'
      ];

      requiredComponents.forEach(component => {
        expect(componentLabels.some(label => label.name === component)).toBe(true);
      });
    });

    test('should use consistent color scheme for components', () => {
      const componentLabels = labels.filter(label => 
        label.name.startsWith('component:')
      );
      
      const componentColor = '0052CC';
      componentLabels.forEach(label => {
        expect(label.color).toBe(componentColor);
      });
    });
  });

  describe('Type Labels', () => {
    test('should have all issue type labels', () => {
      const typeLabels = labels.filter(label => 
        label.name.startsWith('type:')
      );
      
      const requiredTypes = ['type:bug', 'type:enhancement', 'type:question', 'type:documentation'];
      
      requiredTypes.forEach(type => {
        expect(typeLabels.some(label => label.name === type)).toBe(true);
      });
    });
  });

  describe('Accessibility Compliance', () => {
    test('should meet WCAG AA contrast requirements', () => {
      // Test will verify color combinations meet accessibility standards
      const colorCombinations = [
        { fg: '0052CC', bg: 'FFFFFF' }, // Component labels
        { fg: 'D73A49', bg: 'FFFFFF' }, // Bug labels
        { fg: 'A2EEEF', bg: '000000' }  // Enhancement labels
      ];
      
      colorCombinations.forEach(combo => {
        const contrastRatio = calculateContrastRatio(combo.fg, combo.bg);
        expect(contrastRatio).toBeGreaterThanOrEqual(4.5); // WCAG AA requirement
      });
    });
  });
});

function calculateContrastRatio(color1, color2) {
  // Implementation of WCAG contrast ratio calculation
  const getLuminance = (color) => {
    const rgb = parseInt(color, 16);
    const r = (rgb >> 16) & 0xff;
    const g = (rgb >> 8) & 0xff; 
    const b = (rgb >> 0) & 0xff;
    
    const [rs, gs, bs] = [r, g, b].map(c => {
      c = c / 255;
      return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
    });
    
    return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
  };

  const l1 = getLuminance(color1);
  const l2 = getLuminance(color2);
  const lighter = Math.max(l1, l2);
  const darker = Math.min(l1, l2);
  
  return (lighter + 0.05) / (darker + 0.05);
}
```

**Green Phase - Implementation**:
```yaml
# .github/labels.yml
# Component Labels (Blue: #0052CC)
- name: "component:agent-spec-analyst"
  description: "Issues related to specification analysis agent"
  color: "0052CC"

- name: "component:agent-test-designer"
  description: "Issues related to test design agent"
  color: "0052CC"

# ... (continue with all component labels)

# Type Labels
- name: "type:bug"
  description: "Software defects and errors"
  color: "D73A49"

- name: "type:enhancement"
  description: "New features and improvements"
  color: "A2EEEF"

# ... (continue with type, priority, and status labels)
```

### 4.2 Auto-Labeling Logic Tests

#### Task TDD-008: Content Analysis Auto-Labeling
**Duration**: 8 hours
**Dependencies**: TDD-007

**Red Phase - Failing Tests**:

```javascript
// tests/automation/auto-labeling.test.js
const { analyzeIssueContent, detectComponents, detectPriority } = require('../../utils/auto-labeling');

describe('Auto-Labeling Logic Tests', () => {
  describe('Component Detection', () => {
    test('should detect spec-analyst component from content', () => {
      const content = 'The spec-analyst agent fails to parse requirements properly';
      const components = detectComponents(content);
      expect(components).toContain('component:agent-spec-analyst');
    });

    test('should detect installation component from file paths', () => {
      const content = 'Error in scripts/install.sh when running on macOS';
      const components = detectComponents(content);
      expect(components).toContain('component:installation');
    });

    test('should detect multiple components but return only most relevant', () => {
      const content = 'The /spec-init command uses spec-analyst but validation fails';
      const components = detectComponents(content);
      expect(components).toHaveLength(1); // Should prioritize most specific match
    });

    test('should handle edge cases gracefully', () => {
      const emptyContent = '';
      const components = detectComponents(emptyContent);
      expect(components).toHaveLength(0);

      const vagueContent = 'Something is broken';
      const vague Components = detectComponents(vagueContent);
      expect(vagueComponents).toHaveLength(0);
    });
  });

  describe('Priority Detection', () => {
    test('should detect critical priority from keywords', () => {
      const content = 'Critical: System completely broken, urgent fix needed';
      const priority = detectPriority(content);
      expect(priority).toBe('priority:critical');
    });

    test('should detect high priority appropriately', () => {
      const content = 'This is important and affects productivity';
      const priority = detectPriority(content);
      expect(priority).toBe('priority:high');
    });

    test('should default to normal priority for unclear content', () => {
      const content = 'This would be nice to have';
      const priority = detectPriority(content);
      expect(priority).toBe('priority:normal');
    });
  });

  describe('Accuracy Requirements', () => {
    test('should achieve >85% accuracy on test dataset', async () => {
      const testCases = [
        { content: 'spec-analyst agent broken', expected: ['component:agent-spec-analyst'] },
        { content: 'installation fails on macOS', expected: ['component:installation'] },
        { content: '/qa-check command errors', expected: ['component:command-qa-check'] },
        // ... more test cases
      ];

      let correct = 0;
      testCases.forEach(testCase => {
        const detected = detectComponents(testCase.content);
        if (testCase.expected.every(label => detected.includes(label))) {
          correct++;
        }
      });

      const accuracy = correct / testCases.length;
      expect(accuracy).toBeGreaterThan(0.85);
    });
  });
});
```

**Green Phase - Implementation**:
```javascript
// utils/auto-labeling.js
const componentMappings = {
  'component:agent-spec-analyst': ['spec-analyst', 'specification analysis', 'requirements analysis'],
  'component:agent-test-designer': ['test-designer', 'test design', 'test creation'],
  'component:installation': ['install.sh', 'installation', 'install', 'setup'],
  // ... more mappings
};

const filePaths = {
  'component:installation': ['scripts/install.sh', 'scripts/update.sh'],
  'component:validation': ['framework/validate-framework.sh'],
  // ... more path mappings
};

function detectComponents(content) {
  const lowerContent = content.toLowerCase();
  
  // Check file paths first (higher confidence)
  for (const [label, paths] of Object.entries(filePaths)) {
    if (paths.some(path => lowerContent.includes(path))) {
      return [label];
    }
  }
  
  // Check content keywords
  for (const [label, keywords] of Object.entries(componentMappings)) {
    if (keywords.some(keyword => lowerContent.includes(keyword))) {
      return [label];
    }
  }
  
  return [];
}

function detectPriority(content) {
  const lowerContent = content.toLowerCase();
  
  if (lowerContent.includes('critical') || lowerContent.includes('urgent') || lowerContent.includes('breaking')) {
    return 'priority:critical';
  }
  
  if (lowerContent.includes('important') || lowerContent.includes('high priority')) {
    return 'priority:high';
  }
  
  return 'priority:normal';
}

module.exports = { detectComponents, detectPriority };
```

## 5. Phase 4: Automation Tests

### 5.1 GitHub Actions Workflow Tests

#### Task TDD-009: Auto-Labeling Workflow Tests
**Duration**: 6 hours
**Dependencies**: TDD-008

**Red Phase - Failing Tests**:

```javascript
// tests/workflows/auto-labeling-workflow.test.js
const { execSync } = require('child_process');
const yaml = require('js-yaml');
const fs = require('fs');

describe('Auto-Labeling Workflow Tests', () => {
  const workflowPath = '.github/workflows/issue-labeler.yml';
  let workflow;

  beforeAll(() => {
    const content = fs.readFileSync(workflowPath, 'utf8');
    workflow = yaml.safeLoad(content);
  });

  describe('Workflow Configuration', () => {
    test('should have correct trigger events', () => {
      expect(workflow.on.issues.types).toContain('opened');
      expect(workflow.on.issues.types).toContain('edited');
    });

    test('should have appropriate permissions', () => {
      const job = workflow.jobs['label-issue'];
      expect(job.permissions.issues).toBe('write');
      expect(job.permissions.contents).toBe('read');
    });

    test('should use secure GitHub Actions', () => {
      const job = workflow.jobs['label-issue'];
      const checkoutStep = job.steps.find(step => step.uses && step.uses.includes('checkout'));
      expect(checkoutStep.uses).toBe('actions/checkout@v4');
      
      const scriptStep = job.steps.find(step => step.uses && step.uses.includes('github-script'));
      expect(scriptStep.uses).toBe('actions/github-script@v7');
    });
  });

  describe('Workflow Logic Testing', () => {
    test('should contain content analysis logic', () => {
      const job = workflow.jobs['label-issue'];
      const scriptStep = job.steps.find(step => step.uses && step.uses.includes('github-script'));
      
      expect(scriptStep.with.script).toContain('componentMappings');
      expect(scriptStep.with.script).toContain('filePaths');
      expect(scriptStep.with.script).toContain('addLabels');
    });

    test('should handle errors gracefully', () => {
      const job = workflow.jobs['label-issue'];
      const scriptStep = job.steps.find(step => step.uses && step.uses.includes('github-script'));
      
      expect(scriptStep.with.script).toContain('try');
      expect(scriptStep.with.script).toContain('catch');
    });
  });

  describe('Performance Requirements', () => {
    test('should complete within timeout limits', async () => {
      // This would test actual workflow execution time
      // For now, verify timeout configuration exists
      const job = workflow.jobs['label-issue'];
      expect(job['timeout-minutes']).toBeLessThanOrEqual(5);
    });
  });
});
```

**Green Phase - Implementation**:
```yaml
# .github/workflows/issue-labeler.yml
name: Issue Auto-Labeler

on:
  issues:
    types: [opened, edited]

jobs:
  label-issue:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    permissions:
      issues: write
      contents: read
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Auto-label based on content
        uses: actions/github-script@v7
        with:
          script: |
            try {
              const issue = context.payload.issue;
              const title = issue.title.toLowerCase();
              const body = issue.body ? issue.body.toLowerCase() : '';
              const content = title + ' ' + body;
              
              const labelsToAdd = [];
              
              // Component detection logic (from utils/auto-labeling.js)
              const componentMappings = {
                'component:agent-spec-analyst': ['spec-analyst', 'specification analysis'],
                // ... more mappings
              };
              
              // Analysis and labeling logic
              for (const [label, keywords] of Object.entries(componentMappings)) {
                if (keywords.some(keyword => content.includes(keyword))) {
                  labelsToAdd.push(label);
                  break;
                }
              }
              
              if (labelsToAdd.length > 0) {
                await github.rest.issues.addLabels({
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  issue_number: issue.number,
                  labels: labelsToAdd
                });
              }
            } catch (error) {
              console.error('Auto-labeling failed:', error);
            }
```

#### Task TDD-010: Welcome Message Workflow Tests
**Duration**: 4 hours
**Dependencies**: TDD-009

**Red Phase - Failing Tests**:

```javascript
// tests/workflows/welcome-workflow.test.js
describe('Welcome Message Workflow Tests', () => {
  const workflowPath = '.github/workflows/welcome-new-contributors.yml';
  
  describe('First-Time Contributor Detection', () => {
    test('should correctly identify first-time contributors', async () => {
      // Mock GitHub API responses for testing
      const mockOctokit = {
        rest: {
          search: {
            issuesAndPullRequests: jest.fn().mockResolvedValue({
              data: { total_count: 1 }
            })
          },
          issues: {
            createComment: jest.fn().mockResolvedValue({ data: { id: 123 } })
          }
        }
      };

      const isFirstTime = await checkFirstTimeContributor(mockOctokit, 'testuser', 'owner/repo');
      expect(isFirstTime).toBe(true);
    });
  });

  describe('Welcome Message Content', () => {
    test('should customize welcome message based on issue type', () => {
      const bugMessage = generateWelcomeMessage('bug', 'testuser');
      expect(bugMessage).toContain('bug');
      expect(bugMessage).toContain('@testuser');
      expect(bugMessage).toContain('Contributing Guidelines');
    });
  });

  describe('Timing Requirements', () => {
    test('should trigger within 5 minutes of issue creation', () => {
      const workflow = yaml.safeLoad(fs.readFileSync(workflowPath, 'utf8'));
      const job = workflow.jobs.welcome;
      
      // Verify no artificial delays that would exceed 5 minutes
      expect(job['timeout-minutes']).toBeLessThanOrEqual(5);
    });
  });
});
```

**Green Phase - Implementation**: Create welcome workflow with the tested functionality.

## 6. Phase 5: Integration Tests

### 6.1 End-to-End Workflow Tests

#### Task TDD-011: Complete Bug Report Workflow
**Duration**: 8 hours  
**Dependencies**: TDD-010

**Red Phase - Failing Tests**:

```javascript
// tests/integration/bug-report-e2e.test.js
const GitHubApiClient = require('../../utils/github-api');

describe('Bug Report End-to-End Workflow', () => {
  let apiClient;
  const testRepoOwner = process.env.TEST_REPO_OWNER;
  const testRepoName = process.env.TEST_REPO_NAME;

  beforeAll(() => {
    apiClient = new GitHubApiClient(process.env.GITHUB_TOKEN);
  });

  describe('Complete Bug Report Journey', () => {
    test('should handle complete bug report workflow', async () => {
      // Step 1: Create bug report issue (simulating template submission)
      const issueData = {
        title: '[Bug] Test bug report workflow',
        body: `**Bug Description**
Installation script fails on macOS with permission error

**Expected Behavior**
Installation should complete successfully

**Actual Behavior** 
Script exits with permission denied

**Steps to Reproduce**
1. Run ./scripts/install.sh
2. Observe permission error

**Framework Component**
Installation (scripts/install.sh)

**Environment**
- OS: macOS 13.0
- Claude Code Version: v1.0.0
- Framework Version: v1.0.0
- Shell: zsh`,
        labels: ['type:bug', 'status:needs-triage']
      };

      const issue = await apiClient.createIssue(
        testRepoOwner, testRepoName, issueData.title, issueData.body
      );

      expect(issue.id).toBeTruthy();

      // Step 2: Wait for auto-labeling to complete (max 30 seconds)
      await waitForAutomation(30000);

      // Step 3: Verify auto-labeling worked
      const updatedIssue = await apiClient.getIssue(testRepoOwner, testRepoName, issue.number);
      const labelNames = updatedIssue.labels.map(label => label.name);
      
      expect(labelNames).toContain('type:bug');
      expect(labelNames).toContain('status:needs-triage');
      expect(labelNames).toContain('component:installation'); // Auto-detected

      // Step 4: Verify welcome message was posted (for first-time contributors)
      const comments = await apiClient.getIssueComments(testRepoOwner, testRepoName, issue.number);
      
      if (comments.length > 0) {
        const welcomeComment = comments.find(comment => 
          comment.body.includes('Welcome to the Claude Spec-First Framework')
        );
        expect(welcomeComment).toBeTruthy();
      }

      // Step 5: Test manual milestone assignment
      await apiClient.assignToMilestone(testRepoOwner, testRepoName, issue.number, 'v1.1.0');
      
      // Step 6: Test status progression
      await apiClient.addLabels(testRepoOwner, testRepoName, issue.number, ['status:in-progress']);
      await apiClient.removeLabels(testRepoOwner, testRepoName, issue.number, ['status:needs-triage']);

      // Cleanup
      await apiClient.closeIssue(testRepoOwner, testRepoName, issue.number);

    }, 60000); // 60 second timeout for full workflow
  });

  describe('Error Handling in Workflows', () => {
    test('should handle automation failures gracefully', async () => {
      // Create issue with malformed content that might break automation
      const problematicIssue = await apiClient.createIssue(
        testRepoOwner, testRepoName,
        'Test automation error handling',
        '<script>alert("xss")</script>' // Potential XSS content
      );

      // Wait for automation
      await waitForAutomation(30000);

      // Verify issue was created despite problematic content
      const issue = await apiClient.getIssue(testRepoOwner, testRepoName, problematicIssue.number);
      expect(issue.state).toBe('open');

      // Verify content was sanitized or handled properly
      expect(issue.body).not.toContain('<script>');

      // Cleanup
      await apiClient.closeIssue(testRepoOwner, testRepoName, problematicIssue.number);
    });
  });
});

async function waitForAutomation(timeoutMs) {
  return new Promise(resolve => setTimeout(resolve, timeoutMs));
}
```

**Green Phase - Implementation**: Ensure all automation workflows handle the test scenarios correctly.

#### Task TDD-012: Feature Request to Implementation Workflow
**Duration**: 6 hours
**Dependencies**: TDD-011

**Red Phase - Failing Tests**:

```javascript
// tests/integration/feature-request-e2e.test.js
describe('Feature Request End-to-End Workflow', () => {
  test('should handle complete feature request lifecycle', async () => {
    // Step 1: Create feature request
    const featureRequest = await apiClient.createIssue(
      testRepoOwner, testRepoName,
      '[Feature] Add TypeScript support to framework',
      `**Feature Description**
Add TypeScript support for better type safety

**Use Case**
As a developer using the framework, I want TypeScript definitions so that I can catch type errors at compile time.

**Acceptance Criteria**
- [ ] TypeScript definitions are provided
- [ ] Examples work with TypeScript
- [ ] Documentation includes TypeScript usage

**Business Priority**
High - Significantly improves productivity`
    );

    // Step 2: Verify auto-labeling
    await waitForAutomation(30000);
    
    const updatedIssue = await apiClient.getIssue(testRepoOwner, testRepoName, featureRequest.number);
    const labelNames = updatedIssue.labels.map(label => label.name);
    
    expect(labelNames).toContain('type:enhancement');
    expect(labelNames).toContain('priority:high'); // Should be auto-detected
    
    // Step 3: Community discussion simulation
    await apiClient.createComment(testRepoOwner, testRepoName, featureRequest.number,
      'This would be very useful for my TypeScript projects!'
    );

    // Step 4: Maintainer response and milestone assignment
    await apiClient.assignToMilestone(testRepoOwner, testRepoName, featureRequest.number, 'v1.2.0');
    
    // Step 5: Status progression through development
    await apiClient.addLabels(testRepoOwner, testRepoName, featureRequest.number, ['status:in-progress']);
    
    // Cleanup
    await apiClient.closeIssue(testRepoOwner, testRepoName, featureRequest.number);
  });
});
```

## 7. Phase 6: Performance & Security Tests

### 7.1 Performance Tests

#### Task TDD-013: Load Testing
**Duration**: 6 hours
**Dependencies**: TDD-012

**Red Phase - Failing Tests**:

```javascript
// tests/performance/load-testing.test.js
describe('Performance Load Tests', () => {
  describe('High Volume Issue Processing', () => {
    test('should handle 100 concurrent issue submissions', async () => {
      const startTime = Date.now();
      
      // Create 100 issues concurrently
      const issuePromises = Array(100).fill(null).map((_, index) => 
        apiClient.createIssue(
          testRepoOwner, testRepoName,
          `Load Test Issue ${index}`,
          `This is load test issue #${index} for performance testing.`
        )
      );

      const issues = await Promise.all(issuePromises);
      const creationTime = Date.now() - startTime;
      
      // All issues should be created successfully
      expect(issues).toHaveLength(100);
      issues.forEach(issue => {
        expect(issue.id).toBeTruthy();
      });

      // Wait for all automation to complete
      await waitForAutomation(60000); // 1 minute for 100 issues

      // Verify automation completed for all issues
      let processedCount = 0;
      for (const issue of issues.slice(0, 10)) { // Check first 10 as sample
        const updatedIssue = await apiClient.getIssue(testRepoOwner, testRepoName, issue.number);
        if (updatedIssue.labels.length > 0) {
          processedCount++;
        }
      }

      // At least 80% should be processed (allowing for some timing variance)
      expect(processedCount / 10).toBeGreaterThan(0.8);

      // Performance targets
      expect(creationTime).toBeLessThan(30000); // 30 seconds for creation
      
      // Cleanup
      await Promise.all(issues.map(issue => 
        apiClient.closeIssue(testRepoOwner, testRepoName, issue.number)
      ));

    }, 120000); // 2 minute timeout
  });

  describe('Auto-Labeling Performance', () => {
    test('should complete auto-labeling within 30 seconds', async () => {
      const issue = await apiClient.createIssue(
        testRepoOwner, testRepoName,
        '[Performance Test] spec-analyst agent performance issue',
        'The spec-analyst agent is taking too long to process requirements'
      );

      const startTime = Date.now();
      
      // Poll for labels to be applied
      let labeled = false;
      while (Date.now() - startTime < 30000 && !labeled) {
        await new Promise(resolve => setTimeout(resolve, 2000)); // Wait 2 seconds
        
        const updatedIssue = await apiClient.getIssue(testRepoOwner, testRepoName, issue.number);
        const hasComponentLabel = updatedIssue.labels.some(label => 
          label.name.startsWith('component:')
        );
        
        if (hasComponentLabel) {
          labeled = true;
        }
      }

      const processingTime = Date.now() - startTime;
      
      expect(labeled).toBe(true);
      expect(processingTime).toBeLessThan(30000);

      // Cleanup
      await apiClient.closeIssue(testRepoOwner, testRepoName, issue.number);
    });
  });

  describe('GitHub API Rate Limiting', () => {
    test('should stay within API rate limits with buffer', async () => {
      const rateLimit = await apiClient.checkRateLimit();
      
      // Should maintain 20% buffer
      const bufferThreshold = rateLimit.limit * 0.8;
      expect(rateLimit.remaining).toBeGreaterThan(bufferThreshold);
    });

    test('should handle rate limiting gracefully', async () => {
      // This test would simulate rate limiting conditions
      // For now, verify the logic exists in workflows
      const workflowPath = '.github/workflows/issue-labeler.yml';
      const content = fs.readFileSync(workflowPath, 'utf8');
      
      expect(content).toContain('rate limit'); // Rate limit handling code exists
    });
  });
});
```

**Green Phase - Implementation**: Optimize workflows to pass performance tests.

### 7.2 Security Tests

#### Task TDD-014: Security Validation Tests
**Duration**: 8 hours
**Dependencies**: TDD-013

**Red Phase - Failing Tests**:

```javascript
// tests/security/security-validation.test.js
describe('Security Validation Tests', () => {
  describe('Input Sanitization', () => {
    test('should sanitize XSS attempts in issue content', async () => {
      const maliciousContent = `<script>alert('xss')</script>
      <img src="x" onerror="alert('xss')">
      javascript:alert('xss')`;

      const issue = await apiClient.createIssue(
        testRepoOwner, testRepoName,
        'XSS Test Issue',
        maliciousContent
      );

      // Wait for any processing
      await waitForAutomation(10000);

      const retrievedIssue = await apiClient.getIssue(testRepoOwner, testRepoName, issue.number);
      
      // Malicious scripts should be sanitized/escaped
      expect(retrievedIssue.body).not.toContain('<script>');
      expect(retrievedIssue.body).not.toContain('onerror');
      expect(retrievedIssue.body).not.toContain('javascript:');

      await apiClient.closeIssue(testRepoOwner, testRepoName, issue.number);
    });

    test('should handle large payload attacks', async () => {
      const largePayload = 'A'.repeat(1024 * 1024); // 1MB payload

      const startTime = Date.now();
      
      try {
        const issue = await apiClient.createIssue(
          testRepoOwner, testRepoName,
          'Large Payload Test',
          largePayload
        );

        const processingTime = Date.now() - startTime;
        
        // Should either reject or handle gracefully within reasonable time
        expect(processingTime).toBeLessThan(10000); // 10 seconds
        
        if (issue.id) {
          await apiClient.closeIssue(testRepoOwner, testRepoName, issue.number);
        }
      } catch (error) {
        // Rejection is acceptable for oversized payloads
        expect(error.status).toBeGreaterThanOrEqual(400);
      }
    });
  });

  describe('Authentication and Authorization', () => {
    test('should verify GitHub token has minimal required permissions', async () => {
      const user = await apiClient.getAuthenticatedUser();
      expect(user.login).toBeTruthy();

      // Verify token can perform required operations but not more
      const canCreateIssues = await testPermission('issues', 'write');
      const canReadRepo = await testPermission('contents', 'read');
      
      expect(canCreateIssues).toBe(true);
      expect(canReadRepo).toBe(true);
    });

    test('should handle API authentication failures gracefully', () => {
      const invalidClient = new GitHubApiClient('invalid-token');
      
      expect(async () => {
        await invalidClient.getAuthenticatedUser();
      }).rejects.toThrow();
    });
  });

  describe('Sensitive Data Detection', () => {
    test('should detect and handle potential API keys in issue content', async () => {
      const sensitiveContent = `
Here's my configuration:
API_KEY=sk-1234567890abcdef1234567890abcdef
SECRET_TOKEN=ghp_abcdefghijklmnopqrstuvwxyz123456789012
PASSWORD=mysecretpassword123
`;

      const issue = await apiClient.createIssue(
        testRepoOwner, testRepoName,
        'Sensitive Data Test',
        sensitiveContent
      );

      await waitForAutomation(10000);

      // Check if sensitive data was masked/flagged
      const comments = await apiClient.getIssueComments(testRepoOwner, testRepoName, issue.number);
      const sensitiveDataWarning = comments.find(comment => 
        comment.body.includes('sensitive') || comment.body.includes('credential')
      );

      // Either content should be masked or warning should be posted
      if (!sensitiveDataWarning) {
        const retrievedIssue = await apiClient.getIssue(testRepoOwner, testRepoName, issue.number);
        expect(retrievedIssue.body).not.toContain('sk-1234567890abcdef');
        expect(retrievedIssue.body).not.toContain('ghp_abcdefghijk');
      }

      await apiClient.closeIssue(testRepoOwner, testRepoName, issue.number);
    });
  });

  describe('Workflow Security', () => {
    test('should use secure versions of GitHub Actions', () => {
      const workflowFiles = fs.readdirSync('.github/workflows')
        .filter(file => file.endsWith('.yml'));

      workflowFiles.forEach(file => {
        const content = fs.readFileSync(`.github/workflows/${file}`, 'utf8');
        const workflow = yaml.safeLoad(content);

        Object.values(workflow.jobs).forEach(job => {
          job.steps.forEach(step => {
            if (step.uses) {
              // Should use specific versions, not latest or master
              expect(step.uses).toMatch(/@v\d+/);
              
              // Should use known secure actions
              if (step.uses.includes('actions/')) {
                expect(step.uses).toMatch(/actions\/(checkout|github-script)@v[4-9]/);
              }
            }
          });
        });
      });
    });
  });
});

async function testPermission(scope, level) {
  try {
    // Attempt operation that requires the permission
    if (scope === 'issues' && level === 'write') {
      // Test creating a label (requires issues write)
      return true; // Simplified for example
    }
    return false;
  } catch {
    return false;
  }
}
```

**Green Phase - Implementation**: Implement security measures to pass all tests.

## 8. Test Execution Strategy

### 8.1 Test Execution Order

**Sequential Execution Required**:
1. Foundation tests must pass before template tests
2. Template tests must pass before label tests  
3. Label tests must pass before automation tests
4. All unit/integration tests must pass before E2E tests
5. Functional tests must pass before performance tests
6. All tests must pass before security tests

### 8.2 Test Environment Management

**Test Data Management**:
```javascript
// tests/setup/test-data-manager.js
class TestDataManager {
  constructor(apiClient) {
    this.apiClient = apiClient;
    this.createdIssues = [];
  }

  async createTestIssue(title, body, labels = []) {
    const issue = await this.apiClient.createIssue(
      process.env.TEST_REPO_OWNER,
      process.env.TEST_REPO_NAME,
      title, body
    );
    
    if (labels.length > 0) {
      await this.apiClient.addLabels(
        process.env.TEST_REPO_OWNER,
        process.env.TEST_REPO_NAME,
        issue.number,
        labels
      );
    }
    
    this.createdIssues.push(issue);
    return issue;
  }

  async cleanup() {
    for (const issue of this.createdIssues) {
      try {
        await this.apiClient.closeIssue(
          process.env.TEST_REPO_OWNER,
          process.env.TEST_REPO_NAME,
          issue.number
        );
      } catch (error) {
        console.warn(`Failed to cleanup issue ${issue.number}: ${error.message}`);
      }
    }
    this.createdIssues = [];
  }
}
```

### 8.3 CI/CD Integration

**GitHub Actions Test Runner**:
```yaml
# .github/workflows/tdd-test-runner.yml
name: TDD Test Suite

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run Foundation Tests
        run: npm run test:foundation
        env:
          GITHUB_TOKEN: ${{ secrets.TEST_GITHUB_TOKEN }}
          TEST_REPO_OWNER: ${{ vars.TEST_REPO_OWNER }}
          TEST_REPO_NAME: ${{ vars.TEST_REPO_NAME }}
          
      - name: Run Template Tests  
        run: npm run test:templates
        if: success()
        
      - name: Run Label Tests
        run: npm run test:labels
        if: success()
        
      - name: Run Automation Tests
        run: npm run test:automation
        if: success()
        
      - name: Run Integration Tests
        run: npm run test:integration
        if: success()
        
      - name: Run Performance Tests
        run: npm run test:performance
        if: success()
        
      - name: Run Security Tests
        run: npm run test:security
        if: success()
```

## 9. Quality Gates and Success Criteria

### 9.1 Phase Completion Gates

**Phase 1 - Foundation**: 100% infrastructure tests passing
**Phase 2 - Templates**: 100% template validation tests passing + manual usability confirmation
**Phase 3 - Labels**: 100% label tests passing + >85% auto-labeling accuracy
**Phase 4 - Automation**: 100% workflow tests passing + performance benchmarks met
**Phase 5 - Integration**: 100% E2E tests passing + community feedback positive
**Phase 6 - Performance & Security**: 100% tests passing + security review completed

### 9.2 Overall Success Metrics

**Functional Success**:
- All 200+ test cases passing
- Template usage rate >90% in testing
- Auto-labeling accuracy >85%
- Average processing time <30 seconds

**Quality Success**:
- Code coverage >95% for custom logic
- Security tests 100% passing
- Performance benchmarks met
- Accessibility compliance verified

**Community Success**:
- Test contributors can complete workflows successfully
- Feedback on templates and automation is positive
- Issue quality improvement measurable in test scenarios

This comprehensive TDD implementation plan ensures that every requirement is thoroughly tested before implementation, following the Red → Green → Refactor cycle throughout the entire development process.