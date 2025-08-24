#!/bin/bash

# Framework Integrity Validation Test Suite
# Tests TC001-TC003: validate-framework.sh execution with all checks passing

set -e

# Test Framework Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMP_TEST_DIR="$SCRIPT_DIR/temp"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# Color codes for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test utility functions
setup_test_env() {
    rm -rf "$TEMP_TEST_DIR"
    mkdir -p "$TEMP_TEST_DIR"
    cd "$TEMP_TEST_DIR"
}

cleanup_test_env() {
    cd "$SCRIPT_DIR"
    rm -rf "$TEMP_TEST_DIR"
}

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${BLUE}Running: $test_name${NC}"
    
    if $test_function; then
        echo -e "${GREEN}✅ PASS: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL: $test_name${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

expect_failure() {
    local command="$1"
    local expected_message="$2"
    
    if $command 2>&1 | grep -q "$expected_message"; then
        return 0  # Test passes - expected failure occurred
    else
        echo "Expected failure with message: $expected_message"
        return 1  # Test fails - expected failure didn't occur
    fi
}

expect_success() {
    local command="$1"
    
    if $command >/dev/null 2>&1; then
        return 0  # Test passes - expected success
    else
        echo "Expected success but command failed: $command"
        return 1  # Test fails - expected success didn't occur
    fi
}

# TC001: Framework Structure Validation Tests
test_tc001_complete_framework_validation() {
    # Given: A complete and valid framework installation
    setup_test_env
    
    # Create a complete framework structure
    cat > CLAUDE.md << 'EOF'
# Specification-First Development Workflow

## Core Principles
- Specifications before implementation
- Test-driven approach

## Workflow
1. Specification Phase
2. Test Phase
3. Implementation Phase

## Instructions for Claude
- Always ask clarifying questions
EOF

    mkdir -p agents commands examples
    
    # Create all required agents with valid YAML frontmatter
    for agent in spec-analyst test-designer arch-designer impl-specialist qa-validator doc-synthesizer; do
        cat > "agents/$agent.md" << EOF
---
name: $agent
description: Test agent for framework validation
tools: [Read, Write, Edit]
---

# $agent Agent
Test agent content
EOF
    done
    
    # Create all required commands with valid YAML frontmatter
    for command in spec-init spec-review impl-plan qa-check spec-workflow doc-generate; do
        cat > "commands/$command.md" << EOF
---
description: Test command for framework validation
---

# $command Command
Use spec-analyst \$ARGUMENTS
EOF
    done
    
    # Create validation script
    cp "$TEST_ROOT/framework/validate-framework.sh" ./
    chmod +x validate-framework.sh
    
    # When: validate-framework.sh is executed
    # Then: All validation checks should pass
    if ./validate-framework.sh | grep -q "Framework validation PASSED"; then
        return 0
    else
        echo "Expected framework validation to pass, but it failed"
        ./validate-framework.sh
        return 1
    fi
}

test_tc002_missing_critical_components() {
    # Given: A framework with missing critical components
    setup_test_env
    
    # Create minimal structure missing agents directory
    cat > CLAUDE.md << 'EOF'
# Basic CLAUDE.md
EOF
    mkdir -p commands
    
    cp "$TEST_ROOT/framework/validate-framework.sh" ./
    chmod +x validate-framework.sh
    
    # When: validate-framework.sh is executed
    # Then: Validation should fail with specific error about missing agents
    expect_failure "./validate-framework.sh" "agents/ directory exists"
}

test_tc003_invalid_yaml_frontmatter() {
    # Given: Agents with invalid YAML frontmatter
    setup_test_env
    
    cat > CLAUDE.md << 'EOF'
# Specification-First Development Workflow

## Core Principles
## Workflow  
## Instructions for Claude
EOF

    mkdir -p agents commands
    
    # Create agent with invalid YAML (missing closing ---)
    cat > "agents/spec-analyst.md" << 'EOF'
---
name: spec-analyst
description: Test agent
# Missing closing ---

# Spec Analyst Agent
EOF
    
    cp "$TEST_ROOT/framework/validate-framework.sh" ./
    chmod +x validate-framework.sh
    
    # When: validate-framework.sh is executed  
    # Then: Validation should fail with YAML frontmatter error
    expect_failure "./validate-framework.sh" "spec-analyst has YAML frontmatter"
}

# TC002: Validation Script Behavior Tests
test_tc004_validation_script_exit_codes() {
    # Given: Various framework states
    setup_test_env
    
    # Test successful validation returns 0
    cat > CLAUDE.md << 'EOF'
# Specification-First Development Workflow
## Core Principles
## Workflow
## Instructions for Claude
EOF
    
    mkdir -p agents commands
    for agent in spec-analyst test-designer arch-designer impl-specialist qa-validator doc-synthesizer; do
        cat > "agents/$agent.md" << EOF
---
name: $agent
description: Test
tools: [Read]
---
# $agent
EOF
    done
    
    for command in spec-init spec-review impl-plan qa-check spec-workflow doc-generate; do
        cat > "commands/$command.md" << EOF
---
description: Test
---
Use spec-analyst \$ARGUMENTS
EOF
    done
    
    cp "$TEST_ROOT/framework/validate-framework.sh" ./
    chmod +x validate-framework.sh
    
    # When: Framework is complete
    # Then: Exit code should be 0
    if ./validate-framework.sh >/dev/null 2>&1; then
        return 0
    else
        echo "Expected exit code 0 for complete framework"
        return 1
    fi
}

