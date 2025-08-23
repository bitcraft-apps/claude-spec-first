# Claude Spec-First Framework Components

This directory contains the core components of the Claude Specification-First Development Framework.

## Components

### Agents (`agents/`)
- **spec-analyst**: Requirements analysis and specification creation
- **test-designer**: Test-first development with comprehensive test suites  
- **arch-designer**: System architecture and technical design decisions
- **impl-specialist**: Code implementation following specifications and tests
- **qa-validator**: Quality assurance and deployment readiness validation
- **doc-synthesizer**: Documentation synthesis from development artifacts

### Commands (`commands/`)
- **spec-init**: Initialize specification process for new features
- **spec-review**: Multi-agent specification validation
- **impl-plan**: Implementation planning with architecture decisions
- **qa-check**: Quality validation and deployment readiness
- **spec-workflow**: Complete end-to-end workflow automation
- **doc-generate**: Generate comprehensive documentation from artifacts

### Templates (`templates/`)
- **technical/**: Technical documentation templates
- **user/**: User-facing documentation templates
- **documentation-structure.md**: Documentation organization guide
- **metadata-system.md**: Metadata and traceability system
- **archival-process.md**: Specification archival procedures

### Examples (`examples/`)
- **todo-api-example.md**: Complete workflow example
- **doc-generation-test.md**: Documentation generation validation

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

### Specialized Agents
- **`spec-analyst`** - Requirements analysis and specification creation
- **`test-designer`** - Test-first development with comprehensive test suites
- **`arch-designer`** - System architecture and technical design decisions
- **`impl-specialist`** - Code implementation following specifications and tests
- **`qa-validator`** - Quality assurance and deployment readiness validation
- **`doc-synthesizer`** - Documentation synthesis from development artifacts

## Validation

Run the validation script to ensure all components are properly configured:

```bash
./validate-framework.sh
```

---

*This framework transforms Claude Code into a professional specification-first development environment.*