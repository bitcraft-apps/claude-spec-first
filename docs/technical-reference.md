# Technical Reference: Claude Spec-First Framework

<!-- Generated: 2026-03-09 | Source: PR #88 (CSF v1.0 Native) | Framework version: 0.23.0 -->

## Overview

The Claude Spec-First (CSF) framework provides a minimalist development workflow built on YAGNI, KISS, and SRP principles. It consists of 3 commands that orchestrate 12 specialized agents.

As of v0.23.0, the framework delegates pattern discovery to Claude Code's built-in Explore subagent and supports LSP-based semantic navigation in the `analyze-implementation` agent. The net effect is tighter alignment with built-in capabilities and less custom code to maintain.

Architecture:

```
3 commands  -->  12 agents
                   |
                   v
   .claude/.csf/research/   (gitignored runtime output)
```

## API Reference

### Commands

#### `/csf:spec [REQUIREMENTS]`

Creates specifications through parallel analysis.

| Agent | Responsibility |
|-------|---------------|
| manage-spec-directory | Ensure `.claude/.csf/` exists |
| define-scope | Define what to build |
| create-criteria | Define acceptance criteria |
| identify-risks | Identify risks and unknowns |
| synthesize-spec | Merge agent outputs into `spec.md` |

Output: `.claude/.csf/spec.md`

#### `/csf:implement [SPECIFICATION_OR_PATH]`

Orchestrates implementation in two sequential steps:

| Step | Mechanism | Output |
|------|-----------|--------|
| 1: Learn | `Agent` tool with `subagent_type="Explore"`, medium thoroughness | `.claude/.csf/research/pattern-example.md` |
| 2: Implement | Delegates to `implement-minimal` agent | Working code + `.claude/.csf/implementation-summary.md` |

Input resolution order:
1. `$ARGUMENTS` if provided (path or inline spec)
2. `.claude/.csf/spec.md` if it exists
3. Interactive prompt

Error recovery: when exploration finds no patterns, `implement-minimal` creates a basic file structure following language conventions and notes "No existing patterns found - used minimal approach" in the summary.

#### `/csf:document [SPEC_PATH] [IMPLEMENTATION_PATH]`

Generates documentation through comprehensive analysis.

| Agent | Responsibility |
|-------|---------------|
| analyze-artifacts | Examine spec and implementation artifacts |
| analyze-implementation | Analyze code structure (supports LSP) |
| create-technical-docs | Generate technical documentation |
| create-user-docs | Generate user-facing documentation |
| integrate-docs | Merge and deduplicate documentation |

Output: Documentation in `docs/` and `docs/user/`

### Agents

#### analyze-implementation

```yaml
name: analyze-implementation
description: Analyze actual implementation files and code structure
tools: Read, Grep, Glob, LSP
```

- Input: implementation paths from arguments or artifact references
- Output: `.claude/.csf/research/implementation-summary.md`
- Responsibilities: find main implementation files, identify key APIs/functions/patterns, note file organization, extract usage examples from code and tests
- LSP is optional; the agent falls back to Read, Grep, and Glob when LSP is unavailable

#### implement-minimal

```yaml
name: implement-minimal
description: Write simplest working code
tools: Read, Write, Edit, MultiEdit, Bash
```

- Inputs: `.claude/.csf/spec.md` (or specified path) and `.claude/.csf/research/pattern-example.md`
- Output: working code + `.claude/.csf/implementation-summary.md`

### Validation Script

`framework/validate-framework.sh` defines these framework constants:

```bash
REQUIRED_AGENTS=("define-scope" "create-criteria" "identify-risks" "synthesize-spec"
                 "implement-minimal" "analyze-artifacts" "analyze-implementation"
                 "create-technical-docs" "create-user-docs" "integrate-docs")

VALID_TOOLS=("Read" "Write" "Edit" "MultiEdit" "Bash" "Grep" "Glob" "LSP")
```

The `REQUIRED_AGENTS` array has 10 entries. Two agents (`challenge-assumptions` and `research-context`) exist in the agents directory but are not in the required list. The deleted `explore-patterns` has been removed from all validation paths.

## Integration Contracts

### pattern-example.md

The file `.claude/.csf/research/pattern-example.md` is the handoff artifact between Step 1 (Explore) and Step 2 (implement-minimal). Its content is free-form markdown describing codebase patterns discovered during exploration. No fixed schema is enforced; the contract is the file path and the expectation that it contains pattern descriptions relevant to the current specification.

Referenced in:
- `framework/commands/implement.md` (producer, Step 1)
- `framework/agents/implement-minimal.md` (consumer)

To change the output path or format, update both files.

## Setup

### Prerequisites

- Claude Code CLI with subagent support (the `Agent` tool must support `subagent_type="Explore"`)
- For LSP benefits in `analyze-implementation`: a language server configured for the target project's language(s). This is optional; the agent works without it.

### Configuration: .gitignore

The `.gitignore` includes two entries that prevent CSF artifacts from being committed:

```gitignore
.csf/
.claude/.csf/
```

The first covers the legacy layout (`.csf/` at project root). The second covers the current layout (`.claude/.csf/`). Both are present for backward compatibility during migration.

### Version

The framework version is `0.23.0`, stored in `framework/VERSION`.

## Extension Points

### Adding a new agent

1. Create a markdown file in `framework/agents/` with YAML frontmatter:
   ```yaml
   ---
   name: your-agent-name
   description: What it does
   tools: Read, Grep, Glob
   ---
   ```
2. Add the agent name to `REQUIRED_AGENTS` in `framework/validate-framework.sh` if it should be validated.
3. Reference the agent from the appropriate command file in `framework/commands/`.
4. Update agent counts in `CLAUDE.md` and `README.md`.
5. Run `bash framework/validate-framework.sh` to confirm.

Tools must be drawn from the `VALID_TOOLS` list: `Read`, `Write`, `Edit`, `MultiEdit`, `Bash`, `Grep`, `Glob`, `LSP`.

### Replacing an agent with a built-in subagent

Follow the pattern established by the `explore-patterns` removal:

1. Identify the custom agent whose work overlaps with a Claude Code built-in capability.
2. In the command file that delegates to that agent, replace the agent delegation with an inline `Agent` tool call specifying the appropriate `subagent_type`.
3. Preserve the output file path so downstream agents continue to find the expected artifact.
4. Delete the agent file from `framework/agents/`.
5. Remove the agent from `REQUIRED_AGENTS` in `validate-framework.sh`.
6. Update agent counts in `CLAUDE.md` and `README.md`.
7. Update or remove any tests that reference the deleted agent.

### Adding tools to an agent

Add the tool name to the `tools:` line in the agent's YAML frontmatter. The tool must exist in the `VALID_TOOLS` array in `validate-framework.sh`. If introducing a new tool type, add it to `VALID_TOOLS` first.

## Cross-References

- [User Guide](user/guide.md) -- usage-oriented documentation for framework users
- [CLAUDE.md](../CLAUDE.md) -- framework rules and development guidelines
- [CHANGELOG.md](../CHANGELOG.md) -- version history
