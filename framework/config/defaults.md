# Framework Configuration Defaults

## Code Limits & Thresholds

### Lines of Code Limits
- `MAX_LOC_DEFAULT_THRESHOLD: 500` - Default maximum lines of code for a single feature/PR (excluding tests and docs)
- `MAX_LOC_SIMPLE_THRESHOLD: 200` - Threshold below which projects are considered "simple"
- `MAX_LOC_COMPLEX_THRESHOLD: 1000` - Threshold above which projects require full enterprise workflow

### Token Efficiency Settings
- `TOKEN_EFFICIENCY: high` - Default token usage optimization level
  - `high`: Ultra-concise outputs, minimal documentation, essential-only sections
  - `medium`: Balanced outputs with moderate documentation
  - `low`: Comprehensive outputs with full documentation (original framework behavior)

### Complexity Modes
- `COMPLEXITY_MODE: mvp` - Default development approach
  - `mvp`: Focus on minimal viable product, skip non-essential phases
  - `standard`: Balanced approach with selective phase execution
  - `enterprise`: Full framework workflow with comprehensive documentation

## Workflow Behavior

### Phase Skipping Rules (MVP Mode)
- Skip architecture phase if LOC < `MAX_LOC_DEFAULT`
- Skip separate QA validation phase, integrate into implementation
- Skip comprehensive documentation generation (generate on-demand only)
- Use single-pass spec+test+implementation for simple features

### Phase Skipping Rules (Standard Mode)
- Include architecture phase if LOC > `MAX_LOC_DEFAULT`
- Include QA validation for medium complexity projects
- Generate focused documentation for key components

### Output Optimization
- `CONCISENESS_LEVEL: high` - Agent output verbosity control
  - `high`: Bullet points, essential info only, 3-5 sections max
  - `medium`: Structured but concise, 5-8 sections
  - `low`: Full comprehensive outputs (original behavior)

## Configuration Override

### Project-Level Configuration
Projects can override defaults by creating `.claude-config.yaml`:

```yaml
# Project-specific overrides
max_loc: 750
complexity_mode: standard
token_efficiency: medium
conciseness_level: medium
skip_phases:
  - documentation  # Skip doc generation
  - qa_validation  # Skip separate QA phase
```

### Runtime Configuration
Commands can specify mode temporarily:
- `/spec-mvp --mode=enterprise` - Override default complexity
- `/implement-now --max-loc=1000` - Override LOC limit for this task

## Smart Defaults

### Auto-Complexity Detection
Framework automatically detects project complexity:

1. **Simple Projects** (< 200 LOC estimated):
   - Direct implementation without specifications
   - Essential tests only
   - Minimal documentation

2. **Medium Projects** (200-500 LOC estimated):
   - Light specifications
   - Test-driven implementation
   - Focused documentation

3. **Complex Projects** (> 500 LOC estimated):
   - Full specification workflow
   - Comprehensive testing
   - Complete documentation

### Configuration Inheritance
1. Framework defaults (this file)
2. User global config (`~/.claude/config.yaml`)
3. Project config (`.claude-config.yaml`)
4. Command-line overrides

## Performance Targets

### MVP Mode Targets
- Token usage: 60-70% reduction vs original framework
- Time to implementation: 50% faster for simple features
- Code delivery: Stay under LOC limits while maintaining quality

### Quality Maintenance
Even in MVP mode, maintain:
- Working, tested code
- Essential error handling
- Basic documentation (inline comments)
- Code that passes validation

## Usage Guidelines

### When to Use MVP Mode
- Prototype development
- Small feature additions
- Bug fixes and improvements
- Time-critical deliveries
- Learning and experimentation

### When to Use Standard/Enterprise Mode
- Production system development
- Complex integrations
- Team collaboration projects
- Regulated/compliance environments
- Long-term maintenance codebases

## Implementation Notes

These defaults are referenced by:
- All framework agents (adjust output based on mode)
- Workflow commands (conditional phase execution)
- Global CLAUDE.md (mode-aware instructions)
- Project templates and examples