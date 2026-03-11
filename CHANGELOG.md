# Changelog

All notable changes to the Claude Spec-First Framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.27.0] - 2026-03-11

### Changed
- Migrate hooks from `settings.json` injection to plugin-native `hooks.json` format
- Use `${CLAUDE_PLUGIN_ROOT}` for hook command paths per Claude Code plugin spec
- Add `cleanup_old_hooks()` to remove legacy CSF hook entries from `settings.json` on upgrade

### Fixed
- Fix flaky test 19 ("works without git repository") failing on broken symlinks in local `.csf/` state

## [0.26.0] - 2026-03-11

### Changed
- Migrate commands to skills format — `framework/commands/*.md` → `framework/skills/*/SKILL.md` with YAML frontmatter (#95)
- Update `validate-framework.sh` to validate skills in repo mode, commands in installed mode
- Update `install.sh` to install from `framework/skills/*/SKILL.md` instead of `framework/commands/`
- Update `plugin.json` key from `commands` to `skills`
- Update integration tests for new skill paths
- Update stale "command files" reference in AGENTS.md

## [0.25.3] - 2026-03-10

### Fixed
- Add `manage-spec-directory` to fallback agent list in `validate-framework.sh`
- Add plugin.json vs VERSION file consistency check to catch version drift

## [0.25.2] - 2026-03-10

### Changed
- Trim `manage-spec-directory` agent from 63 to 49 lines — collapse gitignore logic, remove legacy `.csf/` warning (#112)

## [0.25.1] - 2026-03-10

### Changed
- **Standardize agent description frontmatter**: All 12 agent descriptions now follow a consistent two-sentence pattern: `[Verb phrase]. Use when [condition].` No behavior changes (#111).

## [0.25.0] - 2026-03-10

### Added
- `maxTurns` limits on all 13 agent invocations to prevent runaway execution

### Changed
- Rewrite doc agents with exclusion language — mandatory sections replaced with "include only if warranted"
- AGENTS.md is now the single source of truth; CLAUDE.md references it via `@AGENTS.md`
- Trim all project docs 63% (945→351 lines) — cut speculative content, redundancy, verbose changelog
- Validation checks AGENTS.md instead of CLAUDE.md for project rules

(#110)

## [0.24.0] - 2026-03-10

### Changed
- Route 7 research agents to Haiku for faster, cheaper execution (#90)
- Add model field validation to `validate-framework.sh`

## [0.23.0] - 2026-03-09

### Changed
- Replace `explore-patterns` agent with Claude Code's built-in Explore subagent (#54)
- Add LSP support to `analyze-implementation` agent (#53)
- Add `.claude/.csf/` to `.gitignore`

### Fixed
- Same-version update message shows "reinstalled" instead of misleading arrow (#86)

## [0.22.2] - 2026-03-09

### Fixed
- Suppress false positive legacy `.csf/` warning in installed mode (#71)

## [0.22.1] - 2026-03-09

### Fixed
- `$ARGUMENTS` placeholder in implement and document commands

## [0.22.0] - 2026-03-09

### Added
- Auto-append `.claude/.csf/` to `.gitignore` when creating spec directory

## [0.21.0] - 2026-03-09

### Changed
- Collapse 3-tier size constraints into 2: agents (50 lines) and commands (75 lines)

## [0.20.0] - 2026-03-09

### Changed
- Raise doc agent line limit from 25 to 50
- Add dedup checks via `docs-inventory.md` and shared `doc-context.md`

## [0.19.1] - 2026-03-09

### Fixed
- Gate 2: downgrade missing sections from block to warn
- Include gate warnings in terminal summary

## [0.19.0] - 2026-03-09

### Added
- `analyze-existing-docs` agent for doc inventory, enabling update-or-create behavior

## [0.18.0] - 2026-03-09

### Changed
- Add required-sections contracts to `create-technical-docs` and `create-user-docs`

## [0.17.0] - 2026-03-09

### Changed
- Rewrite `integrate-docs` for content synthesis via Edit/MultiEdit

## [0.16.1] - 2026-03-09

### Fixed
- Install script repo URL: `bitcraft-labs` → `bitcraft-apps`
- Temp directory leak on early exit
- Install test for download fallback behavior

## [0.16.0] - 2026-03-09

### Added
- SubagentStop hook (`validate-subagent.sh`) for non-empty output validation
- Installer configures both Stop and SubagentStop hooks

### Fixed
- Hook scripts explicitly `exit 0` on happy path

## [0.15.1] - 2025-09-24

### Fixed
- Agent paths: use literal `.claude/.csf/research/` instead of bash function calls
- Remove unnecessary `csf-paths.sh` utility (300+ lines removed)

## [0.15.0] - 2025-09-23

### Added
- Centralized path utility `csf-paths.sh` for CSF directory management

## [0.14.0] - 2025-09-16

### Fixed
- Framework installs globally (`~/.claude/`), outputs project-locally (`./.claude/.csf/`)

## [0.13.0] - 2025-09-16

### Changed
- Migrate CSF storage from `.csf/` to `.claude/.csf/`

## [0.12.0] - 2025-09-13

### Added
- Spec directory isolation: prompts update/create-new on subsequent runs (#36)
- `manage-spec-directory` agent

## [0.11.0] - 2025-09-01

### Changed
- Split monolithic `/csf:document` into 5 parallel micro-agents (#30)

## [0.10.0] - 2025-09-01

### Changed
- Split monolithic `/csf:implement` into sequential `explore-patterns` + `implement-minimal` (#34)

## [0.9.0] - 2025-09-01

### Changed
- Split monolithic `/csf:spec` into 4 parallel micro-agents (#28)
- Simplify CLAUDE.md from 296 to 93 lines (69% reduction)

## [0.8.0] - 2025-08-29

### Added
- File persistence system (`.csf/` directory)

## [0.7.0] - 2025-08-28

### Added
- Planning phase and `csf-plan` agent (later merged into spec)

## [0.6.0] - 2025-08-27

### Added
- Validation script, version management, test infrastructure

## [0.5.0] - 2025-08-26

### Changed
- **BREAKING**: 6 agents → 3, 9 commands → 4

## [0.4.0] - 2025-08-26

### Changed
- Smart command routing via `/csf:spec-init`
- Removed overengineered GitHub automation

## [0.3.0] - 2025-08-25

### Changed
- **BREAKING**: Agent namespacing with `csf-` prefix

## [0.2.0] - 2025-08-25

### Added
- MVP workflow commands, configurable LOC limits

## [0.1.0] - 2025-08-25

### Added
- Semantic versioning system, dual-mode validation

[Unreleased]: https://github.com/bitcraft-apps/claude-spec-first/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/bitcraft-apps/claude-spec-first/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/bitcraft-apps/claude-spec-first/releases/tag/v0.4.0
[0.3.0]: https://github.com/bitcraft-apps/claude-spec-first/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/bitcraft-apps/claude-spec-first/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bitcraft-apps/claude-spec-first/releases/tag/v0.1.0
