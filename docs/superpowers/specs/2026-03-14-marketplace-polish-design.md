# Marketplace Polish — Targeted Readiness for Anthropic Submission

## Problem

Spec-first v1.0.0 is functionally complete but has a hard blocker (`claude plugin validate .` fails on marketplace.json schema) and missing metadata that weakens the marketplace listing. The plugin needs targeted polish before submission to Anthropic's official marketplace.

## Scope

Four changes, all scoped to marketplace readiness:

1. **Fix marketplace.json** — remove fields rejected by the official validator
2. **Enrich plugin.json** — add author, repository, homepage, license, keywords
3. **Add examples/** — one minimal example showing the 3-command workflow
4. **Validate** — confirm both official and project validation pass clean

### Out of Scope

- README changes
- CHANGELOG changes
- External tester recruitment
- Announcement strategy
- New features or refactoring

## Acceptance Criteria

- [ ] `claude plugin validate .` passes with zero errors
- [ ] `make validate` passes with zero failures
- [ ] marketplace.json contains only valid schema fields (name, owner, plugins)
- [ ] plugin.json includes author, repository, homepage, license, keywords
- [ ] `examples/rate-limiter/README.md` exists and demonstrates the spec > implement > document workflow
- [ ] All changes committed to main

## Changes

### 1. marketplace.json

Strip `title`, `tagline`, `description`, `categories` from root level. Keep `name`, `owner`, `plugins`.

```json
{
  "name": "spec-first",
  "owner": {
    "name": "bitcraft-apps"
  },
  "plugins": [
    {
      "name": "sf",
      "source": {
        "source": "github",
        "repo": "bitcraft-apps/spec-first"
      },
      "description": "Minimalist spec-first development workflow",
      "version": "1.0.0"
    }
  ]
}
```

### 2. plugin.json

Add metadata fields:

```json
{
  "name": "sf",
  "version": "1.0.0",
  "description": "Minimalist spec-first development workflow",
  "author": {
    "name": "Szymon Graczyk",
    "url": "https://github.com/bitcraft-apps"
  },
  "repository": "https://github.com/bitcraft-apps/spec-first",
  "homepage": "https://github.com/bitcraft-apps/spec-first",
  "license": "MIT",
  "keywords": ["spec-first", "workflow", "documentation", "development"]
}
```

### 3. examples/rate-limiter/README.md

Single file, under 50 lines. Walks through the 3-command flow with a concrete rate-limiter scenario:

1. `/sf:spec` — define the requirement
2. `/sf:implement` — generate the code
3. `/sf:document` — generate the docs

Shows commands and what to expect. No generated artifacts included.

### 4. Validation

Run both validators after changes:
- `claude plugin validate .` — zero errors
- `make validate` — zero failures

## Risks

- **Anthropic's review criteria are unpublished** — they may request additional changes. This spec addresses all known technical requirements; review feedback will drive further iteration.
- **marketplace.json field removal** — the stripped fields (title, tagline, etc.) are likely captured in the web submission form instead. If not, they can be re-added to plugin.json if the schema supports them there.
