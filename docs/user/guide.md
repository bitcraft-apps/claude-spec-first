# User Guide: Claude Spec-First Framework

## Getting Started

Clone and use as a Claude Code plugin. No configuration needed.

Then use the three commands:

1. `/csf:spec Add user authentication` — creates a specification
2. `/csf:implement` — builds it following codebase patterns
3. `/csf:document` — generates docs proportional to the change

## Common Tasks

### Specifying what to build

`/csf:spec [your requirements]` — agents will challenge vague requirements and produce a minimal spec at `.claude/.csf/spec.md`.

### Implementing from a spec

`/csf:implement` reads the spec and your codebase patterns, then writes the smallest working code. You can also pass a path: `/csf:implement ./my-spec.md`.

### Generating documentation

`/csf:document` analyzes what was built and updates existing docs. Small changes get small docs (or none). No configuration or flags needed.

### Keeping artifacts out of git

`.claude/.csf/` is gitignored automatically. If you previously committed files from it: `git rm -r --cached .claude/.csf/` and commit.

## Troubleshooting

### An agent produced incomplete output

Re-run the command — agents may take a different path. If it persists, break the task into smaller pieces.

## Cross-References

- [Technical Reference](../technical-reference.md) — contracts and setup
- [README](../../README.md) — installation
- [CHANGELOG](../../CHANGELOG.md) — version history
