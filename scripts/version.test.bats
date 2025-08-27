#!/usr/bin/env bats

# Test Suite for Version Utilities
# Validates all version utility functions with comprehensive test cases

# Project root detection (inline)
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    # Create temporary test directory
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    
    # Create temporary VERSION file for testing
    TEMP_VERSION_FILE="$TEST_DIR/VERSION"
    echo "1.0.0" > "$TEMP_VERSION_FILE"
    export TEMP_VERSION_FILE
    
    # Source the version utilities for function testing, but handle set -e
    set +e  # Temporarily disable exit on error
    # Source the version utilities - handle different execution contexts
    # Find the actual scripts directory regardless of where bats is run from
    if [ -f "$(dirname "${BASH_SOURCE[0]}")/version.sh" ]; then
        # Running from same directory or with full path
        source "$(dirname "${BASH_SOURCE[0]}")/version.sh"
    elif [ -f "$PROJECT_ROOT/scripts/version.sh" ]; then
        # Running through test runner
        source "$PROJECT_ROOT/scripts/version.sh"
    else
        # Fallback - try to find it
        local version_script
        version_script=$(find "$PROJECT_ROOT" -name "version.sh" -path "*/scripts/*" -type f 2>/dev/null | head -1)
        if [ -n "$version_script" ]; then
            source "$version_script"
        else
            echo "ERROR: Cannot find version.sh script" >&2
            exit 1
        fi
    fi
    set -e  # Re-enable for BATS
}

