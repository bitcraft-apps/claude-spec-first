#!/usr/bin/env bats

# Unit Tests for scripts/version.sh
# Tests pure functions via sourcing, CLI via subprocess

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export PROJECT_ROOT
VERSION_SCRIPT="$PROJECT_ROOT/scripts/version.sh"

# Source version.sh functions (set -e is active but BATS handles it)
setup() {
    TEST_DIR="$(mktemp -d)"
    # Source in subshell-safe way: override set -e impact
    source "$VERSION_SCRIPT"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# --- validate_version ---

@test "validate_version accepts valid version" {
    run validate_version "1.2.3"
    [ "$status" -eq 0 ]
}

@test "validate_version accepts 0.0.0" {
    run validate_version "0.0.0"
    [ "$status" -eq 0 ]
}

@test "validate_version rejects empty string" {
    run validate_version ""
    [ "$status" -ne 0 ]
    [[ "$output" == *"empty"* ]]
}

@test "validate_version rejects invalid format" {
    run validate_version "1.2"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Invalid version"* ]]
}

@test "validate_version rejects non-numeric" {
    run validate_version "a.b.c"
    [ "$status" -ne 0 ]
}

# --- parse_version ---

@test "parse_version sets MAJOR MINOR PATCH" {
    parse_version "2.5.9"
    [ "$MAJOR" = "2" ]
    [ "$MINOR" = "5" ]
    [ "$PATCH" = "9" ]
}

@test "parse_version rejects invalid input" {
    run parse_version "not-a-version"
    [ "$status" -ne 0 ]
}

# --- compare_versions ---

@test "compare_versions returns 0 for equal versions" {
    set +e
    compare_versions "1.2.3" "1.2.3"
    result=$?
    set -e
    [ "$result" -eq 0 ]
}

@test "compare_versions returns 1 when first is greater" {
    set +e
    compare_versions "2.0.0" "1.0.0"
    result=$?
    set -e
    [ "$result" -eq 1 ]
}

@test "compare_versions returns 2 when first is less" {
    set +e
    compare_versions "1.0.0" "2.0.0"
    result=$?
    set -e
    [ "$result" -eq 2 ]
}

@test "compare_versions compares minor correctly" {
    set +e
    compare_versions "1.3.0" "1.2.0"
    result=$?
    set -e
    [ "$result" -eq 1 ]
}

@test "compare_versions compares patch correctly" {
    set +e
    compare_versions "1.0.1" "1.0.2"
    result=$?
    set -e
    [ "$result" -eq 2 ]
}

# --- increment_version ---

@test "increment_version patch" {
    run increment_version "1.2.3" "patch"
    [ "$status" -eq 0 ]
    [ "$output" = "1.2.4" ]
}

@test "increment_version minor resets patch" {
    run increment_version "1.2.3" "minor"
    [ "$status" -eq 0 ]
    [ "$output" = "1.3.0" ]
}

@test "increment_version major resets minor and patch" {
    run increment_version "1.2.3" "major"
    [ "$status" -eq 0 ]
    [ "$output" = "2.0.0" ]
}

@test "increment_version rejects invalid type" {
    run increment_version "1.2.3" "invalid"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Invalid increment type"* ]]
}

# --- CLI subcommands ---

@test "CLI get returns version from VERSION file" {
    cd "$TEST_DIR"
    echo "3.2.1" > VERSION
    run "$VERSION_SCRIPT" get
    [ "$status" -eq 0 ]
    [ "$output" = "3.2.1" ]
}

@test "CLI validate accepts valid version" {
    run "$VERSION_SCRIPT" validate "1.0.0"
    [ "$status" -eq 0 ]
}

@test "CLI validate rejects invalid version" {
    run "$VERSION_SCRIPT" validate "bad"
    [ "$status" -ne 0 ]
}

@test "CLI compare shows equality" {
    run "$VERSION_SCRIPT" compare "1.0.0" "1.0.0"
    [ "$status" -eq 0 ]
    [[ "$output" == *"=="* ]]
}

@test "CLI unknown command exits 1" {
    run "$VERSION_SCRIPT" nonexistent
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
}

@test "CLI set updates VERSION file" {
    cd "$TEST_DIR"
    echo "1.0.0" > VERSION
    run "$VERSION_SCRIPT" set "2.0.0"
    [ "$status" -eq 0 ]
    result=$(cat "$TEST_DIR/VERSION")
    [ "$result" = "2.0.0" ]
}

@test "CLI get fails without VERSION file" {
    cd "$TEST_DIR"
    rm -f VERSION
    run "$VERSION_SCRIPT" get
    [ "$status" -ne 0 ]
}
