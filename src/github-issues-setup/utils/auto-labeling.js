/**
 * Auto-labeling utilities for GitHub Issues
 * Analyzes issue content and applies appropriate labels
 */

// Component mappings for content-based detection
const componentMappings = {
  'component:agent-spec-analyst': [
    'spec-analyst', 'specification analysis', 'requirements analysis', 
    'spec analyst', 'requirement parsing', 'specification parsing'
  ],
  'component:agent-test-designer': [
    'test-designer', 'test design', 'test creation', 'test designer',
    'testing framework', 'test cases', 'test planning'
  ],
  'component:agent-arch-designer': [
    'arch-designer', 'architecture', 'system design', 'arch designer',
    'architectural', 'design patterns', 'system architecture'
  ],
  'component:agent-impl-specialist': [
    'impl-specialist', 'implementation', 'code generation', 'impl specialist',
    'code implementation', 'implementation specialist', 'coding'
  ],
  'component:agent-qa-validator': [
    'qa-validator', 'quality assurance', 'validation', 'qa validator',
    'quality validation', 'qa check', 'quality control'
  ],
  'component:command-spec-init': [
    '/spec-init', 'spec-init', 'initialize specification', 'spec init',
    'specification initialization'
  ],
  'component:command-spec-review': [
    '/spec-review', 'spec-review', 'review specification', 'spec review',
    'specification review'
  ],
  'component:command-impl-plan': [
    '/impl-plan', 'impl-plan', 'implementation plan', 'impl plan',
    'implementation planning'
  ],
  'component:command-qa-check': [
    '/qa-check', 'qa-check', 'quality check', 'qa check'
  ],
  'component:command-spec-workflow': [
    '/spec-workflow', 'spec-workflow', 'complete workflow', 'spec workflow',
    'workflow automation'
  ],
  'component:installation': [
    'install.sh', 'installation', 'install', 'setup', 'scripts/install',
    'framework installation', 'setup script'
  ],
  'component:validation': [
    'validate-framework.sh', 'validation', 'validate', 'framework/validate',
    'framework validation', 'validation script'
  ],
  'component:docs': [
    'documentation', 'readme', 'docs/', 'guide', '.md',
    'documentation update', 'docs improvement'
  ]
};

// File path mappings (higher priority than content analysis)
const filePathMappings = {
  'component:agent-spec-analyst': [
    'framework/agents/spec-analyst.md',
    'agents/spec-analyst',
    'spec-analyst.md'
  ],
  'component:agent-test-designer': [
    'framework/agents/test-designer.md',
    'agents/test-designer',
    'test-designer.md'
  ],
  'component:agent-arch-designer': [
    'framework/agents/arch-designer.md',
    'agents/arch-designer',
    'arch-designer.md'
  ],
  'component:agent-impl-specialist': [
    'framework/agents/impl-specialist.md',
    'agents/impl-specialist',
    'impl-specialist.md'
  ],
  'component:agent-qa-validator': [
    'framework/agents/qa-validator.md',
    'agents/qa-validator',
    'qa-validator.md'
  ],
  'component:command-spec-init': [
    'framework/commands/spec-init.md',
    'commands/spec-init',
    'spec-init.md'
  ],
  'component:command-spec-review': [
    'framework/commands/spec-review.md',
    'commands/spec-review',
    'spec-review.md'
  ],
  'component:command-impl-plan': [
    'framework/commands/impl-plan.md',
    'commands/impl-plan',
    'impl-plan.md'
  ],
  'component:command-qa-check': [
    'framework/commands/qa-check.md',
    'commands/qa-check',
    'qa-check.md'
  ],
  'component:command-spec-workflow': [
    'framework/commands/spec-workflow.md',
    'commands/spec-workflow',
    'spec-workflow.md'
  ],
  'component:installation': [
    'scripts/install.sh',
    'scripts/update.sh',
    'scripts/uninstall.sh',
    'install.sh'
  ],
  'component:validation': [
    'framework/validate-framework.sh',
    'validate-framework.sh',
    'validate-framework'
  ],
  'component:docs': [
    'README.md',
    'docs/',
    'CONTRIBUTING.md',
    'documentation'
  ]
};

// Priority detection keywords
const priorityKeywords = {
  'priority:critical': [
    'critical', 'urgent', 'breaking', 'system down', 'production down',
    'security breach', 'data loss', 'corruption', 'crash', 'fatal'
  ],
  'priority:high': [
    'important', 'high priority', 'significantly', 'blocking', 'blocker',
    'major bug', 'serious', 'affects many', 'productivity impact'
  ],
  'priority:low': [
    'low priority', 'nice to have', 'minor', 'convenience', 'cosmetic',
    'trivial', 'small improvement', 'polish'
  ]
};

// Security-related keywords
const securityKeywords = [
  'security', 'vulnerability', 'exploit', 'cve', 'xss', 'injection',
  'authentication', 'authorization', 'privilege escalation', 'malicious',
  'attack', 'breach', 'sensitive data', 'credentials'
];

