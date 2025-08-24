#!/bin/bash
# Agent Delegation Verification Tests
# Tests TC007-TC009: Task tool routing to specialized sub-agents

set -euo pipefail

# Test configuration
FRAMEWORK_DIR="$HOME/.claude"
TEST_DIR="/tmp/agent-test-$$"
PASSED=0
FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

setup_test() {
    mkdir -p "$TEST_DIR"
    echo "Setting up agent delegation tests..."
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

# TC007: Test Task tool agent resolution for all required agents
test_agent_availability() {
    echo "Testing agent availability..."
    
    local agents=("spec-analyst" "test-designer" "arch-designer" "impl-specialist" "qa-validator" "doc-synthesizer")
    local result="PASS"
    
    for agent in "${agents[@]}"; do
        if [[ ! -f "$FRAMEWORK_DIR/agents/$agent.md" ]]; then
            echo "Missing agent: $agent"
            result="FAIL"
        fi
    done
    
    print_result "Agent availability check" "$result"
}

# TC008: Test agent YAML frontmatter and tool specifications  
test_agent_configuration() {
    echo "Testing agent configuration..."
    
    local result="PASS"
    
    for agent_file in "$FRAMEWORK_DIR"/agents/*.md; do
        if [[ -f "$agent_file" ]]; then
            # Check for required YAML frontmatter fields
            if ! grep -q "^name:" "$agent_file"; then
                echo "Missing 'name' field in $(basename "$agent_file")"
                result="FAIL"
            fi
            if ! grep -q "^description:" "$agent_file"; then
                echo "Missing 'description' field in $(basename "$agent_file")"
                result="FAIL"
            fi
            if ! grep -q "^tools:" "$agent_file"; then
                echo "Missing 'tools' field in $(basename "$agent_file")"
                result="FAIL"
            fi
        fi
    done
    
    print_result "Agent configuration check" "$result"
}

# TC009: Test agent delegation patterns
test_agent_delegation() {
    echo "Testing agent delegation patterns..."
    
    local result="PASS"
    
    # Check if spec-analyst exists and has proper structure
    if [[ -f "$FRAMEWORK_DIR/agents/spec-analyst.md" ]]; then
        # Verify it contains specification-related content
        if ! grep -i -q "requirement\|specification" "$FRAMEWORK_DIR/agents/spec-analyst.md"; then
            echo "spec-analyst doesn't contain requirements/specification content"
            result="FAIL"
        fi
    else
        echo "spec-analyst.md not found"
        result="FAIL"
    fi
    
    print_result "Agent delegation patterns" "$result"
}

# Main test execution
main() {
    echo "=== Agent Delegation Verification Tests ==="
    echo
    
    setup_test
    trap cleanup_test EXIT
    
    test_agent_availability
    test_agent_configuration  
    test_agent_delegation
    
    echo
    echo "=== Test Results ==="
    echo -e "Passed: ${GREEN}$PASSED${NC}"
    echo -e "Failed: ${RED}$FAILED${NC}"
    
    if [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}All agent delegation tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

main "$@"