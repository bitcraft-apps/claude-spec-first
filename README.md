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
- 6 workflow commands for structured development
- Smart installation with backup and merge capabilities
- Test-driven development support
- Quality assurance validation
- Comprehensive documentation generation from artifacts
- Conflict-free operation with other Claude Code tools

## Command Reference

The framework provides these workflow commands:

- `/spec-init` - Initialize specification process for new features
- `/spec-review` - Multi-agent specification validation
- `/impl-plan` - Implementation planning with architecture decisions
- `/qa-check` - Quality validation and deployment readiness
- `/doc-generate` - Generate comprehensive documentation from artifacts
- `/spec-workflow` - Complete end-to-end workflow automation

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