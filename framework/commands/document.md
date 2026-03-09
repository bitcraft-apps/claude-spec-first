---
description: Generate comprehensive documentation through parallel micro-agents
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

1. If paths provided: Use specified artifact/implementation locations
2. Else if `.claude/.csf/spec.md` and `.claude/.csf/implementation-summary.md` exist: Use them
3. Else: Ask user for artifact locations

## Execution

After input resolution, run micro-agents in 4 batches:

**Batch 1 (Parallel):**
- Task: analyze-artifacts with requirements: $ARTIFACT_PATHS
- Task: analyze-implementation with requirements: $IMPLEMENTATION_PATHS
- Task: analyze-existing-docs (scans project for existing documentation inventory)

**Batch 2 (Parallel):**
- Task: create-technical-docs (reads $CSF_DIR/research/artifacts-summary.md, $CSF_DIR/research/implementation-summary.md, $CSF_DIR/research/docs-inventory.md)
- Task: create-user-docs (reads $CSF_DIR/research/artifacts-summary.md, $CSF_DIR/research/implementation-summary.md, $CSF_DIR/research/docs-inventory.md)

**Batch 3:**
- Task: integrate-docs (reads docs-inventory.md to update existing files or create new ones)

**Batch 4:**
- Cleanup: Remove $CSF_DIR/research/docs-inventory.md

Output: Documentation in `docs/` and `docs/user/` + terminal summary

## Performance
- 20%+ speed improvement through parallel generation
- Specialized micro-agents for focused output quality