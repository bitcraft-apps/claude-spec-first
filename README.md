# spec-first

A Claude Code plugin that enforces a define-then-build workflow. You write requirements, it generates a spec, implements code from the spec, and writes documentation proportional to the change.

## Who is this for

Engineers and teams who want Claude Code to stop guessing and start building from clear requirements.

## Quick Start

### Install

```bash
claude plugin add bitcraft-apps/claude-spec-first
```

### 1. Define what to build

```
/sf:spec Add a rate limiter to the API gateway
```

```
Researching requirements...

  Batch 1 (parallel): define-scope, create-criteria, identify-risks
  Batch 2: synthesize-spec

Spec written to .claude/.sf/spec.md
```

### 2. Implement it

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

### 3. Document it

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

Each command orchestrates specialized agents that run in parallel where possible. Agents write intermediate output to `.claude/.sf/research/` (gitignored). The spec is the contract between define and implement -- no spec, no code.

See [AGENTS.md](AGENTS.md) for framework principles and constraints.

## Command Reference

| Command | Purpose |
|---------|---------|
| `/sf:spec [REQUIREMENTS]` | Define what to build and why |
| `/sf:implement [--isolate] [SPEC_OR_PATH]` | Build the minimal working solution |
| `/sf:document [PATHS]` | Generate docs proportional to the change |
