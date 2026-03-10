# Technical Reference: Claude Spec-First Framework

<!-- Generated: 2026-03-10 | Updated: 2026-03-10 (PR #110 maxTurns) | Framework version: 0.25.0 -->

## Overview

The Claude Spec-First (CSF) framework provides a minimalist development workflow built on YAGNI, KISS, and SRP principles. It consists of 3 commands that orchestrate 13 agent invocations (12 named agents plus 1 built-in Explore subagent).

As of v0.23.0, the framework delegates pattern discovery to Claude Code's built-in Explore subagent and supports LSP-based semantic navigation in the `analyze-implementation` agent. PR #109 introduced two-tier model routing: 7 lightweight research agents run on Haiku, while 5 synthesis and implementation agents use the caller's default model. PR #110 adds explicit `maxTurns` limits to all 13 agent invocations, preventing runaway agents without affecting normal operation.

Architecture:

```
3 commands  -->  13 agent invocations
                   |
          +--------+--------+
          |                 |
  7 Haiku agents     5 default-model agents + Explore subagent
  (research/analysis)  (synthesis/implementation)
          |                 |
          v                 v
   .claude/.csf/research/   (gitignored runtime output)
```

### Key design decisions (maxTurns)

- **Inline parameters, no abstractions.** Each `maxTurns` value lives directly on its task line in the command files. No config file, no shared constants, no indirection. This follows KISS and YAGNI.
- **Tiered by task complexity.** A six-tier scheme maps agent responsibility to turn budget. Simple file operations get 3 turns; full code implementation gets 25.
- **Conservative but not restrictive.** Values are high enough that normal operation never hits the cap, but low enough to catch degenerate behavior quickly.

### Tiered maxTurns scheme

| Tier | maxTurns | Agent count | Rationale |
|------|----------|-------------|-----------|
| Lightweight | 3 | 1 | Deterministic directory setup, no iteration needed |
| Research | 6 | 5 | File reading and structured extraction with bounded scope |
| Deep analysis | 10 | 2 | Codebase exploration that may require multiple search passes |
| Synthesis | 12 | 1 | Combines multiple research inputs, needs iteration room |
| Generation | 15 | 3 | Produces final documents through writing and revision cycles |
| Implementation | 25 | 1 | Code writing with the most complex edit-test-revise loops |

## API Reference

### Commands

#### `/csf:spec [REQUIREMENTS]`

Creates specifications through parallel analysis.

| Agent | Model | maxTurns | Tier | Responsibility |
|-------|-------|----------|------|---------------|
| manage-spec-directory | Haiku | 3 | Lightweight | Ensure `.claude/.csf/` exists |
| define-scope | Haiku | 6 | Research | Define what to build |
| create-criteria | Haiku | 6 | Research | Define acceptance criteria |
| identify-risks | Haiku | 6 | Research | Identify risks and unknowns |
| synthesize-spec | Default | 12 | Synthesis | Merge agent outputs into `spec.md` |

Output: `.claude/.csf/spec.md`

#### `/csf:implement [SPECIFICATION_OR_PATH]`

Orchestrates implementation in two sequential steps:

| Step | Mechanism | maxTurns | Tier | Output |
|------|-----------|----------|------|--------|
| 1: Learn | `Agent` tool with `subagent_type="Explore"` | 10 | Deep analysis | `.claude/.csf/research/pattern-example.md` |
| 2: Implement | `implement-minimal` agent (default model) | 25 | Implementation | Working code + `.claude/.csf/implementation-summary.md` |

Input resolution order:
1. `$ARGUMENTS` if provided (path or inline spec)
2. `.claude/.csf/spec.md` if it exists
3. Interactive prompt

Error recovery: when exploration finds no patterns, `implement-minimal` creates a basic file structure following language conventions and notes "No existing patterns found - used minimal approach" in the summary.

#### `/csf:document [SPEC_PATH] [IMPLEMENTATION_PATH]`

Generates documentation through comprehensive analysis.

| Agent | Model | maxTurns | Tier | Responsibility |
|-------|-------|----------|------|---------------|
| analyze-artifacts | Haiku | 6 | Research | Examine spec and implementation artifacts |
| analyze-implementation | Haiku | 10 | Deep analysis | Analyze code structure (supports LSP) |
| analyze-existing-docs | Haiku | 6 | Research | Scan project for existing documentation |
| create-technical-docs | Default | 15 | Generation | Generate technical documentation |
| create-user-docs | Default | 15 | Generation | Generate user-facing documentation |
| integrate-docs | Default | 15 | Generation | Merge and deduplicate documentation |

Output: Documentation in `docs/` and `docs/user/`

### Agents

Frontmatter fields: `name` (required), `description` (required), `tools` (required), `model` (optional -- only valid value is `haiku`). When `model` is omitted, the agent inherits the caller's model. The `maxTurns` parameter is not part of the agent frontmatter; it is specified in the command files that invoke the agent.

### maxTurns parameter syntax

Two syntax forms are used depending on invocation style:

**Task invocations** (named agents defined in `framework/agents/`):
```
Task: <agent-name> (maxTurns: N)
```

**Agent tool invocations** (built-in Claude Code agent types like Explore):
```
Use Agent tool with subagent_type="Explore", maxTurns=N
```

The parameter is an integer that caps the total number of turns (tool calls + responses) the agent can perform. When an agent reaches its limit, it stops and returns whatever output it has produced so far.

### Behavior at the limit

- The agent stops and returns its current output (partial or complete).
- No error is raised to the orchestrator unless the output fails a downstream gate check.
- Parallel siblings are unaffected; they continue independently.

#### analyze-implementation

```yaml
name: analyze-implementation
description: Analyze actual implementation files and code structure
tools: Read, Grep, Glob, LSP
model: haiku
```

- Input: implementation paths from arguments or artifact references
- Output: `.claude/.csf/research/implementation-summary.md`
- Responsibilities: find main implementation files, identify key APIs/functions/patterns, note file organization, extract usage examples from code and tests
- LSP is optional; the agent falls back to Read, Grep, and Glob when LSP is unavailable
- maxTurns: 10 (Deep analysis tier)

#### implement-minimal

```yaml
name: implement-minimal
description: Write simplest working code
tools: Read, Write, Edit, MultiEdit, Bash
```

- Inputs: `.claude/.csf/spec.md` (or specified path) and `.claude/.csf/research/pattern-example.md`
- Output: working code + `.claude/.csf/implementation-summary.md`
- No `model` field -- runs on the caller's default model for full synthesis capability
- maxTurns: 25 (Implementation tier)

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

- Claude Code CLI with subagent support (the `Agent` tool must support `subagent_type="Explore"` and the `maxTurns` parameter)
- For LSP benefits in `analyze-implementation`: a language server configured for the target project's language(s). This is optional; the agent works without it.
- Haiku model access is needed for the 7 research agents. If unavailable, those agents may fail at runtime.

### No maxTurns configuration needed

The `maxTurns` values are embedded directly in the command files (`framework/commands/spec.md`, `implement.md`, `document.md`). There are no environment variables, configuration files, or CLI flags. The values take effect automatically when commands are invoked.

### Configuration: .gitignore

The `.gitignore` includes two entries that prevent CSF artifacts from being committed:

```gitignore
.csf/
.claude/.csf/
```

The first covers the legacy layout (`.csf/` at project root). The second covers the current layout (`.claude/.csf/`). Both are present for backward compatibility during migration.

### Version

The framework version is `0.25.0`, stored in `framework/VERSION`.

## Extension Points

### Choosing maxTurns for a new agent

When adding a new agent, assign its `maxTurns` by mapping it to the closest existing tier:

1. **Match the task to a tier:**
   - Reads a file and writes structured output -- Research (6)
   - Explores the codebase with search tools -- Deep analysis (10)
   - Combines multiple inputs into a deliverable -- Synthesis (12)
   - Produces a final user-facing document -- Generation (15)
   - Writes or modifies code files -- Implementation (25)
   - Performs a single deterministic operation -- Lightweight (3)

2. **Start with the tier default.** Run the agent several times on representative inputs. If it consistently finishes well under the limit, the value is correct. If it occasionally hits the cap and produces truncated output, raise the value or consider whether the agent's scope is too broad.

3. **Prefer existing tier values.** The tiers use 3, 6, 10, 12, 15, and 25. A value like 8 is acceptable if an agent genuinely falls between Research and Deep analysis, but avoid inventing a new tier for every agent.

### Adding a new agent (full checklist)

1. Create a markdown file in `framework/agents/` with YAML frontmatter:
   ```yaml
   ---
   name: your-agent-name
   description: What it does
   tools: Read, Grep, Glob
   model: haiku              # optional -- add for research/analysis agents
   ---
   ```
2. Decide the model tier: if the agent performs constrained research or analysis and its output feeds a downstream synthesis agent, add `model: haiku`. If it produces final deliverables or requires complex judgment, omit the `model` field.
3. Add the agent invocation to the appropriate command file in `framework/commands/` with a `maxTurns` value from the tiered scheme.
4. Add the agent name to `REQUIRED_AGENTS` in `framework/validate-framework.sh` if it should be validated.
5. Update agent counts in `CLAUDE.md` and `README.md`.
6. Run `bash framework/validate-framework.sh` to confirm.

Tools must be drawn from the `VALID_TOOLS` list: `Read`, `Write`, `Edit`, `MultiEdit`, `Bash`, `Grep`, `Glob`, `LSP`.

### Replacing an agent with a built-in subagent

Follow the pattern established by the `explore-patterns` removal:

1. Identify the custom agent whose work overlaps with a Claude Code built-in capability.
2. In the command file that delegates to that agent, replace the agent delegation with an inline `Agent` tool call specifying the appropriate `subagent_type` and a `maxTurns` value from the relevant tier.
3. Preserve the output file path so downstream agents continue to find the expected artifact.
4. Delete the agent file from `framework/agents/`.
5. Remove the agent from `REQUIRED_AGENTS` in `validate-framework.sh`.
6. Update agent counts in `CLAUDE.md` and `README.md`.
7. Update or remove any tests that reference the deleted agent.

### Adding tools to an agent

Add the tool name to the `tools:` line in the agent's YAML frontmatter. The tool must exist in the `VALID_TOOLS` array in `validate-framework.sh`. If introducing a new tool type, add it to `VALID_TOOLS` first.

### Adding a new maxTurns tier

If a new category of agent genuinely does not fit existing tiers, add it to the tiered scheme table in the Overview section and use the value consistently across all agents in that category. The framework has no enforcement mechanism for tier consistency -- it is a convention maintained by contributors.

### Modifying an existing tier's default

The `maxTurns` values are not centralized. To change a tier's default (for example, raising all Research agents from 6 to 8), update every agent invocation in that tier across all three command files. Search for `(maxTurns: 6)` to find all Research-tier task invocations. The Explore agent uses `maxTurns=10` syntax (no parentheses), so search for both patterns.

### Interaction between maxTurns and model routing

The `maxTurns` parameter is independent of model routing. An agent routed to Haiku with `model: haiku` in its frontmatter uses the same `maxTurns` budget as one running on the default model. The two features compose without conflict: model routing controls which model runs the agent, `maxTurns` controls how long it runs.

## Cross-References

- [User Guide](user/guide.md) -- usage-oriented documentation for framework users
- [CLAUDE.md](../CLAUDE.md) -- framework rules and development guidelines
- [CHANGELOG.md](../CHANGELOG.md) -- version history
