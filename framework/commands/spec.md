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

## Execution

After clarification (if needed), run micro-agents:

**Batch 1 (Parallel):**
- Task: define-scope with requirements: $ARGUMENTS
- Task: create-criteria with requirements: $ARGUMENTS  
- Task: identify-risks with requirements: $ARGUMENTS

**Batch 2:**
- Task: synthesize-spec to combine all research

Output: `.csf/spec.md`