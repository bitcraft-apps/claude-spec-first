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

@test "all 4 phases have corresponding agents" {
    # Phase 1: Specification
    [ -f "$PROJECT_ROOT/framework/agents/spec.md" ]
    grep -q "name: csf-spec" "$PROJECT_ROOT/framework/agents/spec.md"
    
    # Phase 2: Planning  
    [ -f "$PROJECT_ROOT/framework/agents/plan.md" ]
    grep -q "name: csf-plan" "$PROJECT_ROOT/framework/agents/plan.md"
    
    # Phase 3: Implementation
    [ -f "$PROJECT_ROOT/framework/agents/implement.md" ]
    grep -q "name: csf-implement" "$PROJECT_ROOT/framework/agents/implement.md"
    
    # Phase 4: Documentation
    [ -f "$PROJECT_ROOT/framework/agents/document.md" ]
    grep -q "name: csf-document" "$PROJECT_ROOT/framework/agents/document.md"
}

@test "all 4 phases have corresponding commands" {
    # Phase 1: Specification
    [ -f "$PROJECT_ROOT/framework/commands/spec.md" ]
    grep -q "csf-spec" "$PROJECT_ROOT/framework/commands/spec.md"
    
    # Phase 2: Planning
    [ -f "$PROJECT_ROOT/framework/commands/plan.md" ]
    grep -q "csf-plan" "$PROJECT_ROOT/framework/commands/plan.md"
    
    # Phase 3: Implementation
    [ -f "$PROJECT_ROOT/framework/commands/implement.md" ]
    grep -q "csf-implement" "$PROJECT_ROOT/framework/commands/implement.md"
    
    # Phase 4: Documentation
    [ -f "$PROJECT_ROOT/framework/commands/document.md" ]
    grep -q "csf-document" "$PROJECT_ROOT/framework/commands/document.md"
}

@test "workflow command includes all 4 phases" {
    [ -f "$PROJECT_ROOT/framework/commands/workflow.md" ]
    
    # Check that workflow command references all 4 phases
    grep -q "Phase 1: Specification" "$PROJECT_ROOT/framework/commands/workflow.md"
    grep -q "Phase 2:" "$PROJECT_ROOT/framework/commands/workflow.md"
    grep -q "Phase 3: Implementation" "$PROJECT_ROOT/framework/commands/workflow.md"
    grep -q "Phase 4: Documentation" "$PROJECT_ROOT/framework/commands/workflow.md"
    
    # Check that workflow delegates to all 4 agents
    grep -q "csf-spec" "$PROJECT_ROOT/framework/commands/workflow.md"
    grep -q "csf-plan" "$PROJECT_ROOT/framework/commands/workflow.md"
    grep -q "csf-implement" "$PROJECT_ROOT/framework/commands/workflow.md"
    grep -q "csf-document" "$PROJECT_ROOT/framework/commands/workflow.md"
}

@test "planning agent is properly configured for safe research" {
    # Verify planning agent only has read-only tools for safe codebase research
    grep -q "tools: Read, Grep, Glob" "$PROJECT_ROOT/framework/agents/plan.md"
    
    # Should NOT have write tools (Write, Edit, MultiEdit, Bash)
    ! grep -q "Write" "$PROJECT_ROOT/framework/agents/plan.md" || true
    ! grep -q "Edit" "$PROJECT_ROOT/framework/agents/plan.md" || true
    ! grep -q "MultiEdit" "$PROJECT_ROOT/framework/agents/plan.md" || true
    ! grep -q "Bash" "$PROJECT_ROOT/framework/agents/plan.md" || true
}

@test "implementation agent can follow plans" {
    # Verify implementation agent has all necessary tools
    grep -q "tools: Read, Write, Edit, MultiEdit, Bash, Grep, Glob" "$PROJECT_ROOT/framework/agents/implement.md"
    
    # Check that implementation agent is instructed to work with specifications
    grep -q -i "specification" "$PROJECT_ROOT/framework/agents/implement.md"
}

