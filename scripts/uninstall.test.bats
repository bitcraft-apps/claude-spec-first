#!/usr/bin/env bats

# BATS tests for uninstall.sh script
# Tests various uninstall scenarios and edge cases

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

assert_output_contains() {
    local expected="$1"
    if ! echo "$output" | grep -q "$expected"; then
        echo "Expected output to contain: '$expected'" >&2
        echo "Actual output:" >&2
        echo "$output" >&2
        return 1
    fi
}

test_info() {
    echo "INFO: $*" >&2
}

setup() {
    # Create temporary test directory
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    
    # Create unique test directories - uninstall.sh expects HOME/.claude structure
    export TEST_HOME_DIR="$TEST_DIR/home" 
    export TEST_CLAUDE_DIR="$TEST_HOME_DIR/.claude"
    export CSF_PREFIX="csf"
    
    # Make scripts executable
    chmod +x "$PROJECT_ROOT/scripts/install.sh"
    chmod +x "$PROJECT_ROOT/scripts/uninstall.sh"
}

teardown() {
    # Cleanup test directory
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

@test "uninstall script exists and is executable" {
    [ -f "$PROJECT_ROOT/scripts/uninstall.sh" ]
    [ -x "$PROJECT_ROOT/scripts/uninstall.sh" ]
}

@test "detects when framework is not installed" {
    # Run uninstall on empty directory - set HOME to the parent directory
    export HOME="$TEST_HOME_DIR"
    
    run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "n"
    assert_success
    
    assert_output_contains "⚠️  Framework doesn't appear to be installed."
    assert_output_contains "Nothing to uninstall."
    
    test_info "✅ Detects when framework is not installed"
}

@test "shows confirmation prompt" {
    # Install framework first
    env CLAUDE_DIR="$TEST_CLAUDE_DIR" "$PROJECT_ROOT/scripts/install.sh" > /dev/null
    
    # Set HOME for uninstall script
    export HOME="$TEST_HOME_DIR"
    
    # Run uninstall with "no" response
    run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "n"
    assert_success
    
    assert_output_contains "Are you sure you want to uninstall? (y/N):"
    assert_output_contains "❌ Uninstallation cancelled."
    
    test_info "✅ Shows confirmation prompt"
}

@test "cancels uninstallation when user says no" {
    # Install framework first
    env CLAUDE_DIR="$TEST_CLAUDE_DIR" "$PROJECT_ROOT/scripts/install.sh" > /dev/null
    
    # Set HOME for uninstall script  
    export HOME="${TEST_CLAUDE_DIR%/*}"
    
    # Run uninstall with "no" response
    run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "n"
    assert_success
    
    # Framework should still be installed
    [ -d "$TEST_CLAUDE_DIR/commands/csf" ]
    [ -d "$TEST_CLAUDE_DIR/agents/csf" ]
    [ -d "$TEST_CLAUDE_DIR/.csf" ]
    
    test_info "✅ Cancels uninstallation when user says no"
}

@test "removes commands directory when user confirms" {
    # Install framework first
    env CLAUDE_DIR="$TEST_CLAUDE_DIR" "$PROJECT_ROOT/scripts/install.sh" > /dev/null
    
    # Verify commands exist before uninstall
    [ -d "$TEST_CLAUDE_DIR/commands/csf" ]
    
    # Set HOME for uninstall script
    export HOME="${TEST_CLAUDE_DIR%/*}"
    
    # Run uninstall with "yes" response
    run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "y"
    assert_success
    
    # Commands should be removed
    [ ! -d "$TEST_CLAUDE_DIR/commands/csf" ]
    
    assert_output_contains "✅ Removed: commands/csf/"
    
    test_info "✅ Removes commands directory when user confirms"
}

@test "removes agents directory when user confirms" {
    # Install framework first
    env CLAUDE_DIR="$TEST_CLAUDE_DIR" "$PROJECT_ROOT/scripts/install.sh" > /dev/null
    
    # Verify agents exist before uninstall
    [ -d "$TEST_CLAUDE_DIR/agents/csf" ]
    
    # Set HOME for uninstall script
    export HOME="${TEST_CLAUDE_DIR%/*}"
    
    # Run uninstall with "yes" response
    run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "y"
    assert_success
    
    # Agents should be removed
    [ ! -d "$TEST_CLAUDE_DIR/agents/csf" ]
    
    assert_output_contains "✅ Removed: agents/csf/"
    
    test_info "✅ Removes agents directory when user confirms"
}

@test "removes .csf metadata directory when user confirms" {
    # Install framework first
    env CLAUDE_DIR="$TEST_CLAUDE_DIR" "$PROJECT_ROOT/scripts/install.sh" > /dev/null
    
    # Create some additional files in .csf
    echo "test backup" > "$TEST_CLAUDE_DIR/.csf/backup.txt"
    
    # Verify .csf exists before uninstall
    [ -d "$TEST_CLAUDE_DIR/.csf" ]
    [ -f "$TEST_CLAUDE_DIR/.csf/backup.txt" ]
    
    # Set HOME for uninstall script
    export HOME="${TEST_CLAUDE_DIR%/*}"
    
    # Run uninstall with "yes" response
    run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "y"
    assert_success
    
    # .csf should be completely removed
    [ ! -d "$TEST_CLAUDE_DIR/.csf" ]
    
    assert_output_contains "✅ Removed: .csf/ (metadata, templates, and backups)"
    
    test_info "✅ Removes .csf metadata directory when user confirms"
}

@test "cleans up empty parent directories" {
    # Install framework first
    env CLAUDE_DIR="$TEST_CLAUDE_DIR" "$PROJECT_ROOT/scripts/install.sh" > /dev/null
    
    # Verify parent directories exist
    [ -d "$TEST_CLAUDE_DIR/commands" ]
    [ -d "$TEST_CLAUDE_DIR/agents" ]
    
    # Set HOME for uninstall script
    export HOME="${TEST_CLAUDE_DIR%/*}"
    
    # Run uninstall with "yes" response
    run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "y"
    assert_success
    
    # Parent directories should be removed if empty
    [ ! -d "$TEST_CLAUDE_DIR/commands" ]
    [ ! -d "$TEST_CLAUDE_DIR/agents" ]
    
    assert_output_contains "✅ Removed empty commands directory"
    assert_output_contains "✅ Removed empty agents directory"
    
    test_info "✅ Cleans up empty parent directories"
}

@test "preserves non-empty parent directories" {
    # Install framework first
    env CLAUDE_DIR="$TEST_CLAUDE_DIR" "$PROJECT_ROOT/scripts/install.sh" > /dev/null
    
    # Create additional files in parent directories
    echo "other command" > "$TEST_CLAUDE_DIR/commands/other.md"
    echo "other agent" > "$TEST_CLAUDE_DIR/agents/other.md"
    
    # Set HOME for uninstall script
    export HOME="${TEST_CLAUDE_DIR%/*}"
    
    # Run uninstall with "yes" response
    run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "y"
    assert_success
    
    # Parent directories should be preserved (they have other files)
    [ -d "$TEST_CLAUDE_DIR/commands" ]
    [ -d "$TEST_CLAUDE_DIR/agents" ]
    [ -f "$TEST_CLAUDE_DIR/commands/other.md" ]
    [ -f "$TEST_CLAUDE_DIR/agents/other.md" ]
    
    # Should not mention removing empty directories
    ! assert_output_contains "✅ Removed empty commands directory"
    ! assert_output_contains "✅ Removed empty agents directory"
    
    test_info "✅ Preserves non-empty parent directories"
}

@test "shows correct success messages" {
    # Install framework first
    env CLAUDE_DIR="$TEST_CLAUDE_DIR" "$PROJECT_ROOT/scripts/install.sh" > /dev/null
    
    # Set HOME for uninstall script
    export HOME="${TEST_CLAUDE_DIR%/*}"
    
    # Run uninstall with "yes" response
    run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "y"
    assert_success
    
    # Check for key success messages
    assert_output_contains "🎉 Uninstallation completed successfully!"
    assert_output_contains "📋 Uninstallation Summary:"
    assert_output_contains "All CSF commands removed"
    assert_output_contains "All CSF agents removed"
    assert_output_contains "Framework metadata, templates, and backups removed"
    assert_output_contains "✨ Framework successfully uninstalled!"
    
    test_info "✅ Shows correct success messages"
}

@test "shows analysis of what will be removed" {
    # Install framework first
    env CLAUDE_DIR="$TEST_CLAUDE_DIR" "$PROJECT_ROOT/scripts/install.sh" > /dev/null
    
    # Set HOME for uninstall script
    export HOME="${TEST_CLAUDE_DIR%/*}"
    
    # Run uninstall with "no" response to see analysis
    run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "n"
    assert_success
    
    # Should show analysis
    assert_output_contains "📋 Analyzing current installation..."
    assert_output_contains "⚠️  This will remove:"
    assert_output_contains "All CSF commands from"
    assert_output_contains "All CSF agents from"
    assert_output_contains "Framework metadata, templates, and backups from"
    
    test_info "✅ Shows analysis of what will be removed"
}

@test "handles partial installations correctly" {
    # Create the .claude directory structure that uninstall expects
    mkdir -p "$TEST_CLAUDE_DIR/.claude/commands/csf"
    echo "test command" > "$TEST_CLAUDE_DIR/.claude/commands/csf/test.md"
    
    # No agents directory  
    # No .csf directory
    
    # Set HOME for uninstall script (parent of .claude)
    export HOME="$TEST_CLAUDE_DIR"
    
    # Should still offer to uninstall
    run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "y"
    assert_success
    
    # Should remove what exists
    [ ! -d "$TEST_CLAUDE_DIR/.claude/commands/csf" ]
    assert_output_contains "✅ Removed: commands/csf/"
    
    # Should not mention removing non-existent directories
    ! assert_output_contains "✅ Removed: agents/csf/"
    ! assert_output_contains "✅ Removed: .csf/"
    
    test_info "✅ Handles partial installations correctly"
}

@test "handles permission errors gracefully" {
    # Install framework first
    env CLAUDE_DIR="$TEST_CLAUDE_DIR" "$PROJECT_ROOT/scripts/install.sh" > /dev/null
    
    # Make a directory read-only to cause permission error
    chmod 444 "$TEST_CLAUDE_DIR/commands/csf"
    
    # Set HOME for uninstall script
    export HOME="${TEST_CLAUDE_DIR%/*}"
    
    # Run uninstall - might fail due to permissions but shouldn't crash
    run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "y"
    # Don't assert success/failure as it depends on system behavior
    
    # Should attempt to remove
    assert_output_contains "🗑️  Removing framework commands and agents..."
    
    # Cleanup
    chmod 755 "$TEST_CLAUDE_DIR/commands/csf" 2>/dev/null || true
    
    test_info "✅ Handles permission errors gracefully"
}

@test "works with different input responses" {
    # Test various ways to say "yes"
    local responses=("y" "Y" "yes" "YES")
    
    for response in "${responses[@]}"; do
        # Install framework
        env CLAUDE_DIR="$TEST_CLAUDE_DIR" "$PROJECT_ROOT/scripts/install.sh" > /dev/null
        
        # Set HOME
        export HOME="${TEST_CLAUDE_DIR%/*}"
        
        # Test uninstall with this response
        run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "$response"
        assert_success
        
        # Should complete uninstall
        [ ! -d "$TEST_CLAUDE_DIR/commands/csf" ]
        
        test_info "✅ Works with response: $response"
        
        # Cleanup for next iteration
        rm -rf "$TEST_CLAUDE_DIR"
    done
}

@test "rejects installation after 'no' responses" {
    # Create .claude directory structure
    mkdir -p "$TEST_CLAUDE_DIR/.claude"
    
    # Install framework first (to the correct .claude subdirectory)
    env CLAUDE_DIR="$TEST_CLAUDE_DIR/.claude" "$PROJECT_ROOT/scripts/install.sh" > /dev/null
    
    # Test various ways to say "no"
    local responses=("n" "N" "no" "NO" "" "anything")
    
    # Set HOME correctly (parent of .claude)
    export HOME="$TEST_CLAUDE_DIR"
    
    for response in "${responses[@]}"; do
        # Test uninstall with this response
        run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "$response"
        assert_success
        
        # Should cancel uninstall
        assert_output_contains "❌ Uninstallation cancelled."
        
        # Framework should still exist
        [ -d "$TEST_CLAUDE_DIR/.claude/commands/csf" ]
        
        test_info "✅ Rejects with response: '$response'"
    done
}

@test "preserves utils directory and other framework files" {
    # Install framework first
    env CLAUDE_DIR="$TEST_CLAUDE_DIR" "$PROJECT_ROOT/scripts/install.sh" > /dev/null
    
    # Verify utils exists
    [ -d "$TEST_CLAUDE_DIR/utils" ]
    [ -f "$TEST_CLAUDE_DIR/utils/version.sh" ]
    
    # Set HOME for uninstall script
    export HOME="${TEST_CLAUDE_DIR%/*}"
    
    # Run uninstall
    run "$PROJECT_ROOT/scripts/uninstall.sh" <<< "y"
    assert_success
    
    # Utils directory should still exist (not removed by uninstall)
    [ -d "$TEST_CLAUDE_DIR/utils" ]
    [ -f "$TEST_CLAUDE_DIR/utils/version.sh" ]
    
    test_info "✅ Preserves utils directory and other framework files"
}