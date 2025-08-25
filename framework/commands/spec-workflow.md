---
description: Complete specification-first development workflow - orchestrates all phases from requirements to deployment-ready implementation
---

# Complete Specification-First Development Workflow

You are executing the complete specification-first development process for: **$ARGUMENTS**

## Overview
This command orchestrates the specification-first workflow using specialized sub-agents, with **conditional phase execution** based on project complexity and configuration. Phases are automatically skipped or streamlined based on scope to optimize efficiency while maintaining quality.

## Configuration-Based Phase Execution

### IMPORTANT: Check Complexity First
**Before starting, determine if this is the right workflow:**
- **Simple projects** (<200 LOC): Use `/spec-mvp` instead for faster delivery
- **Medium projects** (200-500 LOC): Use conditional phases (skip architecture, streamline QA)
- **Complex projects** (>500 LOC): Execute full workflow with all phases

### Reference Configuration Settings
- **MAX_LOC_DEFAULT_THRESHOLD**: 500 (configurable project threshold)
- **COMPLEXITY_MODE**: mvp/standard/enterprise
- **TOKEN_EFFICIENCY**: high/medium/low
- **Project-specific**: Check for `.claude-config.yaml` overrides

### Phase Execution Rules

#### Standard Mode (200-500 LOC):
- ✅ Phase 1: Requirements & Specification (focused)
- ✅ Phase 2: Test Design (essential tests only)
- ❌ **Skip Phase 3**: Architecture Planning (use sensible defaults)
- ✅ Phase 4: Implementation Execution
- ❌ **Skip Phase 5**: Separate QA validation (integrate into implementation)
- ❌ **Skip Phase 6**: Documentation generation (minimal inline docs only)

#### Enterprise Mode (>500 LOC):
- ✅ Execute all phases comprehensively

## Adaptive Workflow Phases

### Phase 1: Requirements & Specification
**Command**: Execute `/spec-init $ARGUMENTS` process
- Use csf-spec-analyst to gather requirements and create detailed specifications
- Generate comprehensive test cases and acceptance criteria
- Create clear scope boundaries and success metrics
- Document assumptions and constraints

### Phase 2: Specification Review & Validation
**Command**: Execute `/spec-review $ARGUMENTS` process  
- Cross-validate specifications across multiple agents
- Identify gaps, inconsistencies, and improvement opportunities
- Ensure specifications are complete and implementable
- Get stakeholder sign-off on requirements

### Phase 3: Architecture & Implementation Planning (CONDITIONAL)
**Execution Rule**: Only execute if complexity mode is "enterprise" or estimated LOC > 500

**If SKIPPED (Standard mode):**
- Use sensible technology defaults from existing codebase
- Follow established patterns and conventions
- Defer architectural decisions to implementation phase
- Skip to Phase 4 directly

**If EXECUTED (Enterprise mode):**
**Command**: Execute `/impl-plan $ARGUMENTS` process
- Create detailed implementation roadmap with phases
- Plan test-driven development approach using csf-arch-designer
- Identify dependencies, risks, and resource requirements  
- Establish quality gates and validation checkpoints

### Phase 4: Implementation Execution
**Execute implementation using csf-impl-specialist**
- Write code following TDD approach (Red → Green → Refactor)
- Implement according to architectural guidelines
- Ensure all tests pass and requirements are met
- Maintain code quality and documentation standards

### Phase 5: Quality Assurance & Deployment Readiness (CONDITIONAL)
**Execution Rule**: Only execute separate QA phase if complexity mode is "enterprise" or high-risk system

**If SKIPPED (Standard mode):**
- QA validation integrated into Phase 4 implementation
- csf-impl-specialist performs basic testing and validation
- Run existing test suite to ensure no regressions
- Skip to Phase 6 or completion

**If EXECUTED (Enterprise mode):**
**Command**: Execute `/qa-check $ARGUMENTS` process
- Comprehensive quality validation against specifications
- Test execution and coverage analysis
- Security, performance, and accessibility validation
- Generate deployment readiness assessment