test_tc005_validation_failure_exit_code() {
    # Given: Framework with failures
    setup_test_env
    
    # Create incomplete structure (missing CLAUDE.md)
    mkdir -p agents
    
    cp "$TEST_ROOT/framework/validate-framework.sh" ./
    chmod +x validate-framework.sh
    
    # When: Framework has failures
    # Then: Exit code should be 1  
    if ! ./validate-framework.sh >/dev/null 2>&1; then
        return 0  # Test passes - expected failure
    else
        echo "Expected exit code 1 for incomplete framework"
        return 1
    fi
}

# TC003: Framework File Integrity Tests
test_tc006_claude_md_content_validation() {
    # Given: CLAUDE.md with missing required sections
    setup_test_env
    
    cat > CLAUDE.md << 'EOF'
# Some Random Title
This file is missing required sections.
EOF
    
    mkdir -p agents commands
    cp "$TEST_ROOT/framework/validate-framework.sh" ./
    chmod +x validate-framework.sh
    
    # When: validate-framework.sh checks CLAUDE.md content
    # Then: Should fail on missing required sections
    expect_failure "./validate-framework.sh" "CLAUDE.md contains specification-first principles"
}

test_tc007_agent_tool_validation() {
    # Given: Agent with invalid tool specification
    setup_test_env
    
    cat > CLAUDE.md << 'EOF'
# Specification-First Development Workflow
## Core Principles  
## Workflow
## Instructions for Claude
EOF

    mkdir -p agents commands
    
    cat > "agents/spec-analyst.md" << 'EOF'
---
name: spec-analyst
description: Test agent
tools: [InvalidTool, AnotherInvalidTool]
---

# Spec Analyst
EOF
    
    cp "$TEST_ROOT/framework/validate-framework.sh" ./
    chmod +x validate-framework.sh
    
    # When: Agent specifies invalid tools
    # Then: Should warn about tools field (note: current script is permissive)
    ./validate-framework.sh 2>&1 | grep -q "spec-analyst tools:" || {
        echo "Expected tool validation information"
        return 1
    }
    
    return 0
}

test_tc008_command_delegation_validation() {
    # Given: Command that doesn't delegate to agents
    setup_test_env
    
    cat > CLAUDE.md << 'EOF'
# Specification-First Development Workflow
## Core Principles
## Workflow  
## Instructions for Claude
EOF

    mkdir -p agents commands
    
    # Create agents
    for agent in spec-analyst test-designer arch-designer impl-specialist qa-validator doc-synthesizer; do
        cat > "agents/$agent.md" << EOF
---
name: $agent
description: Test
---
# $agent
EOF
    done
    
    # Create command that doesn't delegate
    cat > "commands/spec-init.md" << 'EOF'
---
description: Test command
---

# Spec Init Command
This command doesn't delegate to any agents.
EOF
    
    cp "$TEST_ROOT/framework/validate-framework.sh" ./
    chmod +x validate-framework.sh
    
    # When: Command doesn't delegate to agents
    # Then: Should warn about missing agent delegation
    ./validate-framework.sh 2>&1 | grep -q "spec-init doesn't delegate to agents" && return 0 || {
        echo "Expected warning about missing agent delegation"
        return 1
    }
}

# Run all tests
echo "🧪 Framework Integrity Validation Test Suite"
echo "============================================="
echo ""

run_test "TC001: Complete Framework Validation" test_tc001_complete_framework_validation
run_test "TC002: Missing Critical Components" test_tc002_missing_critical_components  
run_test "TC003: Invalid YAML Frontmatter" test_tc003_invalid_yaml_frontmatter
run_test "TC004: Validation Script Exit Codes" test_tc004_validation_script_exit_codes
run_test "TC005: Validation Failure Exit Code" test_tc005_validation_failure_exit_code
run_test "TC006: CLAUDE.md Content Validation" test_tc006_claude_md_content_validation
run_test "TC007: Agent Tool Validation" test_tc007_agent_tool_validation
run_test "TC008: Command Delegation Validation" test_tc008_command_delegation_validation

# Cleanup
cleanup_test_env

# Test summary
echo "============================================="
echo "Test Results:"
echo "  Total: $TESTS_RUN"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All Framework Integrity tests PASSED!${NC}"
    exit 0
else
    echo -e "${RED}❌ $TESTS_FAILED Framework Integrity tests FAILED!${NC}"
    exit 1
fi