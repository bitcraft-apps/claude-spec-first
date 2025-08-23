#!/usr/bin/env node
/**
 * Template Validation Script
 * Validates GitHub issue templates for syntax and completeness
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const TEMPLATE_DIR = path.join(__dirname, '../../../.github/ISSUE_TEMPLATE');
const REQUIRED_TEMPLATES = [
  'bug_report.yml',
  'feature_request.yml',
  'question_installation.yml',
  'question_usage.yml',
  'documentation.yml',
  'config.yml'
];

/**
 * Validate YAML syntax
 */
function validateYamlSyntax(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    yaml.load(content);
    return { valid: true };
  } catch (error) {
    return { valid: false, error: error.message };
  }
}

/**
 * Validate GitHub issue template schema
 */
function validateTemplateSchema(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const template = yaml.load(content);
    const errors = [];

    // Skip validation for config.yml
    if (path.basename(filePath) === 'config.yml') {
      if (!template.hasOwnProperty('blank_issues_enabled')) {
        errors.push('Missing blank_issues_enabled property');
      }
      if (!template.hasOwnProperty('contact_links') || !Array.isArray(template.contact_links)) {
        errors.push('Missing or invalid contact_links array');
      }
      return { valid: errors.length === 0, errors };
    }

    // Validate issue template schema
    if (!template.name || typeof template.name !== 'string') {
      errors.push('Missing or invalid name field');
    }
    
    if (!template.description || typeof template.description !== 'string') {
      errors.push('Missing or invalid description field');
    }
    
    if (!template.body || !Array.isArray(template.body)) {
      errors.push('Missing or invalid body array');
    }

    if (template.labels && !Array.isArray(template.labels)) {
      errors.push('Invalid labels field (must be array)');
    }

    return { valid: errors.length === 0, errors };
  } catch (error) {
    return { valid: false, errors: [error.message] };
  }
}

/**
 * Validate required fields in templates
 */
function validateRequiredFields(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const template = yaml.load(content);
    
    if (path.basename(filePath) === 'config.yml') {
      return { valid: true, requiredFields: [] };
    }

    const requiredFields = template.body
      .filter(field => field.validations && field.validations.required)
      .map(field => field.id);

    const expectedRequiredFields = {
      'bug_report.yml': ['description', 'expected', 'actual', 'steps', 'component'],
      'feature_request.yml': ['feature-description', 'use-case', 'acceptance-criteria'],
      'question_installation.yml': ['question', 'attempted-solutions'],
      'question_usage.yml': ['question', 'context'],
      'documentation.yml': ['issue-description', 'proposed-improvement']
    };

    const fileName = path.basename(filePath);
    const expected = expectedRequiredFields[fileName] || [];
    const missing = expected.filter(field => !requiredFields.includes(field));

    return {
      valid: missing.length === 0,
      requiredFields,
      expected,
      missing
    };
  } catch (error) {
    return { valid: false, error: error.message };
  }
}

/**
 * Main validation function
 */
function validateTemplates() {
  console.log('🔍 Validating GitHub Issue Templates...\n');

  let allValid = true;
  const results = [];

  // Check if template directory exists
  if (!fs.existsSync(TEMPLATE_DIR)) {
    console.error(`❌ Template directory not found: ${TEMPLATE_DIR}`);
    return false;
  }

  // Validate each required template
  for (const templateFile of REQUIRED_TEMPLATES) {
    const filePath = path.join(TEMPLATE_DIR, templateFile);
    const result = { file: templateFile, valid: true, errors: [] };

    console.log(`📄 Validating ${templateFile}...`);

    // Check if file exists
    if (!fs.existsSync(filePath)) {
      result.valid = false;
      result.errors.push('File does not exist');
      console.log(`  ❌ File not found`);
      allValid = false;
      results.push(result);
      continue;
    }

    // Validate YAML syntax
    const yamlValidation = validateYamlSyntax(filePath);
    if (!yamlValidation.valid) {
      result.valid = false;
      result.errors.push(`YAML syntax error: ${yamlValidation.error}`);
      console.log(`  ❌ YAML syntax error: ${yamlValidation.error}`);
      allValid = false;
    } else {
      console.log(`  ✅ YAML syntax valid`);
    }

    // Validate template schema
    const schemaValidation = validateTemplateSchema(filePath);
    if (!schemaValidation.valid) {
      result.valid = false;
      result.errors.push(...schemaValidation.errors);
      schemaValidation.errors.forEach(error => {
        console.log(`  ❌ Schema error: ${error}`);
      });
      allValid = false;
    } else {
      console.log(`  ✅ Schema valid`);
    }

    // Validate required fields
    const fieldsValidation = validateRequiredFields(filePath);
    if (!fieldsValidation.valid) {
      if (fieldsValidation.error) {
        result.errors.push(`Required fields error: ${fieldsValidation.error}`);
        console.log(`  ❌ Required fields error: ${fieldsValidation.error}`);
      } else if (fieldsValidation.missing && fieldsValidation.missing.length > 0) {
        result.errors.push(`Missing required fields: ${fieldsValidation.missing.join(', ')}`);
        console.log(`  ❌ Missing required fields: ${fieldsValidation.missing.join(', ')}`);
      }
      allValid = false;
    } else {
      if (fieldsValidation.requiredFields && fieldsValidation.requiredFields.length > 0) {
        console.log(`  ✅ Required fields: ${fieldsValidation.requiredFields.join(', ')}`);
      }
    }

    results.push(result);
    console.log('');
  }

  // Summary
  console.log('📊 Validation Summary:');
  console.log(`Total templates: ${REQUIRED_TEMPLATES.length}`);
  console.log(`Valid templates: ${results.filter(r => r.valid).length}`);
  console.log(`Invalid templates: ${results.filter(r => !r.valid).length}`);

  if (!allValid) {
    console.log('\n❌ Template validation failed. Please fix the issues above.');
    results.filter(r => !r.valid).forEach(result => {
      console.log(`\n${result.file}:`);
      result.errors.forEach(error => console.log(`  - ${error}`));
    });
  } else {
    console.log('\n✅ All templates are valid!');
  }

  return allValid;
}

// Run validation if called directly
if (require.main === module) {
  const isValid = validateTemplates();
  process.exit(isValid ? 0 : 1);
}

module.exports = { validateTemplates };