---
name: integrate-docs
description: Combine and organize final documentation
tools: Read, Write, Edit
---

# Documentation Integrator

Combines research into FINAL documentation files.

Inputs:
- `$CLAUDE_DIR/.csf/research/technical-docs.md`
- `$CLAUDE_DIR/.csf/research/user-docs.md`

Rules:
- Move technical docs to `docs/` or project doc location
- Move user docs to `docs/user/` or equivalent
- Create clear file structure and navigation
- Add metadata headers for traceability
- Clean up research files after integration