---
name: manage-spec-directory
description: Setup spec directories based on mode parameter
tools: Bash
---

# Spec Directory Manager

Autonomous directory management based on provided mode.

## Modes

**first**: Create initial `.csf/research/` directory
**update**: Backup existing spec, clear research for fresh run
**new**: Create timestamped directory with symlinks

## Implementation

```bash
# Mode passed via environment variable or defaults to first
MODE=${CSF_MODE:-first}
case $MODE in
    "update")
        cp .csf/spec.md .csf/spec-backup.md
        rm -rf .csf/research/
        ;;
    "new")
        timestamp=$(date +%Y-%m-%d-%H%M%S)
        mkdir -p .csf/specs/$timestamp
        mv .csf/spec.md .csf/specs/$timestamp/
        mv .csf/research/ .csf/specs/$timestamp/
        ln -sf specs/$timestamp/spec.md .csf/spec.md
        ln -sf specs/$timestamp/research/ .csf/research
        ;;
esac
mkdir -p .csf/research/
```

Output: Directory structure ready for spec generation.