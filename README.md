# spec-first

Build faster by writing requirements before code. This Claude Code plugin enforces a three-step workflow: define what to build, implement it from the spec, and generate documentation — all from your terminal.

## Who is this for

Engineers and teams who want Claude Code to stop guessing and start building from clear requirements.

## Quick Start

Add the marketplace and install the plugin from your terminal:

```bash
claude plugin marketplace add bitcraft-apps/spec-first
claude plugin install sf@spec-first
```

Or from within Claude Code:

```
/plugin marketplace add bitcraft-apps/spec-first
/plugin install sf@spec-first
```

Write your first spec:

```
/sf:spec Add a rate limiter to the API gateway
```

```
Researching requirements...

  Batch 1 (parallel): define-scope, create-criteria, identify-risks
  Batch 2: synthesize-spec

Spec written to .claude/.sf/spec.md
```

Implement it:

```
/sf:implement
```

```
Step 1: Learning patterns from codebase...
  Found: src/middleware/auth.ts (similar middleware pattern)

Step 2: Implementing...
  Created: src/middleware/rate-limiter.ts
  Updated: src/middleware/index.ts
  Created: src/middleware/rate-limiter.test.ts

Implementation summary written to .claude/.sf/implementation-summary.md
```

Document it:

```
/sf:document
```

```
Batch 1 (parallel): analyze-artifacts, analyze-implementation, analyze-existing-docs
Batch 2 (parallel): create-technical-docs, create-user-docs
Batch 3: integrate-docs

Updated: docs/middleware.md (added rate limiter section)
```

## How it works

Each command orchestrates specialized agents that run in parallel where possible. The spec is the contract between define and implement — no spec, no code.

## Command Reference

| Command | Purpose |
|---------|---------|
| `/sf:spec [REQUIREMENTS]` | Define what to build and why |
| `/sf:implement [--isolate] [SPEC_OR_PATH]` | Build the minimal working solution |
| `/sf:document [PATHS]` | Generate docs proportional to the change |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
