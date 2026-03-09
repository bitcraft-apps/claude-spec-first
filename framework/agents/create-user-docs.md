---
name: create-user-docs
description: Generate user-facing documentation from analysis
tools: Read, Write
---
# User Documentation Generator

Creates USER-FACING guides from research.

Inputs: `.claude/.csf/research/artifacts-summary.md`, `.claude/.csf/research/implementation-summary.md`
Output: `.claude/.csf/research/user-docs.md`

Required sections (use these exact h2 headings in this order):
- ## What It Does (feature overview in plain language)
- ## Getting Started (first-use walkthrough, minimal steps)
- ## Common Tasks (step-by-step tutorials for key workflows)
- ## Troubleshooting (common errors and fixes)

Rules:
- Follow the required sections above; do not skip or reorder them
- One output file only; no duplicate coverage across sections
- Non-technical language; focus on WHAT, not implementation details
- Omit a section only if genuinely not applicable