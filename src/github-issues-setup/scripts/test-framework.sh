#!/bin/bash
# GitHub Issues Setup Framework Testing Script
# Validates the complete implementation

set -e

echo "🧪 Testing GitHub Issues Setup Framework..."
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "🔍 Testing $test_name... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Function to check file exists
check_file_exists() {
    local file_path="$1"
    test -f "$file_path"
}

# Function to check directory exists
check_dir_exists() {
    local dir_path="$1"
    test -d "$dir_path"
}

# Function to validate YAML syntax using Node.js
validate_yaml() {
    local file_path="$1"
    if command -v node >/dev/null 2>&1 && [ -f "src/github-issues-setup/node_modules/js-yaml/package.json" ]; then
        node -e "
const yaml = require('./src/github-issues-setup/node_modules/js-yaml');
const fs = require('fs');
try {
    const content = fs.readFileSync('$file_path', 'utf8');
    yaml.load(content);
} catch (error) {
    console.error('YAML Error:', error.message);
    process.exit(1);
}
" > /dev/null 2>&1
    else
        # Fallback to python if available
        python3 -c "
import yaml
try:
    with open('$file_path', 'r') as f:
        yaml.safe_load(f)
except:
    exit(1)
" > /dev/null 2>&1
    fi
}

# Function to check GitHub CLI is available
check_gh_cli() {
    command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1
}

echo -e "${BLUE}Phase 1: Directory Structure Validation${NC}"
echo "----------------------------------------"

# Test directory structure
run_test "GitHub templates directory" "check_dir_exists '.github/ISSUE_TEMPLATE'"
run_test "GitHub workflows directory" "check_dir_exists '.github/workflows'"
run_test "Source implementation directory" "check_dir_exists 'src/github-issues-setup'"
run_test "Utils directory" "check_dir_exists 'src/github-issues-setup/utils'"
run_test "Tests directory" "check_dir_exists 'src/github-issues-setup/tests'"
run_test "Scripts directory" "check_dir_exists 'src/github-issues-setup/scripts'"

echo ""
echo -e "${BLUE}Phase 2: Template File Validation${NC}"
echo "-----------------------------------"

# Test template files existence
run_test "Bug report template" "check_file_exists '.github/ISSUE_TEMPLATE/bug_report.yml'"
run_test "Feature request template" "check_file_exists '.github/ISSUE_TEMPLATE/feature_request.yml'"
run_test "Installation question template" "check_file_exists '.github/ISSUE_TEMPLATE/question_installation.yml'"
run_test "Usage question template" "check_file_exists '.github/ISSUE_TEMPLATE/question_usage.yml'"
run_test "Documentation template" "check_file_exists '.github/ISSUE_TEMPLATE/documentation.yml'"
run_test "Template configuration" "check_file_exists '.github/ISSUE_TEMPLATE/config.yml'"

echo ""
echo -e "${BLUE}Phase 3: YAML Syntax Validation${NC}"
echo "--------------------------------"

# Test YAML syntax for templates
if command -v node >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
    run_test "Bug report YAML" "validate_yaml '.github/ISSUE_TEMPLATE/bug_report.yml'"
    run_test "Feature request YAML" "validate_yaml '.github/ISSUE_TEMPLATE/feature_request.yml'"
    run_test "Installation question YAML" "validate_yaml '.github/ISSUE_TEMPLATE/question_installation.yml'"
    run_test "Usage question YAML" "validate_yaml '.github/ISSUE_TEMPLATE/question_usage.yml'"
    run_test "Documentation YAML" "validate_yaml '.github/ISSUE_TEMPLATE/documentation.yml'"
    run_test "Template config YAML" "validate_yaml '.github/ISSUE_TEMPLATE/config.yml'"
    run_test "Labels configuration YAML" "validate_yaml '.github/labels.yml'"
    run_test "Milestones configuration YAML" "validate_yaml '.github/milestones.yml'"
else
    echo -e "${YELLOW}⚠️  Neither Node.js nor Python3 available, skipping YAML validation${NC}"
fi

