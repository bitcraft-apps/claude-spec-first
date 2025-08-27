# Makefile for Claude Spec-First Framework

.PHONY: help test test-verbose test-integration test-version test-unit test-e2e test-parallel setup install validate clean

# Default target
help:
	@echo "Claude Spec-First Framework - Development Commands"
	@echo "=================================================="
	@echo ""
	@echo "Available targets:"
	@echo "  test              Run all BATS tests"
	@echo "  test-verbose      Run tests with verbose output"
	@echo "  test-integration  Run only integration tests (centralized)"
	@echo "  test-version      Run only version utility tests (collocated)"
	@echo "  test-scripts      Run only install/uninstall script tests (collocated)"
	@echo "  test-unit         Run all unit tests (collocated with code)"
	@echo "  test-e2e          Run end-to-end tests"
	@echo "  test-parallel     Run tests in parallel"
	@echo ""
	@echo "  setup             Initialize git submodules and setup"
	@echo "  install           Install framework to ~/.claude"
	@echo "  validate          Validate framework configuration"
	@echo "  clean             Clean up test artifacts"
	@echo ""
	@echo "Test filtering:"
	@echo "  make test FILTER=version     # Run tests matching 'version'"
	@echo "  make test FILTER=integration # Run tests matching 'integration'"
	@echo ""
	@echo "Examples:"
	@echo "  make setup && make test      # Setup and run all tests"
	@echo "  make test-unit               # Run only unit tests"
	@echo "  make test-scripts            # Run only install/uninstall tests"
	@echo "  make test-integration        # Run only integration tests"
	@echo "  make test-e2e                # Run only E2E tests"
	@echo "  make test-verbose            # Detailed test output"
	@echo "  make test-parallel           # Faster parallel execution"

# Initialize and setup
setup:
	@echo "🔧 Setting up Claude Spec-First Framework..."
	git submodule update --init --recursive
	chmod +x tests/run-tests.sh
	chmod +x tests/bats-core/bin/bats
	chmod +x scripts/*.sh
	chmod +x framework/validate-framework.sh
	@echo "✅ Setup complete!"

# Run all tests
test: setup
	@echo "🧪 Running BATS test suite..."
	cd tests && ./run-tests.sh $(if $(FILTER),--filter $(FILTER))

# Run tests with verbose output
test-verbose: setup
	@echo "🧪 Running BATS test suite (verbose)..."
	cd tests && ./run-tests.sh --verbose $(if $(FILTER),--filter $(FILTER))

# Run only integration tests (organized structure)
test-integration: setup
	@echo "🧪 Running integration tests..."
	cd tests && ./run-tests.sh --integration

# Run only version utility tests (collocated)
test-version: setup
	@echo "🧪 Running version utility tests (collocated)..."
	cd tests && ./run-tests.sh --filter version

# Run install/uninstall script tests (collocated)
test-scripts: setup
	@echo "🧪 Running install/uninstall script tests (collocated)..."
	cd tests && ./run-tests.sh --filter "install\|uninstall"

# Run all unit tests (collocated with source code)
test-unit: setup
	@echo "🧪 Running unit tests (collocated)..."
	cd tests && ./run-tests.sh --unit

# Run end-to-end tests
test-e2e: setup
	@echo "🧪 Running E2E tests..."
	cd tests && ./run-tests.sh --e2e

# Run tests in parallel
test-parallel: setup
	@echo "🧪 Running BATS test suite (parallel)..."
	cd tests && ./run-tests.sh --parallel $(if $(FILTER),--filter $(FILTER))


# Install framework
install: validate
	@echo "📦 Installing Claude Spec-First Framework..."
	./scripts/install.sh

# Validate framework
validate: setup
	@echo "🔍 Validating framework..."
	./framework/validate-framework.sh

# Clean up test artifacts
clean:
	@echo "🧹 Cleaning up test artifacts..."
	@find tests -name "*.tmp" -delete 2>/dev/null || true
	@find tests -name "test-data" -type d -exec rm -rf {} + 2>/dev/null || true
	@rm -rf /tmp/versioning-integration-test 2>/dev/null || true
	@rm -rf /tmp/test-home* 2>/dev/null || true
	@echo "✅ Cleanup complete!"

# CI/CD targets
ci-test: setup
	@echo "🚀 Running CI test suite..."
	cd tests && ./run-tests.sh --tap

ci-validate: setup validate

# Development targets
dev-test: test-verbose

dev-watch:
	@echo "👀 Watching for changes (requires fswatch)..."
	@if command -v fswatch >/dev/null 2>&1; then \
		fswatch -o framework/ scripts/ tests/ | while read f; do \
			echo "🔄 Changes detected, running tests..."; \
			make test; \
		done; \
	else \
		echo "❌ fswatch not installed. Install with: brew install fswatch"; \
		exit 1; \
	fi

# Documentation targets
docs:
	@echo "📚 Framework documentation available in:"
	@echo "  - README.md (project overview)"
	@echo "  - CLAUDE.md (development guide)"
	@echo "  - framework/CLAUDE.md (global workflow)"
	@echo "  - tests/ (test examples and setup)"

# Version management
version:
	@./scripts/version.sh get

version-info:
	@./scripts/version.sh info

# Quick development cycle
dev: clean setup test-verbose

# Release preparation
release-check: clean setup ci-test validate
	@echo "🎉 Release check complete - ready for deployment!"