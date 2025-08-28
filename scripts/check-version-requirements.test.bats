#!/usr/bin/env bats

# Unit tests for check-version-requirements.sh
# Tests version requirement detection based on file changes

setup() {
    # Create temporary directory for tests
    export TEST_TEMP_DIR="$(mktemp -d)"
    export ORIGINAL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    
    # Initialize git repo in temp dir
    cd "$TEST_TEMP_DIR"
    git init --quiet
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create basic project structure
    mkdir -p framework/{agents,commands,examples} scripts tests .github/workflows docs
    
    # Create framework files (these should require version bumps)
    echo "# Framework CLAUDE.md" > framework/CLAUDE.md
    echo "0.1.0" > framework/VERSION
    echo "spec-analyst agent" > framework/agents/spec-analyst.md
    echo "spec-init command" > framework/commands/spec-init.md
    echo "framework example" > framework/examples/example.md
    
    # Create scripts
    echo "#!/bin/bash" > scripts/install.sh
    echo "#!/bin/bash" > scripts/uninstall.sh
    echo "#!/bin/bash" > scripts/version.sh
    
    # Create non-version-requiring files
    echo "name: CI" > .github/workflows/ci.yml
    echo "#!/usr/bin/env bats" > tests/example.bats
    echo "# README" > README.md
    echo "# Documentation" > docs/guide.md
    echo "# Installation test" > scripts/install.test.bats
    
    # Copy scripts under test
    cp "$ORIGINAL_DIR/scripts/check-version-requirements.sh" scripts/
    cp "$ORIGINAL_DIR/scripts/version.sh" scripts/
    chmod +x scripts/check-version-requirements.sh
    chmod +x scripts/version.sh
    
    # Create initial commit
    git add .
    git commit -m "Initial commit" --quiet
    git branch -M main
}

teardown() {
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_TEMP_DIR"
}

@test "help message displays correctly" {
    run scripts/check-version-requirements.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Version Requirement Detection Script"* ]]
}

@test "handles no changes" {
    run scripts/check-version-requirements.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"No files changed"* ]]
}

@test "requires version bump for framework files" {
    echo "# Updated framework" > framework/CLAUDE.md
    git add framework/CLAUDE.md
    git commit -m "Update framework" --quiet
    
    run scripts/check-version-requirements.sh
    [ "$status" -ne 0 ]
    [[ "$output" == *"Version bump REQUIRED"* ]]
    [[ "$output" == *"framework/CLAUDE.md"* ]]
}

@test "requires version bump for agent files" {
    echo "updated agent" > framework/agents/spec-analyst.md
    git add framework/agents/spec-analyst.md
    git commit -m "Update agent" --quiet
    
    run scripts/check-version-requirements.sh
    [ "$status" -ne 0 ]
    [[ "$output" == *"Version bump REQUIRED"* ]]
    [[ "$output" == *"framework/agents/spec-analyst.md"* ]]
}

@test "allows changes to install script" {
    echo "#!/bin/bash\necho updated" > scripts/install.sh
    git add scripts/install.sh
    git commit -m "Update install script" --quiet
    
    run scripts/check-version-requirements.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"No version bump required"* ]]
}

@test "allows changes to test files" {
    echo "#!/usr/bin/env bats\n# Updated test" > tests/example.bats
    git add tests/example.bats
    git commit -m "Update test" --quiet
    
    run scripts/check-version-requirements.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"No version bump required"* ]]
}

@test "allows changes to workflow files" {
    echo "name: Updated CI" > .github/workflows/ci.yml
    git add .github/workflows/ci.yml
    git commit -m "Update workflow" --quiet
    
    run scripts/check-version-requirements.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"No version bump required"* ]]
}

@test "allows README changes" {
    echo "# Updated README" > README.md
    git add README.md
    git commit -m "Update README" --quiet
    
    run scripts/check-version-requirements.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"No version bump required"* ]]
}

@test "passes when version bumped for framework changes" {
    echo "# Updated framework" > framework/CLAUDE.md
    echo "0.2.0" > framework/VERSION
    git add .
    git commit -m "Update framework and bump version" --quiet
    
    run scripts/check-version-requirements.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Version bump REQUIRED"* ]]
    [[ "$output" == *"Version bump detected: 0.1.0 → 0.2.0"* ]]
    [[ "$output" == *"Version requirement satisfied"* ]]
}

@test "requires version bump for mixed changes with framework files" {
    echo "# Updated framework" > framework/CLAUDE.md
    echo "# Updated README" > README.md
    git add .
    git commit -m "Mixed updates" --quiet
    
    run scripts/check-version-requirements.sh
    [ "$status" -ne 0 ]
    [[ "$output" == *"Version bump REQUIRED"* ]]
    [[ "$output" == *"framework/CLAUDE.md"* ]]
}

@test "allows mixed non-framework changes" {
    echo "# Updated README" > README.md
    echo "name: Updated CI" > .github/workflows/ci.yml
    git add .
    git commit -m "Non-framework updates" --quiet
    
    run scripts/check-version-requirements.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"No version bump required"* ]]
}

@test "verbose output shows file analysis" {
    echo "# Updated framework" > framework/CLAUDE.md
    echo "# Updated README" > README.md
    git add .
    git commit -m "Mixed updates" --quiet
    
    run scripts/check-version-requirements.sh --verbose
    [ "$status" -ne 0 ]
    [[ "$output" == *"File Analysis:"* ]]
    [[ "$output" == *"Files requiring version bump:"* ]]
    [[ "$output" == *"Files NOT requiring version bump:"* ]]
}

@test "github actions format works" {
    echo "# Updated framework" > framework/CLAUDE.md
    git add framework/CLAUDE.md
    git commit -m "Update framework" --quiet
    
    run scripts/check-version-requirements.sh --github-actions
    [ "$status" -ne 0 ]
    [[ "$output" == *"::error::"* ]] || [[ "$output" == *"::warning::"* ]]
}