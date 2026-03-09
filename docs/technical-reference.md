# Technical Reference: Claude Spec-First Framework

<!-- Generated: 2026-03-09 | Source: PR #109 (Route lightweight agents to Haiku) | Framework version: 0.23.0 -->

## Overview

The Claude Spec-First (CSF) framework provides a minimalist development workflow built on YAGNI, KISS, and SRP principles. It consists of 3 commands that orchestrate 12 specialized agents.

As of v0.23.0, the framework delegates pattern discovery to Claude Code's built-in Explore subagent and supports LSP-based semantic navigation in the `analyze-implementation` agent. The net effect is tighter alignment with built-in capabilities and less custom code to maintain.

PR #109 introduces two-tier model routing: 7 lightweight research agents are routed to Haiku (cheaper, faster), while 5 synthesis and implementation agents continue using the caller's default model for full capability.

Architecture:

```
3 commands  -->  12 agents
                   |
          +--------+--------+
          |                 |
  7 Haiku agents     5 default-model agents
  (research/analysis)  (synthesis/implementation)
          |                 |
          v                 v
   .claude/.csf/research/   (gitignored runtime output)
```

## API Reference

### Commands

#### `/csf:spec [REQUIREMENTS]`

Creates specifications through parallel analysis.

| Agent | Model | Responsibility |
|-------|-------|---------------|
| manage-spec-directory | Haiku | Ensure `.claude/.csf/` exists |
| define-scope | Haiku | Define what to build |
| create-criteria | Haiku | Define acceptance criteria |
| identify-risks | Haiku | Identify risks and unknowns |
| synthesize-spec | Default | Merge agent outputs into `spec.md` |

Output: `.claude/.csf/spec.md`

#### `/csf:implement [SPECIFICATION_OR_PATH]`

Orchestrates implementation in two sequential steps:

| Step | Mechanism | Output |
|------|-----------|--------|
| 1: Learn | `Agent` tool with `subagent_type="Explore"`, medium thoroughness | `.claude/.csf/research/pattern-example.md` |
| 2: Implement | Delegates to `implement-minimal` agent (default model) | Working code + `.claude/.csf/implementation-summary.md` |

Input resolution order:
1. `$ARGUMENTS` if provided (path or inline spec)
2. `.claude/.csf/spec.md` if it exists
3. Interactive prompt

Error recovery: when exploration finds no patterns, `implement-minimal` creates a basic file structure following language conventions and notes "No existing patterns found - used minimal approach" in the summary.

#### `/csf:document [SPEC_PATH] [IMPLEMENTATION_PATH]`

Generates documentation through comprehensive analysis.

| Agent | Model | Responsibility |
|-------|-------|---------------|
| analyze-artifacts | Haiku | Examine spec and implementation artifacts |
| analyze-implementation | Haiku | Analyze code structure (supports LSP) |
| analyze-existing-docs | Haiku | Scan project for existing documentation |
| create-technical-docs | Default | Generate technical documentation |
| create-user-docs | Default | Generate user-facing documentation |
| integrate-docs | Default | Merge and deduplicate documentation |

Output: Documentation in `docs/` and `docs/user/`

### Agents

#### Frontmatter Schema

Every agent file in `framework/agents/` uses YAML frontmatter with these fields:

```yaml
---
name: <agent-name>           # required, kebab-case identifier
description: <one-liner>     # required, human-readable purpose
tools: <comma-separated>     # required, tool access list
model: haiku                 # optional, routes to Haiku; omit for default model
---
```

The `model` field accepts `haiku` as its only defined value. When omitted, the agent inherits the caller's model (typically Sonnet or Opus).

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

#### implement-minimal

```yaml
name: implement-minimal
description: Write simplest working code
tools: Read, Write, Edit, MultiEdit, Bash
```

- Inputs: `.claude/.csf/spec.md` (or specified path) and `.claude/.csf/research/pattern-example.md`
- Output: working code + `.claude/.csf/implementation-summary.md`
- No `model` field -- runs on the caller's default model for full synthesis capability

### Model Routing

PR #109 introduces a two-tier model routing strategy using the `model:` frontmatter field. The field is optional; when present with value `haiku`, the agent runs on the Haiku model instead of inheriting the caller's model.

