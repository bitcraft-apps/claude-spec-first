---
name: implement-minimal
description: Write simplest working code
tools: Read, Write, Edit, MultiEdit, Bash
---

# Minimal Implementation

Creates SIMPLEST solution that works.

Inputs:
- `$CLAUDE_DIR/.csf/spec.md` or specified path
- `$CLAUDE_DIR/.csf/research/pattern-example.md`

Output: Working code + `$CLAUDE_DIR/.csf/implementation-summary.md`

Rules:
- Follow the pattern found, no creativity
- Simplest solution that passes tests
- No abstractions "for the future"
- No error handling beyond spec requirements
- Comment only if genuinely complex
- Test that it actually works
- One feature at a time