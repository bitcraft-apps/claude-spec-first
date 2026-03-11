---
name: spec
description: Create specifications through parallel analysis
disable-model-invocation: true
argument-hint: "[REQUIREMENTS]"
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

**Directory Management:**

Claude Code will use `.claude/.csf/` as the working directory.

**Command-level logic** (Claude Code handles user interaction):

```
If .claude/.csf/spec.md exists:
    Prompt: "Existing spec found. Update (u) or Create new (n)?"
    If user chooses 'u': Write "update" to .claude/.csf/mode
    If user chooses 'n': Write "new" to .claude/.csf/mode
Else:
    Write "first" to .claude/.csf/mode
```

## Execution

After directory setup and clarification (if needed), run agents:

**Pre-execution:**
- Task: manage-spec-directory (maxTurns: 3) (reads mode from $CSF_DIR/mode file)

**Batch 1 (Parallel):**
- Task: define-scope (maxTurns: 6) with requirements: $ARGUMENTS
- Task: create-criteria (maxTurns: 6) with requirements: $ARGUMENTS
- Task: identify-risks (maxTurns: 6) with requirements: $ARGUMENTS

**Batch 2:**
- Task: synthesize-spec (maxTurns: 12) to combine all research

Output: `$CSF_DIR/spec.md` (direct file or symlink to timestamped spec)

## Error Recovery

If any agent fails:
1. Claude Code shows the specific error
2. Fix the issue (usually unclear requirements)
3. Re-run /csf:spec with clearer input
4. No partial state - each run starts fresh
