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
        ".csf/validate-framework.sh"

    assert_directory_structure "$HOME_DIR/.claude" \
        "commands/csf" \
        "agents/csf"

    # Step 3: Test framework validation from global location
    cd "$HOME_DIR/.claude"

    run ./.csf/validate-framework.sh
    assert_success
    assert_output_contains "Framework Version:"
    assert_output_contains "Framework validation PASSED"
}

