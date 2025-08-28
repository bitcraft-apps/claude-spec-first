# Claude Spec-First Framework

A streamlined specification-first development framework for Claude Code that transforms it into a professional development environment following a clean 4-phase workflow: Specification → Planning → Implementation → Documentation.

## Quick Start

```bash
# Install framework globally
./scripts/install.sh

# Validate installation
~/.claude/validate-framework.sh
```

## Features

- 4 specialized agents for focused development phases (namespaced as `csf-*`)
- 5 streamlined commands for clean workflow execution
- Context clearing between phases for focused work
- Smart installation with backup and merge capabilities
- Comprehensive documentation generation from artifacts
- Conflict-free operation with other Claude Code tools

## Command Reference

The framework provides 5 streamlined workflow commands:

**Workflow Commands:**
- `/csf:spec` - Create specifications from business requirements
- `/csf:plan` - Create technical implementation plan from specifications
- `/csf:implement` - Implement code following specifications and plans
- `/csf:document` - Generate documentation from spec and implementation
- `/csf:workflow` - Execute complete spec → plan → implement → document cycle

## Agent Namespacing

All framework agents use the `csf-` prefix to avoid conflicts with other Claude Code tools:

- `csf-spec` - Requirements analysis and specification creation
- `csf-plan` - Technical planning and implementation strategy creation
- `csf-implement` - Code implementation specialist
- `csf-document` - Documentation synthesis specialist

This ensures the framework can coexist with other agent-based tools without naming conflicts.

## Documentation

See [CLAUDE.md](./CLAUDE.md) for detailed setup and usage instructions.