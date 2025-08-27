# Testing Documentation

## Overview

The Claude Spec-First Framework uses **BATS (Bash Automated Testing System)** for comprehensive testing. This modern testing approach provides better structure, reporting, and CI/CD integration compared to the previous shell-based tests.

## Architecture

### Test Structure
```
tests/
├── bats-core/                    # Git submodule - BATS testing framework
├── framework_integration.bats    # Integration tests for the complete framework
├── version_utilities.bats        # Unit tests for version management utilities
├── test_helper.bash             # Common test utilities and setup functions
├── run_tests.sh                 # Test runner with advanced options
├── integration.sh               # Legacy integration tests (for compatibility)
├── version.sh                   # Legacy version tests (for compatibility)
└── README.md                    # This documentation
```

### Why BATS over Shell Scripts?

**Advantages of BATS:**
- **Structured Testing**: Clear test organization with `@test` annotations
- **Better Reporting**: Detailed pass/fail reporting with line numbers
- **CI Integration**: TAP (Test Anything Protocol) output for GitHub Actions
- **Parallel Execution**: Run tests concurrently for faster feedback
- **Error Handling**: Robust error reporting and debugging capabilities
- **Filtering**: Run specific test subsets during development

**Git Submodule Approach:**
- **Version Pinning**: Exact control over BATS version across environments
- **Self-Contained**: No external dependencies or package manager requirements
- **Offline Support**: Works without internet after initial clone
- **CI Consistency**: Same BATS version in GitHub Actions and local development

## Quick Start

### Setup
```bash
# Initialize the testing framework
make setup

# Or manually:
git submodule update --init --recursive
chmod +x tests/run_tests.sh
```

### Running Tests
```bash
# Run all tests
make test

# Run with detailed output  
make test-verbose

# Run specific test suite
make test-version           # Version utility tests
make test-integration       # Framework integration tests

# Run with filtering
make test FILTER=version    # Tests matching "version"
make test FILTER=validate   # Tests matching "validate"

# Parallel execution (faster)
make test-parallel
```

### Direct BATS Usage
```bash
cd tests

# Run all tests
./run_tests.sh

# Run with options
./run_tests.sh --verbose           # Detailed output
./run_tests.sh --parallel          # Parallel execution
./run_tests.sh --filter version    # Filter by pattern
./run_tests.sh --tap               # TAP output for CI
```

## Test Suites

### 1. Version Utilities Tests (`version_utilities.bats`)

Tests all version management functionality:
- **Version Validation**: Format validation and error handling
- **Version Parsing**: Component extraction (major, minor, patch)
- **Version Comparison**: Semantic version comparison logic
- **Version Incrementing**: Major, minor, and patch increments
- **Framework Operations**: File-based version management
- **CLI Interface**: Command-line utility testing

**Example Tests:**
```bash
@test "validate_version accepts basic version" {
    run validate_version "1.0.0"
    [ "$status" -eq 0 ]
}

@test "increment_version major resets minor and patch" {
    result=$(increment_version "1.2.3" "major")
    [ "$result" = "2.0.0" ]
}
```

### 2. Framework Integration Tests (`framework_integration.bats`)

Tests complete framework workflows:
- **Repository Mode**: Framework functionality in development mode
- **Installation Mode**: Framework behavior after installation
- **Version Operations**: End-to-end version management
- **Validation Pipeline**: Complete framework validation
- **Error Handling**: Graceful degradation with missing components

**Example Tests:**
```bash
@test "framework validation includes version" {
    cd "$PROJECT_ROOT"
    run ./framework/validate-framework.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Framework Version:"* ]]
}

@test "installed version utilities work" {
    # Creates mock installation and tests functionality
    HOME_DIR="$TEST_DIR/home"
    setup_mock_installation "$HOME_DIR"
    
    cd "$HOME_DIR/.claude"
    run ./utils/version.sh get
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}
```

## Test Utilities

### Test Helper Functions (`test_helper.bash`)

Common utilities shared across all test suites:
- **Environment Setup**: Temporary directories and mock installations
- **Validation Helpers**: Version format checking, output pattern matching
- **Mock Functions**: Override framework directories for isolated testing
- **Debugging Tools**: Test failure investigation utilities

**Key Functions:**
```bash
create_mock_home()         # Setup isolated installation environment
is_valid_version()         # Validate semantic version format
override_framework_dir()   # Redirect framework operations to test directory
debug_test_failure()       # Debug information for failing tests
```

### Test Runner (`run_tests.sh`)

Advanced test execution with multiple options:
- **Filtering**: Run specific test patterns
- **Parallel Execution**: Concurrent test execution
- **Output Formats**: Human-readable or TAP for CI
- **Legacy Integration**: Run old shell-based tests for comparison

**Command Line Options:**
```bash
./run_tests.sh --help               # Show all options
./run_tests.sh --verbose            # Detailed output
./run_tests.sh --parallel           # Concurrent execution  
./run_tests.sh --filter "version"   # Pattern filtering
./run_tests.sh --tap                # TAP output for CI
```

