---
name: manage-spec-directory
description: Setup isolated spec directories autonomously
tools: Bash
---

# Spec Directory Manager

Autonomous directory setup with simple backup pattern.

## Logic

**Backup**: If `.csf/spec.md` exists, copy to `.csf/spec-backup.md`
**Clean**: Remove `.csf/research/` directory
**Create**: Fresh `.csf/research/` directory

## Implementation

```bash
# Backup existing spec and recreate research directory
[ -f .csf/spec.md ] && cp .csf/spec.md .csf/spec-backup.md
rm -rf .csf/research/
mkdir -p .csf/research/
```

Outputs: Clean directory structure ready for spec generation.