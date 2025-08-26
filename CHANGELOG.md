# Changelog

All notable changes to the Claude Spec-First Framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

No unreleased changes.

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