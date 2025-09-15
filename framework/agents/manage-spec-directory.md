---
name: manage-spec-directory
description: Setup spec directories based on .csf/mode file
tools: Bash
---

# Spec Directory Manager

Autonomous directory management based on mode from .csf/mode file.

## Modes

**first**: Create initial `.csf/research/` directory
**update**: Backup existing spec, clear research for fresh run
**new**: Create timestamped directory with symlinks

## Implementation

```bash
# Mode passed via .csf/mode file or defaults to first
MODE=$(cat .csf/mode 2>/dev/null || echo "first")
case $MODE in
    "update")
        cp .csf/spec.md .csf/spec-backup.md
        rm -rf .csf/research/
        ;;
    "new")
        timestamp=$(date -u +%Y-%m-%dT%H%M%S)
        mkdir -p .csf/specs/$timestamp
        mv .csf/spec.md .csf/specs/$timestamp/
        mv .csf/research/ .csf/specs/$timestamp/
        if ! ln -sf specs/$timestamp/spec.md .csf/spec.md; then
            echo "Error: Failed to create spec symlink"
            exit 1
        fi
        if ! ln -sf specs/$timestamp/research/ .csf/research; then
            echo "Error: Failed to create research symlink"
            exit 1
        fi
        ;;
esac
mkdir -p .csf/research/
```

Output: Directory structure ready for spec generation.