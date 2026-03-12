# Technical Reference: Claude Spec-First Framework

## Overview

3 commands orchestrate 13 agent invocations. 7 research agents run on Haiku; 5 synthesis/implementation agents use the caller's model. 1 built-in Explore subagent handles pattern discovery. All output goes to `.claude/.csf/research/` (gitignored).

## Commands

Commands are defined as skills in `framework/skills/`. Each `SKILL.md` is the source of truth for agent orchestration, batching, and gates.

- `/csf:spec [REQUIREMENTS]` — parallel research → synthesis into `spec.md`
- `/csf:implement [SPEC_OR_PATH]` — Explore subagent for patterns → `implement-minimal` for code
- `/csf:document [PATHS]` — parallel analysis → parallel doc generation → integration into `docs/`

## Agents

Agent files live in `framework/agents/`. Each has YAML frontmatter: `name`, `description`, `tools` (required), `model` (optional, only `haiku`). See agent files for details — they are the source of truth.

Agent turn limits (`maxTurns`) are set in skill files, not agent frontmatter.

## Integration Contracts

### pattern-example.md

`.claude/.csf/research/pattern-example.md` is the handoff between Explore (Step 1) and `implement-minimal` (Step 2) in `/csf:implement`. Free-form markdown. Referenced in `framework/skills/implement/SKILL.md` and `framework/agents/implement-minimal.md`.

### plugin.json

`.claude-plugin/plugin.json` declares the framework's component inventory: agents, skills, and hooks. `validate-framework.sh` reads it to enumerate files instead of maintaining separate lists.

Schema:

```json
{
  "name": "string",
  "version": "string (must match framework/VERSION)",
  "description": "string",
  "agents": ["string — relative path to agent directory"],
  "skills": ["string — relative path to skill directory"],
  "hooks": "string — relative path to hooks.json"
}
```

**Fallback behavior:** If the manifest is missing, invalid JSON, or `jq` is not installed, `validate-framework.sh` falls back to hardcoded arrays.

**Version drift:** `validate-framework.sh` checks that `plugin.json` version matches `framework/VERSION` and fails validation if they differ. This check only runs in repository mode.

### marketplace.json

`.claude-plugin/marketplace.json` — marketplace catalog for plugin discovery. Enables `claude plugin marketplace add bitcraft-apps/claude-spec-first`.

Schema:

```json
{
  "name": "string (marketplace identifier)",
  "owner": { "name": "string" },
  "plugins": [{
    "name": "string (plugin identifier)",
    "source": { "source": "github", "repo": "owner/repo" },
    "description": "string",
    "version": "string (must match framework/VERSION)"
  }]
}
```

Plugin version is auto-synced by release-please alongside `plugin.json`. `validate-framework.sh` checks consistency.

**Relationship to plugin.json:** `marketplace.json` is the catalog (how users discover and install the plugin). `plugin.json` is the manifest (what the plugin provides). Both have version fields kept in sync automatically.

### hooks.json

`framework/hooks/hooks.json` declares hook commands in Claude Code's plugin-native format.

Schema:

```json
{
  "hooks": {
    "<EventName>": [{
      "matcher": "string (optional — glob pattern for SubagentStop)",
      "hooks": [{
        "type": "command",
        "command": "string"
      }]
    }]
  }
}
```

Hook commands use `${CLAUDE_PLUGIN_ROOT}` as a path prefix. Claude Code resolves this to the plugin's install directory at runtime, so hook scripts do not contain absolute paths.

Current events: `Stop` (2 hooks: validate-spec, validate-implementation), `SubagentStop` (1 hook: validate-subagent, matcher `*`).

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

- [CLAUDE.md](../CLAUDE.md) — framework philosophy and rules
- [CHANGELOG.md](../CHANGELOG.md)
