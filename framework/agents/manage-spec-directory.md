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
# Directory setup
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
mkdir -p "$CLAUDE_DIR/.csf"

# Legacy directory detection
if [ -d ".csf" ]; then
    echo -e "\033[1;33m⚠️  Legacy .csf/ directory detected. Please migrate manually:\033[0m"
    echo "   1. Copy .csf/ content to $CLAUDE_DIR/.csf/"
    echo "   2. Remove old .csf/ directory"
fi

# Mode passed via .claude/.csf/mode file or defaults to first
MODE=$(cat "$CLAUDE_DIR/.csf/mode" 2>/dev/null || echo "first")
case $MODE in
    "update")
        cp "$CLAUDE_DIR/.csf/spec.md" "$CLAUDE_DIR/.csf/spec-backup.md"
        rm -rf "$CLAUDE_DIR/.csf/research/"
        ;;
    "new")
        timestamp=$(date -u +%Y-%m-%dT%H%M%S)
        mkdir -p "$CLAUDE_DIR/.csf/specs/$timestamp"
        mv "$CLAUDE_DIR/.csf/spec.md" "$CLAUDE_DIR/.csf/specs/$timestamp/"
        mv "$CLAUDE_DIR/.csf/research/" "$CLAUDE_DIR/.csf/specs/$timestamp/"
        if ! ln -sf "specs/$timestamp/spec.md" "$CLAUDE_DIR/.csf/spec.md"; then
            rm -rf "$CLAUDE_DIR/.csf/specs/$timestamp/"
            echo "Error: Failed to create spec symlink"
            exit 1
        fi
        if ! ln -sf "specs/$timestamp/research/" "$CLAUDE_DIR/.csf/research"; then
            rm -rf "$CLAUDE_DIR/.csf/specs/$timestamp/"
            echo "Error: Failed to create research symlink"
            exit 1
        fi
        ;;
esac
mkdir -p "$CLAUDE_DIR/.csf/research/"
rm -f "$CLAUDE_DIR/.csf/mode"
```

Output: Directory structure ready for spec generation.