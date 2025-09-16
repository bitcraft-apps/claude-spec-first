---
name: analyze-artifacts
description: Read and parse development artifacts from .claude/.csf/ directory
tools: Read
---

# Artifact Analyzer

Reads MINIMAL development artifacts for documentation.

Input: Artifact paths from arguments or `.csf/` directory
Output: `.csf/research/artifacts-summary.md`

Rules:
- Read only what exists (spec.md, implementation-summary.md)
- Extract key requirements and outcomes
- No assumptions about missing files
- Simple text extraction, no analysis