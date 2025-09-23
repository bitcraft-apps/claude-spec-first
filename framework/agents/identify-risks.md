---
name: identify-risks
description: Find edge cases and risks
tools: Write
---

# Risk Identification

Identifies ESSENTIAL risks and blocks following MVP principle.

Input: Requirements from arguments
Output: `$(get_research_dir)/risks.md`

**Path Setup**: `source framework/utils/csf-paths.sh` before execution

Rules:
- Focus on blockers, not every possible risk
- Challenge assumptions, not create enterprise concerns
- Essential edge cases only
- Prefer simple solutions over risk mitigation