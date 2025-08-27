#!/bin/bash

# Test Runner for Claude Spec-First Framework
# Orchestrates execution of BATS test suites with proper setup and reporting

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BATS_EXECUTABLE="$SCRIPT_DIR/bats-core/bin/bats"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test configuration
VERBOSE=0
PARALLEL=0
FILTER=""
TAP_OUTPUT=0

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -p|--parallel)
                PARALLEL=1
                shift
                ;;
            -f|--filter)
                FILTER="$2"
                shift 2
                ;;
            -t|--tap)
                TAP_OUTPUT=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    echo "Test Runner for Claude Spec-First Framework"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose     Enable verbose output"
    echo "  -p, --parallel    Run tests in parallel"
    echo "  -f, --filter STR  Filter tests by name pattern"
    echo "  -t, --tap         Output in TAP format"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Run all tests"
    echo "  $0 -v                       # Run with verbose output"
    echo "  $0 -f 'version'             # Run only version-related tests"
    echo "  $0 -p                       # Run tests in parallel"
    echo "  $0 -t                       # Output in TAP format for CI"
}

# Check prerequisites
check_prerequisites() {
    echo "🔍 Checking test prerequisites..."
    
    # Check if we're in the right directory
    if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
        echo -e "${RED}❌ Not in Claude Spec-First Framework repository${NC}" >&2
        exit 1
    fi
    
    # Check if bats-core submodule is initialized
    if [ ! -f "$BATS_EXECUTABLE" ]; then
        echo "📦 Initializing bats-core submodule..."
        cd "$PROJECT_ROOT"
        git submodule update --init --recursive
        
        if [ ! -f "$BATS_EXECUTABLE" ]; then
            echo -e "${RED}❌ Failed to initialize bats-core submodule${NC}" >&2
            echo "Please run: git submodule update --init --recursive" >&2
            exit 1
        fi
    fi
    
    # Make bats executable
    chmod +x "$BATS_EXECUTABLE"
    
    # Check if test files exist
    if [ ! -f "$SCRIPT_DIR/version_utilities.bats" ] || [ ! -f "$SCRIPT_DIR/framework_integration.bats" ]; then
        echo -e "${RED}❌ Test files not found${NC}" >&2
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Initialize git submodules if needed
init_submodules() {
    if [ ! -d "$SCRIPT_DIR/bats-core/.git" ]; then
        echo "🔄 Initializing git submodules..."
        cd "$PROJECT_ROOT"
        git submodule update --init --recursive
    fi
}

# Build BATS command
build_bats_command() {
    local cmd="$BATS_EXECUTABLE"
    
    # Add verbose flag if requested
    if [ $VERBOSE -eq 1 ]; then
        cmd="$cmd --verbose-run"
    fi
    
    # Add TAP output if requested
    if [ $TAP_OUTPUT -eq 1 ]; then
        cmd="$cmd --tap"
    fi
    
    # Add filter if specified
    if [ -n "$FILTER" ]; then
        cmd="$cmd --filter '$FILTER'"
    fi
    
    echo "$cmd"
}

# Run test suite
run_tests() {
    echo "🧪 Running Claude Spec-First Framework Test Suite"
    echo "=================================================="
    echo ""
    
    # Set up environment
    export PROJECT_ROOT
    cd "$SCRIPT_DIR"
    
    # Build test file list
    local test_files=()
    test_files+=("version_utilities.bats")
    test_files+=("framework_integration.bats")
    
    # Filter test files if pattern specified
    if [ -n "$FILTER" ]; then
        local filtered_files=()
        for file in "${test_files[@]}"; do
            if [[ "$file" == *"$FILTER"* ]]; then
                filtered_files+=("$file")
            fi
        done
        test_files=("${filtered_files[@]}")
    fi
    
    # Check if we have tests to run
    if [ ${#test_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No test files match the filter: $FILTER${NC}"
        exit 0
    fi
    
    # Build and execute BATS command
    local cmd=$(build_bats_command)
    
    if [ $PARALLEL -eq 1 ] && [ ${#test_files[@]} -gt 1 ]; then
        echo "🚀 Running tests in parallel..."
        cmd="$cmd --jobs 4"
    fi
    
    # Add test files to command
    for file in "${test_files[@]}"; do
        cmd="$cmd $file"
    done
    
    echo "💻 Executing: $cmd"
    echo ""
    
    # Execute tests
    if eval "$cmd"; then
        echo ""
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        return 0
    else
        local exit_code=$?
        echo ""
        echo -e "${RED}❌ Some tests failed!${NC}"
        return $exit_code
    fi
}

# Run legacy tests for comparison (if they exist)
run_legacy_tests() {
    echo ""
    echo "🔄 Running legacy tests for comparison..."
    echo "======================================="
    
    # Run old shell-based tests if they exist
    if [ -x "$SCRIPT_DIR/integration.sh" ]; then
        echo "Running integration.sh..."
        if "$SCRIPT_DIR/integration.sh"; then
            echo -e "${GREEN}✅ Legacy integration tests passed${NC}"
        else
            echo -e "${YELLOW}⚠️  Legacy integration tests failed${NC}"
        fi
    fi
    
    if [ -x "$SCRIPT_DIR/version.sh" ]; then
        echo "Running version.sh tests..."
        if "$SCRIPT_DIR/version.sh"; then
            echo -e "${GREEN}✅ Legacy version tests passed${NC}"
        else
            echo -e "${YELLOW}⚠️  Legacy version tests failed${NC}"
        fi
    fi
}

# Generate test report
generate_report() {
    echo ""
    echo "📊 Test Execution Summary"
    echo "========================="
    echo "Test runner: BATS (Bash Automated Testing System)"
    echo "Framework: Claude Spec-First Framework"
    echo "Date: $(date)"
    echo "Project: $PROJECT_ROOT"
    echo ""
}

# Main execution
main() {
    parse_args "$@"
    
    # Show header
    echo -e "${BLUE}Claude Spec-First Framework - Test Suite${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Run prerequisite checks
    check_prerequisites
    init_submodules
    
    # Execute tests
    local test_result=0
    if ! run_tests; then
        test_result=1
    fi
    
    # Run legacy tests if not in CI mode
    if [ $TAP_OUTPUT -eq 0 ] && [ $test_result -eq 0 ]; then
        run_legacy_tests
    fi
    
    # Generate report
    generate_report
    
    # Exit with appropriate code
    exit $test_result
}

# Execute main function with all arguments
main "$@"