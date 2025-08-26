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
1. Read and understand the specification thoroughly
2. Examine existing codebase to understand patterns and conventions
3. Write clean, working code that matches the specification exactly
4. Handle all specified error cases and edge conditions
5. Add appropriate comments for complex logic
6. Test your implementation to ensure it works correctly
7. Provide a summary of what was implemented and where

Focus on creating maintainable code that fulfills all specified requirements.