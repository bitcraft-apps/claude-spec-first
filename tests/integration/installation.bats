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
    # Create mock project directory
    PROJECT_DIR="$TEST_DIR/project"
    mkdir -p "$PROJECT_DIR"
    echo "# Test Project" > "$PROJECT_DIR/CLAUDE.md"

    # Run installation from project directory
    cd "$PROJECT_DIR"
    run "$PROJECT_ROOT/scripts/install.sh"
    [ "$status" -eq 0 ]

    # Verify installation files exist in correct locations
    [ -f "$PROJECT_DIR/.claude/.csf/VERSION" ]
    [ -x "$PROJECT_DIR/.claude/utils/version.sh" ]
    [ -x "$PROJECT_DIR/.claude/.csf/validate-framework.sh" ]
    [ -d "$PROJECT_DIR/.claude/commands/csf" ]
    [ -d "$PROJECT_DIR/.claude/agents/csf" ]
}

@test "installed version utilities work" {
    # Create and install to mock project
    PROJECT_DIR="$TEST_DIR/project"
    mkdir -p "$PROJECT_DIR"
    echo "# Test Project" > "$PROJECT_DIR/CLAUDE.md"

    cd "$PROJECT_DIR"
    "$PROJECT_ROOT/scripts/install.sh" >/dev/null 2>&1

    # Test installed utilities (VERSION file is in .csf subdirectory)
    cd "$PROJECT_DIR/.claude"
    run ./utils/version.sh get
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "version operations work after installation" {
    # Create and install to mock project
    PROJECT_DIR="$TEST_DIR/project"
    mkdir -p "$PROJECT_DIR"
    echo "# Test Project" > "$PROJECT_DIR/CLAUDE.md"

    cd "$PROJECT_DIR"
    "$PROJECT_ROOT/scripts/install.sh" >/dev/null 2>&1

    cd "$PROJECT_DIR/.claude"
    
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
    # Create and install to mock project
    PROJECT_DIR="$TEST_DIR/project"
    mkdir -p "$PROJECT_DIR"
    echo "# Test Project" > "$PROJECT_DIR/CLAUDE.md"

    cd "$PROJECT_DIR"
    "$PROJECT_ROOT/scripts/install.sh" >/dev/null 2>&1

    cd "$PROJECT_DIR/.claude"
    run ./.csf/validate-framework.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Framework Version:"* ]]
    [[ "$output" == *"Framework validation PASSED"* ]]
}

@test "framework handles missing VERSION file gracefully" {
    # Create and install to mock project
    PROJECT_DIR="$TEST_DIR/project"
    mkdir -p "$PROJECT_DIR"
    echo "# Test Project" > "$PROJECT_DIR/CLAUDE.md"

    cd "$PROJECT_DIR"
    "$PROJECT_ROOT/scripts/install.sh" >/dev/null 2>&1

    cd "$PROJECT_DIR/.claude"
    
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