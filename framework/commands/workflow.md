---
description: Execute the complete specification-first workflow - spec, plan, implement, document
---

# Workflow Command

This command orchestrates the complete specification-first development process using the 4-phase workflow.

## Usage
```
/csf:workflow [REQUIREMENTS]
```

## What it does
Executes the full development cycle in sequence:
1. **Specification** - Creates clear requirements and acceptance criteria
2. **Planning** - Creates technical implementation strategy from specifications
3. **Implementation** - Builds working code that follows the plan exactly
4. **Documentation** - Generates comprehensive docs from spec and code

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

### Phase 2: Planning
- Delegates to `csf-plan` agent
- Analyzes specification and existing codebase
- Creates detailed technical implementation strategy
- Identifies risks, dependencies, and step-by-step approach
- **Context cleared before next phase**

### Phase 3: Implementation
- Delegates to `csf-implement` agent  
- Reads plan and follows implementation strategy exactly
- Executes planned changes in specified order
- Validates each step according to plan success criteria
- **Context cleared before next phase**

### Phase 4: Documentation
- Delegates to `csf-document` agent
- Reads specifications and implementation artifacts
- Creates technical and user documentation
- Ensures documentation accuracy and completeness

## Success Criteria
- [ ] Clear specifications with acceptance criteria created
- [ ] Detailed implementation plan with risk assessment completed
- [ ] Working implementation that follows the plan exactly
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

**Phase 2: Create Implementation Plan**

Use the Task tool to delegate to the csf-plan agent:

**Task Description:** Create implementation plan from specification
**Agent Type:** csf-plan
**Prompt:** Create a detailed technical implementation plan for the specification created in Phase 1.

Please:
1. Read and analyze the specification thoroughly to understand all requirements
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

**Wait for Phase 2 to complete before proceeding to Phase 3.**

---

**Phase 3: Implementation** 

Use the Task tool to delegate to the csf-implement agent:

**Task Description:** Implement feature following plan
**Agent Type:** csf-implement
**Prompt:** Implement the feature by following the implementation plan created in Phase 2.

Please:
1. Read and understand both the specification and implementation plan thoroughly
2. Follow the implementation plan step-by-step in the exact order specified
3. Validate each step according to the success criteria in the plan
4. Write clean, working code that matches the specification exactly
5. Handle all specified error cases and edge conditions as outlined in the plan
6. Execute the testing strategy defined in the plan
7. Provide a summary of what was implemented and verification that plan was followed

**Wait for Phase 3 to complete before proceeding to Phase 4.**

---

**Phase 4: Documentation Generation**

Use the Task tool to delegate to the csf-document agent:

**Task Description:** Generate documentation from specification and implementation
**Agent Type:** csf-document  
**Prompt:** Create comprehensive documentation based on the specification, plan, and implementation from the previous phases.

Please:
1. Read and analyze the specification, implementation plan, and implementation code
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

**Workflow complete when all four phases finish successfully.**