#### Tier 1: Haiku (research and analysis)

These 7 agents produce intermediate inputs consumed by downstream synthesis agents. Their tasks are constrained: file reading, glob scanning, text extraction, and directory management.

| Agent | Tools | Purpose |
|-------|-------|---------|
| `define-scope` | Write | Define MVP boundaries from requirements |
| `create-criteria` | Write | Generate minimal acceptance criteria |
| `identify-risks` | Write | Find essential risks and blockers |
| `analyze-artifacts` | Read | Parse CSF development artifacts |
| `analyze-implementation` | Read, Grep, Glob, LSP | Analyze codebase structure and patterns |
| `analyze-existing-docs` | Read, Glob | Scan project for existing documentation |
| `manage-spec-directory` | Bash | Setup/manage `.claude/.csf/` directories |

#### Tier 2: Default model (synthesis and implementation)

These 5 agents produce final user-facing deliverables. They consume Tier 1 outputs and require the stronger model for judgment, synthesis, and code generation.

| Agent | Tools | Purpose |
|-------|-------|---------|
| `synthesize-spec` | Read, Write | Combine research into final specification |
| `implement-minimal` | Read, Write, Edit, MultiEdit, Bash | Write simplest working code |
| `create-technical-docs` | Read, Write | Generate developer documentation |
| `create-user-docs` | Read, Write | Generate user-facing documentation |
| `integrate-docs` | Read, Write, Edit, MultiEdit, Glob | Combine and organize final documentation |

#### Rationale

The split aligns with the orchestration flow: every parallel fan-out batch runs entirely on Haiku (cheaper), while fan-in synthesis steps use the default model (stronger). Research agents produce structured intermediate markdown that does not require high creativity. Synthesis agents combine those inputs into polished specs, code, and documentation where output quality matters directly.

#### Orchestration flow by model tier

**`/csf:spec`:**
1. Pre-execution: `manage-spec-directory` [Haiku]
2. Batch 1 (parallel): `define-scope` + `create-criteria` + `identify-risks` [Haiku]
3. Batch 2: `synthesize-spec` [default]

**`/csf:document`:**
1. Batch 1 (parallel): `analyze-artifacts` + `analyze-implementation` + `analyze-existing-docs` [Haiku]
2. Batch 2 (parallel): `create-technical-docs` + `create-user-docs` [default]
3. Batch 3: `integrate-docs` [default]

**`/csf:implement`:**
1. Explore subagent for pattern learning
2. `implement-minimal` [default]

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
- Haiku model access is needed for the 7 research agents. If unavailable, those agents may fail at runtime.

### Configuration: .gitignore

The `.gitignore` includes two entries that prevent CSF artifacts from being committed:

```gitignore
.csf/
.claude/.csf/
```

The first covers the legacy layout (`.csf/` at project root). The second covers the current layout (`.claude/.csf/`). Both are present for backward compatibility during migration.

### Version

The framework version is `0.23.0`, stored in `framework/VERSION`.

## Usage Examples

Agent files are self-documenting. Each file in `framework/agents/` contains its complete prompt, input/output contracts, and behavioral rules. Refer to the agent files directly for working examples of:

- Frontmatter with `model: haiku`: any Tier 1 agent (e.g., `framework/agents/define-scope.md`)
- Frontmatter without `model` field: any Tier 2 agent (e.g., `framework/agents/synthesize-spec.md`)
- Command orchestration with model tiers: `framework/commands/spec.md`, `framework/commands/document.md`

Typical workflow:

```bash
# 1. Specify what to build (Haiku agents gather research, default model synthesizes)
/csf:spec "Add rate limiting to the API endpoint"

# 2. Implement the spec (Explore subagent + default model writes code)
/csf:implement

# 3. Document what was built (Haiku agents analyze, default model writes docs)
/csf:document
```

## Extension Points

### Adding a new agent

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
3. Add the agent name to `REQUIRED_AGENTS` in `framework/validate-framework.sh` if it should be validated.
4. Reference the agent from the appropriate command file in `framework/commands/`.
5. Update agent counts in `CLAUDE.md` and `README.md`.
6. Run `bash framework/validate-framework.sh` to confirm.

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
