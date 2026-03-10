# Claude Spec-First Framework

Minimalist development workflow for Claude Code following YAGNI, KISS, and SRP principles. **Build the smallest thing that works.**

## Quick Start

### One-Command Installation

```bash
# Install framework directly from GitHub (recommended)
curl -fsSL https://raw.githubusercontent.com/bitcraft-apps/claude-spec-first/main/scripts/remote-install.sh | bash
```

### Alternative Installation Methods

```bash
# Using wget
wget -qO- https://raw.githubusercontent.com/bitcraft-apps/claude-spec-first/main/scripts/remote-install.sh | bash

# Manual installation (requires cloning)
git clone https://github.com/bitcraft-apps/claude-spec-first.git
cd claude-spec-first
./scripts/install.sh
```

### Validate Installation

```bash
~/.claude/.csf/validate-framework.sh
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

See `framework/commands/` for orchestration details.

## File Structure

```
.claude/
└── .csf/
    ├── spec.md        # Current specification (overwritten each run)
    ├── research/      # Agent outputs
    └── [project files remain in natural locations]
```

## Documentation

- [User Guide](docs/user/guide.md) — how to use the framework
- [Technical Reference](docs/technical-reference.md) — contracts and setup
- [CLAUDE.md](./CLAUDE.md) — framework rules and development guidelines
