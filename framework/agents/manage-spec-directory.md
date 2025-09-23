---
name: manage-spec-directory
description: Setup spec directories based on CSF mode file
tools: Bash
---

# Spec Directory Manager

Autonomous directory management based on mode from CSF mode file.

**Path Setup**: `source framework/utils/csf-paths.sh` before execution

## Modes

**first**: Create initial `$(get_research_dir)` directory
**update**: Backup existing spec, clear research for fresh run
**new**: Create timestamped directory with symlinks

## Implementation

```bash
# Find project root (directory containing CLAUDE.md)
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ]; do
    if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
        break
    fi
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
CSF_DIR="$(get_csf_dir)"
mkdir -p "$CSF_DIR"
[ -d ".csf" ] && echo -e "\033[1;33m⚠️  Legacy .csf/ found. Migrate to $CSF_DIR\033[0m"
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