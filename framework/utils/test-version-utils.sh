#!/bin/bash

# Test Suite for Version Utilities
# Validates all version utility functions with comprehensive test cases

set -e  # Exit on any error

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_UTILS="$SCRIPT_DIR/version-utils.sh"
TEST_DIR="$SCRIPT_DIR/test-data"
TEMP_VERSION_FILE=""

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🧪 Version Utilities Test Suite"
echo "==============================="
echo ""

# Setup test environment
setup_test_env() {
    # Create temporary test directory
    mkdir -p "$TEST_DIR"
    
    # Create temporary VERSION file for testing
    TEMP_VERSION_FILE="$TEST_DIR/VERSION"
    echo "1.0.0" > "$TEMP_VERSION_FILE"
    
    # Source the version utilities
    . "$VERSION_UTILS"
}

# Cleanup test environment
cleanup_test_env() {
    if [ -n "$TEMP_VERSION_FILE" ] && [ -f "$TEMP_VERSION_FILE" ]; then
        rm -f "$TEMP_VERSION_FILE"
    fi
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}: $test_name"
        echo -e "   Expected: '$expected'"
        echo -e "   Actual:   '$actual'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_success() {
    local command="$1"
    local test_name="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}: $test_name"
        echo -e "   Command failed: $command"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_failure() {
    local command="$1"
    local test_name="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${RED}❌ FAIL${NC}: $test_name"
        echo -e "   Command should have failed: $command"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    else
        echo -e "${GREEN}✅ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    fi
}

# Helper function to safely get version with fallback
get_version_safe() {
    "$VERSION_UTILS" get 2>/dev/null || echo "failed"
}

# Test: Version validation
test_version_validation() {
    echo -e "${BLUE}Testing version validation...${NC}"
    
    # Valid versions
    assert_success "validate_version '1.0.0'" "validate_version accepts basic version"
    assert_success "validate_version '0.1.0'" "validate_version accepts version with zero major"
    assert_success "validate_version '10.20.30'" "validate_version accepts multi-digit versions"
    assert_success "validate_version '999.999.999'" "validate_version accepts large versions"
    
    # Invalid versions
    assert_failure "validate_version ''" "validate_version rejects empty version"
    assert_failure "validate_version '1.0'" "validate_version rejects incomplete version"
    assert_failure "validate_version '1.0.0.0'" "validate_version rejects too many components"
    assert_failure "validate_version 'v1.0.0'" "validate_version rejects version with prefix"
    assert_failure "validate_version '1.0.0-alpha'" "validate_version rejects pre-release suffix"
    assert_failure "validate_version '1.a.0'" "validate_version rejects non-numeric components"
    assert_failure "validate_version '1..0'" "validate_version rejects empty component"
    
    echo ""
}

# Test: Version parsing
test_version_parsing() {
    echo -e "${BLUE}Testing version parsing...${NC}"
    
    # Test basic parsing
    parse_version "1.2.3"
    assert_equals "1" "$MAJOR" "parse_version extracts major version"
    assert_equals "2" "$MINOR" "parse_version extracts minor version"  
    assert_equals "3" "$PATCH" "parse_version extracts patch version"
    
    # Test edge cases
    parse_version "0.0.0"
    assert_equals "0" "$MAJOR" "parse_version handles zero versions"
    
    parse_version "999.888.777"
    assert_equals "999" "$MAJOR" "parse_version handles large versions"
    
    echo ""
}

# Test: Version comparison
test_version_comparison() {
    echo -e "${BLUE}Testing version comparison...${NC}"
    
    # Equal versions
    compare_versions "1.0.0" "1.0.0"
    assert_equals "0" "$?" "compare_versions identifies equal versions"
    
    # Major version differences
    compare_versions "2.0.0" "1.0.0"
    assert_equals "1" "$?" "compare_versions identifies newer major version"
    
    compare_versions "1.0.0" "2.0.0"
    assert_equals "2" "$?" "compare_versions identifies older major version"
    
    # Minor version differences
    compare_versions "1.2.0" "1.1.0"
    assert_equals "1" "$?" "compare_versions identifies newer minor version"
    
    compare_versions "1.1.0" "1.2.0"
    assert_equals "2" "$?" "compare_versions identifies older minor version"
    
    # Patch version differences
    compare_versions "1.0.2" "1.0.1"
    assert_equals "1" "$?" "compare_versions identifies newer patch version"
    
    compare_versions "1.0.1" "1.0.2"
    assert_equals "2" "$?" "compare_versions identifies older patch version"
    
    echo ""
}

