#!/bin/bash

# Claude Spec-First Framework - Version Requirement Detection
# Determines if changes to the codebase require a version bump based on impact to installed framework
# Enforces version bump policy for framework-affecting changes

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
BASE_BRANCH="origin/main"
OUTPUT_FORMAT="human"  # human, github-actions
VERBOSE=0

show_help() {
    echo "Version Requirement Detection Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -b, --base BRANCH     Base branch for comparison (default: origin/main)"
    echo "  --github-actions      Output in GitHub Actions format"
    echo "  -v, --verbose         Verbose output with file analysis"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Purpose:"
    echo "  Determines if changes require a version bump based on files modified"
    echo "  Only framework/ changes require version bumps (framework capabilities)"
    echo "  Scripts, tests, docs, CI changes do not require version bumps"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--base)
                BASE_BRANCH="$2"
                shift 2
                ;;
            --github-actions)
                OUTPUT_FORMAT="github-actions"
                shift
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_help >&2
                exit 1
                ;;
        esac
    done
}

# Output functions for different formats
output_info() {
    if [ "$OUTPUT_FORMAT" = "github-actions" ]; then
        echo "::notice::$1"
    else
        echo -e "${BLUE}ℹ️  $1${NC}"
    fi
}

output_success() {
    if [ "$OUTPUT_FORMAT" = "github-actions" ]; then
        echo "::notice::$1"
    else
        echo -e "${GREEN}✅ $1${NC}"
    fi
}

output_warning() {
    if [ "$OUTPUT_FORMAT" = "github-actions" ]; then
        echo "::warning::$1"
    else
        echo -e "${YELLOW}⚠️  $1${NC}"
    fi
}

output_error() {
    if [ "$OUTPUT_FORMAT" = "github-actions" ]; then
        echo "::error::$1"
    else
        echo -e "${RED}❌ $1${NC}" >&2
    fi
}

set_github_output() {
    if [ "$OUTPUT_FORMAT" = "github-actions" ] && [ -n "$GITHUB_OUTPUT" ]; then
        echo "$1=$2" >> "$GITHUB_OUTPUT"
    fi
}

# Define files that require version bumps when changed
# Only framework content affects the installed framework capabilities
get_version_requiring_patterns() {
    echo "framework/"
}

# Define files that do NOT require version bumps
# These are files that don't affect installed framework capabilities
get_version_exempt_patterns() {
    echo ".github/workflows/"
    echo "tests/"
    echo "scripts/"  # All scripts are tooling, not framework content
    echo "README.md"
    echo "docs/"
    echo "*.md"
    echo ".gitignore"
    echo ".gitmodules"
    echo "LICENSE"
}

# Get list of changed files
get_changed_files() {
    local base_branch="$1"
    
    # If we're in GitHub Actions and have the event, use it
    if [ -n "$GITHUB_EVENT_PATH" ] && [ -f "$GITHUB_EVENT_PATH" ]; then
        # Try to extract changed files from GitHub event
        if command -v jq >/dev/null 2>&1; then
            jq -r '.pull_request.changed_files[]?.filename // empty' "$GITHUB_EVENT_PATH" 2>/dev/null || true
        fi
    fi
    
    # Fallback to git diff
    git diff --name-only "$base_branch"...HEAD 2>/dev/null || {
        output_warning "Could not determine changed files from git diff"
        return 1
    }
}

