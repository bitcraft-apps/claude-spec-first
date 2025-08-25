---
description: Rapid MVP development workflow - combines lightweight specification, essential testing, and implementation in a single streamlined pass for simple features
---

# MVP Specification-First Development

You are executing the **MVP specification-first development process** for: **$ARGUMENTS**

## Overview
This command provides a rapid, token-efficient development workflow for simple features and prototypes. It combines essential specification, testing, and implementation in a streamlined single-pass approach, optimized for features under 500 lines of code.

## Key Principles
- **Speed over comprehensive analysis** - Get to working code quickly
- **Essential testing only** - Cover critical paths, skip extensive edge cases  
- **Minimal documentation** - Inline comments and basic README updates
- **Skip architecture phase** - Use sensible defaults and existing patterns
- **Token efficiency** - Concise outputs focused on immediate needs

## Workflow Execution

### Step 1: Quick Requirements Analysis (2-3 minutes)
Use **spec-analyst in MVP mode** to:
- Ask 2-3 essential clarifying questions (only blockers)
- Define core functionality in 3-5 bullet points
- Identify 1-2 critical success criteria
- Set clear scope boundaries (what's NOT included)
- **Estimate LOC** - confirm this should be <500 LOC for MVP workflow

**Output Expected:** Essential requirements in MVP format (see spec-analyst MVP mode)

### Step 2: Essential Test Design (2-3 minutes)
Use **test-designer in MVP mode** to:
- Create 3-6 essential tests covering main happy path
- Add 1-2 critical edge case tests
- Generate minimal test data/fixtures
- **Write failing tests** that encode the requirements
- Skip comprehensive test strategy documentation

**Output Expected:** Working test files that fail initially (see test-designer MVP mode)

### Step 3: Streamlined Implementation (Main effort)
Use **impl-specialist in MVP mode** to:
- Implement minimal code to pass all tests
- Add essential error handling only
- Include basic inline comments for complex logic
- Use sensible defaults for technology choices
- **Skip architecture phase** - follow existing patterns

**Output Expected:** Working code with minimal documentation (see impl-specialist MVP mode)

### Step 4: Quick Validation & Cleanup (1-2 minutes)
- Run tests to ensure they pass
- Basic functionality verification
- Minimal code cleanup if needed
- **No comprehensive QA phase** - essential validation only

## Success Criteria for MVP Mode

### Must Achieve:
- [ ] Working code that passes all essential tests
- [ ] Core functionality implemented correctly
- [ ] Basic error handling for obvious failure modes
- [ ] Code follows existing project patterns
- [ ] Implementation stays under estimated LOC limit

### Skip in MVP Mode:
- [ ] ~~Comprehensive edge case testing~~
- [ ] ~~Formal architecture documentation~~
- [ ] ~~Detailed performance optimization~~
- [ ] ~~Extensive documentation generation~~
- [ ] ~~Security audit (beyond basics)~~
- [ ] ~~Scalability planning~~

## Token Efficiency Guidelines

### High-Efficiency Outputs:
- Use bullet points instead of paragraphs
- Focus on "what" not "why" (save rationale for complex cases only)
- Combine related information into single sections
- Skip redundant validation steps
- Use working code examples instead of verbose explanations

### Time Management:
- **Total time target: 15-30 minutes** for typical MVP features
- Requirements: 2-3 minutes max
- Testing: 2-3 minutes max  
- Implementation: 10-20 minutes
- Validation: 1-2 minutes max

## When to Use MVP Mode

### Ideal for:
- Simple feature additions to existing systems
- Prototypes and proof-of-concept development
- Bug fixes and small improvements
- Time-critical deliveries
- Learning and experimentation
- Features estimated at <200 LOC

### Upgrade to Standard/Enterprise When:
- Implementation exceeds 500 LOC
- Complex business logic requires formal specification
- Integration with multiple external systems
- Compliance/regulatory requirements
- Production-critical systems with high reliability needs

## Instructions for Execution

**Start immediately with:** Use spec-analyst in MVP mode to gather essential requirements for "$ARGUMENTS"

**Then proceed sequentially:**
1. Clarify requirements (MVP mode)
2. Create failing tests (MVP mode) 
3. Implement solution (MVP mode)
4. Quick validation

**Quality Gates:**
- After requirements: Can this be built in <500 LOC? If not, escalate to `/spec-workflow`
- After tests: Do tests fail as expected and cover critical paths?
- After implementation: Do all tests pass and meet core requirements?

## Emergency Escalation

**Escalate to full `/spec-workflow` if:**
- Requirements analysis reveals >500 LOC complexity
- Multiple system integrations required
- Formal architecture decisions needed
- Compliance/security requirements identified
- Stakeholders request comprehensive documentation

**Escalate to `/implement-now` if:**
- Requirements are obvious and well-understood
- No testing infrastructure exists or needed
- Immediate hot-fix required
- Simple configuration or documentation change

This workflow prioritizes rapid delivery of working, tested code while maintaining essential quality standards. Focus on getting to working code quickly, then iterate and improve if needed.