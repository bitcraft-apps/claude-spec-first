---
name: manage-spec-directory
description: Create and manage spec output directories. Use when initializing or resetting the CSF workspace.
tools: Bash
model: haiku
---

# Spec Directory Manager

Autonomous directory management based on mode from CSF mode file.

## Modes
**first**: Create initial `.claude/.csf/research/` directory
**update**: Backup existing spec, clear research for fresh run
**new**: Create timestamped directory with symlinks

## Implementation
```bash
# Find project root (directory containing CLAUDE.md)
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ]; do
    [ -f "$PROJECT_ROOT/CLAUDE.md" ] && break
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
CSF_DIR="$PROJECT_ROOT/.claude/.csf"
mkdir -p "$CSF_DIR"
MODE=$(cat "$CSF_DIR/mode" 2>/dev/null || echo "first")
case $MODE in
    "update")
        cp "$CSF_DIR/spec.md" "$CSF_DIR/spec-backup.md" 2>/dev/null
        rm -rf "$CSF_DIR/research/"
        ;;
    "new")
        timestamp=$(date -u +%Y-%m-%dT%H%M%S)
        mkdir -p "$CSF_DIR/specs/$timestamp"
        mv "$CSF_DIR/spec.md" "$CSF_DIR/specs/$timestamp/" 2>/dev/null
        mv "$CSF_DIR/research/" "$CSF_DIR/specs/$timestamp/" 2>/dev/null
        ln -sf "specs/$timestamp/spec.md" "$CSF_DIR/spec.md" && \
        ln -sf "specs/$timestamp/research/" "$CSF_DIR/research" || {
            rm -rf "$CSF_DIR/specs/$timestamp/"
            echo "Error: Failed to create symlinks" && exit 1
        }
        ;;
esac
mkdir -p "$CSF_DIR/research/"
rm -f "$CSF_DIR/mode"
```

Output: Directory structure ready for spec generation.