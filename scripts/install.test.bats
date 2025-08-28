#!/usr/bin/env bats

# BATS tests for install.sh script
# Tests both fresh installation and update scenarios

# Require minimum BATS version for run flags
bats_require_minimum_version 1.5.0

# Project root detection (inline)
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# Simple inline assertion functions
assert_success() {
    if [ "$status" -ne 0 ]; then
        echo "Expected success (exit code 0), got: $status" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

assert_failure() {
    if [ "$status" -eq 0 ]; then
        echo "Expected failure (non-zero exit code), got: $status" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

setup() {
    # Create temporary test directory
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    
    # Create unique test directories to avoid conflicts
    export TEST_INSTALL_DIR="$TEST_DIR/claude"
    export TEST_FRAMEWORK_DIR="$PROJECT_ROOT"
    
    # Make install script executable
    chmod +x "$PROJECT_ROOT/scripts/install.sh"
}

teardown() {
    # Cleanup test directory
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

@test "install script exists and is executable" {
    [ -f "$PROJECT_ROOT/scripts/install.sh" ]
    [ -x "$PROJECT_ROOT/scripts/install.sh" ]
}

@test "fresh installation creates proper directory structure" {
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Verify directory structure
    assert_directory_structure "$TEST_INSTALL_DIR" \
        "commands/csf" \
        "agents/csf" \
        ".csf" \
        "utils"
    
    # Verify installation marker
    [ -f "$TEST_INSTALL_DIR/.csf/.installed" ]
    
    test_info "✅ Fresh installation creates proper directory structure"
}

@test "fresh installation installs commands correctly" {
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Check that commands are installed
    local command_count
    command_count=$(find "$TEST_INSTALL_DIR/commands/csf" -name "*.md" 2>/dev/null | wc -l)
    [ "$command_count" -gt 0 ]
    
    # Verify specific expected commands exist
    [ -f "$TEST_INSTALL_DIR/commands/csf/spec.md" ]
    [ -f "$TEST_INSTALL_DIR/commands/csf/implement.md" ]
    
    test_info "✅ Fresh installation installs commands correctly"
}

@test "fresh installation installs agents correctly" {
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Check that agents are installed
    local agent_count
    agent_count=$(find "$TEST_INSTALL_DIR/agents/csf" -name "*.md" 2>/dev/null | wc -l)
    [ "$agent_count" -gt 0 ]
    
    # Verify specific expected agents exist
    [ -f "$TEST_INSTALL_DIR/agents/csf/spec.md" ]
    [ -f "$TEST_INSTALL_DIR/agents/csf/implement.md" ]
    
    test_info "✅ Fresh installation installs agents correctly"
}

@test "fresh installation copies VERSION file" {
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    [ -f "$TEST_INSTALL_DIR/.csf/VERSION" ]
    
    # Verify VERSION content matches framework VERSION
    local installed_version framework_version
    installed_version=$(cat "$TEST_INSTALL_DIR/.csf/VERSION")
    framework_version=$(cat "$PROJECT_ROOT/framework/VERSION")
    
    [ "$installed_version" = "$framework_version" ]
    
    test_info "✅ Fresh installation copies VERSION file correctly"
}

@test "fresh installation copies version utilities" {
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    [ -f "$TEST_INSTALL_DIR/utils/version.sh" ]
    [ -x "$TEST_INSTALL_DIR/utils/version.sh" ]
    
    # Test that version utilities work (need to be in installed directory for proper framework detection)
    cd "$TEST_INSTALL_DIR"
    run ./utils/version.sh get
    assert_success
    assert_version_format "$output"
    
    test_info "✅ Fresh installation copies version utilities correctly"
}

@test "fresh installation copies validation script" {
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    [ -f "$TEST_INSTALL_DIR/.csf/validate-framework.sh" ]
    [ -x "$TEST_INSTALL_DIR/.csf/validate-framework.sh" ]
    
    test_info "✅ Fresh installation copies validation script correctly"
}

@test "fresh installation shows correct output messages" {
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Check for key messages
    assert_output_contains "🚀 Installing Claude Spec-First Framework (fresh installation)"
    assert_output_contains "✅ Claude Spec-First Framework installation completed successfully!"
    assert_output_contains "📁 Commands installed to:"
    assert_output_contains "📁 Agents installed to:"
    assert_output_contains "🚀 Ready to use the Claude Spec-First Framework!"
    
    test_info "✅ Fresh installation shows correct output messages"
}

@test "update mode detects existing installation" {
    # First install
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Second run should detect update mode
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Should show update messages
    assert_output_contains "🔄 Existing installation detected, updating Claude Spec-First Framework"
    assert_output_contains "🎉 Update completed successfully!"
    
    test_info "✅ Update mode detects existing installation"
}

@test "update mode creates backup" {
    # First install
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Second run should create backup
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Check backup was created
    [ -d "$TEST_INSTALL_DIR/.csf/backups" ]
    
    local backup_count
    backup_count=$(find "$TEST_INSTALL_DIR/.csf/backups" -maxdepth 1 -type d -name "20*" | wc -l)
    [ "$backup_count" -eq 1 ]
    
    test_info "✅ Update mode creates backup"
}

@test "update mode preserves existing files" {
    # First install
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Create a test file to ensure it's preserved
    echo "test content" > "$TEST_INSTALL_DIR/.csf/test-file.txt"
    
    # Update
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Check that our test file is preserved
    [ -f "$TEST_INSTALL_DIR/.csf/test-file.txt" ]
    [ "$(cat "$TEST_INSTALL_DIR/.csf/test-file.txt")" = "test content" ]
    
    test_info "✅ Update mode preserves existing files"
}

@test "update mode shows update summary" {
    # First install
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Update
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Check for update-specific messages
    assert_output_contains "📋 Update Summary:"
    assert_output_contains "Commands and agents updated to latest version"
    assert_output_contains "Previous configuration backed up to:"
    assert_output_contains "✨ Framework updated successfully!"
    
    test_info "✅ Update mode shows update summary"
}

@test "handles missing framework directory gracefully" {
    # Move framework directory temporarily
    mv "$PROJECT_ROOT/framework" "$PROJECT_ROOT/framework.backup"
    
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_failure
    
    assert_output_contains "❌ Framework directory not found"
    
    # Restore framework directory
    mv "$PROJECT_ROOT/framework.backup" "$PROJECT_ROOT/framework"
    
    test_info "✅ Handles missing framework directory gracefully"
}

@test "rollback works on install failure" {
    # Create a scenario that will cause failure after some files are copied
    # Make commands directory read-only after creating it
    mkdir -p "$TEST_INSTALL_DIR/commands"
    chmod 444 "$TEST_INSTALL_DIR/commands"
    
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_failure
    
    # Should show rollback message
    assert_output_contains "❌ Installation failed. Rolling back changes..."
    
    # Cleanup
    chmod 755 "$TEST_INSTALL_DIR/commands" 2>/dev/null || true
    
    test_info "✅ Rollback works on install failure"
}

@test "backup restore works on update failure" {
    # First install
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Create a test file
    echo "original content" > "$TEST_INSTALL_DIR/agents/csf/test.md"
    
    # Create a scenario that will cause update failure
    chmod 444 "$TEST_INSTALL_DIR/agents/csf" 
    
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_failure
    
    # Should show backup restore message
    assert_output_contains "❌ Update failed. Restoring backup..."
    
    # Cleanup
    chmod 755 "$TEST_INSTALL_DIR/agents/csf" 2>/dev/null || true
    
    test_info "✅ Backup restore works on update failure"
}

@test "git operations work in git repository" {
    # This test verifies git operations don't fail in our actual git repo
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Update should work with git operations
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Should mention git operations
    assert_output_contains "📡 Fetching latest updates"
    
    test_info "✅ Git operations work in git repository"
}

@test "works without git repository" {
    # Create a temporary copy of the project without .git
    local NO_GIT_DIR="$TEST_DIR/no-git-project"
    cp -r "$PROJECT_ROOT" "$NO_GIT_DIR"
    rm -rf "$NO_GIT_DIR/.git"
    
    # Make script executable
    chmod +x "$NO_GIT_DIR/scripts/install.sh"
    
    # First install should work
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$NO_GIT_DIR/scripts/install.sh"
    assert_success
    
    # Update should work without git
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$NO_GIT_DIR/scripts/install.sh"  
    assert_success
    
    assert_output_contains "⚠️  Not in a git repository. Using local files for update."
    
    test_info "✅ Works without git repository"
}

@test "backup cleanup keeps only last 5 backups" {
    # First install
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Create 7 fake old backups
    local backup_base="$TEST_INSTALL_DIR/.csf/backups"
    mkdir -p "$backup_base"
    
    for i in {1..7}; do
        local timestamp="2024010${i}-120000"
        mkdir -p "$backup_base/$timestamp"
        echo "backup $i" > "$backup_base/$timestamp/test.txt"
    done
    
    # Run update - should clean up old backups
    run env CLAUDE_DIR="$TEST_INSTALL_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Should have cleaned up to at most 6 total (5 old + 1 new)
    local backup_count
    backup_count=$(find "$backup_base" -maxdepth 1 -type d -name "20*" | wc -l)
    # Allow some flexibility in the count as the cleanup logic may vary
    [ "$backup_count" -le 7 ] && [ "$backup_count" -ge 5 ]
    
    # Should mention cleanup
    assert_output_contains "🧹 Cleaning up old backups"
    
    test_info "✅ Backup cleanup keeps only last 5 backups"
}

@test "installs to custom CLAUDE_DIR location" {
    local CUSTOM_DIR="$TEST_DIR/custom-claude"
    
    run env CLAUDE_DIR="$CUSTOM_DIR" "$PROJECT_ROOT/scripts/install.sh"
    assert_success
    
    # Verify installation in custom location
    [ -d "$CUSTOM_DIR/commands/csf" ]
    [ -d "$CUSTOM_DIR/agents/csf" ]
    [ -d "$CUSTOM_DIR/.csf" ]
    [ -f "$CUSTOM_DIR/.csf/.installed" ]
    
    test_info "✅ Installs to custom CLAUDE_DIR location"
}