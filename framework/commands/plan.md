---
description: Create technical implementation plan from existing specification
---

# Plan Command

This command delegates to the `csf-plan` agent to create detailed technical implementation plans from completed specifications.

## Usage
```
/csf:plan [SPECIFICATION_FILE]
```

## Prerequisites
- A specification must exist (created via `/csf:spec`)
- Specification should be complete and contain clear requirements
- Codebase should be accessible for analysis

**This command is ideal for critical work** where you need clean context boundaries. Use `/clear` after specification phase to ensure clean planning context. For rapid prototyping, consider using `/csf:workflow` instead.

## What it does
- Analyzes existing codebase to understand patterns and architecture
- Translates specification requirements into technical implementation steps
- Identifies files that need to be created, modified, or deleted
- Assesses implementation risks and provides mitigation strategies
- Creates detailed execution roadmap for implementation
- Provides testing and rollback strategies

## Example
```
# After creating a specification
/csf:spec Add user authentication with email/password login

# Create implementation plan from the specification
/csf:plan docs/specifications/user-authentication.md

# Or if working with the most recent specification
/csf:plan
```

## Agent
Uses the `csf-plan` agent with the following capabilities:
- Read, Grep, Glob tools for codebase research
- Technical planning and risk assessment
- Step-by-step implementation strategy creation
- Architecture and pattern analysis

## Output
The plan command produces:
- **Technical Implementation Plan**: Step-by-step implementation strategy
- **Risk Assessment**: Identified risks and mitigation approaches
- **File Change List**: Specific files to create, modify, or delete
- **Testing Strategy**: How to validate the implementation
- **Rollback Plan**: How to undo changes if needed

---

Use the Task tool to delegate to the csf-plan agent:

**Task Description:** Create implementation plan from specification
**Agent Type:** csf-plan  
**Prompt:** Create a detailed technical implementation plan for: $ARGUMENTS

Please:
1. Read the specification from `.csf/current/spec.md` if it exists, or from the provided path if specified, or ask user for specification location if neither exists
2. Explore the existing codebase to understand architecture, patterns, and conventions
3. Create a comprehensive implementation plan that includes:
   - Step-by-step implementation approach
   - Specific files to create, modify, or delete
   - Risk assessment and mitigation strategies
   - Testing strategy and validation steps
   - Rollback procedures if issues arise
4. Ensure the plan follows existing code patterns and architectural decisions
5. Break complex changes into manageable, ordered steps
6. Provide clear success criteria for each step

**IMPORTANT**: Write the complete implementation plan to `.csf/current/plan.md` using the Write tool, following the format specified in the csf-plan agent instructions. Provide a brief summary to the terminal after saving the file.

Focus on creating a plan that can be followed step-by-step by the implementation agent to build exactly what the specification requires.