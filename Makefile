# Makefile for Claude Spec-First Framework

.PHONY: help test test-verbose test-integration test-version setup install validate clean

# Default target
help:
	@echo "Claude Spec-First Framework - Development Commands"
	@echo "=================================================="
	@echo ""
	@echo "Available targets:"
	@echo "  test              Run all BATS tests"
	@echo "  test-verbose      Run tests with verbose output"
	@echo "  test-integration  Run only integration tests"
	@echo "  test-version      Run only version utility tests"
	@echo "  test-parallel     Run tests in parallel"
	@echo "  test-legacy       Run legacy shell-based tests"
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
	@echo "  make test-verbose            # Detailed test output"
	@echo "  make test-parallel           # Faster parallel execution"

# Initialize and setup
setup:
	@echo "🔧 Setting up Claude Spec-First Framework..."
	git submodule update --init --recursive
	chmod +x tests/run_tests.sh
	chmod +x tests/bats-core/bin/bats
	chmod +x scripts/*.sh
	chmod +x framework/validate-framework.sh
	@echo "✅ Setup complete!"

# Run all tests
test: setup
	@echo "🧪 Running BATS test suite..."
	cd tests && ./run_tests.sh $(if $(FILTER),--filter $(FILTER))

# Run tests with verbose output
test-verbose: setup
	@echo "🧪 Running BATS test suite (verbose)..."
	cd tests && ./run_tests.sh --verbose $(if $(FILTER),--filter $(FILTER))

# Run only integration tests
test-integration: setup
	@echo "🧪 Running integration tests..."
	cd tests && ./run_tests.sh --filter integration

# Run only version utility tests
test-version: setup
	@echo "🧪 Running version utility tests..."
	cd tests && ./run_tests.sh --filter version

# Run tests in parallel
test-parallel: setup
	@echo "🧪 Running BATS test suite (parallel)..."
	cd tests && ./run_tests.sh --parallel $(if $(FILTER),--filter $(FILTER))

# Run legacy shell-based tests
test-legacy: setup
	@echo "🔄 Running legacy shell-based tests..."
	@if [ -f tests/integration.sh ]; then \
		echo "Running integration.sh..."; \
		chmod +x tests/integration.sh; \
		tests/integration.sh; \
	fi
	@if [ -f tests/version.sh ]; then \
		echo "Running version.sh..."; \
		chmod +x tests/version.sh; \
		tests/version.sh; \
	fi

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
	cd tests && ./run_tests.sh --tap

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
release-check: clean setup test-legacy ci-test validate
	@echo "🎉 Release check complete - ready for deployment!"