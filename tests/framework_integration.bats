#!/usr/bin/env bats

# Integration Test for Versioning System MVP
# Tests the complete versioning system in both repository and installed modes

# Load bats helpers
load 'test_helper'

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

@test "framework directory structure exists" {
    [ -f "$PROJECT_ROOT/CLAUDE.md" ]
    [ -f "$PROJECT_ROOT/framework/VERSION" ]
    [ -d "$PROJECT_ROOT/framework/commands" ]
    [ -d "$PROJECT_ROOT/framework/agents" ]
    [ -x "$PROJECT_ROOT/framework/validate-framework.sh" ]
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

@test "framework validation includes version" {
    cd "$PROJECT_ROOT"
    run ./framework/validate-framework.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Framework Version:"* ]]
}

@test "framework validation passes" {
    cd "$PROJECT_ROOT"
    run ./framework/validate-framework.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Framework validation PASSED"* ]]
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