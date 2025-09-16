#!/usr/bin/env bats

# Complete Workflow E2E Tests
# Tests the full spec-first development workflow from start to finish

# Detect project root directory
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

# Inline helper functions - only what's actually used
create_mock_home() {
    local home_dir="${1:-$TEST_DIR/mock_home}"
    mkdir -p "$home_dir/.claude"
    export HOME="$home_dir"
    echo "$home_dir"
}

create_mock_project() {
    local project_dir="${1:-$TEST_DIR/mock_project}"
    mkdir -p "$project_dir"
    # Create CLAUDE.md to mark this as a project root
    echo "# Test Project" > "$project_dir/CLAUDE.md"
    echo "$project_dir"
}

assert_success() {
    [ "$status" -eq 0 ] || {
        echo "Expected success (exit code 0), got: $status" >&2
        echo "Output: $output" >&2
        return 1
    }
}

assert_files_exist() {
    local base_dir="$1"
    shift
    for file in "$@"; do
        [ -f "$base_dir/$file" ] || {
            echo "Expected file: $base_dir/$file" >&2
            return 1
        }
    done
}

assert_directory_structure() {
    local base_dir="$1"
    shift
    for dir in "$@"; do
        [ -d "$base_dir/$dir" ] || {
            echo "Expected directory: $base_dir/$dir" >&2
            return 1
        }
    done
}

assert_version_format() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Expected semantic version format (x.y.z), got: $version" >&2
        return 1
    fi
}

assert_output_contains() {
    local expected="$1"
    [[ "$output" == *"$expected"* ]] || {
        echo "Expected output to contain: $expected" >&2
        echo "Actual output: $output" >&2
        return 1
    }
}

setup() {
    # Create temporary test directory
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    export ORIGINAL_HOME="$HOME"
    export ORIGINAL_PWD="$(pwd)"
}

teardown() {
    # Restore original environment
    if [ -n "$ORIGINAL_HOME" ]; then
        export HOME="$ORIGINAL_HOME"
    fi
    if [ -n "$ORIGINAL_PWD" ] && [ -d "$ORIGINAL_PWD" ]; then
        cd "$ORIGINAL_PWD"
    fi
    # Cleanup test directory
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

@test "complete framework installation and validation workflow" {
    # Create clean environments
    HOME_DIR="$TEST_DIR/home"
    PROJECT_DIR="$TEST_DIR/project"
    create_mock_home "$HOME_DIR"
    create_mock_project "$PROJECT_DIR"

    # Step 1: Install framework to global location
    cd "$PROJECT_ROOT"
    run env HOME="$HOME_DIR" ./scripts/install.sh
    assert_success

    # Step 2: Verify framework installation in global location
    assert_files_exist "$HOME_DIR/.claude" \
        ".csf/VERSION" \
        "utils/version.sh" \
        ".csf/validate-framework.sh"

    assert_directory_structure "$HOME_DIR/.claude" \
        "commands/csf" \
        "agents/csf"

    # Step 3: Test installed version utilities from global location
    cd "$HOME_DIR/.claude"
    
    run ./utils/version.sh get
    assert_success
    assert_version_format "$output"
    
    # Step 4: Test version operations
    ORIGINAL_VERSION="$output"
    
    run ./utils/version.sh increment patch
    assert_success
    assert_output_contains "SUCCESS"
    
    run ./utils/version.sh get
    assert_success
    NEW_VERSION="$output"
    
    # Verify version changed
    [ "$NEW_VERSION" != "$ORIGINAL_VERSION" ]
    
    # Step 5: Test framework validation
    run ./.csf/validate-framework.sh
    assert_success
    assert_output_contains "Framework Version:"
    assert_output_contains "Framework validation PASSED"
    
    # Step 6: Reset version
    run ./utils/version.sh set "$ORIGINAL_VERSION"
    assert_success
    
    run ./utils/version.sh get
    assert_success
    [ "$output" = "$ORIGINAL_VERSION" ]
}

@test "version lifecycle management workflow" {
    # Setup installation
    HOME_DIR="$TEST_DIR/home"
    create_mock_home "$HOME_DIR"

    cd "$PROJECT_ROOT"
    env HOME="$HOME_DIR" ./scripts/install.sh >/dev/null 2>&1

    cd "$HOME_DIR/.claude"
    
    # Get starting version
    STARTING_VERSION=$(./utils/version.sh get)
    
    # Test patch increment
    run ./utils/version.sh increment patch
    assert_success
    
    PATCH_VERSION=$(./utils/version.sh get)
    
    # Test minor increment
    run ./utils/version.sh increment minor
    assert_success
    
    MINOR_VERSION=$(./utils/version.sh get)
    
    # Test major increment  
    run ./utils/version.sh increment major
    assert_success
    
    MAJOR_VERSION=$(./utils/version.sh get)
    
    # Verify progression
    run ./utils/version.sh compare "$STARTING_VERSION" "$PATCH_VERSION"
    assert_success
    assert_output_contains "<"
    
    run ./utils/version.sh compare "$PATCH_VERSION" "$MINOR_VERSION"
    assert_success
    assert_output_contains "<"
    
    run ./utils/version.sh compare "$MINOR_VERSION" "$MAJOR_VERSION"
    assert_success
    assert_output_contains "<"
    
    # Test validation of all versions
    for version in "$STARTING_VERSION" "$PATCH_VERSION" "$MINOR_VERSION" "$MAJOR_VERSION"; do
        run ./utils/version.sh validate "$version"
        assert_success
    done
}