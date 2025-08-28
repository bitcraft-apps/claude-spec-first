#!/usr/bin/env bash

# Test Environment Setup and Teardown
# Provides standardized setup/teardown functions for different test types

# Load common utilities
load 'common'

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

# Setup for unit tests (minimal)
setup_unit_test() {
    # Validate project root
    validate_project_root || return 1
    
    test_info "Unit test setup complete"
}

# Helper to run commands with timeout
run_with_timeout() {
    local timeout_duration="${1:-30s}"
    shift
    
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout_duration" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$timeout_duration" "$@"
    else
        # Fallback: run without timeout
        test_warning "No timeout command available, running without timeout"
        "$@"
    fi
}

# Helper to check if we're running in CI
is_ci_environment() {
    [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ] || [ -n "$CONTINUOUS_INTEGRATION" ]
}

# Helper to skip tests in certain environments
skip_if_ci() {
    if is_ci_environment; then
        skip "${1:-Skipping in CI environment}"
    fi
}

skip_if_not_ci() {
    if ! is_ci_environment; then
        skip "${1:-Skipping outside CI environment}"
    fi
}