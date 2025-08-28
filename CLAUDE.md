# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Claude Spec-First Framework** - a comprehensive specification-first development framework for Claude Code. The framework transforms Claude Code into a professional development environment that follows structured workflows: Requirements → Specifications → Tests → Architecture → Implementation → Quality Assurance → Documentation.

## Development Commands

### Framework Management
```bash
# Install or update framework (auto-detects existing installations)
./scripts/install.sh

# Validate framework installation
./framework/validate-framework.sh

# Uninstall framework
./scripts/uninstall.sh
```

### Testing & Validation
```bash
# Validate framework configuration
~/.claude/validate-framework.sh

# Test installation in Claude directory
cd ~/.claude && ./validate-framework.sh
```

### Repository Operations
```bash
# No build process - this is a configuration framework
# No test suite - validation is through validate-framework.sh
# No package manager - pure shell script and markdown files
```

## Architecture Overview

### Core Components

**Framework Structure:**
- `/framework/` - Core framework files that get installed to `~/.claude/`
- `/framework/CLAUDE.md` - Global workflow principles for all Claude Code sessions
- `/framework/agents/` - 6 specialized sub-agents with YAML frontmatter
- `/framework/commands/` - 6 workflow commands with YAML frontmatter
- `/framework/examples/` - Usage examples and templates

**Installation System:**
- `scripts/install.sh` - Unified installer/updater with auto-detection, backup capabilities, and customization preservation
- `scripts/uninstall.sh` - Clean removal with restoration of original configs

### Sub-Agent Architecture

The framework provides 6 specialized sub-agents, each with specific roles:

1. **spec-analyst** - Requirements analysis and specification creation
2. **test-designer** - Test-first development with comprehensive test suites
3. **arch-designer** - System architecture and technical design decisions
4. **impl-specialist** - Code implementation following specifications and tests
5. **qa-validator** - Quality assurance and deployment readiness validation
6. **doc-synthesizer** - Documentation synthesis from development artifacts

Each agent is defined with YAML frontmatter specifying:
- `name` - Agent identifier for Claude Code's Task tool
- `description` - Role and capabilities
- `tools` - Available Claude Code tools (Read, Write, Edit, Bash, Grep, Glob)

### Command System

6 workflow commands orchestrate the development process:

1. **`/spec-init`** - Initialize specification process for new features
2. **`/spec-review`** - Multi-agent specification validation
3. **`/impl-plan`** - Implementation planning with architecture decisions
4. **`/qa-check`** - Quality validation and deployment readiness
5. **`/doc-generate`** - Generate comprehensive documentation from artifacts
6. **`/spec-workflow`** - Complete end-to-end workflow automation

Commands use YAML frontmatter with `description` field and delegate to appropriate agents using `$ARGUMENTS` placeholder.

### Installation Strategy

**Smart Installation Process:**
1. Creates `~/.claude/` directory structure if needed
2. Backs up existing configurations with timestamp
3. Merges framework principles with existing `CLAUDE.md` (if present)
4. Installs agents, commands, examples, and validation tools
5. Handles both local execution and remote installation via curl

**Update Strategy:**
- Preserves user customizations in existing files
- Only overwrites framework-specific sections
- Maintains backup chain for rollback capability

## Development Workflow

When working on this framework:

1. **Agent Development**: Agents in `/framework/agents/` must have proper YAML frontmatter with `name`, `description`, and `tools` fields
2. **Command Development**: Commands in `/framework/commands/` must have `description` field and use `$ARGUMENTS` for parameter passing
3. **Validation**: Always run `./framework/validate-framework.sh` before commits
4. **Documentation**: Update examples in `/framework/examples/` for new features
5. **Installation Testing**: Test installation process with `./scripts/install.sh` on clean systems

## File Organization Standards

- **Specifications**: `docs/specifications/` (when framework is used)
- **Architecture decisions**: `docs/architecture/` (when framework is used)
- **Context and examples**: `docs/context/` (when framework is used)
- **Framework source**: `/framework/` (this repository)
- **Installation target**: `~/.claude/` (user systems)

## Quality Standards

- All agents must pass validation script checks
- Commands must properly delegate to specialized agents
- YAML frontmatter must be syntactically correct
- Installation scripts must handle edge cases (existing configs, permissions, etc.)
- Framework must maintain backward compatibility during updates