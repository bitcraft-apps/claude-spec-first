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

@test "micro-agents exist and are properly configured" {
    # Check all 4 micro-agents exist
    [ -f "$PROJECT_ROOT/framework/agents/define-scope.md" ]
    [ -f "$PROJECT_ROOT/framework/agents/create-criteria.md" ]
    [ -f "$PROJECT_ROOT/framework/agents/identify-risks.md" ]
    [ -f "$PROJECT_ROOT/framework/agents/synthesize-spec.md" ]
    
    # Check YAML frontmatter for define-scope
    grep -q "name: define-scope" "$PROJECT_ROOT/framework/agents/define-scope.md"
    grep -q "description:" "$PROJECT_ROOT/framework/agents/define-scope.md"
    grep -q "tools: Write" "$PROJECT_ROOT/framework/agents/define-scope.md"
}

@test "spec command delegates to micro-agents properly" {
    [ -f "$PROJECT_ROOT/framework/commands/spec.md" ]
    
    # Check YAML frontmatter  
    grep -q "description:" "$PROJECT_ROOT/framework/commands/spec.md"
    
    # Check delegation to micro-agents
    grep -q "define-scope" "$PROJECT_ROOT/framework/commands/spec.md"
    grep -q "create-criteria" "$PROJECT_ROOT/framework/commands/spec.md"
    grep -q "identify-risks" "$PROJECT_ROOT/framework/commands/spec.md"
    grep -q "synthesize-spec" "$PROJECT_ROOT/framework/commands/spec.md"
    grep -q '\$ARGUMENTS' "$PROJECT_ROOT/framework/commands/spec.md"
}

@test "micro-agents have file persistence instructions" {
    # Verify micro-agents write to research directory using literal paths
    grep -q "Output:" "$PROJECT_ROOT/framework/agents/define-scope.md"
    grep -q "\.claude/\.csf/research.*scope.md" "$PROJECT_ROOT/framework/agents/define-scope.md"

    # Verify synthesize-spec reads from research
    grep -q "Inputs:" "$PROJECT_ROOT/framework/agents/synthesize-spec.md"
    grep -q "\.claude/\.csf/research.*\.md" "$PROJECT_ROOT/framework/agents/synthesize-spec.md"

    # Verify micro-agents are focused (small instruction sets)
    line_count=$(wc -l < "$PROJECT_ROOT/framework/agents/define-scope.md")
    [ "$line_count" -le 25 ]
}

