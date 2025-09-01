#!/usr/bin/env bats

# 4-Phase Workflow Integration Tests
# Tests the complete specification → planning → implementation → documentation workflow

# Detect project root directory
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

setup() {
    # Create clean test environment
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    cd "$TEST_DIR"
    
    # Create a minimal project structure for testing
    mkdir -p src docs/specifications docs/plans
    
    # Create a simple package.json for testing
    cat > package.json << 'EOF'
{
    "name": "test-project",
    "version": "1.0.0",
    "scripts": {
        "test": "echo 'No tests specified'"
    }
}
EOF

    # Create a basic source file
    cat > src/index.js << 'EOF'
function greet(name) {
    return `Hello, ${name}!`;
}

module.exports = { greet };
EOF
}

teardown() {
    # Cleanup test environment
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

@test "all phases have corresponding agents" {
    # Phase 1: Specification micro-agents
    [ -f "$PROJECT_ROOT/framework/agents/define-scope.md" ]
    grep -q "name: define-scope" "$PROJECT_ROOT/framework/agents/define-scope.md"
    
    [ -f "$PROJECT_ROOT/framework/agents/create-criteria.md" ]
    grep -q "name: create-criteria" "$PROJECT_ROOT/framework/agents/create-criteria.md"
    
    [ -f "$PROJECT_ROOT/framework/agents/identify-risks.md" ]
    grep -q "name: identify-risks" "$PROJECT_ROOT/framework/agents/identify-risks.md"
    
    [ -f "$PROJECT_ROOT/framework/agents/synthesize-spec.md" ]
    grep -q "name: synthesize-spec" "$PROJECT_ROOT/framework/agents/synthesize-spec.md"
    
    # Phase 2: Implementation micro-agents
    [ -f "$PROJECT_ROOT/framework/agents/explore-patterns.md" ]
    grep -q "name: explore-patterns" "$PROJECT_ROOT/framework/agents/explore-patterns.md"
    [ -f "$PROJECT_ROOT/framework/agents/implement-minimal.md" ]
    grep -q "name: implement-minimal" "$PROJECT_ROOT/framework/agents/implement-minimal.md"
    
    # Phase 3: Documentation
    [ -f "$PROJECT_ROOT/framework/agents/document.md" ]
    grep -q "name: csf-document" "$PROJECT_ROOT/framework/agents/document.md"
}

@test "all phases have corresponding commands" {
    # Phase 1: Specification
    [ -f "$PROJECT_ROOT/framework/commands/spec.md" ]
    grep -q "spec" "$PROJECT_ROOT/framework/commands/spec.md"
    
    # Phase 2: Implementation
    [ -f "$PROJECT_ROOT/framework/commands/implement.md" ]
    grep -q "explore-patterns" "$PROJECT_ROOT/framework/commands/implement.md"
    grep -q "implement-minimal" "$PROJECT_ROOT/framework/commands/implement.md"
    
    # Phase 3: Documentation
    [ -f "$PROJECT_ROOT/framework/commands/document.md" ]
    grep -q "csf-document" "$PROJECT_ROOT/framework/commands/document.md"
}

@test "spec command orchestrates micro-agents" {
    # Check that spec command references micro-agents
    grep -q "define-scope" "$PROJECT_ROOT/framework/commands/spec.md"
    grep -q "create-criteria" "$PROJECT_ROOT/framework/commands/spec.md"
    grep -q "identify-risks" "$PROJECT_ROOT/framework/commands/spec.md"
    grep -q "synthesize-spec" "$PROJECT_ROOT/framework/commands/spec.md"
}

@test "micro-agents are properly configured for safe research" {
    # Verify micro-agents have minimal tool sets
    grep -q "tools: Write" "$PROJECT_ROOT/framework/agents/define-scope.md"
    grep -q "tools: Write" "$PROJECT_ROOT/framework/agents/create-criteria.md"
    grep -q "tools: Write" "$PROJECT_ROOT/framework/agents/identify-risks.md"
    grep -q "tools: Read, Write" "$PROJECT_ROOT/framework/agents/synthesize-spec.md"
}

@test "implementation micro-agents have appropriate tools" {
    # Verify explore-patterns has research tools
    grep -q "tools: Read, Grep, Glob" "$PROJECT_ROOT/framework/agents/explore-patterns.md"
    
    # Verify implement-minimal has implementation tools
    grep -q "tools: Read, Write, Edit, MultiEdit, Bash" "$PROJECT_ROOT/framework/agents/implement-minimal.md"
    
    # Check that implement-minimal works with specifications
    grep -q -i "spec" "$PROJECT_ROOT/framework/agents/implement-minimal.md"
}

@test "specification micro-agents execute in parallel" {
    # Verify spec command uses parallel execution
    grep -q "Batch 1.*Parallel" "$PROJECT_ROOT/framework/commands/spec.md"
    
    # Verify micro-agents are listed
    grep -q "define-scope" "$PROJECT_ROOT/framework/commands/spec.md"
    grep -q "create-criteria" "$PROJECT_ROOT/framework/commands/spec.md"
    grep -q "identify-risks" "$PROJECT_ROOT/framework/commands/spec.md"
}

@test "micro-agents follow minimalist principles" {
    # Verify micro-agents enforce MVP principles
    grep -q "MVP" "$PROJECT_ROOT/framework/agents/define-scope.md"
    grep -q "YAGNI" "$PROJECT_ROOT/framework/agents/define-scope.md"
    grep -q "KISS" "$PROJECT_ROOT/framework/agents/create-criteria.md"
}

@test "synthesize-spec reads from research outputs" {
    # Verify synthesize-spec agent reads from micro-agent outputs
    grep -q ".csf/research" "$PROJECT_ROOT/framework/agents/synthesize-spec.md"
    grep -q "Inputs.*\.csf/research/\*.md" "$PROJECT_ROOT/framework/agents/synthesize-spec.md"
}

@test "implementation follows sequential workflow" {
    # Verify implement command uses sequential execution (Step 1, Step 2)
    grep -q "Step 1.*Learn" "$PROJECT_ROOT/framework/commands/implement.md"
    grep -q "Step 2.*Implement" "$PROJECT_ROOT/framework/commands/implement.md"
    
    # Verify the philosophy of pattern-first implementation
    grep -q "Pattern consistency over creativity" "$PROJECT_ROOT/framework/commands/implement.md"
    grep -q "Working code over perfect code" "$PROJECT_ROOT/framework/commands/implement.md"
}

@test "risk agent focuses on essential risks" {
    # Verify risk agent focuses on blockers, not comprehensive risks
    grep -q -i "essential risks" "$PROJECT_ROOT/framework/agents/identify-risks.md"
    grep -q "blockers" "$PROJECT_ROOT/framework/agents/identify-risks.md"
    grep -q "simple solutions" "$PROJECT_ROOT/framework/agents/identify-risks.md"
}

@test "documentation phase includes specification and implementation" {
    # Verify document agent reads from specification and implementation
    grep -q -i "specification" "$PROJECT_ROOT/framework/agents/document.md"
    grep -q -i "implementation" "$PROJECT_ROOT/framework/agents/document.md"
}

@test "framework validation recognizes all micro-agents" {
    cd "$PROJECT_ROOT"
    run ./framework/validate-framework.sh
    [ "$status" -eq 0 ]
    
    # Verify micro-agents are validated
    [[ "$output" == *"define-scope"* ]]
    [[ "$output" == *"create-criteria"* ]]
    [[ "$output" == *"identify-risks"* ]]
    [[ "$output" == *"synthesize-spec"* ]]
}

@test "framework validation recognizes all 3 commands" {
    cd "$PROJECT_ROOT"
    run ./framework/validate-framework.sh
    [ "$status" -eq 0 ]
    
    # Check that framework finds 3 command files (spec, implement, document)
    [[ "$output" == *"Found 3 command files"* ]]
}

@test "specification maintains minimalist philosophy" {
    # Verify spec command maintains specification-first philosophy
    grep -q "specification" "$PROJECT_ROOT/framework/commands/spec.md"
    
    # Verify synthesize-spec enforces line limits
    grep -q "under 50 lines" "$PROJECT_ROOT/framework/agents/synthesize-spec.md"
}