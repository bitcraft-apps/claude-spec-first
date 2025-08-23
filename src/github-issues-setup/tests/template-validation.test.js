/**
 * Template Validation Tests
 * Validates GitHub issue templates for correctness and completeness
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

describe('GitHub Issue Template Validation', () => {
  const templateDir = path.join(__dirname, '../../../.github/ISSUE_TEMPLATE');
  const requiredTemplates = [
    'bug_report.yml',
    'feature_request.yml',
    'question_installation.yml',
    'question_usage.yml',
    'documentation.yml',
    'config.yml'
  ];

  describe('Template File Existence', () => {
    test('should have all required template files', () => {
      for (const template of requiredTemplates) {
        const templatePath = path.join(templateDir, template);
        expect(fs.existsSync(templatePath)).toBe(true);
      }
    });

    test('should have template directory', () => {
      expect(fs.existsSync(templateDir)).toBe(true);
    });
  });

  describe('YAML Syntax Validation', () => {
    test('should have valid YAML syntax for all templates', () => {
      const templateFiles = fs.readdirSync(templateDir)
        .filter(file => file.endsWith('.yml'));

      for (const file of templateFiles) {
        const filePath = path.join(templateDir, file);
        const content = fs.readFileSync(filePath, 'utf8');
        
        expect(() => yaml.load(content)).not.toThrow();
      }
    });
  });

  describe('GitHub Template Schema Validation', () => {
    test('should have required schema fields for issue templates', () => {
      const issueTemplates = requiredTemplates.filter(file => 
        file !== 'config.yml'
      );

      for (const file of issueTemplates) {
        const filePath = path.join(templateDir, file);
        const content = fs.readFileSync(filePath, 'utf8');
        const template = yaml.load(content);

        // Required fields for GitHub issue templates
        expect(template).toHaveProperty('name');
        expect(template).toHaveProperty('description');
        expect(template).toHaveProperty('body');

        expect(typeof template.name).toBe('string');
        expect(typeof template.description).toBe('string');
        expect(Array.isArray(template.body)).toBe(true);
      }
    });

    test('should have valid config.yml structure', () => {
      const configPath = path.join(templateDir, 'config.yml');
      const content = fs.readFileSync(configPath, 'utf8');
      const config = yaml.load(content);

      expect(config).toHaveProperty('blank_issues_enabled');
      expect(config).toHaveProperty('contact_links');
      expect(Array.isArray(config.contact_links)).toBe(true);

      if (config.contact_links.length > 0) {
        for (const link of config.contact_links) {
          expect(link).toHaveProperty('name');
          expect(link).toHaveProperty('url');
          expect(link).toHaveProperty('about');
        }
      }
    });
  });

  describe('Bug Report Template Validation', () => {
    let template;

    beforeAll(() => {
      const templatePath = path.join(templateDir, 'bug_report.yml');
      const content = fs.readFileSync(templatePath, 'utf8');
      template = yaml.load(content);
    });

    test('should have correct metadata', () => {
      expect(template.name).toBe('Bug Report');
      expect(template.description).toContain('bug');
      expect(template.title).toBe('[Bug] ');
      expect(template.labels).toContain('type:bug');
      expect(template.labels).toContain('status:needs-triage');
    });

    test('should have required form fields', () => {
      const fieldIds = template.body.map(field => field.id).filter(Boolean);
      
      expect(fieldIds).toContain('description');
      expect(fieldIds).toContain('expected');
      expect(fieldIds).toContain('actual');
      expect(fieldIds).toContain('steps');
      expect(fieldIds).toContain('component');
    });

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

    test('should have comprehensive component options', () => {
      const componentField = template.body.find(field => field.id === 'component');
      expect(componentField).toBeTruthy();
      expect(componentField.type).toBe('dropdown');
      
      const options = componentField.attributes.options;
      expect(options).toContain('Installation (scripts/install.sh)');
      expect(options).toContain('Agent: Spec Analyst');
      expect(options).toContain('Documentation');
    });

    test('should capture environment information', () => {
      const environmentFields = ['os', 'claude-version', 'framework-version', 'shell'];
      const bodyIds = template.body.map(field => field.id);
      
      for (const envField of environmentFields) {
        expect(bodyIds).toContain(envField);
      }
    });
  });

  describe('Feature Request Template Validation', () => {
    let template;

    beforeAll(() => {
      const templatePath = path.join(templateDir, 'feature_request.yml');
      const content = fs.readFileSync(templatePath, 'utf8');
      template = yaml.load(content);
    });

    test('should have correct metadata', () => {
      expect(template.name).toBe('Feature Request');
      expect(template.description).toContain('feature');
      expect(template.title).toBe('[Feature] ');
      expect(template.labels).toContain('type:enhancement');
      expect(template.labels).toContain('status:needs-triage');
    });

    test('should have use case and acceptance criteria fields', () => {
      const fieldIds = template.body.map(field => field.id).filter(Boolean);
      
      expect(fieldIds).toContain('use-case');
      expect(fieldIds).toContain('acceptance-criteria');
      expect(fieldIds).toContain('priority');
    });

    test('should have business priority dropdown', () => {
      const priorityField = template.body.find(field => field.id === 'priority');
      expect(priorityField).toBeTruthy();
      expect(priorityField.type).toBe('dropdown');
      
      const options = priorityField.attributes.options;
      expect(options).toContain('Critical - Blocking current work');
      expect(options).toContain('High - Significantly improves productivity');
    });
  });

  describe('Question Templates Validation', () => {
    test('installation question should have troubleshooting checklist', () => {
      const templatePath = path.join(templateDir, 'question_installation.yml');
      const content = fs.readFileSync(templatePath, 'utf8');
      const template = yaml.load(content);

      const checklistField = template.body.find(field => field.id === 'troubleshooting');
      expect(checklistField).toBeTruthy();
      expect(checklistField.type).toBe('checkboxes');
      
      const options = checklistField.attributes.options;
      expect(options.length).toBeGreaterThan(0);
    });

    test('usage question should have component selection', () => {
      const templatePath = path.join(templateDir, 'question_usage.yml');
      const content = fs.readFileSync(templatePath, 'utf8');
      const template = yaml.load(content);

      const componentField = template.body.find(field => field.id === 'component');
      expect(componentField).toBeTruthy();
      expect(componentField.type).toBe('dropdown');
      
      const options = componentField.attributes.options;
      expect(options).toContain('General Usage');
      expect(options).toContain('Workflow and Best Practices');
    });
  });

  describe('Documentation Template Validation', () => {
    let template;

    beforeAll(() => {
      const templatePath = path.join(templateDir, 'documentation.yml');
      const content = fs.readFileSync(templatePath, 'utf8');
      template = yaml.load(content);
    });

    test('should be marked as good first issue', () => {
      expect(template.labels).toContain('status:good-first-issue');
      expect(template.labels).toContain('type:documentation');
    });

    test('should have documentation section dropdown', () => {
      const sectionField = template.body.find(field => field.id === 'doc-section');
      expect(sectionField).toBeTruthy();
      expect(sectionField.type).toBe('dropdown');
      
      const options = sectionField.attributes.options;
      expect(options).toContain('README.md');
      expect(options).toContain('Installation Guide');
    });
  });
});