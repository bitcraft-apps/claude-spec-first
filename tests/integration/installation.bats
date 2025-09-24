#!/usr/bin/env bats

# Installation Integration Tests
# Tests framework installation and post-installation functionality

# Detect project root directory
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

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

@test "installation creates proper structure" {
    # Create mock home directory
    HOME_DIR="$TEST_DIR/home"
    mkdir -p "$HOME_DIR"
    
    # Run installation with specific home directory
    cd "$PROJECT_ROOT"
    run env HOME="$HOME_DIR" ./scripts/install.sh
    [ "$status" -eq 0 ]
    
    # Verify installation files exist in correct locations
    [ -f "$HOME_DIR/.claude/.csf/VERSION" ]
    [ -x "$HOME_DIR/.claude/.csf/validate-framework.sh" ]
    [ -d "$HOME_DIR/.claude/commands/csf" ]
    [ -d "$HOME_DIR/.claude/agents/csf" ]
}

@test "installed validation utilities work" {
    # Create and install to mock home
    HOME_DIR="$TEST_DIR/home"
    mkdir -p "$HOME_DIR"

    cd "$PROJECT_ROOT"
    env HOME="$HOME_DIR" ./scripts/install.sh >/dev/null 2>&1

    # Test installed validation script shows version
    cd "$HOME_DIR/.claude"
    run ./.csf/validate-framework.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Framework Version:"* ]]
    [[ "$output" == *"Framework validation PASSED"* ]]
}

@test "framework validation is resilient after installation" {
    # Create and install to mock home
    HOME_DIR="$TEST_DIR/home"
    mkdir -p "$HOME_DIR"

    cd "$PROJECT_ROOT"
    env HOME="$HOME_DIR" ./scripts/install.sh >/dev/null 2>&1

    cd "$HOME_DIR/.claude"

    # Test validation works multiple times (resilience test)
    for i in {1..3}; do
        run ./.csf/validate-framework.sh
        [ "$status" -eq 0 ]
        [[ "$output" == *"Framework Version:"* ]]
        [[ "$output" == *"Framework validation PASSED"* ]]
    done
    [ "$status" -eq 0 ]
}

@test "installed validation works" {
    # Create and install to mock home
    HOME_DIR="$TEST_DIR/home"
    mkdir -p "$HOME_DIR"
    
    cd "$PROJECT_ROOT"
    env HOME="$HOME_DIR" ./scripts/install.sh >/dev/null 2>&1
    
    cd "$HOME_DIR/.claude"
    run ./.csf/validate-framework.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Framework Version:"* ]]
    [[ "$output" == *"Framework validation PASSED"* ]]
}

@test "framework handles missing VERSION file gracefully" {
    # Create and install to mock home
    HOME_DIR="$TEST_DIR/home"
    mkdir -p "$HOME_DIR"
    
    cd "$PROJECT_ROOT"
    env HOME="$HOME_DIR" ./scripts/install.sh >/dev/null 2>&1
    
    cd "$HOME_DIR/.claude"
    
    # Backup and remove VERSION file (it's in .csf subdirectory)
    mv .csf/VERSION .csf/VERSION.backup
    
    # Test that framework still works (should show warning but not crash)
    run ./.csf/validate-framework.sh
    [ "$status" -ne 0 ] # Should fail validation without VERSION
    [[ "$output" == *"Framework Version: unknown"* ]]
    
    # Restore VERSION file
    mv .csf/VERSION.backup .csf/VERSION
}