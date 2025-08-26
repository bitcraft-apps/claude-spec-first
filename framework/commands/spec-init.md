---
description: Smart specification initialization - automatically routes to optimal workflow based on complexity
---

# Smart Specification Initialization

You are starting the specification-first development process for: **$ARGUMENTS**

## Automatic Workflow Routing

This command intelligently routes to the most appropriate workflow based on task complexity:

### Step 1: Quick Complexity Assessment (30 seconds)
Evaluate the task:
- **Estimated LOC**: How many lines of code will this require?
- **Clarity**: Are requirements obvious and well-understood?
- **Integration**: Does this affect multiple systems or components?

### Step 2: Automatic Routing
Based on assessment, automatically execute:

**For Simple Tasks (<100 LOC, obvious solution):**
```
→ /csf:implement-now $ARGUMENTS
```
Skip specification ceremony and implement directly.

**For Medium Tasks (100-500 LOC, clear requirements):**
```
→ /csf:spec-mvp $ARGUMENTS  
```
Streamlined specification with essential testing and rapid implementation.

**For Complex Tasks (>500 LOC, unclear requirements, high risk):**
```
→ /csf:spec-workflow $ARGUMENTS
```
Complete specification-first workflow with all phases.

## Decision Matrix
```
Is solution obvious and <100 LOC?
├─ Yes → /csf:implement-now
└─ No → Is it well-understood and <500 LOC?
    ├─ Yes → /csf:spec-mvp
    └─ No → /csf:spec-workflow
```

## Instructions
**Immediately assess "$ARGUMENTS" and route to the appropriate workflow:**

1. **Quick assessment**: Estimate complexity and clarity
2. **Route automatically**: Execute the recommended command
3. **No additional ceremony**: Let the routed workflow handle the details

**IMMEDIATE ACTION**: Assess the complexity of "$ARGUMENTS" and automatically execute the most appropriate workflow command (`/csf:implement-now`, `/csf:spec-mvp`, or `/csf:spec-workflow`).