# Specification-First Development Workflow

## Core Principles
- **Specification first** - Always create clear requirements before implementation
- **Context clearing** - Clear context between phases for focused work
- **Baby steps** - Start simple, add complexity only when needed
- **Quality gates** - Validate at each phase before proceeding
- **Ask clarifying questions** - Never assume requirements, always seek clarity

## Simplified Workflow

The framework uses a streamlined 3-phase approach:

### Phase 1: Specification
- Convert business requirements into clear, actionable specifications
- Define concrete acceptance criteria and constraints
- Identify key components and edge cases
- **Clear context before implementation**

### Phase 2: Implementation  
- Build working code that matches specifications exactly
- Follow existing code patterns and conventions
- Handle specified error cases appropriately
- Test implementation for correctness
- **Clear context before documentation**

### Phase 3: Documentation
- Generate comprehensive docs from specification and implementation
- Create both technical and user-facing documentation
- Ensure accuracy against actual implementation
- Organize information logically and clearly

## Workflow Commands

### Primary Commands
- **`/csf:spec`** - Create specification from business requirements
- **`/csf:implement`** - Implement code from specifications
- **`/csf:document`** - Generate documentation from spec and implementation
- **`/csf:workflow`** - Execute complete spec → implement → document cycle

## Specialized Agents

The framework uses 3 specialized agents:

1. **csf-spec** - Requirements analysis and specification creation
2. **csf-implement** - Code implementation following specifications  
3. **csf-document** - Documentation generation and synthesis

Each agent has specific tools and focuses on their phase of the workflow.

## Quality Standards
- All requirements must have clear acceptance criteria
- Implementation must match specifications exactly
- Code must be clean, readable, and maintainable
- Documentation must be accurate and comprehensive
- Each phase must complete successfully before proceeding

## File Organization
- Specifications: `docs/specifications/`
- Implementation: Source code following project structure
- Documentation: `docs/` with technical and user subdirectories

## Instructions for Claude

### Efficiency-First Approach
- **Ask clarifying questions** about vague requirements
- **Use appropriate workflow** - simple tasks may not need full workflow
- **Clear context** between phases for focused work
- **Validate thoroughly** at each phase before proceeding
- **Maintain quality** throughout all phases

### Workflow Execution
- Execute phases in order: spec → implement → document
- Complete each phase fully before moving to next
- Clear context between phases for clean separation
- Validate results at each step
- Maintain traceability between requirements, code, and docs

### Decision Guidelines
```
Clear requirements → /csf:spec then /csf:implement  
Complex feature → /csf:workflow (full cycle)
Documentation only → /csf:document
Simple update → /csf:implement (with existing context)
```

Focus on delivering working, well-documented solutions through clear specifications and quality implementation.