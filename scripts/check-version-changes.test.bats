#!/usr/bin/env bats

# Unit tests for check-version-changes.sh
# Tests version change detection, changelog validation, and semantic versioning

setup() {
    # Create temporary directory for tests
    export TEST_TEMP_DIR="$(mktemp -d)"
    export ORIGINAL_DIR="$PWD"
    
    # Initialize git repo in temp dir
    cd "$TEST_TEMP_DIR"
    git init --quiet
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create basic project structure
    mkdir -p framework scripts
    echo "0.1.0" > framework/VERSION
    
    # Copy script under test
    cp "$ORIGINAL_DIR/scripts/check-version-changes.sh" scripts/
    cp "$ORIGINAL_DIR/scripts/version.sh" scripts/
    chmod +x scripts/check-version-changes.sh
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

create_changelog() {
    local version="$1"
    cat > CHANGELOG.md << 'CHANGELOG_EOF'
# Changelog

All notable changes to this project will be documented in this file.

## [VERSION_PLACEHOLDER] - 2025-08-27

### Added
- New feature

### Changed
- Updated functionality

### Fixed
- Bug fixes
CHANGELOG_EOF
    sed -i.bak "s/VERSION_PLACEHOLDER/$version/g" CHANGELOG.md
    rm CHANGELOG.md.bak 2>/dev/null || true
}

@test "help message displays correctly" {
    run scripts/check-version-changes.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Version Change Validation Script"* ]]
}

@test "detects no version change" {
    run scripts/check-version-changes.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"No version change detected"* ]]
}

@test "detects version change" {
    echo "0.2.0" > framework/VERSION
    git add framework/VERSION
    git commit -m "Bump version to 0.2.0" --quiet
    
    run scripts/check-version-changes.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Version bump detected: 0.1.0 → 0.2.0"* ]]
}

@test "validates changelog when version changes" {
    echo "0.2.0" > framework/VERSION
    create_changelog "0.2.0"
    git add .
    git commit -m "Bump version to 0.2.0 with changelog" --quiet
    
    run scripts/check-version-changes.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Version bump detected"* ]]
    [[ "$output" == *"CHANGELOG.md exists"* ]]
}

@test "fails when changelog missing" {
    echo "0.2.0" > framework/VERSION
    git add framework/VERSION
    git commit -m "Bump version to 0.2.0" --quiet
    
    run scripts/check-version-changes.sh
    [ "$status" -ne 0 ]
    [[ "$output" == *"CHANGELOG.md is required"* ]]
}

@test "fails when changelog entry missing" {
    echo "0.2.0" > framework/VERSION
    create_changelog "0.1.9"
    git add .
    git commit -m "Bump version but wrong changelog" --quiet
    
    run scripts/check-version-changes.sh
    [ "$status" -ne 0 ]
    [[ "$output" == *"missing-current-version"* ]]
}

@test "skip changelog validation works" {
    echo "0.2.0" > framework/VERSION
    git add framework/VERSION
    git commit -m "Bump version to 0.2.0" --quiet
    
    run scripts/check-version-changes.sh --skip-changelog
    [ "$status" -eq 0 ]
    [[ "$output" == *"Version bump detected"* ]]
}

@test "github actions format works" {
    echo "0.2.0" > framework/VERSION
    create_changelog "0.2.0"
    git add .
    git commit -m "Bump version to 0.2.0" --quiet
    
    run scripts/check-version-changes.sh --github-actions
    [ "$status" -eq 0 ]
    [[ "$output" == *"::notice::"* ]]
}