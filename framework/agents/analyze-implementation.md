---
name: analyze-implementation
description: Analyze actual implementation files and code structure
tools: Read, Grep, Glob
---

# Implementation Analyzer

Finds ACTUAL implementation structure and patterns.

Input: Implementation paths from arguments or artifact references
Output: `$(get_research_dir)/implementation-summary.md`

**Path Setup**: `source framework/utils/csf-paths.sh` before execution

Rules:
- Find main implementation files and structure
- Identify key APIs, functions, and patterns
- Note file organization and naming conventions  
- Extract usage examples from code/tests
- Technology agnostic analysis