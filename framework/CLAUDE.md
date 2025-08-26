# Specification-First Development Workflow

## Core Principles
- **Right-sized approach** - Match development rigor to project complexity and constraints
- **MVP by default** - Start with minimal viable approach, scale up only when needed
- **Token efficiency** - Optimize for rapid development while maintaining quality
- **Specifications before implementation** - Create appropriate specifications for the complexity level
- **Test-driven approach** - Write essential tests that encode requirements
- **Quality gates** - Validate at each phase, but skip phases when appropriate
- **Ask clarifying questions** - Never assume requirements, always seek clarity

## Configuration System

### Default Settings (Configurable)
- **MAX_LOC_DEFAULT_THRESHOLD**: 500 lines of code per feature/PR (excludes tests and docs)
- **COMPLEXITY_MODE**: mvp (options: mvp/standard/enterprise)
- **TOKEN_EFFICIENCY**: high (options: high/medium/low)
- **Default approach**: Start with simplest workflow, escalate if needed

### Complexity Detection
**Automatically choose appropriate workflow based on:**
- **Simple projects** (<200 LOC): Use MVP mode, skip architecture phase
- **Medium projects** (200-500 LOC): Use standard mode, focused approach
- **Complex projects** (>500 LOC): Use enterprise mode, comprehensive workflow

### Configuration Override
Projects can override defaults with `.claude-config.yaml`:
```yaml
max_loc: 750
complexity_mode: standard
token_efficiency: medium
```

## Workflow Commands

### Primary Commands (Streamlined Decision Tree)
- **`/csf:spec-init`** - Smart router that automatically selects optimal workflow
- **`/csf:implement-now`** - Direct implementation for obvious tasks (<100 LOC, <30 min)  
- **`/csf:spec-mvp`** - MVP specification workflow (100-500 LOC, minimal ceremony)
- **`/csf:spec-workflow`** - Complete specification-first workflow (>500 LOC, comprehensive)

### Utility Commands
- **`/csf:complexity-eval`** - Analyze task and recommend optimal workflow
- **`/csf:spec-review`**, **`/csf:impl-plan`**, **`/csf:qa-check`**, **`/csf:doc-generate`** - Individual phases

## Adaptive Workflow
1. **Specification Phase**: Requirements → Detailed Specs → Acceptance Criteria
2. **Test Phase**: Convert specs to failing tests that define expected behavior  
3. **Implementation Phase**: Write minimal code to pass tests, then refactor
4. **Validation Phase**: Verify implementation matches specifications exactly
5. **Documentation Phase**: Generate comprehensive documentation and archive artifacts

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

### Efficiency-First Approach
- **Start simple**: Use `/complexity-eval` when unsure of scope, default to simpler workflows
- **Escalate when needed**: Upgrade from `/implement-now` → `/spec-mvp` → `/spec-workflow` as complexity emerges
- **Respect LOC limits**: Keep features under configured limits (default 500 LOC)
- **Skip unnecessary phases**: Architecture, QA, and documentation phases are optional based on complexity

### Quality Maintenance
- Always ask clarifying questions about vague requirements
- Break complex features into smaller, testable components (but implement MVP first)
- Create appropriate specifications for the complexity level (not always comprehensive)
- Write essential tests that encode requirements (focus on critical paths)
- Maintain traceability between requirements, tests, and code

### Configuration Awareness  
- Check project configuration settings before starting work
- Reference framework defaults for LOC limits and complexity modes
- Adapt agent outputs based on token efficiency settings
- Skip phases that don't add value for the current complexity level

### Decision Matrix
```
Start here → /csf:spec-init (smart router)
  ├─ Obvious solution (<100 LOC) → /csf:implement-now  
  ├─ Simple feature (100-500 LOC) → /csf:spec-mvp
  └─ Complex system (>500 LOC) → /csf:spec-workflow

Alternative: /csf:complexity-eval for detailed analysis
```