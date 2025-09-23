---
name: define-scope
description: Define boundaries and MVP scope
tools: Write
---

# Scope Definition

Defines the NARROWEST viable solution following YAGNI principle.

Input: Requirements from arguments
Output: `$(get_research_dir)/scope.md`

**Path Setup**: `source framework/utils/csf-paths.sh` before execution

Rules:
- MVP only - exclude everything not immediately needed
- Challenge feature creep
- Prefer "future considerations" over current scope
- If unclear, exclude it