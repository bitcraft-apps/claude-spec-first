#!/usr/bin/env bats

# CI Pipeline Simulation Tests
# Simulates GitHub Actions workflows locally for testing

# Load helpers
load '../test-helper'

setup() {
    setup_e2e_test
    
    # Set CI environment variables for testing
    export CI=true
    export GITHUB_ACTIONS=true
}

teardown() {
    teardown_e2e_test
    unset CI GITHUB_ACTIONS
}

@test "simulate GitHub Actions setup and validation" {
    # Simulate the checkout step
    cd "$PROJECT_ROOT"
    
    # Simulate submodule initialization (like GHA workflow)
    if [ -d "tests/bats-core/.git" ]; then
        test_info "BATS submodule already initialized"
    else
        run git submodule update --init --recursive
        assert_success
    fi
    
    # Simulate permission setup (like GHA workflow)
    run chmod +x tests/run-tests.sh
    assert_success
    
    run chmod +x tests/bats-core/bin/bats
    assert_success
    
    run chmod +x scripts/version.sh
    assert_success
    
    run chmod +x framework/validate-framework.sh
    assert_success
    
    # Simulate framework validation step
    run ./framework/validate-framework.sh
    assert_success
    assert_output_contains "Framework validation PASSED"
}

@test "simulate CI test execution with TAP output" {
    cd "$PROJECT_ROOT/tests"
    
    # Simulate running tests with TAP output (like GHA)
    run ./run-tests.sh --tap --filter version
    assert_success
    
    # Verify TAP format output
    assert_output_contains "ok "  # TAP success indicators
    assert_output_contains "1.."  # TAP test count
}

@test "simulate multi-stage CI pipeline" {
    cd "$PROJECT_ROOT"
    
    # Stage 1: Framework Validation
    run ./framework/validate-framework.sh
    assert_success
    test_info "✅ Stage 1: Framework validation passed"
    
    # Stage 2: Unit Tests  
    cd tests
    run ./run-tests.sh --tap --filter version
    assert_success
    test_info "✅ Stage 2: Unit tests passed"
    
    # Stage 3: Integration Tests
    run ./run-tests.sh --tap --filter integration
    assert_success
    test_info "✅ Stage 3: Integration tests passed"
    
    # Stage 4: Installation Test
    HOME_DIR="$TEST_DIR/home"
    mkdir -p "$HOME_DIR"
    
    cd "$PROJECT_ROOT"
    run env HOME="$HOME_DIR" ./scripts/install.sh
    assert_success
    test_info "✅ Stage 4: Installation test passed"
    
    # Stage 5: Post-installation Validation
    cd "$HOME_DIR/.claude"
    run ./.csf/validate-framework.sh
    assert_success
    test_info "✅ Stage 5: Post-installation validation passed"
}

@test "simulate cross-platform compatibility checks" {
    cd "$PROJECT_ROOT"
    
    # Test bash version compatibility
    run bash --version
    assert_success
    test_info "Bash version: $(bash --version | head -1)"
    
    # Test git version compatibility  
    run git --version
    assert_success
    test_info "Git version: $(git --version)"
    
    # Test shell compatibility with framework scripts
    run bash -n ./scripts/version.sh
    assert_success
    test_info "✅ version.sh syntax check passed"
    
    run bash -n ./framework/validate-framework.sh  
    assert_success
    test_info "✅ validate-framework.sh syntax check passed"
    
    run bash -n ./tests/run-tests.sh
    assert_success
    test_info "✅ run-tests.sh syntax check passed"
}