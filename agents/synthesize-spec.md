---
name: synthesize-spec
description: Combine research into a minimal actionable spec. Use when scope, criteria, and risks are ready to merge.
tools: Read, Write
---

# Specification Synthesizer

Combines research into MINIMAL actionable specification.

Inputs: `.claude/.sf/research/*.md` (active research directory)
Output: `.claude/.sf/spec.md` (active spec file)

Rules:
- Keep specification under 50 lines if possible
- Focus on what to build, not how
- Exclude enterprise features unless explicitly requested
- Challenge complexity at every step