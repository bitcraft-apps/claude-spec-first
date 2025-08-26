# Claude Spec-First Framework

A comprehensive specification-first development framework for Claude Code that transforms it into a professional development environment following structured workflows: Requirements → Specifications → Tests → Architecture → Implementation → Quality Assurance → Documentation.

## Quick Start

```bash
# Install framework globally
./scripts/install.sh

# Validate installation
~/.claude/validate-framework.sh
```

## Features

- 6 specialized sub-agents for different development phases (namespaced as `csf-*`)
- Streamlined workflow commands with intelligent routing
- Smart installation with backup and merge capabilities
- Test-driven development support
- Quality assurance validation
- Comprehensive documentation generation from artifacts
- Conflict-free operation with other Claude Code tools

## Command Reference

The framework provides these streamlined workflow commands:

**Primary Workflow Commands:**
- `/csf:spec-init` - Smart router that selects optimal workflow automatically
- `/csf:implement-now` - Direct implementation for simple, obvious tasks
- `/csf:spec-mvp` - Rapid development for simple-to-medium features  
- `/csf:spec-workflow` - Complete workflow for complex systems

**Utility Commands:**
- `/csf:complexity-eval` - Analyze task complexity and recommend workflow
- `/csf:spec-review` - Multi-agent specification validation
- `/csf:impl-plan` - Implementation planning with architecture decisions
- `/csf:qa-check` - Quality validation and deployment readiness
- `/csf:doc-generate` - Generate comprehensive documentation from artifacts

## Agent Namespacing

All framework agents use the `csf-` prefix to avoid conflicts with other Claude Code tools:

- `csf-spec-analyst` - Requirements analysis and specification creation
- `csf-test-designer` - Test-driven development specialist
- `csf-arch-designer` - System architecture and design specialist  
- `csf-impl-specialist` - Code implementation specialist
- `csf-qa-validator` - Quality assurance specialist
- `csf-doc-synthesizer` - Documentation synthesis specialist

This ensures the framework can coexist with other agent-based tools without naming conflicts.

## Documentation

See [CLAUDE.md](./CLAUDE.md) for detailed setup and usage instructions.