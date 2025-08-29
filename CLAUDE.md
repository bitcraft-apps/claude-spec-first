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
- `/framework/commands/` - 5 workflow commands with YAML frontmatter
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

5 workflow commands orchestrate the development process:

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
3. **Documentation**: Update examples in `/framework/examples/` for new features
4. **Validation**: Always run `./framework/validate-framework.sh` before commits
5. **Installation Testing**: Test installation process with `./scripts/install.sh` on clean systems

## File Organization Standards

- **Specifications**: `docs/specifications/` (when framework is used)
- **Implementation Plans**: `docs/plans/` (when framework is used)
- **Architecture decisions**: `docs/architecture/` (when framework is used)
- **Context and examples**: `docs/context/` (when framework is used)
- **Framework source**: `/framework/` (this repository)
- **Installation target**: `~/.claude/` (user systems)

## Poison Context Awareness

The framework is designed to handle "poison context" - where behavioral patterns from one phase contaminate subsequent phases. This awareness is built into the framework design:

### Context Contamination Risks
- **Sequential Execution**: When using `/csf:workflow`, all phases run in the same context
- **Behavioral Associations**: Claude may form unintended connections between phases (e.g., assuming every spec needs immediate implementation)
- **Context Accumulation**: Long conversations can degrade performance due to accumulated context

### Built-in Mitigations
- **Agent Isolation**: Each agent uses the Task tool, providing natural context boundaries
- **Explicit Boundaries**: Agents include explicit instructions to focus only on their specific phase
- **Standalone Task Messaging**: Each agent is told this is a standalone task without automatic next steps

### Best Practices
- **Use Individual Commands**: For critical work, run `/csf:spec`, `/csf:plan`, `/csf:implement`, `/csf:document` separately
- **Context Reset**: Use `/clear` command between phases when running individual commands
- **Workflow Command Usage**: Reserve `/csf:workflow` for rapid prototyping or proof-of-concept work
- **Monitor for Associations**: Watch for signs that Claude is making assumptions about automatic phase transitions

### Warning Signs of Poisoned Context
- Claude automatically suggesting next phases without being asked
- Assumptions about immediate implementation when only planning was requested
- Mixing concerns between different development phases
- Degraded performance or confused responses

When these signs appear, use the `/clear` command to reset context and continue with individual phase commands.

## File Persistence System

The framework uses a `.csf/` directory for persistent storage of development artifacts, enabling safe context clearing between phases.

### Directory Structure
```
.csf/
├── current/                    # Active workflow artifacts
│   ├── spec.md                # Current specification
│   ├── plan.md                # Current implementation plan
│   └── implementation-summary.md  # Current implementation summary
└── archived/                   # Previous workflow runs
    └── YYYYMMDD_HHMMSS/        # Timestamped archives
        ├── spec.md
        ├── plan.md
        └── implementation-summary.md
```

### How File Persistence Works

**Specification Phase**: `csf-spec` agent writes complete specifications to `.csf/current/spec.md`
**Planning Phase**: `csf-plan` agent reads the spec file and writes plans to `.csf/current/plan.md`  
**Implementation Phase**: `csf-implement` agent reads both files and writes summary to `.csf/current/implementation-summary.md`
**Documentation Phase**: `csf-document` agent reads all artifacts and generates project documentation

### Benefits

1. **Context Clearing**: Safe to use `/clear` between phases without losing work
2. **Work Resumption**: Continue interrupted workflows by referencing existing files
3. **Audit Trail**: Review decision history through archived artifacts
4. **Debugging**: Inspect intermediate outputs when troubleshooting
5. **Version Control**: `.csf/` can be gitignored or committed based on team preferences

### Archival Process

The `/csf:workflow` command automatically archives previous runs:
- Existing `.csf/current/` content moves to `.csf/archived/YYYYMMDD_HHMMSS/`
- Fresh `.csf/current/` directory created for new workflow
- No data loss between workflow executions

### Git Integration

Add to `.gitignore` to keep artifacts local:
```
# Claude Spec-First Framework artifacts (recommended for most projects)
.csf/
```

Or commit for team visibility while keeping archives local:
```
# Commit current workflow but ignore archived runs
.csf/current/
!.csf/archived/
```

Or commit everything for full audit trail:
```
# Commit all workflow artifacts (use with caution - can grow large)
# .csf/ - commented out to include all
```

### Troubleshooting File Operations

#### Permission Issues
If you encounter permission errors when creating `.csf/` directory:

**Problem**: `mkdir: cannot create directory '.csf': Permission denied`
**Solution**: 
```bash
# Check current directory permissions
ls -la

# If needed, ensure you have write permissions in the project directory
# or choose a different base directory for your project
```

#### Disk Space Issues
If archival fails due to disk space:

**Problem**: `No space left on device`
**Solutions**:
- Clean up old archived workflows: `rm -rf .csf/archived/YYYYMMDD_*`
- Move archives to external storage
- Add `.csf/archived/` to `.gitignore` and don't commit archived workflows

#### Missing Files
If agents can't find expected files:

**Problem**: `spec.md not found in .csf/current/`
**Solutions**:
- Run previous phases first (`/csf:spec`, `/csf:plan`)
- Provide file paths directly when running commands
- Use individual phase commands instead of `/csf:workflow` if files exist elsewhere

#### Corrupted Workflow State
If workflow artifacts become inconsistent:

**Problem**: Mismatched or outdated files between phases
**Solutions**:
```bash
# Reset workflow state
rm -rf .csf/current/
mkdir -p .csf/current

# Start fresh with /csf:workflow or run phases individually
```

#### File System Compatibility
For Windows users or case-sensitive file systems:

**Issue**: File path case sensitivity problems
**Solution**: Framework uses lowercase filenames consistently (`spec.md`, `plan.md`, `implementation-summary.md`)

#### Network File Systems
For projects on NFS, SMB, or other network file systems:

**Issue**: File locking or permission issues
**Solution**: Consider using local temporary directory:
```bash
# Create symlink to local storage if needed
mkdir -p /tmp/project-csf
ln -s /tmp/project-csf .csf
```

## Quality Standards

- All agents must pass validation script checks
- Commands must properly delegate to specialized agents
- YAML frontmatter must be syntactically correct
- Installation scripts must handle edge cases (existing configs, permissions, etc.)
- Framework must maintain backward compatibility during updates