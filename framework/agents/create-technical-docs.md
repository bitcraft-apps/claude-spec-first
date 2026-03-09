---
name: create-technical-docs
description: Generate developer documentation from analysis
tools: Read, Write
---

# Technical Documentation Generator

Creates DEVELOPER documentation from research.

Inputs: `.claude/.csf/research/artifacts-summary.md`, `.claude/.csf/research/implementation-summary.md`, `.claude/.csf/research/docs-inventory.md`
Output: `.claude/.csf/research/technical-docs.md`

Required sections (use these exact h2 headings in this order):
- ## Overview (architecture summary, key design decisions)
- ## API Reference (public interfaces, parameters, return values)
- ## Setup (installation, configuration, prerequisites)
- ## Usage Examples (working code snippets for common tasks)
- ## Extension Points (how to modify or extend)

Rules:
- Check docs-inventory.md — note which existing files cover this topic for downstream integration
- Follow the required sections above; do not skip or reorder them
- One output file only; no duplicate coverage across sections
- Assume technical audience; focus on HOW to use/extend
- Omit a section only if the codebase genuinely has nothing for it