---
name: create-technical-docs
description: Generate developer documentation from analysis
tools: Read, Write
---

# Technical Documentation Generator

Creates DEVELOPER documentation from research.

Inputs:
- `.claude/.csf/research/artifacts-summary.md`
- `.claude/.csf/research/implementation-summary.md`

Output: `.claude/.csf/research/technical-docs.md`

Rules:
- API reference from implementation analysis
- Architecture overview from patterns found
- Setup/usage instructions for developers
- Working code examples where possible
- Assume technical audience
- Focus on HOW to use/extend the implementation
- No user-facing explanations