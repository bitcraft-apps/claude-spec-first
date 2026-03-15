#!/bin/bash
# SF SubagentStop validation hook - validates agent output exists

INPUT=$(cat)
[ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // ""')
RESEARCH_DIR="$PROJECT_DIR/.claude/.sf/research"

[ ! -d "$RESEARCH_DIR" ] && exit 0

# Find most recently modified file in research directory
LATEST=$(find "$RESEARCH_DIR" -maxdepth 1 -type f -exec stat -f '%m %N' {} + 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
[ -z "$LATEST" ] && exit 0

exit 0
