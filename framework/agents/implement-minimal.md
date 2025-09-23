---
name: implement-minimal
description: Write simplest working code
tools: Read, Write, Edit, MultiEdit, Bash
---

# Minimal Implementation

Creates SIMPLEST solution that works.

Inputs:
- `$(get_csf_dir)/spec.md` or specified path
- `$(get_research_dir)/pattern-example.md`

Output: Working code + `$(get_csf_dir)/implementation-summary.md`

**Path Setup**: `source framework/utils/csf-paths.sh` before execution

Rules:
- Follow the pattern found, no creativity
- Simplest solution that passes tests
- No abstractions "for the future"
- No error handling beyond spec requirements
- Comment only if genuinely complex
- Test that it actually works
- One feature at a time