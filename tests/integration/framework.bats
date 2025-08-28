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

@test "planning templates exist and are complete" {
    [ -d "$PROJECT_ROOT/framework/templates/planning" ]
    [ -f "$PROJECT_ROOT/framework/templates/planning/standard-plan.md" ]
    [ -f "$PROJECT_ROOT/framework/templates/planning/refactoring-plan.md" ]
    [ -f "$PROJECT_ROOT/framework/templates/planning/migration-plan.md" ]
    
    # Verify templates have proper structure
    grep -q "Implementation Plan:" "$PROJECT_ROOT/framework/templates/planning/standard-plan.md"
    grep -q "Refactoring Plan:" "$PROJECT_ROOT/framework/templates/planning/refactoring-plan.md"
    grep -q "Migration Plan:" "$PROJECT_ROOT/framework/templates/planning/migration-plan.md"
}