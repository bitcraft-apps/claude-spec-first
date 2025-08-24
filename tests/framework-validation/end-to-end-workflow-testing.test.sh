#!/bin/bash
# End-to-End Workflow Testing
# Tests TC010-TC012: Complete specification cycles with quality output

set -euo pipefail

# Test configuration
FRAMEWORK_DIR="$HOME/.claude"
TEST_DIR="/tmp/workflow-test-$$"
PASSED=0
FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

setup_test() {
    mkdir -p "$TEST_DIR"
    echo "Setting up end-to-end workflow tests..."
}

cleanup_test() {
    rm -rf "$TEST_DIR"
}

print_result() {
    local test_name="$1"
    local result="$2"
    if [[ "$result" == "PASS" ]]; then
        echo -e "${GREEN}✓ $test_name${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name${NC}"
        ((FAILED++))
    fi
}

# TC010: Test complete specification workflow execution
test_workflow_commands() {
    echo "Testing workflow commands..."
    
    local result="PASS"
    local commands=("spec-init" "spec-review" "impl-plan" "qa-check" "spec-workflow" "doc-generate")
    
    for cmd in "${commands[@]}"; do
        if [[ ! -f "$FRAMEWORK_DIR/commands/$cmd.md" ]]; then
            echo "Missing workflow command: $cmd"
            result="FAIL"
        else
            # Check if command contains $ARGUMENTS placeholder
            if ! grep -q '\$ARGUMENTS' "$FRAMEWORK_DIR/commands/$cmd.md"; then
                echo "Command $cmd missing \$ARGUMENTS placeholder"
                result="FAIL"
            fi
        fi
    done
    
    print_result "Workflow commands availability" "$result"
}

# TC011: Test workflow command structure and delegation
test_command_delegation() {
    echo "Testing command delegation patterns..."
    
    local result="PASS"
    
    # Check spec-init delegates to spec-analyst
    if [[ -f "$FRAMEWORK_DIR/commands/spec-init.md" ]]; then
        if ! grep -i -q "spec-analyst" "$FRAMEWORK_DIR/commands/spec-init.md"; then
            echo "spec-init doesn't reference spec-analyst"
            result="FAIL"
        fi
    fi
    
    # Check impl-plan delegates to arch-designer
    if [[ -f "$FRAMEWORK_DIR/commands/impl-plan.md" ]]; then
        if ! grep -i -q "arch-designer" "$FRAMEWORK_DIR/commands/impl-plan.md"; then
            echo "impl-plan doesn't reference arch-designer"
            result="FAIL"
        fi
    fi
    
    # Check qa-check delegates to qa-validator
    if [[ -f "$FRAMEWORK_DIR/commands/qa-check.md" ]]; then
        if ! grep -i -q "qa-validator" "$FRAMEWORK_DIR/commands/qa-check.md"; then
            echo "qa-check doesn't reference qa-validator"
            result="FAIL"
        fi
    fi
    
    # Check doc-generate delegates to doc-synthesizer
    if [[ -f "$FRAMEWORK_DIR/commands/doc-generate.md" ]]; then
        if ! grep -i -q "doc-synthesizer" "$FRAMEWORK_DIR/commands/doc-generate.md"; then
            echo "doc-generate doesn't reference doc-synthesizer"
            result="FAIL"
        fi
    fi
    
    print_result "Command delegation patterns" "$result"
}

# TC012: Test framework integration completeness
test_framework_integration() {
    echo "Testing framework integration..."
    
    local result="PASS"
    
    # Check main CLAUDE.md exists
    if [[ ! -f "$FRAMEWORK_DIR/CLAUDE.md" ]]; then
        echo "Main CLAUDE.md not found in framework directory"
        result="FAIL"
    fi
    
    # Check examples directory
    if [[ ! -d "$FRAMEWORK_DIR/examples" ]]; then
        echo "Examples directory missing"
        result="FAIL"
    fi
    
    # Check validate script exists and is executable
    if [[ ! -x "$FRAMEWORK_DIR/validate-framework.sh" ]]; then
        echo "validate-framework.sh not found or not executable"
        result="FAIL"
    fi
    
    print_result "Framework integration completeness" "$result"
}

# Test performance and basic functionality
test_validation_performance() {
    echo "Testing validation script performance..."
    
    local result="PASS"
    local start_time
    local end_time
    local duration
    
    if [[ -x "$FRAMEWORK_DIR/validate-framework.sh" ]]; then
        start_time=$(date +%s)
        
        # Run validation script (suppress output for clean test results)
        if "$FRAMEWORK_DIR/validate-framework.sh" >/dev/null 2>&1; then
            end_time=$(date +%s)
            duration=$((end_time - start_time))
            
            # Should complete within reasonable time (30 seconds)
            if [[ $duration -gt 30 ]]; then
                echo "Validation script took too long: ${duration}s (should be < 30s)"
                result="FAIL"
            fi
        else
            echo "Validation script execution failed"
            result="FAIL"
        fi
    else
        echo "Validation script not found or not executable"
        result="FAIL"
    fi
    
    print_result "Validation script performance" "$result"
}

# Main test execution
main() {
    echo "=== End-to-End Workflow Testing ==="
    echo
    
    setup_test
    trap cleanup_test EXIT
    
    test_workflow_commands
    test_command_delegation
    test_framework_integration
    test_validation_performance
    
    echo
    echo "=== Test Results ==="
    echo -e "Passed: ${GREEN}$PASSED${NC}"
    echo -e "Failed: ${RED}$FAILED${NC}"
    
    if [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}All end-to-end workflow tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

main "$@"