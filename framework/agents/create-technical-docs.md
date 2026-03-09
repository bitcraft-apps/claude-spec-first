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
- `.claude/.csf/research/docs-inventory.md` (existing doc manifest)

Output: `.claude/.csf/research/technical-docs.md`
Shared context: `.claude/.csf/research/doc-context.md`

Required sections (use these exact h2 headings in this order):
- ## Overview (architecture summary, key design decisions)
- ## API Reference (public interfaces, parameters, return values)
- ## Setup (installation, configuration, prerequisites)
- ## Usage Examples (working code snippets for common tasks)
- ## Extension Points (how to modify or extend)

Rules:
- Read docs-inventory.md first — check what already exists before writing
- If existing docs cover a topic, reference them instead of duplicating
- Follow the required sections above; do not skip or reorder them
- One output file only; no duplicate coverage across sections
- Assume technical audience; focus on HOW to use/extend
- Omit a section only if the codebase genuinely has nothing for it

Shared context convention:
- If `.claude/.csf/research/doc-context.md` exists, read it for terminology decisions
- After writing output, append your terminology choices and topics covered to doc-context.md
- Format: `## Technical Docs` followed by bullet list of terms and topics
- This is optional coordination — do not fail if the file is missing or unreadable
