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
    [ -x "$HOME_DIR/.claude/utils/version.sh" ]
    [ -x "$HOME_DIR/.claude/.csf/validate-framework.sh" ]
    [ -d "$HOME_DIR/.claude/commands/csf" ]
    [ -d "$HOME_DIR/.claude/agents/csf" ]
}

@test "installed version utilities work" {
    # Create and install to mock home
    HOME_DIR="$TEST_DIR/home"
    mkdir -p "$HOME_DIR"
    
    cd "$PROJECT_ROOT"
    env HOME="$HOME_DIR" ./scripts/install.sh >/dev/null 2>&1
    
    # Test installed utilities (VERSION file is in .csf subdirectory)
    cd "$HOME_DIR/.claude"
    run ./utils/version.sh get
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "version operations work after installation" {
    # Create and install to mock home
    HOME_DIR="$TEST_DIR/home"
    mkdir -p "$HOME_DIR"
    
    cd "$PROJECT_ROOT"
    env HOME="$HOME_DIR" ./scripts/install.sh >/dev/null 2>&1
    
    cd "$HOME_DIR/.claude"
    
    # Get current version
    CURRENT_VERSION=$(./utils/version.sh get)
    
    # Test increment
    run ./utils/version.sh increment patch
    [ "$status" -eq 0 ]
    [[ "$output" == *"SUCCESS"* ]]
    
    # Verify version changed
    NEW_VERSION=$(./utils/version.sh get)
    [ "$NEW_VERSION" != "$CURRENT_VERSION" ]
    
    # Reset version
    run ./utils/version.sh set "$CURRENT_VERSION"
    [ "$status" -eq 0 ]
    
    # Verify reset
    RESET_VERSION=$(./utils/version.sh get)
    [ "$RESET_VERSION" = "$CURRENT_VERSION" ]
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
    
    # Test that version utilities handle missing file
    run ./utils/version.sh get
    [ "$status" -ne 0 ] # Should fail gracefully
    
    # Restore VERSION file
    mv .csf/VERSION.backup .csf/VERSION
}