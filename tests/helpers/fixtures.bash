#!/usr/bin/env bash

# Test Fixtures and Mock Data
# Provides functions for creating test environments and mock data

# Load common utilities
load 'common'

# Create a mock home directory for installation tests
create_mock_home() {
    local home_dir="${1:-$TEST_DIR/mock_home}"
    mkdir -p "$home_dir/.claude"
    export TEST_HOME="$home_dir"
    export HOME="$home_dir"
    export CLAUDE_DIR="$home_dir/.claude"
    echo "$home_dir"
}

# Create a temporary VERSION file with specified version
create_version_file() {
    local version="${1:-1.0.0}"
    local version_file="${2:-$TEST_DIR/VERSION}"
    echo "$version" > "$version_file"
    echo "$version_file"
}

# Create a minimal framework structure for testing
create_minimal_framework() {
    local framework_dir="${1:-$TEST_DIR/framework}"
    mkdir -p "$framework_dir"/{commands,agents}
    
    # Create VERSION file
    create_version_file "0.1.0" "$framework_dir/VERSION"
    
    # Create minimal validate-framework.sh
    cat > "$framework_dir/validate-framework.sh" << 'EOF'
#!/bin/bash
echo "Framework Version: $(cat VERSION 2>/dev/null || echo 'unknown')"
echo "Framework validation PASSED"
EOF
    chmod +x "$framework_dir/validate-framework.sh"
    
    echo "$framework_dir"
}

# Create test data for version comparisons
create_version_test_data() {
    cat << 'EOF'
1.0.0
1.0.1
1.1.0
2.0.0
10.20.30
0.0.1
EOF
}

# Setup a complete test environment with framework and mock home
setup_full_test_environment() {
    local test_root="${1:-$TEST_DIR/test_env}"
    mkdir -p "$test_root"
    
    # Create framework structure
    local framework_dir="$test_root/framework"
    create_minimal_framework "$framework_dir"
    
    # Create mock home
    local home_dir="$test_root/home"
    create_mock_home "$home_dir"
    
    # Export environment variables
    export TEST_FRAMEWORK_DIR="$framework_dir"
    export TEST_HOME_DIR="$home_dir"
    
    echo "$test_root"
}

# Cleanup test fixtures
cleanup_fixtures() {
    unset TEST_HOME TEST_HOME_DIR TEST_FRAMEWORK_DIR
}