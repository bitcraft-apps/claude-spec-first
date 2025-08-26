---
description: Execute the complete specification-first workflow - spec, implement, document
---

# Workflow Command

This command orchestrates the complete specification-first development process using the simplified 3-agent workflow.

## Usage
```
/csf:workflow [REQUIREMENTS]
```

## What it does
Executes the full development cycle in sequence:
1. **Specification** - Creates clear requirements and acceptance criteria
2. **Implementation** - Builds working code that matches specifications
3. **Documentation** - Generates comprehensive docs from spec and code

## Example
```
/csf:workflow Add user authentication with email/password login and password reset
```

## Process
The workflow executes these phases in order with context clearing between each:

### Phase 1: Specification Creation
- Delegates to `csf-spec` agent
- Analyzes requirements and creates actionable specifications
- Produces clear acceptance criteria and constraints
- **Context cleared before next phase**

### Phase 2: Implementation
- Delegates to `csf-implement` agent  
- Reads specifications and implements working code
- Follows existing code patterns and conventions
- Tests implementation to ensure correctness
- **Context cleared before next phase**

### Phase 3: Documentation
- Delegates to `csf-document` agent
- Reads specifications and implementation artifacts
- Creates technical and user documentation
- Ensures documentation accuracy and completeness

## Success Criteria
- [ ] Clear specifications with acceptance criteria created
- [ ] Working implementation that matches specifications exactly  
- [ ] Comprehensive documentation covering technical and user aspects
- [ ] All phases completed without blocking issues

---

**Phase 1: Create Specification**

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

**Wait for Phase 1 to complete before proceeding to Phase 2.**

---

**Phase 2: Implementation** 

Use the Task tool to delegate to the csf-implement agent:

**Task Description:** Implement feature from specification  
**Agent Type:** csf-implement
**Prompt:** Implement the feature described in the specification created in Phase 1.

Please:
1. Read and understand the specification thoroughly
2. Examine existing codebase to understand patterns and conventions
3. Write clean, working code that matches the specification exactly
4. Handle all specified error cases and edge conditions
5. Add appropriate comments for complex logic
6. Test your implementation to ensure it works correctly
7. Provide a summary of what was implemented and where

**Wait for Phase 2 to complete before proceeding to Phase 3.**

---

**Phase 3: Documentation Generation**

Use the Task tool to delegate to the csf-document agent:

**Task Description:** Generate documentation from specification and implementation
**Agent Type:** csf-document  
**Prompt:** Create comprehensive documentation based on the specification and implementation from the previous phases.

Please:
1. Read and analyze the specification and implementation code
2. Create technical documentation for developers including:
   - Architecture overview
   - API reference  
   - Setup and usage instructions
3. Generate user-facing documentation including:
   - Feature guides
   - Getting started instructions
   - Common use cases and examples
4. Ensure all documentation is accurate against the actual implementation
5. Use clear, consistent writing throughout
6. Organize documentation in a logical, navigable structure

**Workflow complete when all three phases finish successfully.**