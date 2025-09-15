# Claude Spec-First Framework

Minimalist development workflow for Claude Code following YAGNI, KISS, and SRP principles. **Build the smallest thing that works.**

## Quick Start

```bash
# Install framework globally
./scripts/install.sh

# Validate installation
~/.claude/validate-framework.sh
```

## Core Philosophy

- **YAGNI**: Don't build it until you need it
- **KISS**: Simplest solution that works
- **SRP**: Each component does one thing
- **MVP First**: Deliver narrowest viable change

## Features

- 12 specialized micro-agents (25 lines max each)
- 3 workflow commands (50 lines max each)
- Challenge assumptions and unclear requirements
- Smart implementation: CLI tools for immediate needs, code for reusable solutions
- Granular task execution with progress visibility
- Technology agnostic and self-documenting

## Workflow Commands

**3-Phase Workflow:**
- `/csf:spec` - Define what to build and why (includes planning)
- `/csf:implement` - Build it (code OR direct execution)
- `/csf:document` - Document what was built

## Micro-Agent Architecture

**Specification Agents:**
- `manage-spec-directory`, `define-scope`, `create-criteria`, `identify-risks`, `synthesize-spec`

**Implementation Agents:**
- `explore-patterns`, `implement-minimal`

**Documentation Agents:**
- `analyze-artifacts`, `analyze-implementation`, `create-technical-docs`, `create-user-docs`, `integrate-docs`

## File Structure

```
.csf/
├── spec.md        # Current specification (overwritten each run)
├── research/      # Micro-agent outputs
└── [project files remain in natural locations]
```

## Documentation

See [CLAUDE.md](./CLAUDE.md) for complete framework rules and development guidelines.