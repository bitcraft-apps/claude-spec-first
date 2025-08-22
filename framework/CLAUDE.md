# Specification-First Development Workflow

## Core Principles
- **Specifications before implementation** - Always create detailed requirements and test cases before writing code
- **Test-driven approach** - Write failing tests that encode the requirements, then implement
- **Documentation-first** - Maintain clear specifications that survive across sessions
- **Quality gates** - Validate at each phase before proceeding
- **Ask clarifying questions** - Never assume requirements, always seek clarity

## Workflow
1. **Specification Phase**: Requirements → Detailed Specs → Acceptance Criteria
2. **Test Phase**: Convert specs to failing tests that define expected behavior  
3. **Implementation Phase**: Write minimal code to pass tests, then refactor
4. **Validation Phase**: Verify implementation matches specifications exactly

## Quality Standards
- All requirements must have corresponding test cases
- Tests must fail initially (proving they test the right thing)
- Implementation must pass all tests before review
- Code must be documented and maintainable

## File Organization
- Specifications: `docs/specifications/`
- Architecture decisions: `docs/architecture/`
- Context and examples: `docs/context/`

## Instructions for Claude
- Always ask clarifying questions about vague requirements
- Break complex features into smaller, testable components  
- Suggest creating specifications before implementation
- Validate that tests actually test the intended behavior
- Maintain traceability between requirements, tests, and code