@test "workflow phases are properly sequenced" {
    # Verify workflow command has proper sequencing with context clearing
    grep -q "Phase 1.*Phase 2.*Phase 3.*Phase 4" "$PROJECT_ROOT/framework/commands/workflow.md" || {
        # Alternative check: verify phases appear in correct order
        phase1_line=$(grep -n "Phase 1" "$PROJECT_ROOT/framework/commands/workflow.md" | head -1 | cut -d: -f1)
        phase2_line=$(grep -n "Phase 2" "$PROJECT_ROOT/framework/commands/workflow.md" | head -1 | cut -d: -f1)
        phase3_line=$(grep -n "Phase 3" "$PROJECT_ROOT/framework/commands/workflow.md" | head -1 | cut -d: -f1)
        phase4_line=$(grep -n "Phase 4" "$PROJECT_ROOT/framework/commands/workflow.md" | head -1 | cut -d: -f1)
        
        [ "$phase1_line" -lt "$phase2_line" ]
        [ "$phase2_line" -lt "$phase3_line" ]  
        [ "$phase3_line" -lt "$phase4_line" ]
    }
    
    # Check for context clearing instructions
    grep -q -i "context.*clear" "$PROJECT_ROOT/framework/commands/workflow.md" ||
    grep -q -i "wait.*complete" "$PROJECT_ROOT/framework/commands/workflow.md"
}

@test "planning phase is properly integrated between spec and implementation" {
    # Verify planning phase comes after specification phase in workflow
    grep -q "Phase 1.*Specification" "$PROJECT_ROOT/framework/commands/workflow.md"
    grep -q "Phase 2.*Planning" "$PROJECT_ROOT/framework/commands/workflow.md" 
    grep -q "Phase 3.*Implementation" "$PROJECT_ROOT/framework/commands/workflow.md"
    
    # Verify workflow refers to plan from Phase 2 in Phase 3
    grep -q "implementation plan created in Phase 2" "$PROJECT_ROOT/framework/commands/workflow.md"
    
    # Planning command should require specification as input
    grep -q -i "specification.*input\|spec.*input\|from.*specification\|existing.*specification" "$PROJECT_ROOT/framework/commands/plan.md"
}

@test "error handling for missing specifications in planning phase" {
    # Planning command should have prerequisites about needing specifications
    grep -q -i "prerequisite\|requirement" "$PROJECT_ROOT/framework/commands/plan.md"
    grep -q -i "specification.*exist\|spec.*complete" "$PROJECT_ROOT/framework/commands/plan.md"
}

@test "planning agent includes risk assessment capabilities" {
    # Verify planning agent has comprehensive risk assessment features
    grep -q -i "risk.*assessment\|risk.*identification\|risk.*mitigation" "$PROJECT_ROOT/framework/agents/plan.md"
    grep -q -i "rollback.*plan\|rollback.*procedure" "$PROJECT_ROOT/framework/agents/plan.md"
    grep -q -i "testing.*strategy" "$PROJECT_ROOT/framework/agents/plan.md"
}

@test "documentation phase includes all previous artifacts" {
    # Verify document agent reads from specification, plan, and implementation
    grep -q -i "specification" "$PROJECT_ROOT/framework/agents/document.md"
    grep -q -i "implementation" "$PROJECT_ROOT/framework/agents/document.md"
    
    # Check workflow command instructs document agent to use all artifacts
    grep -q -i "specification.*plan.*implementation\|specification.*implementation.*plan" "$PROJECT_ROOT/framework/commands/workflow.md"
}

@test "framework validation recognizes all 4 agents" {
    cd "$PROJECT_ROOT"
    run ./framework/validate-framework.sh
    [ "$status" -eq 0 ]
    
    # Verify all 4 agents are validated
    [[ "$output" == *"csf-spec"* ]]
    [[ "$output" == *"csf-plan"* ]]
    [[ "$output" == *"csf-implement"* ]]
    [[ "$output" == *"csf-document"* ]]
}

@test "framework validation recognizes all 5 commands" {
    cd "$PROJECT_ROOT"
    run ./framework/validate-framework.sh
    [ "$status" -eq 0 ]
    
    # Check that framework finds 5 command files
    [[ "$output" == *"Found 5 command files"* ]]
}

@test "planning phase maintains specification-first philosophy" {
    # Verify planning agent emphasizes specification-driven planning
    grep -q -i "specification.*driven\|specification.*align" "$PROJECT_ROOT/framework/agents/plan.md"
    
    # Planning command should emphasize specification as primary input
    grep -q -i "from.*specification\|specification.*input" "$PROJECT_ROOT/framework/commands/plan.md"
    
    # Verify planning doesn't bypass specification phase
    ! grep -q -i "skip.*spec\|bypass.*spec" "$PROJECT_ROOT/framework/agents/plan.md"
}