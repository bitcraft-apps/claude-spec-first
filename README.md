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

- 11 specialized micro-agents (4 spec + 2 implement + 5 document micro-agents)
- 3 streamlined commands for clean workflow execution
- Context clearing between phases for focused work
- Smart installation with backup and merge capabilities
- Comprehensive documentation generation from artifacts
- Conflict-free operation with other Claude Code tools

## Command Reference

The framework provides 3 streamlined workflow commands:

**Workflow Commands:**
- `/csf:spec` - Create specifications through parallel micro-agents
- `/csf:implement` - Implement code through sequential micro-agents  
- `/csf:document` - Generate documentation through parallel micro-agents

## Micro-Agent Architecture

The framework uses specialized micro-agents for focused execution:

**Specification Agents:**
- `define-scope`, `create-criteria`, `identify-risks`, `synthesize-spec`

**Implementation Agents:**  
- `explore-patterns`, `implement-minimal`

**Documentation Agents:**
- `analyze-artifacts`, `analyze-implementation`, `create-technical-docs`, `create-user-docs`, `integrate-docs`

This ensures the framework can coexist with other agent-based tools without naming conflicts.

## Documentation

See [CLAUDE.md](./CLAUDE.md) for detailed setup and usage instructions.