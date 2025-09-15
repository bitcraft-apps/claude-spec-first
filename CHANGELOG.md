# Changelog

All notable changes to the Claude Spec-First Framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.12.0] - 2025-09-13

### Added
- **Spec Directory Isolation**: Prevents spec runs from overwriting each other (#36)
  - User-controlled behavior: prompts "Update (u) or Create new (n)?" on subsequent runs
  - Timestamped directories: `.csf/specs/YYYY-MM-DD-HHMMSS/` when creating new
  - Safe backup system: only backs up when user chooses update
  - Symlink compatibility: maintains `.csf/spec.md` and `.csf/research/` paths
  - New micro-agent: `manage-spec-directory` (25 lines, user consent required)

### Changed
- **Enhanced /csf:spec Command**: Added user-controlled directory management
  - Non-destructive: no operations without user consent
  - Flexible workflow: supports both updating existing and creating new specs
  - Backward compatible: existing tools work with symlinked paths

### Technical
- **User Agency**: All destructive operations require explicit user consent
- **KISS Principle**: Simple single-character user prompt (u/n)
- **Framework Compliance**: Follows YAGNI, SRP, and 25-line agent constraints
- **Safe Operations**: Backup and timestamping only when requested

## [0.11.0] - 2025-09-01

### Added
- **Parallel Documentation Micro-Agents**: Transformed /csf:document from monolithic to parallel micro-agents (#30)
  - analyze-artifacts: Read and parse development artifacts (20 lines)
  - analyze-implementation: Analyze code structure and patterns (20 lines)  
  - create-technical-docs: Generate developer documentation (35 lines)
  - create-user-docs: Generate user-facing documentation (35 lines)
  - integrate-docs: Combine and organize final documentation (15 lines)
  - 3-batch orchestrated execution: Parallel analysis → Parallel generation → Sequential integration
  - 20%+ performance improvement through parallel processing

### Changed
- **Documentation Philosophy**: Specialized micro-agents for focused output quality
  - Parallel artifact and implementation analysis for speed
  - Separate technical and user documentation generation for clarity
  - Clean boundaries: analyzers read, generators write to .csf/research/, integrator moves to final locations
  - Input resolution logic: check .csf/ artifacts, ask user if missing

### Removed
- **Monolithic csf-document agent** (156 lines) - replaced with 5 focused micro-agents (125 lines total)

### Technical
- Updated validation script with new micro-agent requirements
- Updated installation tests for new agent structure
- Updated README.md with current micro-agent architecture (11 total agents)

## [0.10.0] - 2025-09-01

### Added
- **Sequential Implementation Micro-Agents**: Transformed /csf:implement from monolithic to sequential micro-agents (#34)
  - explore-patterns: Find existing patterns to follow (18 lines)
  - implement-minimal: Write simplest working code (23 lines)
  - Sequential workflow: Learn patterns → Implement solution
  - Embedded minimalist principles: Pattern consistency over creativity, Working code over perfect code

### Changed
- **Implementation Philosophy**: Enforces pattern discovery before code generation
  - "Pattern consistency over creativity" - must find existing approach first
  - "Working code over perfect code" - implements simplest solution that works
  - "Minimal solution over extensible solution" - no future-proofing abstractions
  - Technology-agnostic approach for any language/framework

### Removed
- **Monolithic csf-implement agent** (136 lines) - replaced with focused micro-agents
- Verbose implementation principles documentation - embedded in agent behavior instead

### Technical
- 55% code reduction in implementation area (191→86 total lines)
- Updated validation script for new agent requirements
- Updated all test suites for sequential micro-agent architecture
- Framework validation: 67/67 tests passing

## [0.9.0] - 2025-09-01

### Added
- **Micro-Agent Architecture**: Transformed /csf:spec from monolithic to parallel micro-agents (#28)
  - csf-define-scope: Define narrowest viable solution (18 lines)
  - csf-create-criteria: Generate minimal acceptance criteria (18 lines) 
  - csf-identify-risks: Identify essential risks only (18 lines)
  - csf-synthesize-spec: Combine research into 50-line specifications (18 lines)
  - Command-level clarification logic for vague requirements
  - Parallel execution of research agents for improved performance

### Changed
- **CLAUDE.md Simplification**: Radically simplified project guidance from 296 to 93 lines (69% reduction)
  - Established minimalist engineering principles (YAGNI, KISS, SRP, MVP-first)
  - Added anti-patterns to avoid (enterprise solutions, blind pattern following, unnecessary complexity)
  - Introduced "Smart Implementation" guidance for choosing between direct CLI usage vs code
  - Enabled "Challenge Mode" to question requirements for robustness
  - Merged planning phase into specification phase to reduce redundancy
  - Removed verbose documentation in favor of self-documenting, actionable rules

- **Agent Output Philosophy**: Embedded minimalist principles directly in agent outputs
  - Agents now produce MVP-focused specifications (51 lines vs 122 lines previously)
  - Automatic YAGNI application: "Last 5 actions (not 10 - YAGNI)"
  - KISS technical approaches: Cache over real-time, progressive enhancement
  - Challenge assumptions: Agents ask clarifying questions instead of assuming enterprise needs
  - Prevent overengineering: No enterprise metrics unless explicitly requested

## [0.8.0] - 2025-08-29

### Added
- **File Persistence System**: Persistent `.csf/` directory for development artifacts enabling safe context clearing
- **Poison Context Awareness**: Built-in guidance and mitigations for context contamination between phases
- **Workflow Archival**: Automatic archiving of previous workflow runs with timestamped backups
- **Context-Safe Operations**: Enhanced agents with standalone task messaging and explicit phase boundaries

### Enhanced
- **Agent Instructions**: Updated all agents with file input/output requirements and persistence capabilities
- **Command Documentation**: Added context management guidance and best practices for individual vs workflow commands
- **Framework Architecture**: Integrated file persistence with existing 4-phase workflow
- **User Guidance**: Comprehensive documentation on when to use `/clear` and individual commands vs workflow

### Changed
- **Agent Behavior**: All agents now write artifacts to `.csf/current/` directory for persistent storage
- **Workflow Process**: Enhanced with archival step and persistent artifact management
- **Documentation Approach**: Framework now enterprise-ready with professional audit trail capabilities

## [0.7.0] - 2025-08-28

### Added
- **Planning Phase**: New technical planning phase between specification and implementation
- **Planning Agent (`csf-plan`)**: Specialized agent for creating technical implementation strategies
- **Planning Command (`/csf:plan`)**: Command for generating implementation plans from specifications
- **Planning Templates**: Comprehensive templates for standard, refactoring, and migration planning
- **4-Phase Workflow**: Enhanced workflow: Specification → Planning → Implementation → Documentation

### Changed
- **Framework Architecture**: Updated from 3-agent to 4-agent system with planning integration
- **Workflow Command**: Enhanced `/csf:workflow` to include planning phase between spec and implementation
- **Template Organization**: Templates moved to `.csf/templates/` directory to avoid Claude Code conflicts
- **Installation Process**: Updated to install planning templates in framework-specific location

### Enhanced
- **Risk Mitigation**: Planning phase provides safe research before execution
- **Implementation Strategy**: Technical approach validated before coding begins
- **Test Coverage**: Added comprehensive tests for all planning components (118 total tests)
- **Documentation**: Updated CLAUDE.md and README.md with 4-phase workflow details

## [0.6.0] - 2025-08-27

### Added
- **Installation Validation**: Added validation script to installation process (installed at `~/.claude/.csf/validate-framework.sh`)
- **Development Testing**: Added `tests/` directory with integration and version testing scripts
- **Version Management**: Added `scripts/version.sh` for semantic version management

### Changed
- **Framework Structure**: Streamlined framework directory to contain only essential installable components
- **Validation Script**: Enhanced dual-mode operation with proper installed mode support
- **Installation Process**: Now installs validation script and provides validation instructions
- **Issue Templates**: Simplified GitHub issue templates to focus on bug reports and feature requests only

### Removed
- **Outdated Documentation**: Removed entire `docs/` directory with obsolete 6-agent system documentation
- **Framework Bloat**: Removed unused `framework/config/`, `framework/templates/`, and outdated examples
- **Redundant Files**: Removed duplicate `framework/README.md` and `framework/CLAUDE.md`
- **Development Utils**: Moved `framework/utils/` to `scripts/` and `tests/` directories
- **Issue Template Complexity**: Removed documentation, installation, and usage question templates

### Fixed
- **Validation Paths**: Fixed validation script to properly handle `.csf/` installation directory
- **Component References**: Updated all validation checks to use current 3-agent, 4-command structure

## [0.5.0] - 2025-08-26

### Added
- **Context Clearing**: Implemented context clearing between workflow phases for focused work
- **Streamlined Command Structure**: New clean command naming with 4 primary commands
- **Simplified Agent System**: Consolidated functionality into 3 specialized agents

### Changed
- **BREAKING**: Revolutionary framework simplification from 6 agents down to 3 agents
- **BREAKING**: Command structure changed from 9 commands to 4 primary commands
- **BREAKING**: Agent names updated to `csf-spec`, `csf-implement`, `csf-document`
- **BREAKING**: Command names updated to `spec`, `implement`, `document`, `workflow`
- Updated workflow to use baby steps evolution approach with clear phase separation
- Enhanced documentation and examples for simplified structure

### Removed
- **BREAKING**: Removed `csf-test-designer` agent (testing integrated into implementation phase)
- **BREAKING**: Removed `csf-arch-designer` agent (architecture integrated into implementation phase)
- **BREAKING**: Removed `csf-qa-validator` agent (QA integrated into implementation phase)
- **BREAKING**: Removed `spec-review`, `impl-plan`, `qa-check`, `complexity-eval`, `spec-mvp` commands
- Eliminated complexity that had accumulated over multiple iterations

## [0.4.0] - 2025-08-26

### Added
- **Smart Command Routing**: `/csf:spec-init` now functions as intelligent router that automatically selects optimal workflow based on project complexity
- **Streamlined Command Structure**: Simplified from 9 commands to 4 primary + 5 utility commands with consistent `csf:` prefixes
- **Decision Matrix**: Clear workflow routing with automatic escalation from simple to complex workflows

### Changed
- **BREAKING**: Command routing behavior - `/csf:spec-init` now routes to appropriate workflow rather than direct specification
- Updated all documentation to use consistent `csf:` command prefixes
- Improved user experience with reduced cognitive load for workflow selection

### Removed
- Overengineered GitHub automation and monitoring system that added unnecessary complexity

## [0.3.0] - 2025-08-25

### Added
- **Agent Namespacing**: All framework agents now use `csf-` prefix to prevent conflicts with other Claude Code tools
- Agents installed to `~/.claude/agents/csf/` and commands to `~/.claude/commands/csf/`
- Dual-mode validation works in both repository and installed environments

### Changed
- **BREAKING**: Agent naming convention changed to include `csf-` prefix

## [0.2.0] - 2025-08-25

### Added
- **MVP Workflow Support**: New `/implement-now`, `/spec-mvp`, `/complexity-eval` commands for rapid development
- **Configuration System**: Configurable LOC limits (500-line default) and complexity modes
- **Token Optimization**: 60-70% token reduction in MVP mode through streamlined outputs
- **Performance Improvements**: 50% faster implementation for simple features

## [0.1.0] - 2025-08-25

### Added
- **Semantic Versioning System**: Complete versioning utilities with CLI interface and framework integration
- VERSION file with semantic versioning (X.Y.Z format)
- Dual-mode operation support for both repository and installed environments
- Comprehensive testing with 45+ unit tests and 20 integration tests
- Enhanced framework validation with version display

## Pre-versioned Releases

The following releases occurred before the versioning system was implemented:

### Dual-Mode Validation Script - 2025-08-25
- Security enhancements and validation improvements
- Support for both development and production environments

### Documentation System - 2025-08-24
- Comprehensive documentation generation system and framework validation
- Phase 6 workflow documentation
- Framework validation testing suite

### GitHub Integration - 2025-08-23
- Comprehensive documentation system with Phase 6 workflow
- Comprehensive GitHub Issues setup with monitoring capabilities
- Automated issue management and labeling system

### Initial Framework - 2025-08-22
- **Core Framework**: Complete Claude Spec-First Framework with 6 specialized agents and 5 workflow commands
- **Core Agents**: spec-analyst, test-designer, arch-designer, impl-specialist, qa-validator, doc-synthesizer  
- **Workflow Commands**: spec-init, spec-review, impl-plan, qa-check, spec-workflow
- **Installation System**: Smart installer with backup/merge capabilities and update/uninstall scripts
- **Validation Suite**: Comprehensive framework validation with 83+ automated checks
- **GitHub Integration**: CI/CD workflows for validation and installation testing

[Unreleased]: https://github.com/bitcraft-apps/claude-spec-first/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/bitcraft-apps/claude-spec-first/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/bitcraft-apps/claude-spec-first/releases/tag/v0.4.0
[0.3.0]: https://github.com/bitcraft-apps/claude-spec-first/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/bitcraft-apps/claude-spec-first/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bitcraft-apps/claude-spec-first/releases/tag/v0.1.0