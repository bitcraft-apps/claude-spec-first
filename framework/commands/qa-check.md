---
description: Comprehensive quality assurance validation - executes tests, validates against specifications, and generates deployment readiness report
---

# Quality Assurance Check Process

You are conducting comprehensive QA validation for: **$ARGUMENTS**

## Multi-Agent Quality Validation Process

### Phase 1: Implementation Validation
**IMMEDIATE ACTION**: Use the csf-qa-validator sub-agent to conduct comprehensive quality assessment.

The csf-qa-validator should:
- Verify implementation against original specifications
- Execute and analyze all test suites and coverage
- Validate code quality, security, and performance standards
- Check requirements traceability from spec to implementation
- Assess deployment readiness with go/no-go recommendation

### Phase 2: Specification Compliance Verification
**IMMEDIATE ACTION**: Use the csf-spec-analyst sub-agent to verify specification compliance.

The csf-spec-analyst should:
- Compare final implementation against original requirements
- Validate that all acceptance criteria are met
- Check for requirement creep or missing functionality
- Verify edge cases and error conditions are properly handled
- Confirm user experience matches specified behavior

### Phase 3: Architecture Compliance Review
**IMMEDIATE ACTION**: Use the csf-arch-designer sub-agent to validate architectural compliance.

The csf-arch-designer should:
- Verify implementation follows architectural decisions
- Check that non-functional requirements are met
- Validate performance, security, and scalability implementations
- Review deployment and operational readiness
- Assess technical debt and maintenance considerations

### Phase 4: Test Coverage Validation
**IMMEDIATE ACTION**: Use the csf-test-designer sub-agent to validate test completeness.

The csf-test-designer should:
- Verify all test cases execute successfully
- Check test coverage against requirements
- Validate that tests actually test intended behavior
- Review test maintenance and sustainability
- Confirm testing strategy supports long-term maintenance

### Phase 5: Documentation Readiness Assessment
**IMMEDIATE ACTION**: Use the csf-doc-synthesizer sub-agent to assess documentation readiness.

The csf-doc-synthesizer should:
- Verify all development artifacts are complete and accessible
- Check that specifications, architecture decisions, and QA reports are available
- Validate implementation artifacts can be analyzed for documentation
- Ensure all components and features are properly documented in code
- Confirm traceability chain from requirements to implementation

## QA Deliverables

Generate the following comprehensive reports:
1. **Overall Quality Assessment** - Pass/Conditional Pass/Fail with rationale
2. **Specification Compliance Report** - Requirement-by-requirement validation
3. **Test Execution Summary** - All test results with coverage analysis
4. **Code Quality Metrics** - Maintainability, security, performance scores
5. **Deployment Readiness Assessment** - Go/no-go with prerequisites
6. **Documentation Readiness Report** - Artifact completeness and documentation readiness
7. **Risk Assessment** - Critical, high, medium, low priority issues
8. **Recommendations Report** - Immediate actions and future improvements

## Quality Gates Validation

Validate all quality gates pass:
- [ ] **Functional Completeness**: All specified features implemented correctly
- [ ] **Test Coverage**: 100% of critical paths, 90%+ overall coverage
- [ ] **Code Quality**: Meets established coding standards and best practices
- [ ] **Performance**: Achieves specified performance benchmarks
- [ ] **Security**: No critical security vulnerabilities
- [ ] **Accessibility**: Meets WCAG 2.1 AA standards (where applicable)
- [ ] **Documentation**: Complete and accurate implementation documentation
- [ ] **Documentation Readiness**: All artifacts available for comprehensive documentation generation

## Deployment Decision Framework

### Ready for Production:
- All quality gates pass
- No critical or high-priority issues
- Performance meets production requirements
- Security review complete with no blocking issues

### Conditional Deployment:
- Minor issues identified with clear mitigation plan
- Non-critical improvements recommended
- Monitoring and rollback plans established

### Not Ready for Deployment:
- Critical issues requiring resolution
- Quality gates not met
- Significant risks to user experience or system stability

## Instructions
- Use all available sub-agents for comprehensive validation
- Focus on deployment readiness and risk assessment
- Provide clear go/no-go recommendation with detailed rationale
- Include specific actions required before deployment
- Consider operational and maintenance requirements

**Start by delegating to the csf-qa-validator for comprehensive quality assessment of: $ARGUMENTS**