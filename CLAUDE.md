# CLAUDE.md

Claude Spec-First Framework - Minimalist development workflow following YAGNI, KISS, and SRP principles.

## Core Philosophy

**Build the smallest thing that works.** Challenge assumptions. Deliver incrementally.

## Engineering Principles

### Mandatory Rules
- **YAGNI**: Don't build it until you need it
- **KISS**: Simplest solution that works
- **SRP**: Each component does one thing
- **MVP First**: Deliver narrowest viable change

### Anti-Patterns to Avoid
- Enterprise solutions without justification
- Blind pattern following
- Assumptions without clarification
- Features without immediate need
- Complexity without clear value

## Framework Rules

### Size Constraints
- Micro-agents: 25 lines max
- Commands: 50 lines max
- Self-documenting through clear naming
- Technology agnostic

### Execution Philosophy
- **Granular Tasks**: One deliverable at a time
- **Challenge Mode**: Question requirements for robustness
- **Smart Implementation**: 
  - If user needs immediate results → Use CLI tools directly (gh, npm, etc.)
  - If user needs reusable solution → Write code
  - When unclear → Ask what outcome they expect
- **Progress Visibility**: Keep user informed
- **Fail Fast & Recover**: Clear errors, then recover

### Workflow Structure

**Commands** (orchestrators):
- `/csf:spec` - Define what to build and why
- `/csf:implement` - Build it (code OR direct execution)
- `/csf:document` - Document what was built

**Note**: Plan merged into spec. Separate planning often overlaps with specification.

**Micro-agents** (executors):
- Single responsibility
- Parallel execution where valuable
- No assumptions - ask when unclear

## File Structure

```
.csf/
├── spec.md        # Current specification (overwritten each run)
├── research/      # Micro-agent outputs
└── [project files remain in natural locations]
```

## Development Guidelines

When modifying framework:

1. **Can it be smaller?** → Make it smaller
2. **Is it needed now?** → If no, document for later
3. **Does it assume?** → Make it ask instead
4. **Is it complex?** → Simplify or remove
5. **Does it work?** → Ship it, iterate later

## Quality Standards

- Challenge unclear requirements
- Provide progress feedback
- Recover gracefully from errors
- Document future improvements instead of implementing
- Battle-test through questioning

## Command Behavior

When user requests something:
1. **Clarify** if requirements are vague
2. **Challenge** if approach seems suboptimal
3. **Choose** simplest approach:
   - Direct execution for immediate needs
   - Code implementation for reusable needs
4. **Deliver** narrowest working solution
5. **Document** future enhancements separately

Remember: Worse is better. Ship small, iterate often.