#!/bin/bash
# CSF SubagentStop validation hook - validates agent output exists and is non-empty

INPUT=$(cat)
[ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // ""')
RESEARCH_DIR="$PROJECT_DIR/.claude/.csf/research"

[ ! -d "$RESEARCH_DIR" ] && exit 0

# Find most recently modified file in research directory
LATEST=$(ls -t "$RESEARCH_DIR"/* 2>/dev/null | head -1)
[ -z "$LATEST" ] && exit 0

if [ ! -s "$LATEST" ]; then
  FILENAME=$(basename "$LATEST")
  echo "{\"decision\":\"block\",\"reason\":\"Subagent output empty: $FILENAME\"}"
fi
exit 0
