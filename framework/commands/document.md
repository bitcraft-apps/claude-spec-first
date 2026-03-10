---
description: Generate minimal documentation through parallel agents
---

# Document Command

Creates minimal, proportional documentation. Match doc weight to change weight.

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
- Task: analyze-artifacts (maxTurns: 6) with requirements: $ARTIFACT_PATHS
- Task: analyze-implementation (maxTurns: 10) with requirements: $IMPLEMENTATION_PATHS
- Task: analyze-existing-docs (maxTurns: 6) (scans project for existing documentation inventory)

**Gate 1 — Post-Analysis:**
Check that each output file exists and is non-empty:
- `$CSF_DIR/research/artifacts-summary.md`
- `$CSF_DIR/research/implementation-summary.md`
- `$CSF_DIR/research/docs-inventory.md`

If any file is missing or empty: halt pipeline, report which file(s) failed, preserve existing output for inspection. Write gate results to `$CSF_DIR/research/gate-analysis.md` (pass/fail per file, warnings for files under 5 lines).

**Batch 2 (Parallel):**
- Task: create-technical-docs (maxTurns: 15) (reads $CSF_DIR/research/artifacts-summary.md, $CSF_DIR/research/implementation-summary.md)
- Task: create-user-docs (maxTurns: 15) (reads $CSF_DIR/research/artifacts-summary.md, $CSF_DIR/research/implementation-summary.md)

**Gate 2 — Post-Generation:**
For each generated doc, verify:
1. File exists (empty is acceptable — means the change didn't warrant that doc type)
2. No placeholder patterns: `TODO`, `TBD`, `PLACEHOLDER`, `[INSERT` (case-insensitive)

Block on: placeholder-only content. Empty files are valid — they mean the agent correctly determined no docs were needed. Write gate results to `$CSF_DIR/research/gate-generation.md`.

**Batch 3:**
- Task: integrate-docs (maxTurns: 15) (reads docs-inventory.md to update existing files or create new ones)

**Gate 3 — Post-Integration:**
Verify integration completed. If no docs were updated or created, that's valid — report "no documentation changes needed" and finish cleanly. Write gate results to `$CSF_DIR/research/gate-integration.md`.

Output: Documentation updates (if any) + terminal summary

## Gate Failure Behavior
On any gate failure: halt immediately, do not proceed to the next batch. Report which gate failed and why. Preserve output for inspection.
