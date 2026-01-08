#!/bin/bash
# CSF Implementation validation hook - validates implementation against spec

INPUT=$(cat)
[ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // ""')
SPEC_FILE="$PROJECT_DIR/.claude/.csf/spec.md"
IMPL_FILE="$PROJECT_DIR/.claude/.csf/implementation-summary.md"

[ ! -f "$SPEC_FILE" ] || [ ! -f "$IMPL_FILE" ] && exit 0

CRITERIA=$(grep -i "^\- \[" "$SPEC_FILE" 2>/dev/null | head -5)
[ -z "$CRITERIA" ] && exit 0

UNCHECKED=$(echo "$CRITERIA" | grep -c "\[ \]" || echo "0")
if [ "$UNCHECKED" -gt 0 ]; then
  echo "{\"decision\":\"block\",\"reason\":\"$UNCHECKED acceptance criteria unchecked in spec\"}"
else
  echo "{\"decision\":\"approve\",\"reason\":\"Implementation aligns with spec\"}"
fi
