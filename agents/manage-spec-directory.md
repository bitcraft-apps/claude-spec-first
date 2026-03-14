---
name: manage-spec-directory
description: Create and manage spec output directories. Use when initializing or resetting the SF workspace.
tools: Bash
model: haiku
---

# Spec Directory Manager

Autonomous directory management based on mode from SF mode file.

## Modes
**first**: Create initial `.claude/.sf/research/` directory
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
SF_DIR="$PROJECT_ROOT/.claude/.sf"
mkdir -p "$SF_DIR"
[ -d "$PROJECT_ROOT/.git" ] && [ -f "$PROJECT_ROOT/.gitignore" ] && ! grep -qF '.claude/.sf/' "$PROJECT_ROOT/.gitignore" && echo '.claude/.sf/' >> "$PROJECT_ROOT/.gitignore"
MODE=$(cat "$SF_DIR/mode" 2>/dev/null || echo "first")
case $MODE in
    "update")
        cp "$SF_DIR/spec.md" "$SF_DIR/spec-backup.md" 2>/dev/null
        rm -rf "$SF_DIR/research/"
        ;;
    "new")
        timestamp=$(date -u +%Y-%m-%dT%H%M%S)
        mkdir -p "$SF_DIR/specs/$timestamp"
        mv "$SF_DIR/spec.md" "$SF_DIR/specs/$timestamp/" 2>/dev/null
        mv "$SF_DIR/research/" "$SF_DIR/specs/$timestamp/" 2>/dev/null
        ln -sf "specs/$timestamp/spec.md" "$SF_DIR/spec.md" && \
        ln -sf "specs/$timestamp/research/" "$SF_DIR/research" || {
            rm -rf "$SF_DIR/specs/$timestamp/"
            echo "Error: Failed to create symlinks" && exit 1
        }
        ;;
esac
mkdir -p "$SF_DIR/research/"
rm -f "$SF_DIR/mode"
```

Output: Directory structure ready for spec generation.