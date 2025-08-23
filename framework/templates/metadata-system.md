# Documentation Metadata System

This document defines the metadata system used by the Claude Spec-First Framework to track documentation sources, versions, and traceability.

## Metadata Schema

### Document Metadata Format
Every generated documentation file must include the following YAML frontmatter:

```yaml
---
# Generation metadata
generated_from:
  specifications: [list of specification files used]
  architecture: [architecture decision files referenced]
  qa_reports: [QA and validation reports used]
  implementation: [source code files analyzed]
  tests: [test files referenced for examples]
generated_date: YYYY-MM-DD
generated_by: doc-synthesizer
generated_version: semantic_version

# Document metadata
document_type: technical | user | reference | archive
document_category: architecture | api | development | operations | getting-started | features | tutorials | support
title: "Document Title"
description: "Brief description of document content"

# Version and status
version: semantic_version
status: current | archived | deprecated | draft
traceability_id: unique_identifier

# Relationships
replaces: [list of documents this replaces]
related_docs: [list of related documents]
parent_spec: specification_file_that_originated_this_content

# Maintenance
last_reviewed: YYYY-MM-DD
review_cycle: days_between_reviews
maintainer: responsible_party
---
```

### Required Fields
- `generated_from`: Source artifacts used for generation
- `generated_date`: When the document was generated
- `generated_by`: Always "doc-synthesizer"
- `document_type`: Category of documentation
- `version`: Semantic version of the document
- `status`: Current status of the document
- `traceability_id`: Unique identifier for change tracking

### Optional Fields
- `document_category`: More specific categorization
- `replaces`: Documents superseded by this one
- `related_docs`: Cross-references to related content
- `parent_spec`: Original specification that led to this content
- `last_reviewed`: Last review date for maintenance
- `review_cycle`: Maintenance schedule
- `maintainer`: Responsible person or team

## Traceability System

### Traceability ID Format
Format: `{project}_{type}_{timestamp}_{hash}`

Examples:
- `github-issues-setup_technical_20240123_a1b2c3`
- `claude-framework_user_20240123_d4e5f6`

### Components
- **project**: Project identifier (lowercase, hyphens)
- **type**: Document type (technical, user, reference, archive)
- **timestamp**: Generation date (YYYYMMDD)
- **hash**: 6-character hash for uniqueness

### Traceability Chain
Each document maintains a chain linking back to original requirements:

```
Requirements → Specifications → Architecture → Implementation → Documentation
     ↓              ↓              ↓              ↓              ↓
req_001.md → spec_001.md → arch_001.md → src/main.js → api-reference.md
```

## Version Management

### Semantic Versioning
Documentation follows semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes in API or significant restructuring
- **MINOR**: New features or sections added
- **PATCH**: Bug fixes, typos, clarifications

### Version Inheritance
- Technical docs version should match implementation version
- User docs version reflects feature completeness
- Archive docs preserve original version numbers

### Version Compatibility Matrix
```yaml
compatibility:
  implementation_version: "1.2.3"
  api_version: "v1"
  framework_version: "1.0.0"
  minimum_supported: "1.2.0"
```

## Source Tracking

### Specification Sources
```yaml
specifications:
  - file: "docs/specifications/github-issues-requirements.md"
    sections: ["Authentication", "API Endpoints"]
    last_modified: "2024-01-20"
    hash: "a1b2c3d4"
  - file: "docs/specifications/test-cases.md"
    sections: ["Security Tests", "Integration Tests"]
    last_modified: "2024-01-21"
    hash: "e5f6g7h8"
```

### Architecture Sources
```yaml
architecture:
  - file: "docs/architecture/system-design.md"
    sections: ["Component Architecture", "Data Flow"]
    decisions: ["ADR-001", "ADR-003"]
    last_modified: "2024-01-22"
    hash: "i9j0k1l2"
```

### Implementation Sources
```yaml
implementation:
  - file: "src/api/auth.js"
    functions: ["authenticate", "authorize"]
    last_modified: "2024-01-23"
    hash: "m3n4o5p6"
  - file: "src/api/issues.js"
    functions: ["createIssue", "listIssues"]
    last_modified: "2024-01-23"
    hash: "q7r8s9t0"
```

### QA Report Sources
```yaml
qa_reports:
  - file: "docs/qa-assessment-report.md"
    sections: ["Test Results", "Security Assessment"]
    date: "2024-01-24"
    status: "PASS"
    hash: "u1v2w3x4"
```

## Archive Management

### Archive Metadata
When archiving original specifications:

```yaml
---
archived_date: YYYY-MM-DD
archived_by: doc-synthesizer
archive_reason: "Superseded by comprehensive documentation"
original_location: "docs/specifications/"
replacement_docs:
  - "docs/technical/api-reference.md"
  - "docs/user/quick-start.md"
preservation_hash: original_file_hash
---
```

### Archive Structure
```
docs/archive/
├── specs/
│   └── 2024-01-25-post-implementation/
│       ├── archive-manifest.md
│       ├── requirements.md
│       ├── test-cases.md
│       ├── implementation-plan.md
│       └── qa-reports.md
└── metadata/
    └── traceability-map.json
```

### Archive Manifest
```yaml
---
archive_id: "github-issues-setup_20240125"
archive_date: 2024-01-25
project: "GitHub Issues Setup"
phase: "Post-Implementation Documentation"
artifacts_count: 15
total_size_mb: 2.3
generated_docs:
  - "docs/technical/system-overview.md"
  - "docs/technical/api-reference.md"
  - "docs/user/quick-start.md"
  - "docs/user/features.md"
traceability_preserved: true
---
```

## Change Tracking

### Change Log Format
```yaml
---
document_id: "api-reference_v1.2.0"
changes:
  - version: "1.2.0"
    date: "2024-01-25"
    type: "minor"
    description: "Added webhook endpoints"
    source_changes:
      - "src/api/webhooks.js (new file)"
      - "docs/specifications/webhook-requirements.md"
  - version: "1.1.1"
    date: "2024-01-20"
    type: "patch"
    description: "Fixed authentication examples"
    source_changes:
      - "src/api/auth.js (line 45-67)"
---
```

## Validation Rules

### Metadata Validation Checklist
- [ ] All required fields present
- [ ] Traceability ID follows format
- [ ] Version follows semantic versioning
- [ ] Source files exist and are accessible
- [ ] Generated date is recent and valid
- [ ] Status is one of allowed values

### Cross-Reference Validation
- [ ] All referenced source files exist
- [ ] Related documents have reciprocal references
- [ ] Parent specifications can be traced
- [ ] Archive references are valid

### Content Validation
- [ ] Document content matches source artifacts
- [ ] Examples from implementation are current
- [ ] Links and references are functional
- [ ] Version compatibility is maintained

## Tools and Utilities

### Metadata Generation Script
```bash
# Generate traceability ID
generate_traceability_id() {
    local project="$1"
    local type="$2"
    local date=$(date +%Y%m%d)
    local hash=$(echo -n "${project}_${type}_${date}" | sha256sum | cut -c1-6)
    echo "${project}_${type}_${date}_${hash}"
}
```

### Validation Script
```bash
# Validate document metadata
validate_metadata() {
    local file="$1"
    # Extract and validate YAML frontmatter
    # Check required fields
    # Validate format and references
    # Return validation status
}
```

### Traceability Report Generator
```bash
# Generate traceability report
generate_traceability_report() {
    local project="$1"
    # Scan all documentation
    # Build traceability chain
    # Identify gaps or broken links
    # Generate comprehensive report
}
```

---

*This metadata system ensures full traceability and version control for all generated documentation while preserving the connection to original development artifacts.*