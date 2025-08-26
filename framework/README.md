# Claude Spec-First Framework

This directory contains the core components of the Claude Specification-First Development Framework

## Components

### Agents (`agents/`)
- **csf-spec**: Requirements analysis and specification creation
- **csf-implement**: Code implementation following specifications
- **csf-document**: Documentation generation from specifications and code

### Commands (`commands/`)
- **spec**: Create specifications from business requirements
- **implement**: Implement code from specifications
- **document**: Generate documentation from spec and implementation
- **workflow**: Execute complete spec → implement → document cycle

### Templates (`templates/`)
- **technical/**: Technical documentation templates
- **user/**: User-facing documentation templates
- **documentation-structure.md**: Documentation organization guide

### Examples (`examples/`)
- **simple-workflow-example.md**: Complete 3-phase workflow example

### Utilities (`utils/`)
- **version-utils.sh**: Framework version management
- **test-version-utils.sh**: Version utility tests
- **integration-test.sh**: Integration testing

## Quick Start

1. **Install Framework**: Use the installation script from the project root:
   ```bash
   ./scripts/install.sh
   ```

2. **Validate Installation**: Ensure all components are properly configured:
   ```bash
   ~/.claude/validate-framework.sh
   ```

3. **Start Development**: Use the simplified workflow:

### Individual Commands
```
/csf:spec Add user authentication
/csf:implement docs/specifications/user-auth-spec.md
/csf:document docs/specifications/user-auth-spec.md src/auth/
```

### Complete Workflow (Recommended)
```
/csf:workflow Add user authentication with email/password login
```

## Workflow

The simplified framework follows a 3-phase approach:

### Phase 1: Specification
- Convert business requirements into clear, actionable specifications
- Define concrete acceptance criteria and constraints
- **Context cleared before implementation**

### Phase 2: Implementation
- Build working code that matches specifications exactly
- Follow existing code patterns and conventions
- **Context cleared before documentation**

### Phase 3: Documentation
- Generate comprehensive docs from specification and implementation
- Create both technical and user-facing documentation
- Ensure accuracy against actual implementation

## Command Reference

### Primary Commands
- **`/csf:spec [requirements]`** - Create specification from business requirements
- **`/csf:implement [spec_or_requirements]`** - Implement code from specifications
- **`/csf:document [spec_and_code_paths]`** - Generate documentation
- **`/csf:workflow [requirements]`** - Execute complete development cycle

### Utility Commands (if still available)
- **`/csf:spec-init`** - Smart router for starting workflows
- **`/csf:implement-now`** - Direct implementation for simple tasks
- **`/csf:doc-generate`** - Documentation generation only

## Key Benefits

- **Simple**: Only 3 agents and 4 commands to understand
- **Clear**: Each phase has a specific, focused purpose
- **Context Clearing**: Prevents information overload between phases
- **Complete**: Delivers specification, working code, and documentation
- **Flexible**: Use individual commands or complete workflow

## Validation

Run the validation script to ensure all components are properly configured:

```bash
./validate-framework.sh
```

---

*This simplified framework focuses on the essential workflow: spec → implement → document.*