teardown() {
    # Cleanup test environment
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Version Validation Tests
@test "validate_version accepts basic version" {
    run validate_version "1.0.0"
    [ "$status" -eq 0 ]
}

@test "validate_version accepts version with zero major" {
    run validate_version "0.1.0"
    [ "$status" -eq 0 ]
}

@test "validate_version accepts multi-digit versions" {
    run validate_version "10.20.30"
    [ "$status" -eq 0 ]
}

@test "validate_version accepts large versions" {
    run validate_version "999.999.999"
    [ "$status" -eq 0 ]
}

@test "validate_version rejects empty version" {
    run validate_version ""
    [ "$status" -ne 0 ]
}

@test "validate_version rejects incomplete version" {
    run validate_version "1.0"
    [ "$status" -ne 0 ]
}

@test "validate_version rejects too many components" {
    run validate_version "1.0.0.0"
    [ "$status" -ne 0 ]
}

@test "validate_version rejects version with prefix" {
    run validate_version "v1.0.0"
    [ "$status" -ne 0 ]
}

@test "validate_version rejects pre-release suffix" {
    run validate_version "1.0.0-alpha"
    [ "$status" -ne 0 ]
}

@test "validate_version rejects non-numeric components" {
    run validate_version "1.a.0"
    [ "$status" -ne 0 ]
}

@test "validate_version rejects empty component" {
    run validate_version "1..0"
    [ "$status" -ne 0 ]
}

# Version Parsing Tests
@test "parse_version extracts major version" {
    parse_version "1.2.3"
    [ "$MAJOR" = "1" ]
}

@test "parse_version extracts minor version" {
    parse_version "1.2.3"
    [ "$MINOR" = "2" ]
}

@test "parse_version extracts patch version" {
    parse_version "1.2.3"
    [ "$PATCH" = "3" ]
}

@test "parse_version handles zero versions" {
    parse_version "0.0.0"
    [ "$MAJOR" = "0" ]
    [ "$MINOR" = "0" ]
    [ "$PATCH" = "0" ]
}

@test "parse_version handles large versions" {
    parse_version "999.888.777"
    [ "$MAJOR" = "999" ]
    [ "$MINOR" = "888" ]
    [ "$PATCH" = "777" ]
}

# Version Comparison Tests
@test "compare_versions identifies equal versions" {
    compare_versions "1.0.0" "1.0.0" || local result=$?
    [ "${result:-0}" -eq 0 ]
}

@test "compare_versions identifies newer major version" {
    compare_versions "2.0.0" "1.0.0" || local result=$?
    [ "${result:-0}" -eq 1 ]
}

@test "compare_versions identifies older major version" {
    compare_versions "1.0.0" "2.0.0" || local result=$?
    [ "${result:-0}" -eq 2 ]
}

@test "compare_versions identifies newer minor version" {
    compare_versions "1.2.0" "1.1.0" || local result=$?
    [ "${result:-0}" -eq 1 ]
}

@test "compare_versions identifies older minor version" {
    compare_versions "1.1.0" "1.2.0" || local result=$?
    [ "${result:-0}" -eq 2 ]
}

@test "compare_versions identifies newer patch version" {
    compare_versions "1.0.2" "1.0.1" || local result=$?
    [ "${result:-0}" -eq 1 ]
}

@test "compare_versions identifies older patch version" {
    compare_versions "1.0.1" "1.0.2" || local result=$?
    [ "${result:-0}" -eq 2 ]
}

# Version Incrementing Tests
@test "increment_version major resets minor and patch" {
    result=$(increment_version "1.2.3" "major")
    [ "$result" = "2.0.0" ]
}

@test "increment_version minor resets patch" {
    result=$(increment_version "1.2.3" "minor")
    [ "$result" = "1.3.0" ]
}

@test "increment_version patch preserves major and minor" {
    result=$(increment_version "1.2.3" "patch")
    [ "$result" = "1.2.4" ]
}

@test "increment_version major from zero" {
    result=$(increment_version "0.0.0" "major")
    [ "$result" = "1.0.0" ]
}

@test "increment_version handles large numbers" {
    result=$(increment_version "999.999.999" "patch")
    [ "$result" = "999.999.1000" ]
}

@test "increment_version rejects invalid type" {
    run increment_version "1.0.0" "invalid"
    [ "$status" -ne 0 ]
}

@test "increment_version requires increment type" {
    run increment_version "1.0.0" ""
    [ "$status" -ne 0 ]
}

# Framework Operations Tests (using test environment)
@test "get_framework_version reads VERSION file" {
    # Override get_framework_dir to use test directory
    get_framework_dir() {
        echo "$TEST_DIR"
    }
    
    version=$(get_framework_version)
    [ "$version" = "1.0.0" ]
}

@test "set_framework_version updates VERSION file" {
    # Override get_framework_dir to use test directory
    get_framework_dir() {
        echo "$TEST_DIR"
    }
    
    run set_framework_version "1.2.3"
    [ "$status" -eq 0 ]
    
    version=$(get_framework_version)
    [ "$version" = "1.2.3" ]
}

@test "validate_version_file validates correct file" {
    # Override get_framework_dir to use test directory
    get_framework_dir() {
        echo "$TEST_DIR"
    }
    
    run validate_version_file
    [ "$status" -eq 0 ]
}

@test "validate_version_file rejects invalid version" {
    # Override get_framework_dir to use test directory
    get_framework_dir() {
        echo "$TEST_DIR"
    }
    
    echo "invalid.version" > "$TEMP_VERSION_FILE"
    run validate_version_file
    [ "$status" -ne 0 ]
}

# CLI Interface Tests
@test "CLI get command works" {
    # Test from project root where framework/VERSION exists
    cd "$PROJECT_ROOT"
    run ./scripts/version.sh get
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "CLI set command works" {
    # Create temporary framework for CLI test
    TEMP_FRAMEWORK_DIR="$TEST_DIR/framework"
    mkdir -p "$TEMP_FRAMEWORK_DIR"
    echo "1.0.0" > "$TEMP_FRAMEWORK_DIR/VERSION"
    
    cd "$TEST_DIR"
    run "$PROJECT_ROOT/scripts/version.sh" set "2.0.0"
    [ "$status" -eq 0 ]
    
    result=$("$PROJECT_ROOT/scripts/version.sh" get)
    [ "$result" = "2.0.0" ]
}

@test "CLI increment command works" {
    # Create temporary framework for CLI test
    TEMP_FRAMEWORK_DIR="$TEST_DIR/framework"
    mkdir -p "$TEMP_FRAMEWORK_DIR"
    echo "2.0.0" > "$TEMP_FRAMEWORK_DIR/VERSION"
    
    cd "$TEST_DIR"
    run "$PROJECT_ROOT/scripts/version.sh" increment patch
    [ "$status" -eq 0 ]
    
    result=$("$PROJECT_ROOT/scripts/version.sh" get)
    [ "$result" = "2.0.1" ]
}

@test "CLI compare command works" {
    run "$PROJECT_ROOT/scripts/version.sh" compare "1.0.0" "2.0.0"
    [ "$status" -eq 0 ]
    [[ "$output" == *"<"* ]]
}

@test "CLI validate command works" {
    run "$PROJECT_ROOT/scripts/version.sh" validate "1.2.3"
    [ "$status" -eq 0 ]
}