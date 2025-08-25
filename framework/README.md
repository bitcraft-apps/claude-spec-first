# Claude Spec-First Framework Components

This directory contains the core components of the Claude Specification-First Development Framework.

## Components

### Agents (`agents/csf/`)
- **csf-spec-analyst**: Requirements analysis and specification creation
- **csf-test-designer**: Test-first development with comprehensive test suites  
- **csf-arch-designer**: System architecture and technical design decisions
- **csf-impl-specialist**: Code implementation following specifications and tests
- **csf-qa-validator**: Quality assurance and deployment readiness validation
- **csf-doc-synthesizer**: Documentation synthesis from development artifacts

*Note: All agents are namespaced with `csf-` prefix to avoid conflicts with other Claude Code tools.*

### Commands (`commands/csf/`)
- **spec-init**: Initialize specification process for new features
- **spec-review**: Multi-agent specification validation
- **impl-plan**: Implementation planning with architecture decisions
- **qa-check**: Quality validation and deployment readiness
- **spec-workflow**: Complete end-to-end workflow automation
- **doc-generate**: Generate comprehensive documentation from artifacts

*Note: Commands are installed in the `csf/` subdirectory and reference the namespaced agents.*

### Templates (`templates/`)
- **technical/**: Technical documentation templates
- **user/**: User-facing documentation templates
- **documentation-structure.md**: Documentation organization guide
- **metadata-system.md**: Metadata and traceability system
- **archival-process.md**: Specification archival procedures

### Examples (`examples/`)
- **todo-api-example.md**: Complete workflow example
- **doc-generation-test.md**: Documentation generation validation

### Utilities (`utils/`)
- **version-utils.sh**: Semantic versioning system for framework management
- **test-version-utils.sh**: Comprehensive test suite for version utilities
- **integration-test.sh**: Integration tests for complete versioning system

## Quick Start

1. **Install Framework**: Use the installation script from the project root:
   ```bash
   ./scripts/install.sh
   ```

2. **Validate Installation**: Ensure all components are properly configured:
   ```bash
   ~/.claude/validate-framework.sh
   ```

3. **Start Development**: Begin with specification initialization:
   ```
   /spec-init my-new-feature
   ```

## Versioning System

The framework includes a comprehensive semantic versioning system to manage framework versions and ensure compatibility.

### Version Management Commands

```bash
# Get current framework version
./utils/version-utils.sh get

# Display version information
./utils/version-utils.sh info

# Set a specific version
./utils/version-utils.sh set 1.2.3

# Increment version (patch, minor, or major)
./utils/version-utils.sh increment patch

# Compare two versions
./utils/version-utils.sh compare 1.0.0 1.2.0

# Validate version format
./utils/version-utils.sh validate 1.2.3
```

### Version Integration

- Framework validation displays current version
- Installation script shows installed version
- Version utilities work in both repository and installed modes
- Backward compatibility with frameworks without VERSION file

4. **Complete Workflow**: Run the full 6-phase development process:
   ```
   /spec-workflow my-project
   ```

5. **Generate Documentation**: Create comprehensive documentation:
   ```
   /doc-generate my-project
   ```

## Command Reference

### Core Workflow Commands
- **`/spec-init [feature]`** - Initialize specification process for new features
- **`/spec-review [feature]`** - Multi-agent specification validation  
- **`/impl-plan [feature]`** - Implementation planning with architecture decisions
- **`/qa-check [project]`** - Quality validation and deployment readiness
- **`/doc-generate [project]`** - Generate comprehensive documentation from artifacts
- **`/spec-workflow [project]`** - Complete end-to-end workflow automation (all phases)

### Specialized Agents (Namespaced)
- **`csf-spec-analyst`** - Requirements analysis and specification creation
- **`csf-test-designer`** - Test-first development with comprehensive test suites
- **`csf-arch-designer`** - System architecture and technical design decisions
- **`csf-impl-specialist`** - Code implementation following specifications and tests
- **`csf-qa-validator`** - Quality assurance and deployment readiness validation
- **`csf-doc-synthesizer`** - Documentation synthesis from development artifacts

*All agents use the `csf-` prefix to prevent conflicts with other tools' agents.*

## Validation

Run the validation script to ensure all components are properly configured:

```bash
./validate-framework.sh
```

---

*This framework transforms Claude Code into a professional specification-first development environment.*