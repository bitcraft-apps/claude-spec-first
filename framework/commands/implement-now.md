---
description: Direct implementation command - skip all ceremony and implement immediately for obvious, well-understood tasks
---

# Direct Implementation

You are **implementing immediately without ceremony** for: **$ARGUMENTS**

## Overview
This command bypasses all specification, testing, and architecture phases for tasks where requirements are obvious and implementation is straightforward. Use this for simple fixes, obvious features, or well-understood changes where formal process would add no value.

## Key Principles
- **Zero ceremony** - Go straight to working code
- **Obvious solutions only** - If implementation isn't clear, escalate to `/spec-mvp`
- **Maximum token efficiency** - Minimal output, maximum implementation
- **Speed is everything** - Target 5-10 minutes total time
- **Quality through simplicity** - Use established patterns and conventions

## When to Use This Command

### Perfect for:
- **Bug fixes** with obvious solutions
- **Simple feature additions** following existing patterns
- **Configuration changes** or environment updates  
- **Documentation updates** or README improvements
- **Refactoring** with clear, isolated scope
- **UI tweaks** or styling adjustments
- **Dependencies updates** or build configuration
- **Hot-fixes** for production issues

### DO NOT use for:
- Unclear or ambiguous requirements
- New complex business logic
- System integrations or API design
- Anything requiring >100 lines of new code
- Features affecting multiple system components
- Changes requiring architectural decisions

## Execution Process

### Step 1: Immediate Assessment (30 seconds)
**Quick check - can you implement this right now without questions?**
- [ ] Requirements are crystal clear
- [ ] Solution approach is obvious  
- [ ] Implementation is <100 LOC
- [ ] No new external dependencies needed
- [ ] Follows existing project patterns
- [ ] No complex business logic involved

**If ANY answer is "no" → Escalate to `/spec-mvp` or `/spec-workflow`**

### Step 2: Direct Implementation (5-8 minutes)
**Just build it:**
- Write working code following existing conventions
- Use established patterns from the codebase
- Add minimal inline comments for non-obvious parts
- Include basic error handling where critical
- Test manually if no automated tests exist

### Step 3: Quick Validation (1-2 minutes)
- Run existing tests if they exist
- Manual verification that it works
- Basic smoke test of the change
- Commit with clear commit message

## Output Format

### Ultra-Minimal Implementation Report
**Files Changed:**
- `path/to/file.js` - [brief description of change]
- `path/to/other.js` - [brief description of change]

**Code Changes:**
[Show actual code changes - no verbose explanations]

**Testing:**
- [How you verified it works - one line]

**Done.** [No additional explanation needed]

## Quality Standards for Direct Implementation

### Still Required:
- Working code that solves the problem
- Basic error handling for obvious failure modes
- Clear, readable code following project conventions
- Manual testing to verify functionality

### Specifically Skipped:
- Comprehensive testing (existing tests should still pass)
- Formal specifications or documentation
- Architecture considerations
- Multiple implementation options analysis
- Extensive error handling and edge cases
- Performance optimization
- Security review (beyond obvious basics)

## Risk Management

### Built-in Safety Measures:
- **Scope limitation**: Only simple, obvious changes
- **Pattern following**: Use existing codebase conventions
- **Manual verification**: Always test the change works
- **Quick iteration**: If problems arise, fix immediately

### Escalation Triggers:
- Implementation takes >15 minutes
- Requirements become unclear during implementation
- Code change grows beyond initial estimate
- External dependencies or complex integration needed
- Multiple approaches seem equally valid

## Time Targets

- **Total process: 5-10 minutes maximum**
- Assessment: 30 seconds
- Implementation: 5-8 minutes
- Validation: 1-2 minutes

**If you exceed these times, stop and escalate to `/spec-mvp`**

## Examples of Good `/implement-now` Tasks

### Excellent Candidates:
- "Fix the button alignment on the login page"
- "Add a --verbose flag to the CLI command"
- "Update the API endpoint URL in the config"
- "Fix the typo in the error message"
- "Add a new field to the user profile form"
- "Change the default timeout from 30s to 60s"

### Bad Candidates (use `/spec-mvp` instead):
- "Add user authentication to the app"
- "Integrate with the new payment API" 
- "Optimize the database queries for better performance"
- "Add error handling for all edge cases"
- "Refactor the entire user management system"

## Instructions

**Proceed immediately to implementation if and only if:**
1. You understand exactly what needs to be built
2. The solution is obvious and straightforward
3. You can complete it in <100 lines of code
4. It follows existing project patterns

**Otherwise, immediately escalate:**
- Use `/spec-mvp` for simple features needing light specification
- Use `/spec-workflow` for complex features needing comprehensive approach

**No further analysis required - just implement "$ARGUMENTS" right now.**