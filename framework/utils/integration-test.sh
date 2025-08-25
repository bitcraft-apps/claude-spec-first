#!/bin/bash

# Integration Test for Versioning System MVP
# Tests the complete versioning system in both repository and installed modes

set -e

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="/tmp/versioning-integration-test"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0

echo "🧪 Versioning System MVP - Integration Test"
echo "==========================================="
echo ""

# Test helper functions
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        return 1
    fi
}

# Cleanup function
cleanup() {
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

echo "📁 Setting up test environment..."

# Create clean test environment
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "🔧 Phase 1: Repository Mode Tests"
echo "=================================="

# Copy framework to test directory
cp -r "$PROJECT_ROOT/framework" "$TEST_DIR/"
cd "$TEST_DIR"

# Test repository mode functionality
run_test "Framework directory detection" "[ -f framework/CLAUDE.md ]"
run_test "VERSION file exists" "[ -f framework/VERSION ]"
run_test "Version utilities exist and are executable" "[ -x framework/utils/version-utils.sh ]"
run_test "Get framework version" "framework/utils/version-utils.sh get | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$'"
run_test "Version validation" "framework/utils/version-utils.sh validate 1.2.3"
run_test "Version comparison" "framework/utils/version-utils.sh compare 1.0.0 2.0.0 | grep -q '<'"
run_test "Framework validation includes version" "framework/validate-framework.sh | grep 'Framework Version:'"
run_test "Validation script passes" "framework/validate-framework.sh | grep 'Framework validation PASSED'"

echo ""
echo "🏠 Phase 2: Installation Mode Tests"  
echo "==================================="

# Test installation
mkdir -p "$TEST_DIR/home/.claude"
export HOME="$TEST_DIR/home"

# Simulate installation
cd "$PROJECT_ROOT"
CLAUDE_DIR="$TEST_DIR/home/.claude" scripts/install.sh >/dev/null 2>&1

cd "$TEST_DIR/home/.claude"

# Test installed mode functionality
run_test "Installation creates VERSION file" "[ -f VERSION ]"
run_test "Installation creates version utilities" "[ -x utils/version-utils.sh ]"
run_test "Get version in installed mode" "utils/version-utils.sh get | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$'"
run_test "Version info shows correct location" "utils/version-utils.sh info | grep 'Location: .'"
run_test "Installed validation includes version" "./validate-framework.sh | grep 'Framework Version:'"
run_test "Installed validation passes" "./validate-framework.sh | grep 'Framework validation PASSED'"

echo ""
echo "⚙️  Phase 3: Version Operations Tests"
echo "===================================="

# Test version operations
CURRENT_VERSION=$(utils/version-utils.sh get)
run_test "Version increment patch" "utils/version-utils.sh increment patch | grep 'SUCCESS'"
NEW_VERSION=$(utils/version-utils.sh get)
run_test "Version was incremented" "[ '$NEW_VERSION' != '$CURRENT_VERSION' ]"
run_test "Reset version" "utils/version-utils.sh set '$CURRENT_VERSION' | grep 'SUCCESS'"
run_test "Version was reset" "[ \$(utils/version-utils.sh get) = '$CURRENT_VERSION' ]"

echo ""
echo "🔄 Phase 4: Backward Compatibility Tests"
echo "========================================"

# Test framework without VERSION file
mv VERSION VERSION.backup
run_test "Framework works without VERSION file" "! ./validate-framework.sh | grep 'VERSION file exists' | grep '✅'"
run_test "Version utilities handle missing file gracefully" "! utils/version-utils.sh get"
mv VERSION.backup VERSION

echo ""
echo "📊 Integration Test Summary"
echo "==========================="
echo -e "Total tests: $TOTAL_TESTS"
echo -e "Passed:      ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:      ${RED}$((TOTAL_TESTS - PASSED_TESTS))${NC}"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo ""
    echo -e "${GREEN}🎉 All integration tests passed!${NC}"
    echo -e "${GREEN}Versioning system MVP is fully functional.${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some integration tests failed!${NC}"
    echo -e "${RED}Please check the failing tests and fix issues before deployment.${NC}"
    exit 1
fi