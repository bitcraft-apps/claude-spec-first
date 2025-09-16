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

**Command-level logic** (Claude Code handles user interaction):

```
If $CLAUDE_DIR/.csf/spec.md exists:
    Prompt: "Existing spec found. Update (u) or Create new (n)?"
    If user chooses 'u': Write "update" to $CLAUDE_DIR/.csf/mode
    If user chooses 'n': Write "new" to $CLAUDE_DIR/.csf/mode
Else:
    Write "first" to $CLAUDE_DIR/.csf/mode
```

## Execution

After directory setup and clarification (if needed), run micro-agents:

**Pre-execution:**
- Task: manage-spec-directory (reads mode from $CLAUDE_DIR/.csf/mode file)

**Batch 1 (Parallel):**
- Task: define-scope with requirements: $ARGUMENTS
- Task: create-criteria with requirements: $ARGUMENTS
- Task: identify-risks with requirements: $ARGUMENTS

**Batch 2:**
- Task: synthesize-spec to combine all research

Output: `$CLAUDE_DIR/.csf/spec.md` (direct file or symlink to timestamped spec)

## Error Recovery

If any micro-agent fails:
1. Claude Code shows the specific error
2. Fix the issue (usually unclear requirements)
3. Re-run /csf:spec with clearer input
4. No partial state - each run starts fresh