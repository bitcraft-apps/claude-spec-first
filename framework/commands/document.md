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

**Path Resolution:**
```bash
# Find project root (directory containing CLAUDE.md)
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ]; do
    if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
        break
    fi
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
CSF_DIR="$PROJECT_ROOT/.claude/.csf"
mkdir -p "$CSF_DIR"
```

1. If paths provided: Use specified artifact/implementation locations
2. Else if `$CSF_DIR/spec.md` and `$CSF_DIR/implementation-summary.md` exist: Use them
3. Else: Ask user for artifact locations

## Execution

After input resolution, run micro-agents in 3 batches:

**Batch 1 (Parallel):**
- Task: analyze-artifacts with requirements: $ARTIFACT_PATHS
- Task: analyze-implementation with requirements: $IMPLEMENTATION_PATHS

**Batch 2 (Parallel):**
- Task: create-technical-docs (reads $CSF_DIR/research/artifacts-summary.md, $CSF_DIR/research/implementation-summary.md)
- Task: create-user-docs (reads $CSF_DIR/research/artifacts-summary.md, $CSF_DIR/research/implementation-summary.md)

**Batch 3:**
- Task: integrate-docs to combine and organize final documentation

Output: Documentation in `docs/` and `docs/user/` + terminal summary

## Performance
- 20%+ speed improvement through parallel generation
- Specialized micro-agents for focused output quality