---
description: Implement through pattern learning
---

# Implement Command

Creates minimal implementation following existing patterns.

## Usage
```
/csf:implement [SPECIFICATION_OR_PATH]
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

1. If path provided: Use specified file
2. Else if `$CSF_DIR/spec.md` exists: Use it
3. Else: Ask user for specification location

## Execution

After input resolution, run sequential micro-agents:

**Step 1: Learn**
- Task: explore-patterns with requirements: $SPECIFICATION

**Step 2: Implement**
- Task: implement-minimal with spec: $SPECIFICATION

Output: Implementation + `$CSF_DIR/implementation-summary.md`

## Philosophy

This command enforces:
- Pattern consistency over creativity
- Working code over perfect code
- Minimal solution over extensible solution

## Error Recovery

If exploration finds no patterns:
1. implement-minimal creates basic file structure following language conventions
2. Implements only the core requirement (no extras)
3. Uses standard naming patterns for the technology
4. Notes in summary: "No existing patterns found - used minimal approach"