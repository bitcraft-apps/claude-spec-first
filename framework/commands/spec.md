---
description: Create clear, actionable specifications from business requirements
---

# Spec Command

This command delegates to the `csf-spec` agent to create specifications from business requirements.

## Usage
```
/csf:spec [REQUIREMENTS]
```

## What it does
- Analyzes business requirements and asks clarifying questions
- Breaks down features into implementable components  
- Creates specifications with concrete acceptance criteria
- Identifies key constraints and edge cases
- Produces clear requirements ready for implementation

## Example
```
/csf:spec Add user authentication with email/password login
```

## Agent
Uses the `csf-spec` agent with the following capabilities:
- Read, Write, Edit, Grep, Glob tools
- Requirements analysis and specification creation
- Clear, actionable output focused on implementation readiness

---

Use the Task tool to delegate to the csf-spec agent:

**Task Description:** Create specification from requirements
**Agent Type:** csf-spec  
**Prompt:** Create a clear, actionable specification for: $ARGUMENTS

Please analyze the requirements, ask any clarifying questions needed, and produce a specification that includes:
- Requirements summary with clear scope
- Functional specifications broken into implementable components
- Concrete acceptance criteria  
- Key constraints and edge cases
- Any questions that need resolution before implementation

Focus on creating specifications that can be implemented directly without additional interpretation.