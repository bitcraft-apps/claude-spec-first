# Technical Reference: Claude Spec-First Framework

<!-- Framework version: 0.25.3 -->

## Overview

3 commands orchestrate 13 agent invocations. 7 research agents run on Haiku; 5 synthesis/implementation agents use the caller's model. 1 built-in Explore subagent handles pattern discovery. All output goes to `.claude/.csf/research/` (gitignored).

## Commands

Commands are defined as skills in `skills/`. Each `SKILL.md` is the source of truth for agent orchestration, batching, and gates.

- `/csf:spec [REQUIREMENTS]` — parallel research → synthesis into `spec.md`
- `/csf:implement [SPEC_OR_PATH]` — Explore subagent for patterns → `implement-minimal` for code
- `/csf:document [PATHS]` — parallel analysis → parallel doc generation → integration into `docs/`

## Agents

Agent files live in `framework/agents/`. Each has YAML frontmatter: `name`, `description`, `tools` (required), `model` (optional, only `haiku`). See agent files for details — they are the source of truth.

Agent turn limits (`maxTurns`) are set in skill files, not agent frontmatter.

## Integration Contracts

### pattern-example.md

`.claude/.csf/research/pattern-example.md` is the handoff between Explore (Step 1) and `implement-minimal` (Step 2) in `/csf:implement`. Free-form markdown. Referenced in `skills/implement/SKILL.md` and `framework/agents/implement-minimal.md`.

### plugin.json

`.claude-plugin/plugin.json` declares the framework's component inventory: agents, skills, and hooks. `install.sh` and `validate-framework.sh` read it to enumerate files instead of maintaining separate lists.

Schema:

```json
{
  "name": "string",
  "version": "string (must match framework/VERSION)",
  "description": "string",
  "agents": ["string — basename without extension"],
  "skills": ["string — basename without extension"],
  "hooks": ["string — filename with extension"]
}
```

**Fallback behavior:** If the manifest is missing, invalid JSON, or `jq` is not installed, both scripts fall back to their previous behavior (directory globs for install, hardcoded arrays for validation).

**Version drift:** `validate-framework.sh` checks that `plugin.json` version matches `framework/VERSION` and fails validation if they differ. This check only runs in repository mode.

## Setup

- Claude Code CLI with `Agent` tool support (`subagent_type`, `maxTurns`)
- Haiku model access for research agents
- LSP is optional — `analyze-implementation` falls back to Grep/Glob

### .gitignore

```gitignore
.csf/
.claude/.csf/
```

Both entries prevent CSF artifacts from being committed.

### Validation

```bash
bash framework/validate-framework.sh
```

## Cross-References

- [User Guide](user/guide.md)
- [CLAUDE.md](../CLAUDE.md) — framework philosophy and rules
- [CHANGELOG.md](../CHANGELOG.md)
