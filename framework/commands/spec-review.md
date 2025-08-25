---
description: Comprehensive specification review using multiple agents - validates completeness, consistency, and quality of specifications
---

# Specification Review Process

You are conducting a comprehensive specification review for: **$ARGUMENTS**

## Multi-Agent Review Process

### Phase 1: Specification Analysis
**IMMEDIATE ACTION**: Use the csf-spec-analyst sub-agent to review the existing specification for completeness, consistency, and clarity.

The csf-spec-analyst should:
- Analyze the current specification documents
- Identify gaps, ambiguities, and inconsistencies  
- Check requirements traceability
- Validate acceptance criteria completeness
- Recommend improvements and clarifications

### Phase 2: Test Alignment Validation
**IMMEDIATE ACTION**: Use the csf-test-designer sub-agent to validate that test cases align with specifications.

The csf-test-designer should:
- Review existing test cases against specifications
- Identify missing test scenarios
- Check for test-specification alignment gaps
- Validate test coverage completeness
- Recommend additional test cases if needed

### Phase 3: Architecture Consistency Check
**IMMEDIATE ACTION**: Use the csf-arch-designer sub-agent to validate architectural alignment with specifications.

The csf-arch-designer should:
- Review architecture against functional requirements
- Check for architectural decision consistency
- Validate non-functional requirement support
- Identify architectural risks or gaps
- Recommend architectural improvements

## Review Deliverables

Generate the following outputs:
1. **Specification Quality Report** - Overall assessment of specification quality
2. **Gap Analysis** - Missing requirements, test cases, or architectural elements
3. **Consistency Matrix** - Cross-agent validation of alignment
4. **Improvement Recommendations** - Prioritized list of enhancements
5. **Sign-off Readiness** - Go/no-go for proceeding to implementation

## Quality Gates

Before approving specifications:
- [ ] All functional requirements are clear and testable
- [ ] Acceptance criteria are measurable and complete
- [ ] Test cases cover all requirements including edge cases
- [ ] Architecture supports all functional and non-functional requirements
- [ ] No conflicting requirements or design decisions
- [ ] All stakeholder concerns have been addressed

## Instructions
- Use multiple sub-agents to cross-validate the specifications
- Focus on finding gaps, inconsistencies, and improvement opportunities
- Provide actionable recommendations with clear priorities
- Ensure specifications are ready for high-quality implementation

**Start by delegating to the csf-spec-analyst for initial specification analysis of: $ARGUMENTS**