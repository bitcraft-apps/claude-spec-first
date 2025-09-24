#!/usr/bin/env bats

# Remote Installation Integration Tests
# Tests remote installation script functionality and error handling

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

@test "remote-install requires git dependency" {
    # Create minimal environment without git
    HOME_DIR="$TEST_DIR/home"
    mkdir -p "$HOME_DIR"
    export HOME="$HOME_DIR"

    # Create a PATH that has essential commands but excludes git
    mkdir -p "$TEST_DIR/bin"
    # Link essential commands using dynamic paths
    ln -s "$(command -v bash)" "$TEST_DIR/bin/bash"
    ln -s "$(command -v sh)" "$TEST_DIR/bin/sh"
    ln -s "$(command -v rm)" "$TEST_DIR/bin/rm"
    ln -s "$(command -v mkdir)" "$TEST_DIR/bin/mkdir"
    ln -s "$(command -v chmod)" "$TEST_DIR/bin/chmod"
    ln -s "$(command -v echo)" "$TEST_DIR/bin/echo"
    ln -s "$(command -v mktemp)" "$TEST_DIR/bin/mktemp"
    # Note: deliberately NOT linking git
    export PATH="$TEST_DIR/bin"

    # Test that script fails without git available
    cd "$PROJECT_ROOT"
    run ./scripts/remote-install.sh
    [ "$status" -ne 0 ]
    [[ "$output" == *"Git required"* ]]
}

@test "remote-install handles fresh installation" {
    # Create mock home directory
    HOME_DIR="$TEST_DIR/home"
    mkdir -p "$HOME_DIR"
    export HOME="$HOME_DIR"

    # Mock git clone to use local project instead of remote
    mkdir -p "$TEST_DIR/bin"
    cat > "$TEST_DIR/bin/git" << 'EOF'
#!/bin/bash
if [[ "$*" == *"clone"* ]]; then
    # Extract destination directory from git clone command
    DEST="${@: -1}"
    # Copy project files instead of cloning
    cp -r "$PROJECT_ROOT" "$DEST"
    exit 0
else
    # Pass through other git commands
    exec /usr/bin/git "$@"
fi
EOF
    chmod +x "$TEST_DIR/bin/git"
    export PATH="$TEST_DIR/bin:$PATH"

    cd "$PROJECT_ROOT"
    run ./scripts/remote-install.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing..."* ]]
    [[ "$output" == *"Complete!"* ]]
}

@test "remote-install handles existing installation update" {
    # Create mock home with existing installation
    HOME_DIR="$TEST_DIR/home"
    mkdir -p "$HOME_DIR/.claude/.csf"
    echo "2023-01-01 12:00:00" > "$HOME_DIR/.claude/.csf/.installed"
    export HOME="$HOME_DIR"

    # Mock git clone
    mkdir -p "$TEST_DIR/bin"
    cat > "$TEST_DIR/bin/git" << 'EOF'
#!/bin/bash
if [[ "$*" == *"clone"* ]]; then
    DEST="${@: -1}"
    cp -r "$PROJECT_ROOT" "$DEST"
    exit 0
else
    exec /usr/bin/git "$@"
fi
EOF
    chmod +x "$TEST_DIR/bin/git"
    export PATH="$TEST_DIR/bin:$PATH"

    cd "$PROJECT_ROOT"
    run ./scripts/remote-install.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Updating..."* ]]
}

@test "remote-install handles download failure gracefully" {
    HOME_DIR="$TEST_DIR/home"
    mkdir -p "$HOME_DIR"
    export HOME="$HOME_DIR"

    # Mock git clone to fail
    mkdir -p "$TEST_DIR/bin"
    cat > "$TEST_DIR/bin/git" << 'EOF'
#!/bin/bash
if [[ "$*" == *"clone"* ]]; then
    exit 1  # Simulate download failure
else
    exec /usr/bin/git "$@"
fi
EOF
    chmod +x "$TEST_DIR/bin/git"
    export PATH="$TEST_DIR/bin:$PATH"

    cd "$PROJECT_ROOT"
    run ./scripts/remote-install.sh
    [ "$status" -ne 0 ]
    [[ "$output" == *"Download failed"* ]]
}

@test "remote-install includes validation step" {
    HOME_DIR="$TEST_DIR/home"
    mkdir -p "$HOME_DIR"
    export HOME="$HOME_DIR"

    # Mock git clone and validation
    mkdir -p "$TEST_DIR/bin"
    cat > "$TEST_DIR/bin/git" << 'EOF'
#!/bin/bash
if [[ "$*" == *"clone"* ]]; then
    DEST="${@: -1}"
    cp -r "$PROJECT_ROOT" "$DEST"
    exit 0
else
    exec /usr/bin/git "$@"
fi
EOF
    chmod +x "$TEST_DIR/bin/git"
    export PATH="$TEST_DIR/bin:$PATH"

    cd "$PROJECT_ROOT"
    run ./scripts/remote-install.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Validated"* ]]
}

@test "remote-install cleanup works on exit" {
    HOME_DIR="$TEST_DIR/home"
    mkdir -p "$HOME_DIR"
    export HOME="$HOME_DIR"

    # Mock git clone to fail after creating temp dir
    mkdir -p "$TEST_DIR/bin"
    cat > "$TEST_DIR/bin/git" << 'EOF'
#!/bin/bash
if [[ "$*" == *"clone"* ]]; then
    # Create some files in temp dir before failing
    DEST="${@: -1}"
    mkdir -p "$DEST"
    echo "test" > "$DEST/testfile"
    exit 1  # Fail after creating files
else
    exec /usr/bin/git "$@"
fi
EOF
    chmod +x "$TEST_DIR/bin/git"
    export PATH="$TEST_DIR/bin:$PATH"

    cd "$PROJECT_ROOT"

    # Count temp directories before
    TEMP_COUNT_BEFORE=$(find /tmp -maxdepth 1 -name "tmp.*" 2>/dev/null | wc -l)

    run ./scripts/remote-install.sh
    [ "$status" -ne 0 ]

    # Cleanup should have happened - temp count shouldn't increase significantly
    TEMP_COUNT_AFTER=$(find /tmp -maxdepth 1 -name "tmp.*" 2>/dev/null | wc -l)
    [ "$TEMP_COUNT_AFTER" -le $((TEMP_COUNT_BEFORE + 1)) ]
}