---
name: create-criteria
description: Generate acceptance criteria
tools: Write
---

# Acceptance Criteria

Creates MINIMAL success conditions following KISS principle.

Input: Requirements from arguments
Output: `$(get_research_dir)/criteria.md`

**Path Setup**: `source framework/utils/csf-paths.sh` before execution

Rules:
- Simplest testable conditions only
- No enterprise metrics unless requested
- Basic functionality over perfection
- "Works" is better than "optimal"