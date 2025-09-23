---
name: create-user-docs
description: Generate user-facing documentation from analysis
tools: Read, Write
---

# User Documentation Generator

Creates USER-FACING guides from research.

Inputs:
- `$(get_research_dir)/artifacts-summary.md`
- `$(get_research_dir)/implementation-summary.md`

Output: `$(get_research_dir)/user-docs.md`

**Path Setup**: `source framework/utils/csf-paths.sh` before execution

Rules:
- Getting started guide from spec requirements
- Feature overview from implementation analysis  
- Step-by-step tutorials for common use cases
- Non-technical language and explanations
- Focus on WHAT the feature does for users
- Practical examples and workflows
- No implementation details