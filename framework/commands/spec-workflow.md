---
description: Complete specification-first development workflow - orchestrates all phases from requirements to deployment-ready implementation
---

# Complete Specification-First Development Workflow

You are executing the complete specification-first development process for: **$ARGUMENTS**

## Overview
This command orchestrates the full specification-first workflow using all specialized sub-agents to ensure high-quality, well-tested implementations that match requirements exactly.

## Workflow Phases

### Phase 1: Requirements & Specification
**Command**: Execute `/spec-init $ARGUMENTS` process
- Use spec-analyst to gather requirements and create detailed specifications
- Generate comprehensive test cases and acceptance criteria
- Create clear scope boundaries and success metrics
- Document assumptions and constraints

### Phase 2: Specification Review & Validation
**Command**: Execute `/spec-review $ARGUMENTS` process  
- Cross-validate specifications across multiple agents
- Identify gaps, inconsistencies, and improvement opportunities
- Ensure specifications are complete and implementable
- Get stakeholder sign-off on requirements

### Phase 3: Implementation Planning
**Command**: Execute `/impl-plan $ARGUMENTS` process
- Create detailed implementation roadmap with phases
- Plan test-driven development approach
- Identify dependencies, risks, and resource requirements
- Establish quality gates and validation checkpoints

### Phase 4: Implementation Execution
**Execute implementation using impl-specialist**
- Write code following TDD approach (Red → Green → Refactor)
- Implement according to architectural guidelines
- Ensure all tests pass and requirements are met
- Maintain code quality and documentation standards

### Phase 5: Quality Assurance & Deployment Readiness
**Command**: Execute `/qa-check $ARGUMENTS` process
- Comprehensive quality validation against specifications
- Test execution and coverage analysis
- Security, performance, and accessibility validation
- Generate deployment readiness assessment

## Success Criteria

### Specification Phase Complete:
- [ ] All requirements clearly documented with acceptance criteria
- [ ] Comprehensive test cases covering happy path and edge cases  
- [ ] Architectural decisions documented with rationale
- [ ] Stakeholder approval on specifications

### Implementation Phase Complete:
- [ ] All tests pass successfully (100% critical path coverage)
- [ ] Implementation matches specifications exactly
- [ ] Code quality meets established standards
- [ ] Documentation complete and accurate

### Quality Validation Complete:
- [ ] QA validation shows "Pass" or "Conditional Pass" 
- [ ] No critical or blocking issues identified
- [ ] Deployment readiness confirmed
- [ ] Monitoring and rollback plans established

## Workflow Execution Instructions

### Step 1: Initialize Specification Process
```
/spec-init $ARGUMENTS
```
Wait for complete specification with test cases before proceeding.

### Step 2: Review and Validate Specifications  
```
/spec-review $ARGUMENTS
```
Address any gaps or issues before proceeding to implementation.

### Step 3: Create Implementation Plan
```
/impl-plan $ARGUMENTS
```
Use the plan to guide development phases and milestones.

### Step 4: Execute Implementation
Follow the implementation plan using test-driven development:
- Write failing tests first
- Implement minimal code to pass tests
- Refactor for quality and maintainability
- Repeat until all features complete

### Step 5: Final Quality Validation
```
/qa-check $ARGUMENTS
```
Ensure deployment readiness before release.

## Quality Assurance Throughout

### Continuous Validation:
- Requirements traceability maintained at every phase
- Test-driven development ensures correctness
- Multiple agent cross-validation prevents errors
- Quality gates prevent progression with issues

### Documentation Standards:
- All specifications version controlled and maintained
- Architectural decisions recorded with rationale
- Implementation documented with inline comments
- Quality reports archived for future reference

## Risk Mitigation

### Early Risk Identification:
- Specification review catches requirement issues early
- Implementation planning identifies technical risks
- Quality validation prevents deployment of flawed code

### Contingency Planning:
- Rollback procedures defined before deployment
- Monitoring and alerting established
- Issue escalation procedures documented

## Instructions
This workflow ensures systematic, high-quality development from initial concept to deployment-ready implementation. Each phase builds on the previous one, with multiple validation points to ensure quality and correctness.

**To start the complete workflow, begin with: `/spec-init $ARGUMENTS`**

The workflow will guide you through each phase with clear checkpoints and quality gates to ensure successful delivery.