### Phase 6: Final Documentation Generation (CONDITIONAL)
**Execution Rule**: Only execute if complexity mode is "enterprise" or documentation explicitly requested

**If SKIPPED (Standard mode):**
- Rely on inline code comments and basic README updates
- Implementation includes minimal documentation as part of Phase 4
- Archive specifications in basic project documentation
- Skip comprehensive documentation generation

**If EXECUTED (Enterprise mode or requested):**
**Command**: Execute `/doc-generate $ARGUMENTS` process
- Synthesize all development artifacts into comprehensive documentation
- Generate technical documentation for developers and maintainers
- Create user-facing documentation for end users and stakeholders
- Archive original specifications with full traceability
- Deploy documentation to chosen platforms

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

### Documentation Generation Complete:
- [ ] All development artifacts successfully synthesized
- [ ] Technical documentation covers architecture, APIs, and operations
- [ ] User documentation provides complete feature coverage and tutorials
- [ ] Original specifications archived with full traceability
- [ ] Documentation deployed and accessible to stakeholders

## Conditional Workflow Execution Instructions

### Pre-Execution: Determine Mode and Phases
1. **Check estimated complexity and LOC** for the requirements
2. **Read project configuration** (.claude-config.yaml or defaults)
3. **Determine which phases to execute** based on complexity mode
4. **Set expectations** for streamlined vs. comprehensive approach

### Execution Path A: Standard Mode (200-500 LOC)

#### Step 1: Focused Specification Process
```
/spec-init $ARGUMENTS
```
- Use csf-spec-analyst in standard mode (focused, not comprehensive)
- Wait for essential specifications before proceeding

#### Step 2: Essential Test Design  
- Use csf-test-designer in standard mode (essential tests, skip comprehensive coverage)
- Focus on happy path and critical edge cases

#### Step 3: Skip Architecture Planning
- **SKIP** formal architecture phase
- Use sensible defaults and existing patterns
- Proceed directly to implementation

#### Step 4: Streamlined Implementation
- Use csf-impl-specialist in standard mode
- Integrate basic QA validation into implementation
- Include essential inline documentation
- **SKIP** separate QA and documentation phases

---

### Execution Path B: Enterprise Mode (>500 LOC)

#### Step 1: Comprehensive Specification Process
```
/spec-init $ARGUMENTS
```
- Use csf-spec-analyst in enterprise mode (comprehensive analysis)
- Wait for complete specifications before proceeding

#### Step 2: Complete Specification Review
```
/spec-review $ARGUMENTS
```
- Cross-validate specifications with multiple agents
- Address gaps and inconsistencies

#### Step 3: Full Architecture & Implementation Planning
```
/impl-plan $ARGUMENTS
```
- Use csf-arch-designer for comprehensive architecture
- Create detailed implementation roadmap
- Plan risk mitigation and quality gates

#### Step 4: Enterprise Implementation
- Use csf-impl-specialist in enterprise mode
- Follow comprehensive architectural guidelines
- Maintain extensive documentation standards

#### Step 5: Comprehensive Quality Assurance
```
/qa-check $ARGUMENTS
```
- Full quality validation against specifications
- Security, performance, and accessibility validation

#### Step 6: Complete Documentation Generation
```
/doc-generate $ARGUMENTS
```
- Generate comprehensive technical and user documentation
- Archive specifications with full traceability

### Step 5: Final Quality Validation
```
/qa-check $ARGUMENTS
```
Ensure deployment readiness before proceeding to documentation.

### Step 6: Generate Final Documentation
```
/doc-generate $ARGUMENTS
```
Create comprehensive documentation and archive development artifacts.

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
This workflow ensures systematic, high-quality development from initial concept to deployment-ready implementation with comprehensive documentation. Each of the 6 phases builds on the previous one, with multiple validation points to ensure quality and correctness.

**To start the complete workflow, begin with: `/spec-init $ARGUMENTS`**

The workflow will guide you through all phases with clear checkpoints and quality gates to ensure successful delivery and complete documentation.