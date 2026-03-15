#!/bin/bash
cd /Users/sgraczyk/Projects/bitcraft-apps/spec-first || exit
echo "=== GitHub Actions workflows ==="
ls -la .github/workflows/
echo ""
echo "=== Shell scripts in project ==="
find . -type f -name "*.sh" | head -20
echo ""
echo "=== Current CI pipeline ==="
cat .github/workflows/*.yml 2>/dev/null | head -100
