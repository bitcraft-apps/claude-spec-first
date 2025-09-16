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
.claude/
└── .csf/
    ├── spec.md        # Current specification (overwritten each run)
    ├── research/      # Micro-agent outputs
    └── [project files remain in natural locations]
```

## Command Reference

### `/csf:spec [REQUIREMENTS]`
Create specifications through parallel analysis
- **Purpose**: Define what to build and why
- **Agents**: manage-spec-directory, define-scope, create-criteria, identify-risks, synthesize-spec
- **Output**: `~/.claude/.csf/spec.md`
- **Example**: `/csf:spec Add user authentication with login/logout`

### `/csf:implement [SPECIFICATION_OR_PATH]`
Implement through pattern learning
- **Purpose**: Build the minimal working solution
- **Agents**: explore-patterns, implement-minimal
- **Output**: Implementation + `~/.claude/.csf/implementation-summary.md`
- **Example**: `/csf:implement` or `/csf:implement ./specs/auth-spec.md`

### `/csf:document [SPEC_PATH] [IMPLEMENTATION_PATH]`
Document through comprehensive analysis
- **Purpose**: Generate technical and user documentation
- **Agents**: analyze-artifacts, analyze-implementation, create-technical-docs, create-user-docs, integrate-docs
- **Output**: Documentation in `docs/` and `docs/user/`
- **Example**: `/csf:document ~/.claude/.csf/spec.md ./src/auth.js`

## Migration from .csf/ to .claude/.csf/

If you have existing `.csf/` directories from previous versions:

```bash
# 1. Copy content to new location
cp -r .csf/* ~/.claude/.csf/

# 2. Remove old directory
rm -rf .csf/

# 3. Framework will automatically use new location
```

The framework will detect legacy `.csf/` directories and provide migration guidance.

## Documentation

See [CLAUDE.md](./CLAUDE.md) for complete framework rules and development guidelines.