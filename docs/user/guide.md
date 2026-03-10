# User Guide: Claude Spec-First Framework

<!-- Generated: 2026-03-10 | Framework version: 0.23.0 -->

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

### Pattern discovery produces different output than before

The Explore subagent may structure its findings slightly differently from the old `explore-patterns` agent. The output file (`.claude/.csf/research/pattern-example.md`) still serves the same purpose and feeds into the same downstream agent (`implement-minimal`). If the output looks different but the implementation step succeeds, everything is working correctly.

### LSP tools are not being used during documentation

LSP availability depends on your environment. If you are running the framework in a context where no language server is active, the `analyze-implementation` agent falls back to Grep and Glob. This is expected behavior, not an error. The analysis still works -- it just cannot follow definitions or references semantically.

### Old explore-patterns references in custom scripts

If you have custom scripts or tooling that references the `explore-patterns` agent by name, those references will break. The agent file no longer exists. Update any such references to remove the dependency -- the Explore subagent is invoked automatically by `/csf:implement` and does not need to be called directly.

## Terminology

| Term | Meaning |
|------|---------|
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
