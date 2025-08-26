# Claude Spec-First Framework

A streamlined specification-first development framework for Claude Code that transforms it into a professional development environment following a clean 3-phase workflow: Specification → Implementation → Documentation.

## Quick Start

```bash
# Install framework globally
./scripts/install.sh

# Validate installation
~/.claude/validate-framework.sh
```

## Features

- 3 specialized agents for focused development phases (namespaced as `csf-*`)
- 4 streamlined commands for clean workflow execution
- Context clearing between phases for focused work
- Smart installation with backup and merge capabilities
- Comprehensive documentation generation from artifacts
- Conflict-free operation with other Claude Code tools

## Command Reference

The framework provides 4 streamlined workflow commands:

**Workflow Commands:**
- `/csf:spec` - Create specifications from business requirements
- `/csf:implement` - Implement code from specifications
- `/csf:document` - Generate documentation from spec and implementation
- `/csf:workflow` - Execute complete spec → implement → document cycle

## Agent Namespacing

All framework agents use the `csf-` prefix to avoid conflicts with other Claude Code tools:

- `csf-spec` - Requirements analysis and specification creation
- `csf-implement` - Code implementation specialist
- `csf-document` - Documentation synthesis specialist

This ensures the framework can coexist with other agent-based tools without naming conflicts.

## Documentation

See [CLAUDE.md](./CLAUDE.md) for detailed setup and usage instructions.