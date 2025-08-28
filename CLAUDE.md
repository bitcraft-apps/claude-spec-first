# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Claude Spec-First Framework** - a comprehensive specification-first development framework for Claude Code. The framework transforms Claude Code into a professional development environment that follows structured workflows: Requirements → Specifications → Planning → Implementation → Documentation.

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
- `/framework/agents/` - 4 specialized sub-agents with YAML frontmatter  
- `/framework/commands/` - 4 workflow commands with YAML frontmatter
- `/framework/templates/` - Planning templates for different scenarios
- `/framework/examples/` - Usage examples and templates

**Installation System:**
- `scripts/install.sh` - Unified installer/updater with auto-detection, backup capabilities, and customization preservation
- `scripts/uninstall.sh` - Clean removal with restoration of original configs

### Sub-Agent Architecture

The framework provides 4 specialized sub-agents, each with specific roles:

1. **csf-spec** - Requirements analysis and specification creation
2. **csf-plan** - Technical planning and implementation strategy creation  
3. **csf-implement** - Code implementation following specifications and plans
4. **csf-document** - Documentation synthesis from development artifacts

Each agent is defined with YAML frontmatter specifying:
- `name` - Agent identifier for Claude Code's Task tool
- `description` - Role and capabilities
- `tools` - Available Claude Code tools (Read, Write, Edit, Bash, Grep, Glob)

### Command System

4 workflow commands orchestrate the development process:

1. **`/csf:spec`** - Create clear, actionable specifications from business requirements
2. **`/csf:plan`** - Create technical implementation plan from existing specification  
3. **`/csf:implement`** - Implement features following specifications and plans
4. **`/csf:document`** - Generate comprehensive documentation from artifacts
5. **`/csf:workflow`** - Complete end-to-end 4-phase workflow automation

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

The framework follows a structured 4-phase approach:

### Phase 1: Specification
- Analyze business requirements and create clear, actionable specifications
- Define functional requirements, acceptance criteria, and constraints
- Ensure specifications are implementation-ready

### Phase 2: Planning  
- Translate specifications into technical implementation strategies
- Analyze existing codebase to understand patterns and architecture
- Create step-by-step implementation plans with risk assessment
- Identify files to modify, dependencies, and testing strategies

### Phase 3: Implementation
- Follow implementation plan step-by-step
- Write clean code that matches specifications exactly
- Validate each step according to plan success criteria
- Execute testing strategy from the plan

### Phase 4: Documentation
- Create comprehensive technical and user documentation
- Ensure documentation accuracy against actual implementation
- Generate API references, guides, and examples

### Framework Development Guidelines

When working on this framework:

1. **Agent Development**: Agents in `/framework/agents/` must have proper YAML frontmatter with `name`, `description`, and `tools` fields
2. **Command Development**: Commands in `/framework/commands/` must have `description` field and use `$ARGUMENTS` for parameter passing
3. **Planning Templates**: Templates in `/framework/templates/planning/` provide structure for different planning scenarios
4. **Validation**: Always run `./framework/validate-framework.sh` before commits
5. **Documentation**: Update examples in `/framework/examples/` for new features
6. **Installation Testing**: Test installation process with `./scripts/install.sh` on clean systems

## File Organization Standards

- **Specifications**: `docs/specifications/` (when framework is used)
- **Implementation Plans**: `docs/plans/` (when framework is used)
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