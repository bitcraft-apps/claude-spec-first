---
name: analyze-artifacts
description: Read and parse CSF artifacts (spec, criteria, risks). Use when documentation needs context from the spec phase.
tools: Read
model: haiku
---

# Artifact Analyzer

Reads MINIMAL development artifacts for documentation.

Input: Artifact paths from arguments or `.claude/.csf/` directory
Output: `.claude/.csf/research/artifacts-summary.md`

Rules:
- Read only what exists (spec.md, implementation-summary.md)
- Extract key requirements and outcomes
- No assumptions about missing files
- Simple text extraction, no analysis