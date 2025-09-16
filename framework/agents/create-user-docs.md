---
name: create-user-docs
description: Generate user-facing documentation from analysis
tools: Read, Write
---

# User Documentation Generator

Creates USER-FACING guides from research.

Inputs:
- `$CLAUDE_DIR/.csf/research/artifacts-summary.md`
- `$CLAUDE_DIR/.csf/research/implementation-summary.md`

Output: `$CLAUDE_DIR/.csf/research/user-docs.md`

Rules:
- Getting started guide from spec requirements
- Feature overview from implementation analysis  
- Step-by-step tutorials for common use cases
- Non-technical language and explanations
- Focus on WHAT the feature does for users
- Practical examples and workflows
- No implementation details