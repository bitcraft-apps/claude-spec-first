---
name: synthesize-spec
description: Combine research into final specification
tools: Read, Write
---

# Specification Synthesizer

Combines research into MINIMAL actionable specification.

Inputs: `$(get_research_dir)/*.md` (active research directory)
Output: `$(get_csf_dir)/spec.md` (active spec file, may be symlink)

**Path Setup**: `source framework/utils/csf-paths.sh` before execution

Rules:
- Keep specification under 50 lines if possible
- Focus on what to build, not how
- Exclude enterprise features unless explicitly requested
- Challenge complexity at every step