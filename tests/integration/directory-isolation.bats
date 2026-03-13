#!/usr/bin/env bats

# Directory Isolation Feature Tests
# Tests the new directory isolation functionality added in v0.12.0

# Detect project root directory
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

setup() {
    # Create clean test environment if needed
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    # Clean up test environment
    [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

@test "manage-spec-directory agent exists and is properly configured" {
    [ -f "$PROJECT_ROOT/agents/manage-spec-directory.md" ]

    # Check agent has required metadata
    grep -q "name: manage-spec-directory" "$PROJECT_ROOT/agents/manage-spec-directory.md"
    grep -q "tools: Bash" "$PROJECT_ROOT/agents/manage-spec-directory.md"

    # Check agent handles the three modes
    grep -q '"first"' "$PROJECT_ROOT/agents/manage-spec-directory.md"
    grep -q '"update"' "$PROJECT_ROOT/agents/manage-spec-directory.md"
    grep -q '"new"' "$PROJECT_ROOT/agents/manage-spec-directory.md"
}

@test "manage-spec-directory agent follows framework constraints" {
    # Agent should be under 40 lines (allowing for project-local path detection + gitignore logic)
    local agent_file="$PROJECT_ROOT/agents/manage-spec-directory.md"
    local code_lines=$(sed -n '/```bash/,/```/p' "$agent_file" | grep -v '```' | grep -v '^#' | grep -v '^$' | wc -l)
    [ "$code_lines" -le 40 ]
}

@test "manage-spec-directory agent includes error recovery" {
    local agent_file="$PROJECT_ROOT/agents/manage-spec-directory.md"

    # Check for cleanup on symlink failure
    grep -q "rm -rf.*specs.*timestamp" "$agent_file"

    # Check for mode file cleanup
    grep -q "rm -f.*mode" "$agent_file"
}

@test "spec skill includes directory management step" {
    # Check spec skill references the new agent
    grep -q "manage-spec-directory" "$PROJECT_ROOT/skills/spec/SKILL.md"

    # Check it explains directory management workflow
    grep -q "Directory Management" "$PROJECT_ROOT/skills/spec/SKILL.md"
    grep -q '"Update existing" / "Create new"' "$PROJECT_ROOT/skills/spec/SKILL.md"
}

@test "directory isolation maintains backward compatibility" {
    # Check that synthesize-spec agent mentions symlink awareness
    grep -q "active.*directory\|symlink-aware" "$PROJECT_ROOT/agents/synthesize-spec.md"

    # Check output paths are documented correctly (now uses $CSF_DIR variable)
    grep -q "CSF_DIR/spec\.md.*direct file or symlink" "$PROJECT_ROOT/skills/spec/SKILL.md"
}

@test "manage-spec-directory agent includes gitignore protection" {
    local agent_file="$PROJECT_ROOT/agents/manage-spec-directory.md"

    # Check it guards on .git existence
    grep -q '\.git"' "$agent_file"

    # Check it appends exact pattern .claude/.csf/
    grep -qF '.claude/.csf/' "$agent_file"

    # Check it skips if already present (negated grep guard)
    grep -q '! grep -qF .*.claude/.csf/' "$agent_file"
}

@test "framework validation recognizes manage-spec-directory agent" {
    # Run framework validation and check it counts the correct number of agents (12 total)
    cd "$PROJECT_ROOT"
    ./scripts/validate-plugin.sh 2>&1 | grep -q "Found 12 agent files"

    # Also verify the agent file is actually detected in the agents directory
    [ -f "$PROJECT_ROOT/agents/manage-spec-directory.md" ]
}