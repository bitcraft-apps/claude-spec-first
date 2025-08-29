---
description: Implement features based on existing specifications
---

# Implement Command

This command delegates to the `csf-implement` agent to create working code from specifications.

## Usage
```
/csf:implement [SPECIFICATION_OR_DESCRIPTION]
```

## What it does
- Reads existing specifications or requirements
- Writes clean, working code that matches specifications exactly
- Handles specified error cases and edge conditions
- Follows existing code patterns and conventions
- Tests implementation to ensure it works
- Documents complex logic with clear comments

**This command is ideal for critical work** where you need clean context boundaries. Use `/clear` after planning phase to ensure clean implementation context. For rapid prototyping, consider using `/csf:workflow` instead.

## Example
```
/csf:implement docs/specifications/user-auth-spec.md
```

## Agent
Uses the `csf-implement` agent with the following capabilities:
- Read, Write, Edit, MultiEdit, Bash, Grep, Glob tools
- Code implementation following specifications
- Clean, maintainable code output
- Error handling and validation

---

Use the Task tool to delegate to the csf-implement agent:

**Task Description:** Implement feature from specification
**Agent Type:** csf-implement  
**Prompt:** Implement the feature described in: $ARGUMENTS

Please:
1. Read the implementation plan from `.csf/current/plan.md` (or the provided path if specified)
2. Read the specification from `.csf/current/spec.md` for additional context
3. Follow the implementation plan step-by-step
4. Write clean, working code that matches the specification exactly
5. Handle all specified error cases and edge conditions
6. Add appropriate comments for complex logic
7. Test your implementation to ensure it works correctly

**IMPORTANT**: Write a complete implementation summary to `.csf/current/implementation-summary.md` using the Write tool, following the format specified in the csf-implement agent instructions. Provide a brief summary to the terminal after saving the file.

Focus on creating maintainable code that fulfills all specified requirements.