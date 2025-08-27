#!/usr/bin/env bash

# Test Helper for BATS Test Suite
# Provides common setup, utilities, and configuration for all tests

# Determine project root directory
if [ -z "$PROJECT_ROOT" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    export PROJECT_ROOT
fi

# Color codes for test output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m'

# Common test utilities
setup_test_framework() {
    # Create temporary directory for test operations
    if [ -z "$TEST_TEMP_DIR" ]; then
        TEST_TEMP_DIR="$(mktemp -d)"
        export TEST_TEMP_DIR
    fi
}

cleanup_test_framework() {
    # Clean up temporary test directory
    if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
        unset TEST_TEMP_DIR
    fi
}

# Helper function to create mock home directory for installation tests
create_mock_home() {
    local home_dir="$1"
    mkdir -p "$home_dir/.claude"
    export HOME="$home_dir"
    export CLAUDE_DIR="$home_dir/.claude"
}

# Helper function to run commands with timeout
run_with_timeout() {
    local timeout_duration="$1"
    shift
    timeout "$timeout_duration" "$@"
}

# Helper function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Helper function to validate version string format
is_valid_version() {
    local version="$1"
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# Helper function to check if directory is git repository
is_git_repo() {
    local dir="${1:-.}"
    [ -d "$dir/.git" ] || git -C "$dir" rev-parse --git-dir >/dev/null 2>&1
}

# Helper function to backup and restore files during tests
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.test_backup"
    fi
}

restore_file() {
    local file="$1"
    if [ -f "$file.test_backup" ]; then
        mv "$file.test_backup" "$file"
    fi
}

# Helper function to create test version file
create_test_version_file() {
    local dir="$1"
    local version="${2:-1.0.0}"
    mkdir -p "$dir"
    echo "$version" > "$dir/VERSION"
}

# Helper function to override framework directory for testing
override_framework_dir() {
    local test_dir="$1"
    
    # Create a function that returns the test directory
    get_framework_dir() {
        echo "$test_dir"
    }
    
    # Export the function so it's available in subshells
    export -f get_framework_dir
}

# Helper function to check test prerequisites
check_test_prerequisites() {
    # Check if we're in the right directory
    if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
        echo "Error: Not in Claude Spec-First Framework repository" >&2
        return 1
    fi
    
    # Check if required scripts exist
    if [ ! -f "$PROJECT_ROOT/scripts/version.sh" ]; then
        echo "Error: Version utilities script not found" >&2
        return 1
    fi
    
    # Check if framework validation script exists
    if [ ! -f "$PROJECT_ROOT/framework/validate-framework.sh" ]; then
        echo "Error: Framework validation script not found" >&2
        return 1
    fi
    
    return 0
}

# Helper function to capture and validate output patterns
output_contains() {
    local pattern="$1"
    [[ "$output" == *"$pattern"* ]]
}

output_matches() {
    local pattern="$1"
    [[ "$output" =~ $pattern ]]
}

# Helper function to create minimal test framework structure
create_test_framework() {
    local base_dir="$1"
    
    mkdir -p "$base_dir/framework"
    mkdir -p "$base_dir/scripts"
    
    # Copy essential files
    cp "$PROJECT_ROOT/framework/CLAUDE.md" "$base_dir/framework/"
    cp "$PROJECT_ROOT/framework/VERSION" "$base_dir/framework/"
    cp "$PROJECT_ROOT/framework/validate-framework.sh" "$base_dir/framework/"
    cp "$PROJECT_ROOT/scripts/version.sh" "$base_dir/scripts/"
    
    # Make scripts executable
    chmod +x "$base_dir/framework/validate-framework.sh"
    chmod +x "$base_dir/scripts/version.sh"
}

# Helper function for debugging test failures
debug_test_failure() {
    echo "=== TEST FAILURE DEBUG INFO ===" >&2
    echo "Status: $status" >&2
    echo "Output: $output" >&2
    echo "Lines: ${#lines[@]}" >&2
    for i in "${!lines[@]}"; do
        echo "Line $i: ${lines[$i]}" >&2
    done
    echo "Working directory: $(pwd)" >&2
    echo "PROJECT_ROOT: $PROJECT_ROOT" >&2
    echo "TEST_DIR: $TEST_DIR" >&2
    echo "==============================" >&2
}

# Run test prerequisites check when helper is loaded
if ! check_test_prerequisites; then
    exit 1
fi