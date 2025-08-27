#!/usr/bin/env bats

# Error Recovery and Edge Case E2E Tests  
# Tests how the system handles various error conditions and edge cases

# Load helpers
load '../test-helper'

# Require minimum BATS version for run flags
bats_require_minimum_version 1.5.0

setup() {
    setup_e2e_test
}

teardown() {
    teardown_e2e_test
}

@test "recover from corrupted VERSION file" {
    # Setup installation
    HOME_DIR="$TEST_DIR/home"
    create_mock_home "$HOME_DIR"
    
    cd "$PROJECT_ROOT"
    env HOME="$HOME_DIR" ./scripts/install.sh >/dev/null 2>&1
    
    cd "$HOME_DIR/.claude"
    
    # Corrupt the VERSION file with invalid content
    echo "invalid.version.format" > .csf/VERSION
    
    # Version utilities should handle this gracefully, but still return the content
    run ./utils/version.sh get
    # Note: The get command returns the content even if it's invalid
    assert_success
    [[ "$output" == "invalid.version.format" ]]
    test_info "✅ Returns corrupted VERSION file content"
    
    # Framework validation should report the issue
    run ./.csf/validate-framework.sh
    assert_failure
    test_info "✅ Framework validation detects corrupted VERSION"
    
    # Recovery: Fix the VERSION file
    echo "1.0.0" > .csf/VERSION
    
    run ./utils/version.sh get
    assert_success
    assert_version_format "$output"
    test_info "✅ Recovery successful after fixing VERSION file"
}

@test "handle missing critical files gracefully" {
    # Setup installation  
    HOME_DIR="$TEST_DIR/home"
    create_mock_home "$HOME_DIR"
    
    cd "$PROJECT_ROOT"
    env HOME="$HOME_DIR" ./scripts/install.sh >/dev/null 2>&1
    
    cd "$HOME_DIR/.claude"
    
    # Test missing VERSION file
    mv .csf/VERSION .csf/VERSION.backup
    
    run ./utils/version.sh get
    assert_failure
    test_info "✅ Handles missing VERSION file"
    
    run ./.csf/validate-framework.sh
    assert_failure  
    test_info "✅ Validation detects missing VERSION file"
    
    # Restore VERSION file
    mv .csf/VERSION.backup .csf/VERSION
    
    # Test missing version utilities
    mv utils/version.sh utils/version.sh.backup
    
    run -127 ./utils/version.sh get 2>/dev/null
    # Expect exit code 127 (command not found)
    [ "$status" -eq 127 ]
    test_info "✅ Handles missing version utilities gracefully"
    
    # Restore utilities
    mv utils/version.sh.backup utils/version.sh
}

@test "handle permission issues gracefully" {
    # Setup installation
    HOME_DIR="$TEST_DIR/home"  
    create_mock_home "$HOME_DIR"
    
    cd "$PROJECT_ROOT"
    env HOME="$HOME_DIR" ./scripts/install.sh >/dev/null 2>&1
    
    cd "$HOME_DIR/.claude"
    
    # Remove execute permissions
    chmod -x utils/version.sh
    
    run -126 ./utils/version.sh get 2>/dev/null
    # Expect exit code 126 (permission denied)
    [ "$status" -eq 126 ]
    test_info "✅ Handles missing execute permissions"
    
    # Restore permissions
    chmod +x utils/version.sh
    
    run ./utils/version.sh get
    assert_success
    test_info "✅ Recovers after fixing permissions"
}

@test "handle disk space and write permission issues" {
    # This test simulates scenarios where writes might fail
    
    # Setup installation
    HOME_DIR="$TEST_DIR/home"
    create_mock_home "$HOME_DIR"
    
    cd "$PROJECT_ROOT"
    env HOME="$HOME_DIR" ./scripts/install.sh >/dev/null 2>&1
    
    cd "$HOME_DIR/.claude"
    
    # Make .csf directory read-only to simulate write permission issues
    chmod 555 .csf/
    
    # Attempt to set version (should fail gracefully due to backup creation failure)
    run ./utils/version.sh set "2.0.0"
    assert_failure
    test_info "✅ Handles write permission errors gracefully"
    
    # Restore permissions
    chmod 755 .csf/
    
    # Verify recovery  
    run ./utils/version.sh set "2.0.0"
    assert_success
    test_info "✅ Recovers after fixing permissions"
}

@test "handle concurrent access scenarios" {
    # Setup installation
    HOME_DIR="$TEST_DIR/home"
    create_mock_home "$HOME_DIR"
    
    cd "$PROJECT_ROOT"
    env HOME="$HOME_DIR" ./scripts/install.sh >/dev/null 2>&1
    
    cd "$HOME_DIR/.claude"
    
    # Simulate concurrent version access by rapidly calling version utilities
    # This tests for race conditions and file locking issues
    
    local pids=()
    local results=()
    
    # Start multiple background processes
    for i in {1..5}; do
        (
            sleep 0.1
            ./utils/version.sh get > "$TEST_DIR/result_$i.txt" 2>&1
            echo $? > "$TEST_DIR/status_$i.txt"
        ) &
        pids+=($!)
    done
    
    # Wait for all processes to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Check that all processes succeeded and got consistent results
    local first_result
    local all_consistent=true
    
    for i in {1..5}; do
        local status=$(cat "$TEST_DIR/status_$i.txt")
        local result=$(cat "$TEST_DIR/result_$i.txt")
        
        [ "$status" -eq 0 ] || {
            test_error "Process $i failed with status $status"
            all_consistent=false
        }
        
        if [ -z "$first_result" ]; then
            first_result="$result"
        elif [ "$result" != "$first_result" ]; then
            test_error "Inconsistent results: '$result' != '$first_result'"
            all_consistent=false
        fi
    done
    
    [ "$all_consistent" = true ]
    test_info "✅ Concurrent access handled consistently"
}