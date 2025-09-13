---
name: manage-spec-directory
description: Setup isolated spec directories with user prompts
tools: Read, Write, Bash
---

# Spec Directory Manager

Sets up directory isolation for spec runs with backward compatibility.

## Logic

**First run**: Create `.csf/spec.md` and `.csf/research/`

**Subsequent runs**:
- Backup current to timestamped directory
- Prompt: "Update existing (u) or Create new (n)?"
- Update: Overwrite current
- New: Create `YYYY-MM-DD-HHMMSS/` directory
- Maintain symlinks for compatibility

Outputs: Ready directory structure for spec generation.