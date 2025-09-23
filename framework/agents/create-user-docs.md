---
name: create-user-docs
description: Generate user-facing documentation from analysis
tools: Read, Write
---

# User Documentation Generator

Creates USER-FACING guides from research.

Inputs:
- `.claude/.csf/research/artifacts-summary.md`
- `.claude/.csf/research/implementation-summary.md`

Output: `.claude/.csf/research/user-docs.md`

Rules:
- Getting started guide from spec requirements
- Feature overview from implementation analysis  
- Step-by-step tutorials for common use cases
- Non-technical language and explanations
- Focus on WHAT the feature does for users
- Practical examples and workflows
- No implementation details