echo ""
echo -e "${BLUE}Phase 4: Workflow File Validation${NC}"
echo "----------------------------------"

# Test workflow files
run_test "Issue labeler workflow" "check_file_exists '.github/workflows/issue-labeler.yml'"
run_test "Welcome contributors workflow" "check_file_exists '.github/workflows/welcome-new-contributors.yml'"
run_test "Issue validator workflow" "check_file_exists '.github/workflows/issue-validator.yml'"

# Test workflow YAML syntax
if command -v node >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
    run_test "Issue labeler YAML" "validate_yaml '.github/workflows/issue-labeler.yml'"
    run_test "Welcome contributors YAML" "validate_yaml '.github/workflows/welcome-new-contributors.yml'"
    run_test "Issue validator YAML" "validate_yaml '.github/workflows/issue-validator.yml'"
fi

echo ""
echo -e "${BLUE}Phase 5: Implementation File Validation${NC}"
echo "---------------------------------------"

# Test implementation files
run_test "GitHub API client" "check_file_exists 'src/github-issues-setup/utils/github-api.js'"
run_test "Auto-labeling logic" "check_file_exists 'src/github-issues-setup/utils/auto-labeling.js'"
run_test "Package.json" "check_file_exists 'src/github-issues-setup/package.json'"
run_test "Template validation script" "check_file_exists 'src/github-issues-setup/scripts/validate-templates.js'"
run_test "Label sync script" "check_file_exists 'src/github-issues-setup/scripts/sync-labels.js'"

echo ""
echo -e "${BLUE}Phase 6: Test Suite Validation${NC}"
echo "------------------------------"

# Test suite files
run_test "Template validation tests" "check_file_exists 'src/github-issues-setup/tests/template-validation.test.js'"
run_test "Auto-labeling tests" "check_file_exists 'src/github-issues-setup/tests/auto-labeling.test.js'"

echo ""
echo -e "${BLUE}Phase 7: Configuration Validation${NC}"
echo "---------------------------------"

# Test configuration content
run_test "Labels configuration" "check_file_exists '.github/labels.yml'"
run_test "Milestones configuration" "check_file_exists '.github/milestones.yml'"

# Test Node.js setup
if cd src/github-issues-setup 2>/dev/null; then
    if command -v node >/dev/null 2>&1; then
        run_test "Node.js availability" "node --version > /dev/null"
        
        if [ -f "package.json" ]; then
            run_test "Package.json syntax" "node -e \"require('./package.json')\""
        fi
        
        # Check if dependencies can be installed (if npm is available)
        if command -v npm >/dev/null 2>&1; then
            if [ ! -d "node_modules" ]; then
                echo "📦 Installing dependencies for testing..."
                npm install --silent || echo "⚠️  Dependency installation failed (this may be expected in CI)"
            fi
            
            if [ -d "node_modules" ]; then
                run_test "Template validation script" "node scripts/validate-templates.js"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  Node.js not available, skipping JavaScript validation${NC}"
    fi
    
    cd - > /dev/null
fi

echo ""
echo -e "${BLUE}Phase 8: GitHub Integration Validation${NC}"
echo "-------------------------------------"

# Test GitHub CLI availability (optional)
if check_gh_cli; then
    run_test "GitHub CLI authentication" "gh auth status"
    echo -e "${GREEN}✅ GitHub CLI is available and authenticated${NC}"
else
    echo -e "${YELLOW}⚠️  GitHub CLI not available or not authenticated (optional for core functionality)${NC}"
fi

echo ""
echo "=========================================="
echo -e "${BLUE}📊 Test Results Summary${NC}"
echo "=========================================="
echo "Total tests: $TESTS_TOTAL"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All tests passed! GitHub Issues Setup is ready for deployment.${NC}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Deploy templates to your repository"
    echo "2. Configure GitHub Actions workflows"
    echo "3. Sync labels using the sync-labels script"
    echo "4. Enable GitHub Actions in your repository"
    echo "5. Test issue creation with the new templates"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed. Please fix the issues above before deployment.${NC}"
    echo ""
    exit 1
fi