# Test: Version incrementing
test_version_incrementing() {
    echo -e "${BLUE}Testing version incrementing...${NC}"
    
    # Major increment
    local result
    result=$(increment_version "1.2.3" "major")
    assert_equals "2.0.0" "$result" "increment_version major resets minor and patch"
    
    # Minor increment
    result=$(increment_version "1.2.3" "minor")
    assert_equals "1.3.0" "$result" "increment_version minor resets patch"
    
    # Patch increment
    result=$(increment_version "1.2.3" "patch")
    assert_equals "1.2.4" "$result" "increment_version patch preserves major and minor"
    
    # Edge cases
    result=$(increment_version "0.0.0" "major")
    assert_equals "1.0.0" "$result" "increment_version major from zero"
    
    result=$(increment_version "999.999.999" "patch")
    assert_equals "999.999.1000" "$result" "increment_version handles large numbers"
    
    # Invalid increment types
    assert_failure "increment_version '1.0.0' 'invalid'" "increment_version rejects invalid type"
    assert_failure "increment_version '1.0.0' ''" "increment_version requires increment type"
    
    echo ""
}

# Test: Framework version operations (requires test setup)
test_framework_operations() {
    echo -e "${BLUE}Testing framework version operations...${NC}"
    
    # Override get_framework_dir to use test directory
    get_framework_dir() {
        echo "$TEST_DIR"
    }
    
    # Test get_framework_version
    local version
    version=$(get_framework_version)
    assert_equals "1.0.0" "$version" "get_framework_version reads VERSION file"
    
    # Test set_framework_version
    assert_success "set_framework_version '1.2.3'" "set_framework_version updates VERSION file"
    
    version=$(get_framework_version)
    assert_equals "1.2.3" "$version" "get_framework_version reflects updated version"
    
    # Test validate_version_file
    assert_success "validate_version_file" "validate_version_file validates correct file"
    
    # Test with invalid version file
    echo "invalid.version" > "$TEMP_VERSION_FILE"
    assert_failure "validate_version_file" "validate_version_file rejects invalid version"
    
    echo ""
}

# Test: Command line interface
test_cli_interface() {
    echo -e "${BLUE}Testing command line interface...${NC}"
    
    # Override get_framework_dir for CLI tests
    get_framework_dir() {
        echo "$TEST_DIR"
    }
    
    # Reset version file
    echo "1.0.0" > "$TEMP_VERSION_FILE"
    
    # Test get command
    local result
    result=$(get_version_safe)
    assert_equals "1.0.0" "$result" "CLI get command works"
    
    # Test set command
    assert_success "'$VERSION_UTILS' set '2.0.0' >/dev/null" "CLI set command works"
    
    result=$(get_version_safe)
    assert_equals "2.0.0" "$result" "CLI set command updates version"
    
    # Test increment command
    assert_success "'$VERSION_UTILS' increment patch >/dev/null" "CLI increment command works"
    
    result=$(get_version_safe)
    assert_equals "2.0.1" "$result" "CLI increment command updates version"
    
    # Test compare command
    result=$("$VERSION_UTILS" compare "1.0.0" "2.0.0" 2>/dev/null | grep '<')
    assert_success "test -n '$result'" "CLI compare command works"
    
    # Test validate command
    assert_success "'$VERSION_UTILS' validate '1.2.3' >/dev/null" "CLI validate command works"
    
    echo ""
}

# Run all tests
run_all_tests() {
    echo "Setting up test environment..."
    setup_test_env
    
    echo ""
    test_version_validation
    test_version_parsing
    test_version_comparison
    test_version_incrementing
    test_framework_operations
    test_cli_interface
    
    echo "Cleaning up test environment..."
    cleanup_test_env
}

# Set trap for cleanup on exit
trap cleanup_test_env EXIT

# Check if version utilities script exists
if [ ! -f "$VERSION_UTILS" ]; then
    echo -e "${RED}❌ Version utilities script not found: $VERSION_UTILS${NC}"
    exit 1
fi

# Run tests
run_all_tests

# Print summary
echo ""
echo "📊 Test Summary"
echo "==============="
echo -e "Total tests: $TESTS_RUN"
echo -e "Passed:      ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed:      ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    echo -e "${GREEN}Version utilities are working correctly.${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed!${NC}"
    echo -e "${RED}Please fix the failing tests before deploying.${NC}"
    exit 1
fi