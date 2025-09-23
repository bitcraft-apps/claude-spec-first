---
description: Create specifications through parallel analysis
---

# Spec Command

Creates specifications with intelligent clarification.

## Usage
```
/csf:spec [REQUIREMENTS]
```

---

## Clarification Check

If requirements are vague (< 15 words or unclear), ask for clarification:

**Questions to consider:**
- What specific problem are you solving?
- Who are the users?
- What's the desired outcome?
- Any technical constraints?
- What's the minimal viable version?

If unclear, prompt: "Your requirements seem brief. Could you provide more context about [specific unclear aspect]?"

## Directory Management

**Path Resolution:**
```bash
# Use centralized path utility
source "$(dirname "$0")/../utils/csf-paths.sh"
CSF_DIR="$(get_csf_dir)"
mkdir -p "$CSF_DIR"
```

**Command-level logic** (Claude Code handles user interaction):

```
If $CSF_DIR/spec.md exists:
    Prompt: "Existing spec found. Update (u) or Create new (n)?"
    If user chooses 'u': Write "update" to $CSF_DIR/mode
    If user chooses 'n': Write "new" to $CSF_DIR/mode
Else:
    Write "first" to $CSF_DIR/mode
```

## Execution

After directory setup and clarification (if needed), run micro-agents:

**Pre-execution:**
- Task: manage-spec-directory (reads mode from $CSF_DIR/mode file)

**Batch 1 (Parallel):**
- Task: define-scope with requirements: $ARGUMENTS
- Task: create-criteria with requirements: $ARGUMENTS
- Task: identify-risks with requirements: $ARGUMENTS

**Batch 2:**
- Task: synthesize-spec to combine all research

Output: `$CSF_DIR/spec.md` (direct file or symlink to timestamped spec)

## Error Recovery

If any micro-agent fails:
1. Claude Code shows the specific error
2. Fix the issue (usually unclear requirements)
3. Re-run /csf:spec with clearer input
4. No partial state - each run starts fresh