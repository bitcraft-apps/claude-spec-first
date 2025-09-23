---
name: synthesize-spec
description: Combine research into final specification
tools: Read, Write
---

# Specification Synthesizer

Combines research into MINIMAL actionable specification.

Inputs: `.claude/.csf/research/*.md` (active research directory)
Output: `.claude/.csf/spec.md` (active spec file)

Rules:
- Keep specification under 50 lines if possible
- Focus on what to build, not how
- Exclude enterprise features unless explicitly requested
- Challenge complexity at every step