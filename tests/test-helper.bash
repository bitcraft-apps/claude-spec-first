#!/usr/bin/env bash

# Master Test Helper - Inlined for BATS Compatibility
# Contains all helper functions inline to avoid path issues with subdirectories

# === COMMON UTILITIES ===

# Determine project root directory
if [ -z "$PROJECT_ROOT" ]; then
    # Handle different execution contexts (direct, via test runner, from subdirs)
    if [ -n "${BASH_SOURCE[0]}" ]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    else
        # Fallback: search upward for CLAUDE.md
        CURRENT_DIR="$(pwd)"
        while [ "$CURRENT_DIR" != "/" ]; do
            if [ -f "$CURRENT_DIR/CLAUDE.md" ]; then
                PROJECT_ROOT="$CURRENT_DIR"
                break
            fi
            CURRENT_DIR="$(dirname "$CURRENT_DIR")"
        done
    fi
    export PROJECT_ROOT
fi

# Color codes for test output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m'

# Test output functions
test_info() {
    echo -e "${BLUE}INFO:${NC} $*" >&2
}

test_success() {
    echo -e "${GREEN}SUCCESS:${NC} $*" >&2
}

test_warning() {
    echo -e "${YELLOW}WARNING:${NC} $*" >&2
}

test_error() {
    echo -e "${RED}ERROR:${NC} $*" >&2
}

# Project validation
validate_project_root() {
    if [ -z "$PROJECT_ROOT" ] || [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
        test_error "Cannot find Claude Spec-First Framework project root"
        return 1
    fi
}

# === ASSERTION FUNCTIONS ===

# Assert that a version string is valid (semantic versioning)
assert_version_format() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        test_error "Expected semantic version format (x.y.z), got: $version"
        return 1
    fi
}

# Assert that a command exists and is executable
assert_executable() {
    local command_path="$1"
    [ -x "$command_path" ] || {
        test_error "Expected executable file at: $command_path"
        return 1
    }
}

# Assert that a directory structure exists
assert_directory_structure() {
    local base_dir="$1"
    shift
    
    for dir in "$@"; do
        [ -d "$base_dir/$dir" ] || {
            test_error "Expected directory: $base_dir/$dir"
            return 1
        }
    done
}

# Assert that required files exist
assert_files_exist() {
    local base_dir="$1"
    shift
    
    for file in "$@"; do
        [ -f "$base_dir/$file" ] || {
            test_error "Expected file: $base_dir/$file"
            return 1
        }
    done
}

# Assert that output contains expected content
assert_output_contains() {
    local expected="$1"
    [[ "$output" == *"$expected"* ]] || {
        test_error "Expected output to contain: $expected"
        test_error "Actual output: $output"
        return 1
    }
}

# Assert that output matches a regex pattern
assert_output_matches() {
    local pattern="$1"
    [[ "$output" =~ $pattern ]] || {
        test_error "Expected output to match pattern: $pattern"
        test_error "Actual output: $output"
        return 1
    }
}

# Assert that a command succeeded
assert_success() {
    [ "$status" -eq 0 ] || {
        test_error "Expected command to succeed (exit code 0), got: $status"
        test_error "Output: $output"
        return 1
    }
}

# Assert that a command failed with specific exit code
assert_failure() {
    local expected_code="${1:-1}"
    [ "$status" -eq "$expected_code" ] || {
        test_error "Expected command to fail with exit code $expected_code, got: $status"
        test_error "Output: $output"
        return 1
    }
}

# === FIXTURES AND MOCK DATA ===

# Create a mock home directory for installation tests
create_mock_home() {
    local home_dir="${1:-$TEST_DIR/mock_home}"
    mkdir -p "$home_dir/.claude"
    export TEST_HOME="$home_dir"
    export HOME="$home_dir"
    export CLAUDE_DIR="$home_dir/.claude"
    echo "$home_dir"
}

# Create a temporary VERSION file with specified version
create_version_file() {
    local version="${1:-1.0.0}"
    local version_file="${2:-$TEST_DIR/VERSION}"
    echo "$version" > "$version_file"
    echo "$version_file"
}

# === ENVIRONMENT SETUP ===

# Standard setup for integration tests
setup_integration_test() {
    # Create temporary test directory
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    
    # Validate project root
    validate_project_root || return 1
    
    # Change to test directory
    cd "$TEST_DIR"
    
    test_info "Integration test setup complete: $TEST_DIR"
}

# Standard teardown for integration tests
teardown_integration_test() {
    # Cleanup test environment
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
        test_info "Cleaned up test directory: $TEST_DIR"
    fi
    
    # Unset test-specific variables
    unset TEST_DIR
}

# Setup for E2E tests (more comprehensive)
setup_e2e_test() {
    setup_integration_test
    
    # Additional E2E setup
    export ORIGINAL_HOME="$HOME"
    export ORIGINAL_PWD="$(pwd)"
    
    test_info "E2E test setup complete"
}

# Teardown for E2E tests
teardown_e2e_test() {
    # Restore original environment
    if [ -n "$ORIGINAL_HOME" ]; then
        export HOME="$ORIGINAL_HOME"
        unset ORIGINAL_HOME
    fi
    
    if [ -n "$ORIGINAL_PWD" ] && [ -d "$ORIGINAL_PWD" ]; then
        cd "$ORIGINAL_PWD"
        unset ORIGINAL_PWD
    fi
    
    # Standard cleanup
    teardown_integration_test
    
    test_info "E2E test teardown complete"
}

# Legacy functions for backward compatibility
setup_test_framework() {
    setup_integration_test
}

cleanup_test_framework() {
    teardown_integration_test
}