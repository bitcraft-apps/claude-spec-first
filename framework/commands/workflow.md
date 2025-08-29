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

**Note**: This command runs all phases sequentially without clearing context between phases. While convenient for rapid development, this can lead to "poison context" where behavioral patterns from one phase affect subsequent phases. For critical work, consider running individual phase commands (`/csf:spec`, `/csf:plan`, `/csf:implement`, `/csf:document`) separately.

## Example
```
/csf:workflow Add user authentication with email/password login and password reset
```

## Process
The workflow executes these phases in order:

### Phase 1: Specification Creation
- Delegates to `csf-spec` agent
- Analyzes requirements and creates actionable specifications
- Produces clear acceptance criteria and constraints

### Phase 2: Planning
- Delegates to `csf-plan` agent
- Analyzes specification and existing codebase
- Creates detailed technical implementation strategy
- Identifies risks, dependencies, and step-by-step approach

### Phase 3: Implementation
- Delegates to `csf-implement` agent  
- Reads plan and follows implementation strategy exactly
- Executes planned changes in specified order
- Validates each step according to plan success criteria

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

**Before Starting: Archive Previous Workflow**

If `.csf/current/` directory exists, archive it:
```bash
mkdir -p .csf/archived/$(date +%Y%m%d_%H%M%S)
mv .csf/current/* .csf/archived/$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true
mkdir -p .csf/current
```

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

**IMPORTANT**: Write the complete specification to `.csf/current/spec.md` using the Write tool. Provide a brief summary to the terminal.

**Wait for Phase 1 to complete before proceeding to Phase 2.**

---

**Phase 2: Create Implementation Plan**

Use the Task tool to delegate to the csf-plan agent:

**Task Description:** Create implementation plan from specification
**Agent Type:** csf-plan
**Prompt:** Create a detailed technical implementation plan for the specification in `.csf/current/spec.md`.

Please:
1. Read and analyze the specification from `.csf/current/spec.md` thoroughly
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

**IMPORTANT**: Write the complete implementation plan to `.csf/current/plan.md` using the Write tool. Provide a brief summary to the terminal.

**Wait for Phase 2 to complete before proceeding to Phase 3.**

---

**Phase 3: Implementation** 

Use the Task tool to delegate to the csf-implement agent:

**Task Description:** Implement feature following plan
**Agent Type:** csf-implement
**Prompt:** Implement the feature by following the implementation plan in `.csf/current/plan.md`.

Please:
1. Read the implementation plan from `.csf/current/plan.md` thoroughly
2. Read the specification from `.csf/current/spec.md` for additional context
3. Follow the implementation plan step-by-step in the exact order specified
4. Validate each step according to the success criteria in the plan
5. Write clean, working code that matches the specification exactly
6. Handle all specified error cases and edge conditions as outlined in the plan
7. Execute the testing strategy defined in the plan

**IMPORTANT**: Write a complete implementation summary to `.csf/current/implementation-summary.md` using the Write tool. Provide a brief summary to the terminal.

**Wait for Phase 3 to complete before proceeding to Phase 4.**

---

**Phase 4: Documentation Generation**

Use the Task tool to delegate to the csf-document agent:

**Task Description:** Generate documentation from specification and implementation
**Agent Type:** csf-document  
**Prompt:** Create comprehensive documentation based on the artifacts in `.csf/current/`.

Please:
1. Read development artifacts from `.csf/current/` directory (spec.md, plan.md, implementation-summary.md)
2. Analyze the actual implementation files and code structure
3. Create technical documentation for developers including:
   - Architecture overview
   - API reference  
   - Setup and usage instructions
4. Generate user-facing documentation including:
   - Feature guides
   - Getting started instructions
   - Common use cases and examples
5. Ensure all documentation is accurate against the actual implementation
6. Use clear, consistent writing throughout
7. Organize documentation in a logical, navigable structure

Create documentation files in the appropriate project locations (docs/, docs/user/, etc.). Provide a summary of generated documentation to the terminal.

**Workflow complete when all four phases finish successfully.**

**Final Summary**: All development artifacts are preserved in `.csf/current/` for reference and can be safely accessed even after context clearing.