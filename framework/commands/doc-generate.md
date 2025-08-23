---
description: Generate comprehensive documentation from development artifacts - synthesizes specifications, architecture, and implementation into final technical and user documentation
---

# Final Documentation Generation

You are generating comprehensive documentation for the completed project: **$ARGUMENTS**

## Overview
This command synthesizes all development artifacts (specifications, tests, architecture decisions, QA reports, and implementation) into final comprehensive documentation that serves as the single source of truth. After successful generation, original specifications can be archived.

## Process Steps

### Phase 1: Artifact Collection and Validation
**IMMEDIATE ACTION**: Use the doc-synthesizer sub-agent to collect and catalog all development artifacts.

The doc-synthesizer should:
- Scan `docs/specifications/` for all requirement documents and test cases
- Collect architecture decisions from `docs/architecture/`
- Gather QA reports and validation results
- Analyze implementation source code and test files
- Identify missing or incomplete artifacts
- Validate artifact consistency and completeness

### Phase 2: Technical Documentation Generation
**IMMEDIATE ACTION**: Use the doc-synthesizer sub-agent to create comprehensive technical documentation.

Generate the following technical documentation structure:
```
docs/technical/
├── architecture/
│   ├── system-overview.md      # High-level system architecture
│   ├── component-design.md     # Detailed component specifications
│   └── deployment-architecture.md # Infrastructure and deployment
├── api/
│   ├── api-reference.md        # Complete API documentation
│   ├── authentication.md      # Security and authentication
│   └── error-handling.md       # Error codes and responses
├── development/
│   ├── setup-guide.md          # Developer environment setup
│   ├── testing-strategy.md     # Testing approach and execution
│   └── contributing.md         # Development guidelines
└── operations/
    ├── deployment.md           # Production deployment guide
    ├── monitoring.md           # Observability and metrics
    └── troubleshooting.md      # Issue diagnosis and resolution
```

### Phase 3: User Documentation Generation
**IMMEDIATE ACTION**: Use the doc-synthesizer sub-agent to create user-facing documentation.

Generate the following user documentation structure:
```
docs/user/
├── getting-started/
│   ├── quick-start.md          # 5-minute getting started guide
│   ├── installation.md        # Installation instructions
│   └── configuration.md       # Configuration guide
├── features/
│   ├── feature-overview.md     # Complete feature catalog
│   └── [individual features]   # Detailed feature documentation
├── tutorials/
│   ├── basic-usage.md          # Step-by-step basic tutorial
│   └── advanced-scenarios.md   # Advanced use cases
└── reference/
    ├── faq.md                  # Frequently asked questions
    ├── glossary.md             # Terms and definitions
    └── support.md              # Support and troubleshooting
```

### Phase 4: Documentation Quality Validation
**IMMEDIATE ACTION**: Use the qa-validator sub-agent to validate documentation quality.

The qa-validator should:
- Verify all documentation against actual implementation
- Check that all major features are documented
- Validate code examples and ensure they work
- Review documentation for completeness and accuracy
- Test user documentation with realistic scenarios
- Ensure consistent terminology and formatting

### Phase 5: Specification Archival
**IMMEDIATE ACTION**: Use the doc-synthesizer sub-agent to archive original specifications.

Archive process:
- Create `docs/archive/specs/[timestamp]/` directory
- Move all original specifications with metadata preservation
- Generate traceability mapping between archived specs and new documentation
- Create archival summary with change tracking information
- Verify all content is preserved with proper timestamps

## Documentation Standards

### Content Requirements
- **Technical Docs**: Include architecture diagrams, API examples, deployment procedures
- **User Docs**: Include screenshots, step-by-step guides, troubleshooting steps
- **Code Examples**: All code must be tested and working
- **Cross-References**: Link related sections across all documentation
- **Search**: Include keywords and searchable content structure

### Metadata Requirements
Each document must include:
```yaml
---
generated_from:
  specifications: [source specification files]
  architecture: [architecture decisions used]
  qa_reports: [validation reports referenced]
  implementation: [source files analyzed]
generated_date: YYYY-MM-DD
version: semantic version
status: current
traceability_id: unique change tracking ID
---
```

### Quality Gates
- [ ] **Completeness**: All major features and APIs documented
- [ ] **Accuracy**: All documentation validated against implementation
- [ ] **Usability**: User documentation tested with realistic scenarios
- [ ] **Consistency**: Uniform terminology and formatting throughout
- [ ] **Traceability**: Clear mapping from requirements to final documentation
- [ ] **Archival**: Original specifications properly archived with metadata

## Deployment Options

### Option 1: Hybrid Approach (Recommended)
- **Technical Docs**: Keep in repository under `docs/technical/`
- **User Docs**: Deploy to GitHub Pages from `docs/user/`
- **Archives**: Store in `docs/archive/` with compression

### Option 2: Unified Platform
- Deploy all documentation to single platform (Docusaurus, MkDocs)
- Maintain version control in repository
- Deploy to GitHub Pages or external hosting

### Option 3: Professional Platform
- Use GitBook, ReadTheDocs, or similar platform
- Import from repository with automated sync
- Provide professional search and navigation features

## Success Criteria

### Documentation Generation Success:
- [ ] All development artifacts successfully collected and analyzed
- [ ] Technical documentation covers all architectural decisions and APIs
- [ ] User documentation provides complete feature coverage and tutorials
- [ ] All documentation validated for accuracy and completeness
- [ ] Original specifications archived with full traceability
- [ ] Documentation deployed to chosen platform(s)

### Quality Validation Success:
- [ ] All code examples tested and working
- [ ] User workflows validated with realistic scenarios
- [ ] Technical documentation verified against implementation
- [ ] No broken links or missing references
- [ ] Consistent terminology and formatting throughout

## Instructions

### Execution Order:
1. **Collect Artifacts**: Ensure all development artifacts are available and complete
2. **Generate Technical**: Create comprehensive developer documentation
3. **Generate User**: Create accessible user guides and tutorials  
4. **Validate Quality**: Test all documentation for accuracy and usability
5. **Archive Specs**: Preserve original specifications with full traceability
6. **Deploy Documentation**: Make final documentation available to stakeholders

### Quality Focus:
- Prioritize accuracy over speed - all technical details must be verified
- Create cohesive narratives rather than disconnected fragments
- Ensure documentation tells complete story from user and developer perspectives
- Maintain traceability while making documentation self-contained
- Test all user workflows and code examples before publication

**IMMEDIATE ACTION**: Start the documentation generation process by delegating to the doc-synthesizer sub-agent to collect and analyze all development artifacts for: "$ARGUMENTS"