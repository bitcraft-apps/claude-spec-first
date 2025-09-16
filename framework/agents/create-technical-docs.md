---
name: create-technical-docs
description: Generate developer documentation from analysis
tools: Read, Write
---

# Technical Documentation Generator

Creates DEVELOPER documentation from research.

Inputs: 
- `$CLAUDE_DIR/.csf/research/artifacts-summary.md`
- `$CLAUDE_DIR/.csf/research/implementation-summary.md`

Output: `$CLAUDE_DIR/.csf/research/technical-docs.md`

Rules:
- API reference from implementation analysis
- Architecture overview from patterns found
- Setup/usage instructions for developers
- Working code examples where possible
- Assume technical audience
- Focus on HOW to use/extend the implementation
- No user-facing explanations