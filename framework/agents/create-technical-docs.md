---
name: create-technical-docs
description: Generate developer documentation from analysis
tools: Read, Write
---

# Technical Documentation Generator

Creates DEVELOPER documentation from research.

Inputs:
- `$(get_research_dir)/artifacts-summary.md`
- `$(get_research_dir)/implementation-summary.md`

Output: `$(get_research_dir)/technical-docs.md`

**Path Setup**: `source framework/utils/csf-paths.sh` before execution

Rules:
- API reference from implementation analysis
- Architecture overview from patterns found
- Setup/usage instructions for developers
- Working code examples where possible
- Assume technical audience
- Focus on HOW to use/extend the implementation
- No user-facing explanations