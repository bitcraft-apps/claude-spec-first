# User Guide: Claude Spec-First Framework

<!-- Generated: 2026-03-10 | Updated: 2026-03-10 (PR #110 maxTurns) | Framework version: 0.25.0 -->

## What Changed in v0.25.0

Every agent in the framework now has a built-in turn limit (called `maxTurns`). A "turn" is one round of work an agent performs -- reading a file, writing output, or making a decision. Turn limits prevent any agent from running indefinitely if it gets stuck or enters a loop.

This is a safety net, not a restriction. Under normal use, agents finish well within their limits. The limits exist to catch edge cases where an agent might otherwise spin without producing useful results.

Each agent's limit is sized to match its job:

- **Simple tasks** (like setting up directories) get 3 turns -- they need very few steps.
- **Research tasks** (like analyzing code or scanning for risks) get 6 turns.
- **Deep analysis** (like exploring a codebase for patterns) gets 10 turns.
- **Writing tasks** (like generating documentation or synthesizing a spec) get 12-15 turns.
- **Implementation** (writing and editing code) gets 25 turns -- the most complex work.

There is nothing to configure. Turn limits are built into the framework and apply automatically. No new flags, environment variables, or settings are needed. If you are already using Claude Spec-First, update to the latest version and the limits take effect immediately.

If an agent reaches its turn limit, it stops and returns whatever progress it has made. The command orchestrator continues with the next step. In practice, the limits are generous enough that this rarely happens. If you work with an unusually large codebase and see incomplete output, breaking the task into smaller pieces is the most effective approach -- which aligns with the framework's core philosophy of delivering the narrowest viable change.

For technical details on the tiered scheme, see the [Technical Reference](../technical-reference.md#tiered-maxturns-scheme).

## What Changed in v0.23.0

Version 0.23.0 makes the framework smaller and smarter by removing a custom agent and replacing it with capabilities that Claude Code already provides natively.

Two changes matter to you as a framework user:

1. **Pattern discovery now uses Claude Code's built-in Explore subagent.** The old `explore-patterns` agent has been removed. When you run `/csf:implement`, Step 1 ("Learn the codebase") now delegates to the Explore subagent that ships with Claude Code. The output still lands in `.claude/.csf/research/pattern-example.md`, so nothing downstream changes.

2. **Code analysis is richer with LSP support.** The `analyze-implementation` agent (used during `/csf:document`) can now use LSP-based navigation -- go-to-definition, find-references, hover for type info -- when your environment supports it. If LSP is not available, it falls back to the same Grep and Glob tools it used before.

The framework drops from 13 agents to 12. The net effect is fewer lines of configuration with no change in what you can do.

## Getting Started

There is nothing special to do. If you are already using the framework, these changes take effect automatically after you update to v0.23.0.

**To update:**

1. Pull the latest version of the framework. The method depends on whether you run in installed mode (from `~/.claude/`) or repository mode (from a local git clone). See the [project README](../../README.md) for install instructions.
2. Confirm the version by checking `framework/VERSION`. It should read `0.23.0`.

**To verify things are working:**

1. Run `/csf:implement` on any task. Step 1 should produce a `.claude/.csf/research/pattern-example.md` file, just as before.
2. Run `/csf:document`. The `analyze-implementation` agent will use LSP tools if your editor or environment provides them.

No configuration flags, environment variables, or migration steps are required. Research agents now run on Haiku automatically for faster, cheaper execution -- synthesis and implementation agents still use your current model.

## Common Tasks

### Running the implementation workflow

The `/csf:implement` command works the same as before. The only difference is internal: Step 1 now calls the Explore subagent instead of a custom agent.

1. Run `/csf:implement` with your task description or a path to a spec file.
2. The framework explores your codebase for relevant patterns (Step 1).
3. It generates implementation based on those patterns (Step 2).
4. Output files appear in their usual locations.

You do not need to invoke the Explore subagent yourself. The command handles it.

### Taking advantage of LSP-enhanced analysis

When you run `/csf:document`, the `analyze-implementation` agent automatically uses LSP if available. This means it can follow function definitions, trace references across files, and understand type relationships -- producing more accurate documentation.

To get the most out of this:

- Use the framework in an environment where LSP is running (most modern editors and Claude Code itself provide this).
- No flags or settings are needed. The agent tries LSP first and falls back to text-based search if LSP is unavailable.

### Keeping CSF artifacts out of version control

Version 0.23.0 adds `.claude/.csf/` to the project's `.gitignore`. This prevents research artifacts (pattern examples, analysis summaries, spec files) from being committed to your repository.

If you previously committed files from `.claude/.csf/`, you may want to remove them from tracking:

1. Run `git rm -r --cached .claude/.csf/` to untrack the directory.
2. Commit the change.

Going forward, new artifacts are ignored automatically.

## Troubleshooting

### An agent seems to have produced incomplete output

The agent likely reached its turn limit. This is most common with large codebases or highly complex tasks. Re-run the command -- agents may take a different path on the second attempt and finish within the limit. If the issue persists, break the task into smaller pieces. For example, implement one feature at a time rather than several at once.

### I want to change the turn limits

Turn limits are set in the framework's command files and are not user-configurable through flags or settings. They are tuned to balance safety against practical needs. If you consistently find a specific agent hitting its limit, that is worth reporting as a framework issue. For one-off adjustments, see the [Technical Reference](../technical-reference.md#no-maxturns-configuration-needed) for instructions on editing values directly in the command files.

### Pattern discovery produces different output than before

The Explore subagent may structure its findings slightly differently from the old `explore-patterns` agent. The output file (`.claude/.csf/research/pattern-example.md`) still serves the same purpose and feeds into the same downstream agent (`implement-minimal`). If the output looks different but the implementation step succeeds, everything is working correctly.

### LSP tools are not being used during documentation

LSP availability depends on your environment. If you are running the framework in a context where no language server is active, the `analyze-implementation` agent falls back to Grep and Glob. This is expected behavior, not an error. The analysis still works -- it just cannot follow definitions or references semantically.

### Old explore-patterns references in custom scripts

If you have custom scripts or tooling that references the `explore-patterns` agent by name, those references will break. The agent file no longer exists. Update any such references to remove the dependency -- the Explore subagent is invoked automatically by `/csf:implement` and does not need to be called directly.

## Terminology

| Term | Meaning |
|------|---------|
| Turn | One round of agent work -- a file read, a write, or a decision step |
| Turn limit (maxTurns) | The maximum number of turns an agent can take before it stops and returns its progress |
| Tiered limits | The scheme where agents get different turn limits based on task complexity (3 for simple ops, up to 25 for implementation) |
| Explore subagent | Claude Code's built-in subagent for codebase exploration, replacing the custom `explore-patterns` agent |
| LSP | Language Server Protocol; used for semantic code navigation (go-to-definition, find-references, hover) |
| Pattern discovery | Step 1 of `/csf:implement`, where the framework learns codebase patterns before generating code |
| Installed mode | Framework running from `~/.claude/` (as opposed to a cloned repo) |
| Repository mode | Framework running from a local git clone with `./framework/VERSION` present |
| Validation script | `framework/validate-framework.sh`, the dual-mode framework validator |

## Cross-References

- [Technical Reference](../technical-reference.md) -- API details, integration contracts, and extension points
- [README](../../README.md) -- installation and quick start
- [CHANGELOG](../../CHANGELOG.md) -- version history
