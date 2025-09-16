---
name: manage-spec-directory
description: Setup spec directories based on .claude/.csf/mode file
tools: Bash
---

# Spec Directory Manager

Autonomous directory management based on mode from .claude/.csf/mode file.

## Modes

**first**: Create initial `.claude/.csf/research/` directory
**update**: Backup existing spec, clear research for fresh run
**new**: Create timestamped directory with symlinks

## Implementation

```bash
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
mkdir -p "$CLAUDE_DIR/.csf"
[ -d ".csf" ] && echo -e "\033[1;33m⚠️  Legacy .csf/ found. Migrate to $CLAUDE_DIR/.csf/\033[0m"
MODE=$(cat "$CLAUDE_DIR/.csf/mode" 2>/dev/null || echo "first")
case $MODE in
    "update")
        cp "$CLAUDE_DIR/.csf/spec.md" "$CLAUDE_DIR/.csf/spec-backup.md" 2>/dev/null
        rm -rf "$CLAUDE_DIR/.csf/research/"
        ;;
    "new")
        timestamp=$(date -u +%Y-%m-%dT%H%M%S)
        mkdir -p "$CLAUDE_DIR/.csf/specs/$timestamp"
        mv "$CLAUDE_DIR/.csf/spec.md" "$CLAUDE_DIR/.csf/specs/$timestamp/" 2>/dev/null
        mv "$CLAUDE_DIR/.csf/research/" "$CLAUDE_DIR/.csf/specs/$timestamp/" 2>/dev/null
        ln -sf "specs/$timestamp/spec.md" "$CLAUDE_DIR/.csf/spec.md" && \
        ln -sf "specs/$timestamp/research/" "$CLAUDE_DIR/.csf/research" || {
            rm -rf "$CLAUDE_DIR/.csf/specs/$timestamp/"
            echo "Error: Failed to create symlinks" && exit 1
        }
        ;;
esac
mkdir -p "$CLAUDE_DIR/.csf/research/"
rm -f "$CLAUDE_DIR/.csf/mode"
```

Output: Directory structure ready for spec generation.