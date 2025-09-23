#!/usr/bin/env bats

# Unit Tests for CSF Path Utilities
# Tests the csf-paths.sh utility functions for correct path resolution

# Detect project root directory
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

# Source the utility functions
load "${PROJECT_ROOT}/framework/utils/csf-paths.sh"

setup() {
    # Create clean test environment
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    # Cleanup test environment
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

@test "get_csf_dir returns correct path from project root" {
    cd "$PROJECT_ROOT"
    result="$(get_csf_dir)"
    [ "$result" = "$PROJECT_ROOT/.claude/.csf" ]
}

@test "get_csf_dir returns correct path from subdirectory" {
    # Create a subdirectory and test from there
    mkdir -p "$PROJECT_ROOT/test-subdir"
    cd "$PROJECT_ROOT/test-subdir"
    result="$(get_csf_dir)"
    [ "$result" = "$PROJECT_ROOT/.claude/.csf" ]
    rmdir "$PROJECT_ROOT/test-subdir"
}

@test "get_csf_dir returns correct path from nested subdirectory" {
    # Test from a deeper nested directory
    mkdir -p "$PROJECT_ROOT/deep/nested/dir"
    cd "$PROJECT_ROOT/deep/nested/dir"
    result="$(get_csf_dir)"
    [ "$result" = "$PROJECT_ROOT/.claude/.csf" ]
    rm -rf "$PROJECT_ROOT/deep"
}

@test "get_research_dir returns correct path" {
    cd "$PROJECT_ROOT"
    result="$(get_research_dir)"
    [ "$result" = "$PROJECT_ROOT/.claude/.csf/research" ]
}

@test "get_specs_dir returns correct path" {
    cd "$PROJECT_ROOT"
    result="$(get_specs_dir)"
    [ "$result" = "$PROJECT_ROOT/.claude/.csf/specs" ]
}

@test "path functions work when CLAUDE.md exists" {
    # Test in our test directory with CLAUDE.md
    cd "$TEST_DIR"
    echo "# Test CLAUDE.md" > CLAUDE.md

    result="$(get_csf_dir)"
    [ "$result" = "$TEST_DIR/.claude/.csf" ]

    result="$(get_research_dir)"
    [ "$result" = "$TEST_DIR/.claude/.csf/research" ]

    result="$(get_specs_dir)"
    [ "$result" = "$TEST_DIR/.claude/.csf/specs" ]
}

@test "get_csf_dir handles error case when CLAUDE.md not found" {
    # Test behavior when no CLAUDE.md is found (reaches filesystem root)
    cd "$TEST_DIR"
    # Don't create CLAUDE.md - function should return error
    run get_csf_dir
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: CLAUDE.md not found in any parent directory"* ]]
}