#!/usr/bin/env bats

# Complete Workflow E2E Tests
# Tests the full spec-first development workflow from start to finish

# Load helpers
load '../test-helper'

setup() {
    setup_e2e_test
}

teardown() {
    teardown_e2e_test
}

@test "complete framework installation and validation workflow" {
    # Create clean environment
    HOME_DIR="$TEST_DIR/home"
    create_mock_home "$HOME_DIR"
    
    # Step 1: Install framework
    cd "$PROJECT_ROOT"
    run env HOME="$HOME_DIR" ./scripts/install.sh
    assert_success
    
    # Step 2: Verify installation structure  
    assert_files_exist "$HOME_DIR/.claude" \
        ".csf/VERSION" \
        "utils/version.sh" \
        ".csf/validate-framework.sh"
    
    assert_directory_structure "$HOME_DIR/.claude" \
        "commands/csf" \
        "agents/csf"
    
    # Step 3: Test installed version utilities
    cd "$HOME_DIR/.claude"
    
    run ./utils/version.sh get
    assert_success
    assert_version_format "$output"
    
    # Step 4: Test version operations
    ORIGINAL_VERSION="$output"
    
    run ./utils/version.sh increment patch
    assert_success
    assert_output_contains "SUCCESS"
    
    run ./utils/version.sh get
    assert_success
    NEW_VERSION="$output"
    
    # Verify version changed
    [ "$NEW_VERSION" != "$ORIGINAL_VERSION" ]
    
    # Step 5: Test framework validation
    run ./.csf/validate-framework.sh
    assert_success
    assert_output_contains "Framework Version:"
    assert_output_contains "Framework validation PASSED"
    
    # Step 6: Reset version
    run ./utils/version.sh set "$ORIGINAL_VERSION"
    assert_success
    
    run ./utils/version.sh get
    assert_success
    [ "$output" = "$ORIGINAL_VERSION" ]
}

@test "version lifecycle management workflow" {
    # Setup installation
    HOME_DIR="$TEST_DIR/home"
    create_mock_home "$HOME_DIR"
    
    cd "$PROJECT_ROOT"
    env HOME="$HOME_DIR" ./scripts/install.sh >/dev/null 2>&1
    
    cd "$HOME_DIR/.claude"
    
    # Get starting version
    STARTING_VERSION=$(./utils/version.sh get)
    
    # Test patch increment
    run ./utils/version.sh increment patch
    assert_success
    
    PATCH_VERSION=$(./utils/version.sh get)
    
    # Test minor increment
    run ./utils/version.sh increment minor
    assert_success
    
    MINOR_VERSION=$(./utils/version.sh get)
    
    # Test major increment  
    run ./utils/version.sh increment major
    assert_success
    
    MAJOR_VERSION=$(./utils/version.sh get)
    
    # Verify progression
    run ./utils/version.sh compare "$STARTING_VERSION" "$PATCH_VERSION"
    assert_success
    assert_output_contains "<"
    
    run ./utils/version.sh compare "$PATCH_VERSION" "$MINOR_VERSION"
    assert_success
    assert_output_contains "<"
    
    run ./utils/version.sh compare "$MINOR_VERSION" "$MAJOR_VERSION"
    assert_success
    assert_output_contains "<"
    
    # Test validation of all versions
    for version in "$STARTING_VERSION" "$PATCH_VERSION" "$MINOR_VERSION" "$MAJOR_VERSION"; do
        run ./utils/version.sh validate "$version"
        assert_success
    done
}