---
description: Generate comprehensive documentation through parallel agents
---

# Document Command

Creates documentation with parallel analysis and generation.

## Usage
```
/csf:document [SPECIFICATION_AND_IMPLEMENTATION_PATHS]
```

---

## Input Resolution

**Input Resolution:**

1. If $ARGUMENTS provided: Use as artifact/implementation paths
2. Else if `.claude/.csf/spec.md` and `.claude/.csf/implementation-summary.md` exist: Use them
3. Else: Ask user for artifact locations

## Execution

After input resolution, run agents in 3 batches:

**Batch 1 (Parallel):**
- Task: analyze-artifacts with requirements: $ARTIFACT_PATHS
- Task: analyze-implementation with requirements: $IMPLEMENTATION_PATHS
- Task: analyze-existing-docs (scans project for existing documentation inventory)

**Gate 1 — Post-Analysis:**
Check that each output file exists and is non-empty:
- `$CSF_DIR/research/artifacts-summary.md`
- `$CSF_DIR/research/implementation-summary.md`
- `$CSF_DIR/research/docs-inventory.md`

If any file is missing or empty: halt pipeline, report which file(s) failed, preserve existing output for inspection. Write gate results to `$CSF_DIR/research/gate-analysis.md` (pass/fail per file, warnings for files under 5 lines).

**Batch 2 (Parallel):**
- Task: create-technical-docs (reads $CSF_DIR/research/artifacts-summary.md, $CSF_DIR/research/implementation-summary.md)
- Task: create-user-docs (reads $CSF_DIR/research/artifacts-summary.md, $CSF_DIR/research/implementation-summary.md)

**Gate 2 — Post-Generation:**
For each generated doc, verify:
1. File exists and is non-empty
2. Contains required h2 sections per structure contracts:
   - `technical-docs.md`: `## Overview`, `## API Reference`, `## Setup`, `## Usage Examples`, `## Extension Points`
   - `user-docs.md`: `## What It Does`, `## Getting Started`, `## Common Tasks`, `## Troubleshooting`
3. No placeholder patterns: `TODO`, `TBD`, `PLACEHOLDER`, `[INSERT` (case-insensitive)

Block on: empty file, placeholder-only content. Warn on: missing required sections (agent contracts allow omission when genuinely not applicable), sparse output (under 10 lines per section). Write gate results to `$CSF_DIR/research/gate-generation.md`.

**Batch 3:**
- Task: integrate-docs (reads docs-inventory.md to update existing files or create new ones)

**Gate 3 — Post-Integration:**
Verify final output files exist and are non-empty in `docs/` and/or `docs/user/`. Block if no output files were created or all are empty. Write gate results to `$CSF_DIR/research/gate-integration.md`.

Output: Documentation in `docs/` and `docs/user/` + terminal summary (include any gate warnings)

## Gate Failure Behavior
On any gate failure: halt immediately, do not proceed to the next batch. Report which gate failed and the specific reason(s). Preserve all failed output for inspection — do not delete or overwrite it.

## Performance
- 20%+ speed improvement through parallel generation
- Specialized agents for focused output quality
