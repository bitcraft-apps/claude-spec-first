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

**Input Resolution:**

1. If $ARGUMENTS provided: Use as specification path or inline requirements
2. Else if `.claude/.csf/spec.md` exists: Use it
3. Else: Ask user for specification location

## Execution

After input resolution, run sequential agents:

**Step 1: Learn**
- Use Agent tool with subagent_type="Explore" and thoroughness="medium" to find similar patterns in the codebase for: $SPECIFICATION
- Save findings to `.claude/.csf/research/pattern-example.md`

**Step 2: Implement**  
- Task: implement-minimal with spec: $SPECIFICATION

Output: Implementation + `.claude/.csf/implementation-summary.md`

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