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

Check for existing specifications:

**First run**: Create standard `.csf/spec.md` and `.csf/research/`

**Subsequent runs**: Prompt user with options:
- "u" → Update existing (backup current, overwrite)
- "n" → Create new timestamped directory

Maintain backward compatibility with symlinks.

## Execution

After directory setup and clarification (if needed), run micro-agents:

**Batch 1 (Parallel):**
- Task: define-scope with requirements: $ARGUMENTS
- Task: create-criteria with requirements: $ARGUMENTS  
- Task: identify-risks with requirements: $ARGUMENTS

**Batch 2:**
- Task: manage-spec-directory to setup isolated directories
- Task: synthesize-spec to combine all research

Output: Active spec in `.csf/spec.md` (symlink to current spec)

## Error Recovery

If any micro-agent fails:
1. Claude Code shows the specific error
2. Fix the issue (usually unclear requirements)
3. Re-run /csf:spec with clearer input
4. No partial state - each run starts fresh