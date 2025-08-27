#!/usr/bin/env bats

# Version System Integration Tests  
# Tests version utility integration and CLI functionality

# Load bats helpers
load '../test-helper'

setup() {
    # Create clean test environment
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    cd "$TEST_DIR"
}

teardown() {
    # Cleanup test environment
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

@test "version utilities are executable" {
    [ -x "$PROJECT_ROOT/scripts/version.sh" ]
}

@test "can get framework version" {
    cd "$PROJECT_ROOT"
    run ./scripts/version.sh get
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "version validation works" {
    cd "$PROJECT_ROOT"
    run ./scripts/version.sh validate "1.2.3"
    [ "$status" -eq 0 ]
}

@test "version comparison works" {
    cd "$PROJECT_ROOT"
    run ./scripts/version.sh compare "1.0.0" "2.0.0"
    [ "$status" -eq 0 ]
    [[ "$output" == *"<"* ]]
}