/**
 * Detect component labels based on issue content
 * @param {string} content Issue title and body combined
 * @returns {Array<string>} Component labels to apply
 */
function detectComponents(content) {
  const lowerContent = content.toLowerCase();
  
  // Check file paths first (higher confidence)
  for (const [label, paths] of Object.entries(filePathMappings)) {
    if (paths.some(path => lowerContent.includes(path.toLowerCase()))) {
      return [label];
    }
  }
  
  // Check content keywords
  for (const [label, keywords] of Object.entries(componentMappings)) {
    if (keywords.some(keyword => lowerContent.includes(keyword.toLowerCase()))) {
      return [label];
    }
  }
  
  return [];
}

/**
 * Detect priority level based on issue content
 * @param {string} content Issue title and body combined
 * @returns {string|null} Priority label to apply
 */
function detectPriority(content) {
  const lowerContent = content.toLowerCase();
  
  // Check for explicit priority keywords with word boundaries
  for (const [priority, keywords] of Object.entries(priorityKeywords)) {
    if (keywords.some(keyword => {
      // Use word boundaries for single words, regular includes for phrases
      if (keyword.includes(' ')) {
        return lowerContent.includes(keyword);
      } else {
        // Use regex with word boundaries for single words
        const regex = new RegExp(`\\b${keyword}\\b`, 'i');
        return regex.test(lowerContent);
      }
    })) {
      return priority;
    }
  }
  
  // Default to normal priority
  return 'priority:normal';
}

/**
 * Detect if issue is security-related
 * @param {string} content Issue title and body combined
 * @returns {boolean} True if security-related
 */
function isSecurityRelated(content) {
  const lowerContent = content.toLowerCase();
  return securityKeywords.some(keyword => lowerContent.includes(keyword));
}

/**
 * Analyze issue content and return appropriate labels
 * @param {string} title Issue title
 * @param {string} body Issue body
 * @returns {Object} Analysis results with labels and confidence
 */
function analyzeIssueContent(title, body) {
  const content = `${title} ${body || ''}`.toLowerCase();
  const labels = [];
  const analysis = {
    components: [],
    priority: null,
    security: false,
    confidence: 0
  };
  
  // Detect components
  const components = detectComponents(content);
  if (components.length > 0) {
    labels.push(...components);
    analysis.components = components;
    analysis.confidence += 0.4; // High confidence for component detection
  }
  
  // Detect priority
  const priority = detectPriority(content);
  if (priority) {
    labels.push(priority);
    analysis.priority = priority;
    analysis.confidence += 0.3;
  }
  
  // Detect security issues
  if (isSecurityRelated(content)) {
    labels.push('type:security');
    // Override priority for security issues
    if (priority === 'priority:normal' || priority === 'priority:low') {
      labels.splice(labels.indexOf(priority), 1);
      labels.push('priority:high');
      analysis.priority = 'priority:high';
    }
    analysis.security = true;
    analysis.confidence += 0.3;
  }
  
  return {
    labels,
    analysis,
    confidence: Math.min(analysis.confidence, 1.0)
  };
}

/**
 * Generate explanation for applied labels
 * @param {Array<string>} labels Applied labels
 * @param {Object} analysis Analysis results
 * @returns {string} Human-readable explanation
 */
function generateLabelExplanation(labels, analysis) {
  const explanations = [];
  
  if (analysis.components.length > 0) {
    const componentName = analysis.components[0].replace('component:', '').replace('-', ' ');
    explanations.push(`Detected component: ${componentName}`);
  }
  
  if (analysis.priority) {
    const priorityLevel = analysis.priority.replace('priority:', '');
    explanations.push(`Priority level: ${priorityLevel}`);
  }
  
  if (analysis.security) {
    explanations.push('Security-related issue detected');
  }
  
  return explanations.join('; ');
}

/**
 * Test accuracy of auto-labeling against known test cases
 * @param {Array<Object>} testCases Array of {content, expected} objects
 * @returns {Object} Accuracy statistics
 */
function testAccuracy(testCases) {
  let correct = 0;
  let total = testCases.length;
  const results = [];
  
  for (const testCase of testCases) {
    const analysis = analyzeIssueContent(testCase.title || testCase.content, testCase.body || '');
    const detected = analysis.labels;
    
    const isCorrect = testCase.expected.every(expectedLabel => 
      detected.includes(expectedLabel)
    );
    
    if (isCorrect) {
      correct++;
    }
    
    results.push({
      content: testCase.content,
      expected: testCase.expected,
      detected,
      correct: isCorrect,
      confidence: analysis.confidence
    });
  }
  
  return {
    accuracy: correct / total,
    totalTests: total,
    correctPredictions: correct,
    results
  };
}

module.exports = {
  detectComponents,
  detectPriority,
  isSecurityRelated,
  analyzeIssueContent,
  generateLabelExplanation,
  testAccuracy,
  componentMappings,
  filePathMappings,
  priorityKeywords,
  securityKeywords
};