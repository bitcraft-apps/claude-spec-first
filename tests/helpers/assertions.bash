#!/usr/bin/env bash

# Custom BATS Assertions
# Provides domain-specific assertions for the Claude Spec-First Framework

# Load common utilities
load 'common'

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