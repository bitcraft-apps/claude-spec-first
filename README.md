# Claude Spec-First Framework

Minimalist development workflow for Claude Code following YAGNI, KISS, and SRP principles. **Build the smallest thing that works.**

## Quick Start

### Installation

```bash
claude plugin marketplace add bitcraft-apps/claude-spec-first
claude plugin install claude-spec-first
```

For local development, use `--plugin-dir` to point at your clone:

```bash
claude --plugin-dir ./claude-spec-first
```

## Core Philosophy

- **YAGNI**: Don't build it until you need it
- **KISS**: Simplest solution that works
- **SRP**: Each component does one thing
- **MVP First**: Deliver narrowest viable change

## Features

- 12 specialized agents (50 lines max each)
- 3 workflow commands (75 lines max each)
- Challenge assumptions and unclear requirements
- Smart implementation: CLI tools for immediate needs, code for reusable solutions
- Technology agnostic and self-documenting

## Command Reference

- `/csf:spec [REQUIREMENTS]` — Define what to build and why
- `/csf:implement [SPEC_OR_PATH]` — Build the minimal working solution
- `/csf:document [PATHS]` — Generate docs proportional to the change

See `skills/` for orchestration details.

## File Structure

```
.claude/
└── .csf/
    ├── spec.md        # Current specification (overwritten each run)
    ├── research/      # Agent outputs
    └── [project files remain in natural locations]
```