# Check if a file matches any pattern
file_matches_patterns() {
    local file="$1"
    shift
    local patterns=("$@")
    
    for pattern in "${patterns[@]}"; do
        # Handle glob patterns
        if [[ "$file" == $pattern ]]; then
            return 0
        fi
        
        # Handle prefix patterns (e.g., "framework/" matches "framework/VERSION")
        if [[ "$pattern" == */ && "$file" == "$pattern"* ]]; then
            return 0
        fi
        
        # Handle suffix patterns (e.g., "*.md" matches "README.md")
        if [[ "$pattern" == *.* && "$file" == *"${pattern#*.}" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Analyze changed files to determine version requirement
analyze_changes() {
    local base_branch="$1"
    
    output_info "Analyzing file changes to determine version requirements..."
    
    # Get changed files
    local changed_files
    changed_files=$(get_changed_files "$base_branch")
    
    if [ -z "$changed_files" ]; then
        output_info "No files changed"
        set_github_output "version_required" "false"
        set_github_output "reason" "no_changes"
        return 1
    fi
    
    # Get patterns
    local version_requiring_patterns version_exempt_patterns
    readarray -t version_requiring_patterns < <(get_version_requiring_patterns)
    readarray -t version_exempt_patterns < <(get_version_exempt_patterns)
    
    # Categorize changed files
    local framework_files=()
    local exempt_files=()
    local other_files=()
    
    while IFS= read -r file; do
        if [ -z "$file" ]; then
            continue
        fi
        
        if file_matches_patterns "$file" "${version_requiring_patterns[@]}"; then
            framework_files+=("$file")
        elif file_matches_patterns "$file" "${version_exempt_patterns[@]}"; then
            exempt_files+=("$file")
        else
            other_files+=("$file")
        fi
    done <<< "$changed_files"
    
    # Output analysis if verbose
    if [ $VERBOSE -eq 1 ]; then
        echo ""
        echo "File Analysis:"
        echo "=============="
        
        if [ ${#framework_files[@]} -gt 0 ]; then
            echo -e "${RED}Files requiring version bump:${NC}"
            printf '  %s\n' "${framework_files[@]}"
        fi
        
        if [ ${#exempt_files[@]} -gt 0 ]; then
            echo -e "${GREEN}Files NOT requiring version bump:${NC}"
            printf '  %s\n' "${exempt_files[@]}"
        fi
        
        if [ ${#other_files[@]} -gt 0 ]; then
            echo -e "${YELLOW}Unategorized files (require review):${NC}"
            printf '  %s\n' "${other_files[@]}"
        fi
        echo ""
    fi
    
    # Determine if version bump is required
    if [ ${#framework_files[@]} -gt 0 ]; then
        output_warning "Version bump REQUIRED - framework files changed:"
        printf '  %s\n' "${framework_files[@]}"
        
        set_github_output "version_required" "true"
        set_github_output "reason" "framework_changes"
        set_github_output "framework_files" "$(IFS=,; echo "${framework_files[*]}")"
        
        return 0
    else
        output_success "No version bump required - only non-framework files changed"
        
        set_github_output "version_required" "false" 
        set_github_output "reason" "no_framework_changes"
        
        return 1
    fi
}

# Check if version was actually bumped
check_version_bump() {
    local base_branch="$1"
    
    # Get versions
    local base_version current_version
    base_version=$(git show "$base_branch:framework/VERSION" 2>/dev/null || echo "0.0.0")
    current_version=$(cat "$PROJECT_ROOT/framework/VERSION" 2>/dev/null || echo "0.0.0")
    
    echo "Base version ($base_branch): $base_version"
    echo "Current version: $current_version"
    
    set_github_output "base_version" "$base_version"
    set_github_output "current_version" "$current_version"
    
    if [ "$base_version" != "$current_version" ]; then
        output_success "Version bump detected: $base_version → $current_version"
        set_github_output "version_bumped" "true"
        return 0
    else
        output_error "Version bump required but not found!"
        set_github_output "version_bumped" "false"
        return 1
    fi
}

# Main execution
main() {
    parse_args "$@"
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Show header
    output_info "Claude Spec-First Framework - Version Requirement Analysis"
    echo "============================================================"
    echo ""
    
    # Analyze what files changed
    local version_required=0
    if analyze_changes "$BASE_BRANCH"; then
        version_required=1
    fi
    
    echo ""
    
    # If version is required, check if it was bumped
    if [ $version_required -eq 1 ]; then
        output_info "Version bump is required - checking if version was bumped..."
        
        if check_version_bump "$BASE_BRANCH"; then
            output_success "✅ Version requirement satisfied"
            set_github_output "requirement_status" "satisfied"
            exit 0
        else
            output_error "❌ Version requirement NOT satisfied"
            echo ""
            echo "Required action:"
            echo "1. Bump version in framework/VERSION"
            echo "2. Add changelog entry in CHANGELOG.md"
            echo ""
            echo "Framework files that require version bump:"
            get_changed_files "$BASE_BRANCH" | while read -r file; do
                if file_matches_patterns "$file" $(get_version_requiring_patterns); then
                    echo "  - $file"
                fi
            done
            
            set_github_output "requirement_status" "unsatisfied"
            exit 1
        fi
    else
        output_success "No version bump required for these changes"
        set_github_output "requirement_status" "not_required"
        exit 0
    fi
}

# Execute main function with all arguments
main "$@"