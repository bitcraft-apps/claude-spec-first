#!/usr/bin/env bats

# Framework Structure Integration Tests
# Tests core framework structure and validation functionality

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

@test "framework directory structure exists" {
    [ -f "$PROJECT_ROOT/CLAUDE.md" ]
    [ -f "$PROJECT_ROOT/framework/VERSION" ]
    [ -d "$PROJECT_ROOT/framework/commands" ]
    [ -d "$PROJECT_ROOT/framework/agents" ]
    [ -d "$PROJECT_ROOT/framework/templates" ]
    [ -x "$PROJECT_ROOT/framework/validate-framework.sh" ]
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

@test "planning agent exists and is properly configured" {
    [ -f "$PROJECT_ROOT/framework/agents/plan.md" ]
    
    # Check YAML frontmatter
    grep -q "name: csf-plan" "$PROJECT_ROOT/framework/agents/plan.md"
    grep -q "description:" "$PROJECT_ROOT/framework/agents/plan.md"
    grep -q "tools: Read, Grep, Glob" "$PROJECT_ROOT/framework/agents/plan.md"
}

@test "planning command exists and delegates properly" {
    [ -f "$PROJECT_ROOT/framework/commands/plan.md" ]
    
    # Check YAML frontmatter  
    grep -q "description:" "$PROJECT_ROOT/framework/commands/plan.md"
    
    # Check delegation to csf-plan agent
    grep -q "csf-plan" "$PROJECT_ROOT/framework/commands/plan.md"
    grep -q '\$ARGUMENTS' "$PROJECT_ROOT/framework/commands/plan.md"
}

@test "planning agent has built-in file persistence instructions" {
    # Verify csf-plan agent has file persistence capabilities
    grep -q "File Input/Output Requirements" "$PROJECT_ROOT/framework/agents/plan.md"
    grep -q "\.csf/current/plan\.md" "$PROJECT_ROOT/framework/agents/plan.md"
    grep -q "Write tool" "$PROJECT_ROOT/framework/agents/plan.md"
    
    # Verify agent has comprehensive planning guidance: at least 20 non-empty instruction lines after "## Output Format"
    output_format_line=$(grep -n "^## Output Format" "$PROJECT_ROOT/framework/agents/plan.md" | cut -d: -f1)
    instruction_lines=$(tail -n +"$((output_format_line + 1))" "$PROJECT_ROOT/framework/agents/plan.md" | grep -v '^\s*$' | grep -v '^#' | wc -l)
    [ "$instruction_lines" -ge 20 ]
}