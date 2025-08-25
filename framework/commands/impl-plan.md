---
description: Generate detailed implementation plan using architecture and test specifications - creates step-by-step development roadmap
---

# Implementation Planning Process

You are creating a detailed implementation plan for: **$ARGUMENTS**

## Multi-Agent Planning Process

### Phase 1: Architecture Implementation Strategy
**IMMEDIATE ACTION**: Use the csf-arch-designer sub-agent to create implementation strategy from architectural specifications.

The csf-arch-designer should:
- Review architectural decisions and component designs
- Create detailed implementation phases and milestones
- Identify critical path dependencies and bottlenecks
- Plan deployment and infrastructure requirements
- Provide technology-specific implementation guidance

### Phase 2: Test-Driven Implementation Plan
**IMMEDIATE ACTION**: Use the csf-test-designer sub-agent to create TDD implementation sequence.

The csf-test-designer should:
- Organize test cases into logical implementation order
- Create test-driven development phases (Red → Green → Refactor)
- Identify test dependencies and setup requirements
- Plan mock implementations and test data requirements
- Define test execution and validation checkpoints

### Phase 3: Implementation Sequencing
**IMMEDIATE ACTION**: Use the csf-impl-specialist sub-agent to create detailed coding plan.

The csf-impl-specialist should:
- Break down implementation into specific coding tasks
- Identify code dependencies and implementation order
- Plan refactoring and code quality improvements
- Create code review and validation checkpoints
- Estimate implementation effort and timeline

## Implementation Plan Deliverables

Generate the following outputs:
1. **Implementation Roadmap** - Phase-by-phase development plan
2. **Task Breakdown Structure** - Detailed tasks with dependencies
3. **Development Timeline** - Estimated effort and milestones
4. **Quality Gates** - Validation checkpoints throughout development
5. **Risk Mitigation Plan** - Identified risks and mitigation strategies
6. **Resource Requirements** - Team skills, tools, and infrastructure needs

## Development Phases

### Phase 1: Foundation (Week 1)
- Set up development environment and tooling
- Implement core utilities and infrastructure
- Create failing tests for critical path functionality
- Establish CI/CD pipeline and quality gates

### Phase 2: Core Implementation (Week 2-3)
- Implement core business logic following TDD approach
- Build primary user interfaces and interactions
- Integrate external APIs and services
- Complete unit and integration testing

### Phase 3: Polish & Integration (Week 4)
- Implement error handling and edge cases
- Add comprehensive logging and monitoring
- Complete accessibility and performance optimization
- Conduct final testing and quality validation

## Quality Checkpoints

At each phase completion:
- [ ] All tests for the phase pass successfully
- [ ] Code quality metrics meet established thresholds
- [ ] Security review completed with no critical issues
- [ ] Performance benchmarks achieved
- [ ] Documentation updated and complete

## Instructions
- Use multiple sub-agents to create comprehensive implementation strategy
- Ensure implementation plan follows test-driven development principles
- Balance speed with quality and maintainability
- Include risk mitigation and contingency planning
- Provide clear deliverables and success criteria for each phase

**Start by delegating to the csf-arch-designer for implementation strategy creation for: $ARGUMENTS**