## GitHub Actions Integration

### Workflow Structure (`.github/workflows/bats-tests.yml`)

**Multi-Matrix Testing:**
- **Test Suites**: Parallel execution of different test suites
- **Cross-Platform**: Ubuntu and macOS testing
- **Integration Levels**: Unit tests → Integration tests → Full validation

**Workflow Jobs:**
1. **bats-tests**: Matrix execution of individual test suites
2. **integration-tests**: Complete framework validation
3. **cross-platform-tests**: Multi-OS compatibility testing

**Features:**
- Automatic submodule initialization
- TAP output for GitHub's test reporting
- Test result summaries in GitHub UI
- Failure investigation with detailed logs

## Development Workflow

### Writing New Tests

1. **Create Test File**: Use `.bats` extension
2. **Add Test Helper**: Load common utilities with `load 'test_helper'`
3. **Write Test Functions**: Use `@test "description" { ... }` format
4. **Use Assertions**: `[ condition ]` for success, check `$status` and `$output`
5. **Add to Runner**: Update `run_tests.sh` if needed

**Test Template:**
```bash
#!/usr/bin/env bats

load 'test_helper'

setup() {
    # Test-specific setup
    TEST_DIR="$(mktemp -d)"
}

teardown() {
    # Cleanup
    rm -rf "$TEST_DIR"
}

@test "descriptive test name" {
    run your_command_here
    [ "$status" -eq 0 ]
    [[ "$output" == *"expected content"* ]]
}
```

### Debugging Failed Tests

1. **Run with Verbose Output**: `make test-verbose`
2. **Use Debug Helper**: Call `debug_test_failure` in test
3. **Isolate the Test**: Use filtering to run single test
4. **Check Environment**: Verify `$PROJECT_ROOT`, `$TEST_DIR` variables
5. **Manual Execution**: Run commands outside BATS for investigation

### Best Practices

- **Isolation**: Each test should be independent and cleanup after itself
- **Descriptive Names**: Test names should clearly describe expected behavior
- **Setup/Teardown**: Use setup() and teardown() for consistent test environment
- **Helper Functions**: Extract common patterns to test_helper.bash
- **Error Messages**: Include context in assertions for easier debugging

## Migration from Legacy Tests

### Legacy Test Support

The old shell-based tests (`integration.sh`, `version.sh`) are preserved for:
- **Backward Compatibility**: Ensure new BATS tests cover same scenarios
- **Transition Period**: Gradual migration without losing test coverage
- **Verification**: Cross-validate BATS results against established tests

### Migration Strategy

1. **Convert Gradually**: Move test cases one-by-one to BATS format
2. **Run Both**: Execute legacy and BATS tests in parallel during transition
3. **Validate Equivalence**: Ensure BATS tests catch same issues as legacy tests
4. **Remove Legacy**: Deprecate shell-based tests once BATS coverage is complete

## Continuous Integration

### Local Development
```bash
# Quick development cycle
make dev                    # Clean, setup, and run verbose tests

# Watch mode (requires fswatch)
make dev-watch             # Auto-run tests on file changes

# Release validation
make release-check         # Complete test suite for release
```

### CI/CD Pipeline
```bash
# CI execution
make ci-test               # TAP output for GitHub Actions
make ci-validate           # Framework validation for CI

# Manual CI testing
export GITHUB_ACTIONS=true
cd tests && ./run_tests.sh --tap
```

## Troubleshooting

### Common Issues

**Submodule Not Initialized:**
```bash
# Fix: Initialize git submodules
git submodule update --init --recursive
make setup
```

**Permission Errors:**
```bash
# Fix: Make scripts executable
chmod +x tests/run_tests.sh
chmod +x tests/bats-core/bin/bats
chmod +x scripts/*.sh
```

**Test Environment Issues:**
```bash
# Fix: Clean and reset
make clean
make setup
```

**Legacy Test Compatibility:**
```bash
# Run legacy tests for comparison
make test-legacy
```

### Getting Help

- **Framework Issues**: Check `./framework/validate-framework.sh` output
- **Version Problems**: Run `./scripts/version.sh info` for diagnostics
- **Test Debugging**: Use `make test-verbose` and `debug_test_failure()`
- **CI Problems**: Check GitHub Actions logs and workflow configuration

## Performance

### Test Execution Times

- **Serial Execution**: ~30-60 seconds for complete suite
- **Parallel Execution**: ~15-30 seconds with `--parallel`
- **Individual Suites**: ~5-15 seconds each
- **CI Execution**: ~2-5 minutes including setup and validation

### Optimization Tips

- Use `make test-parallel` for faster local development
- Filter tests during development: `make test FILTER=specific`
- Run individual suites: `make test-version` or `make test-integration`
- Use `make dev` for clean development cycles