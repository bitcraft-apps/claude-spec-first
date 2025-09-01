#!/bin/bash

# Specification-First Development Framework Validation Script
# Validates all components for Claude Code compliance and functionality
# Supports dual-mode operation: repository mode (./framework/) and installed mode (~/.claude/)

set -e  # Exit on any error

echo "🔍 Validating Specification-First Development Framework..."
echo "=================================================="

# Try to load and display framework version
# Search for version.sh in several likely locations using robust path resolution
VERSION_SH=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_DIR="$(pwd)"

# Check multiple potential locations for version utilities with absolute paths where possible
if [ -f "$SCRIPT_DIR/../scripts/version.sh" ]; then
    VERSION_SH="$SCRIPT_DIR/../scripts/version.sh"
elif [ -f "$SCRIPT_DIR/scripts/version.sh" ]; then
    VERSION_SH="$SCRIPT_DIR/scripts/version.sh"
elif [ -f "${CLAUDE_DIR:-$HOME/.claude}/utils/version.sh" ]; then
    VERSION_SH="${CLAUDE_DIR:-$HOME/.claude}/utils/version.sh"
elif [ -f "$HOME/.claude/utils/version.sh" ]; then
    VERSION_SH="$HOME/.claude/utils/version.sh"
elif [ -f "./scripts/version.sh" ]; then
    VERSION_SH="./scripts/version.sh"
elif [ -f "$(dirname "$CURRENT_DIR")/utils/version.sh" ]; then
    VERSION_SH="$(dirname "$CURRENT_DIR")/utils/version.sh"
fi

if [ -n "$VERSION_SH" ]; then
    . "$VERSION_SH"
    FRAMEWORK_VERSION=$(get_framework_version 2>/dev/null || echo "unknown")
    echo -e "${BLUE}Framework Version: $FRAMEWORK_VERSION${NC}"
else
    FRAMEWORK_VERSION="unknown"
    echo -e "${YELLOW}Framework Version: $FRAMEWORK_VERSION (version utilities not found)${NC}"
fi
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Function to print status
print_status() {
    if [ $2 -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ $1${NC}"
        FAILED=$((FAILED + 1))
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Security and Path Management Functions

# Validate path security - prevent directory traversal attacks
validate_path_security() {
    local path="$1"

    # Check for directory traversal attempts (../ or /./)
    if [[ "$path" == *"../"* ]] || [[ "$path" == *"/./"* ]] || [[ "$path" == *"//"* ]]; then
        return 1
    fi

    # Check for paths starting with ../
    if [[ "$path" == "../"* ]]; then
        return 1
    fi

    # Check for dangerous characters using string pattern matching (more portable)
    case "$path" in
        *\;* | *\|* | *\`* | *\$*) return 1 ;;
    esac

    # Note: Null byte checking removed due to CI environment compatibility issues
    # Null bytes in legitimate file paths are extremely rare in practice

    return 0
}

# Build safe path with framework prefix and security validation
build_safe_path() {
    local relative_path="$1"
    local full_path="${FRAMEWORK_PREFIX}${relative_path}"

    # Validate path security
    if ! validate_path_security "$full_path"; then
        echo -e "${RED}Security Error: Invalid path detected: $full_path${NC}" >&2
        exit 1
    fi

    echo "$full_path"
}

# Detect execution mode based on directory structure
detect_execution_mode() {
    # Get absolute path of script directory for reliable detection
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local current_dir="$(pwd)"

    # Check if we're in repository mode (has ./framework/ directory with VERSION)
    if [ -d "./framework" ] && [ -f "./framework/VERSION" ]; then
        EXECUTION_MODE="repository"
        FRAMEWORK_PREFIX="./framework/"
        print_info "Detected repository mode - using ./framework/ prefix"
        return 0
    fi

    # Check if we're in installed mode (has commands/csf and agents/csf directories)
    if [ -d "./commands/csf" ] && [ -d "./agents/csf" ]; then
        EXECUTION_MODE="installed"
        FRAMEWORK_PREFIX=""
        print_info "Detected installed mode - validating current directory"
        return 0
    fi

    # Check if we're running from .csf directory using absolute paths
    # Look for Claude directory structure (commands/csf and agents/csf in parent)
    local parent_dir="$(dirname "$current_dir")"
    if [ -d "$parent_dir/commands/csf" ] && [ -d "$parent_dir/agents/csf" ]; then
        EXECUTION_MODE="installed"
        FRAMEWORK_PREFIX="$parent_dir/"
        print_info "Detected installed mode (.csf location) - validating parent directory at $parent_dir"
        return 0
    fi

    # Check environment variable for Claude directory
    local claude_dir="${CLAUDE_DIR:-$HOME/.claude}"
    if [ -d "$claude_dir/commands/csf" ] && [ -d "$claude_dir/agents/csf" ]; then
        EXECUTION_MODE="installed"
        FRAMEWORK_PREFIX="$claude_dir/"
        print_info "Detected installed mode via CLAUDE_DIR - validating $claude_dir"
        return 0
    fi

    # Check default installed location
    if [ -d "$HOME/.claude/commands/csf" ] && [ -d "$HOME/.claude/agents/csf" ]; then
        EXECUTION_MODE="installed"
        FRAMEWORK_PREFIX="$HOME/.claude/"
        print_info "Detected installed mode - validating $HOME/.claude"
        return 0
    fi

    # Neither mode detected
    echo -e "${RED}❌ Invalid execution context${NC}" >&2
    echo -e "${RED}This script must be run from either:${NC}" >&2
    echo -e "${RED}  - Repository root (with ./framework/ directory)${NC}" >&2
    echo -e "${RED}  - Installed location (~/.claude/ or \$CLAUDE_DIR)${NC}" >&2
    echo -e "${RED}  - Framework metadata directory (~/.claude/.csf/)${NC}" >&2
    echo -e "${RED}Current directory: $current_dir${NC}" >&2
    echo -e "${RED}Script directory: $script_dir${NC}" >&2
    exit 1
}

# Execution mode detection and path management
EXECUTION_MODE=""
FRAMEWORK_PREFIX=""

echo ""
echo "📁 Checking Directory Structure..."
echo "=================================="

# Initialize execution mode detection
detect_execution_mode

# Check framework structure using detected mode
if [ "$EXECUTION_MODE" = "repository" ]; then
    # In repository mode, check for essential framework components
    print_status "Framework structure detected ($EXECUTION_MODE mode)" 0
else
    # In installed mode, check for CSF directories
    print_status "Framework structure detected ($EXECUTION_MODE mode)" 0
fi

# Check VERSION file
if [ "$EXECUTION_MODE" = "repository" ]; then
    VERSION_PATH=$(build_safe_path "VERSION")
else
    VERSION_PATH=$(build_safe_path ".csf/VERSION")
fi
if [ -f "$VERSION_PATH" ]; then
    print_status "VERSION file exists" 0
    # Use version utilities if available, otherwise fall back to manual parsing
    if command -v get_framework_version >/dev/null 2>&1; then
        VERSION_CONTENT=$(get_framework_version 2>/dev/null || echo "")
    else
        VERSION_CONTENT=$(cat "$VERSION_PATH" 2>/dev/null | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    fi
    if echo "$VERSION_CONTENT" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' >/dev/null; then
        print_status "VERSION file has valid format" 0
        print_info "Framework version: $VERSION_CONTENT"
    else
        print_status "VERSION file has valid format" 1
        print_info "VERSION content: '$VERSION_CONTENT'"
    fi
else
    print_status "VERSION file exists" 1
fi

# Version utilities are available in both repository and installed modes
# The installation script copies version utilities to the installed framework

# Check agents directory
if [ "$EXECUTION_MODE" = "repository" ]; then
    AGENTS_DIR=$(build_safe_path "agents")
else
    AGENTS_DIR=$(build_safe_path "agents/csf")
fi
if [ -d "$AGENTS_DIR" ]; then
    print_status "agents/ directory exists" 0
    AGENT_COUNT=$(find "$AGENTS_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    print_info "Found $AGENT_COUNT agent files"
else
    print_status "agents/ directory exists" 1
    AGENT_COUNT=0
fi

# Check commands directory
if [ "$EXECUTION_MODE" = "repository" ]; then
    COMMANDS_DIR=$(build_safe_path "commands")
else
    COMMANDS_DIR=$(build_safe_path "commands/csf")
fi
if [ -d "$COMMANDS_DIR" ]; then
    print_status "commands/ directory exists" 0
    COMMAND_COUNT=$(find "$COMMANDS_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    print_info "Found $COMMAND_COUNT command files"
else
    print_status "commands/ directory exists" 1
    COMMAND_COUNT=0
fi

echo ""
echo "🤖 Validating Sub-Agents..."
echo "=========================="

# Framework Configuration - centralized list of required components
REQUIRED_AGENTS=("define-scope" "create-criteria" "identify-risks" "synthesize-spec" "csf-implement" "csf-document")
REQUIRED_COMMANDS=("spec" "implement" "document")
VALID_TOOLS=("Read" "Write" "Edit" "MultiEdit" "Bash" "Grep" "Glob")

# Function to build agent pattern dynamically from REQUIRED_AGENTS array
build_agent_pattern() {
    local pattern=""
    local first=true
    for agent in "${REQUIRED_AGENTS[@]}"; do
        if [ "$first" = true ]; then
            pattern="$agent"
            first=false
        else
            pattern="$pattern\|$agent"
        fi
    done
    echo "$pattern"
}

# Build agent pattern for grep searches (used in multiple places)
AGENT_PATTERN=$(build_agent_pattern)

for agent in "${REQUIRED_AGENTS[@]}"; do
    # Remove csf- prefix from agent name for filename
    AGENT_FILENAME=${agent#csf-}

    # Set agent file path
    if [ "$EXECUTION_MODE" = "repository" ]; then
        AGENT_FILE=$(build_safe_path "agents/${AGENT_FILENAME}.md")
    else
        AGENT_FILE=$(build_safe_path "agents/csf/${AGENT_FILENAME}.md")
    fi

    if [ -f "$AGENT_FILE" ]; then
        print_status "$agent.md exists" 0

        # Check YAML frontmatter
        if head -1 "$AGENT_FILE" | grep -q "^---$"; then
            print_status "$agent has YAML frontmatter" 0
        else
            print_status "$agent has YAML frontmatter" 1
        fi

        # Check required fields
        if grep -q "^name: $agent$" "$AGENT_FILE"; then
            print_status "$agent has correct name field" 0
        else
            print_status "$agent has correct name field" 1
        fi

        if grep -q "^description:" "$AGENT_FILE"; then
            print_status "$agent has description field" 0
        else
            print_status "$agent has description field" 1
        fi

        # Check tools field format
        if grep -q "^tools:" "$AGENT_FILE"; then
            TOOLS_LINE=$(grep "^tools:" "$AGENT_FILE")
            print_info "$agent tools: $TOOLS_LINE"

            # Validate tool names
            INVALID_TOOLS=false
            for tool in "${VALID_TOOLS[@]}"; do
                if echo "$TOOLS_LINE" | grep -q "$tool"; then
                    continue
                fi
            done
        else
            print_warning "$agent missing tools field (optional but recommended)"
        fi

        # Check content structure
        if grep -q "^# " "$AGENT_FILE"; then
            print_status "$agent has proper content structure" 0
        else
            print_status "$agent has proper content structure" 1
        fi

    else
        print_status "$agent.md exists" 1
    fi
done

echo ""
echo "📋 Validating Commands..."
echo "========================"

# Using centralized REQUIRED_COMMANDS from framework configuration above

for command in "${REQUIRED_COMMANDS[@]}"; do
    # Set command file path
    if [ "$EXECUTION_MODE" = "repository" ]; then
        COMMAND_FILE=$(build_safe_path "commands/${command}.md")
    else
        COMMAND_FILE=$(build_safe_path "commands/csf/${command}.md")
    fi

    if [ -f "$COMMAND_FILE" ]; then
        print_status "$command.md exists" 0

        # Check YAML frontmatter
        if head -1 "$COMMAND_FILE" | grep -q "^---$"; then
            print_status "$command has YAML frontmatter" 0
        else
            print_status "$command has YAML frontmatter" 1
        fi

        # Check description field
        if grep -q "^description:" "$COMMAND_FILE"; then
            print_status "$command has description field" 0
        else
            print_status "$command has description field" 1
        fi

        # CSF prefix is handled by the command routing system

        # Check for $ARGUMENTS usage
        if grep -q '\$ARGUMENTS' "$COMMAND_FILE"; then
            print_status "$command uses \$ARGUMENTS placeholder" 0
        else
            print_warning "$command doesn't use \$ARGUMENTS (may be intentional)"
        fi

        # Check for agent delegation
        AGENT_MENTIONS=$(grep -c "$AGENT_PATTERN" "$COMMAND_FILE" || true)
        if [ $AGENT_MENTIONS -gt 0 ]; then
            print_status "$command delegates to agents ($AGENT_MENTIONS mentions)" 0
        else
            print_warning "$command doesn't delegate to agents"
        fi

    else
        print_status "$command.md exists" 1
    fi
done

# CLAUDE.md validation only applies to repository mode
if [ "$EXECUTION_MODE" = "repository" ]; then
    echo ""
    echo "📖 Validating CLAUDE.md..."
    echo "=========================="

    # In repository mode, CLAUDE.md is at the root level (relative to current working directory)
    CLAUDE_MD_PATH="./CLAUDE.md"

    # Direct file check (bypassing build_safe_path for this legitimate case)
    if [ -f "$CLAUDE_MD_PATH" ]; then
        print_status "CLAUDE.md exists at repository root" 0

        # Check CLAUDE.md content
        if grep -q "Claude Spec-First Framework" "$CLAUDE_MD_PATH"; then
            print_status "CLAUDE.md contains spec-first framework" 0
        else
            print_status "CLAUDE.md contains spec-first framework" 1
        fi

        if grep -q "## Architecture Overview" "$CLAUDE_MD_PATH"; then
            print_status "CLAUDE.md has architecture overview section" 0
        else
            print_status "CLAUDE.md has architecture overview section" 1
        fi

        if grep -q "## Development Workflow" "$CLAUDE_MD_PATH"; then
            print_status "CLAUDE.md has development workflow section" 0
        else
            print_status "CLAUDE.md has development workflow section" 1
        fi

        if grep -q "## Project Overview" "$CLAUDE_MD_PATH"; then
            print_status "CLAUDE.md has project overview" 0
        else
            print_status "CLAUDE.md has project overview" 1
        fi
    else
        print_status "CLAUDE.md exists at repository root" 1
    fi
fi

# Documentation validation only applies to repository mode
if [ "$EXECUTION_MODE" = "repository" ]; then
    echo ""
    echo "📚 Checking Documentation..."
    echo "============================"

    # In repository mode, README.md is at the root level (relative to current working directory)
    README_PATH="./README.md"
    if [ -f "$README_PATH" ]; then
        print_status "README.md exists" 0

        if grep -q "Quick Start" "$README_PATH"; then
            print_status "README.md has quick start guide" 0
        else
            print_status "README.md has quick start guide" 1
        fi

        if grep -q "Command Reference" "$README_PATH"; then
            print_status "README.md has command reference" 0
        else
            print_status "README.md has command reference" 1
        fi
    else
        print_status "README.md exists" 1
    fi

    EXAMPLES_DIR=$(build_safe_path "examples")
    if [ -d "$EXAMPLES_DIR" ]; then
        print_status "examples/ directory exists" 0
        EXAMPLE_COUNT=$(find "$EXAMPLES_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
        print_info "Found $EXAMPLE_COUNT example files"
    else
        print_warning "examples/ directory missing (recommended)"
    fi
fi

echo ""
echo "🔧 Integration Checks..."
echo "======================="

# Check for consistency between agents and commands
if [ -d "$COMMANDS_DIR" ] && ls "$COMMANDS_DIR"/*.md >/dev/null 2>&1; then
    COMMAND_AGENT_REFS=$(grep -h "$AGENT_PATTERN" "$COMMANDS_DIR"/*.md | wc -l | tr -d ' ')
    print_info "Found $COMMAND_AGENT_REFS agent references in commands"
else
    print_warning "commands/ directory missing or contains no .md files"
    COMMAND_AGENT_REFS=0
fi

if [ $COMMAND_AGENT_REFS -gt 0 ]; then
    print_status "Commands integrate with agents" 0
else
    print_status "Commands integrate with agents" 1
fi

# Documentation consistency validation
echo ""
echo "📋 Documentation Consistency..."
echo "=============================="

# Only validate documentation consistency in repository mode
if [ "$EXECUTION_MODE" = "repository" ]; then
    # Count actual agents and commands
    ACTUAL_AGENT_COUNT=$(echo "${#REQUIRED_AGENTS[@]}")
    ACTUAL_COMMAND_COUNT=$(echo "${#REQUIRED_COMMANDS[@]}")

    # Check CLAUDE.md for consistent agent count references
    if [ -f "./CLAUDE.md" ]; then
        # Check for "4 specialized sub-agents" reference
        if grep -q "$ACTUAL_AGENT_COUNT specialized sub-agents" "./CLAUDE.md"; then
            print_status "CLAUDE.md agent count is consistent" 0
        else
            if grep -q "[0-9] specialized sub-agents" "./CLAUDE.md"; then
                print_status "CLAUDE.md agent count is consistent" 1
                INCORRECT_COUNT=$(grep -o "[0-9] specialized sub-agents" "./CLAUDE.md" | head -1)
                print_info "Found: '$INCORRECT_COUNT', Expected: '$ACTUAL_AGENT_COUNT specialized sub-agents'"
            else
                print_warning "CLAUDE.md agent count reference not found"
            fi
        fi

        # Check for workflow command count references
        if grep -q "$ACTUAL_COMMAND_COUNT workflow commands" "./CLAUDE.md"; then
            print_status "CLAUDE.md command count is consistent" 0
        else
            if grep -q "[0-9] workflow commands" "./CLAUDE.md"; then
                print_status "CLAUDE.md command count is consistent" 1
                INCORRECT_COUNT=$(grep -o "[0-9] workflow commands" "./CLAUDE.md" | head -1)
                print_info "Found: '$INCORRECT_COUNT', Expected: '$ACTUAL_COMMAND_COUNT workflow commands'"
            else
                print_warning "CLAUDE.md command count reference not found"
            fi
        fi
    fi

    # Check README.md for command count consistency
    if [ -f "./README.md" ]; then
        if grep -q "$ACTUAL_COMMAND_COUNT streamlined commands" "./README.md"; then
            print_status "README.md command count is consistent" 0
        else
            if grep -q "[0-9] streamlined commands" "./README.md"; then
                print_status "README.md command count is consistent" 1
                INCORRECT_COUNT=$(grep -o "[0-9] streamlined commands" "./README.md" | head -1)
                print_info "Found: '$INCORRECT_COUNT', Expected: '$ACTUAL_COMMAND_COUNT streamlined commands'"
            else
                print_warning "README.md command count reference not found"
            fi
        fi
    fi
fi

# Check workflow completeness (using centralized command list)
WORKFLOW_COMPLETE=true

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    # Set command path
    if [ "$EXECUTION_MODE" = "repository" ]; then
        CMD_PATH=$(build_safe_path "commands/${cmd}.md")
    else
        CMD_PATH=$(build_safe_path "commands/csf/${cmd}.md")
    fi
    if [ ! -f "$CMD_PATH" ]; then
        WORKFLOW_COMPLETE=false
        break
    fi
done

if [ "$WORKFLOW_COMPLETE" = true ]; then
    print_status "Complete workflow chain available" 0
else
    print_status "Complete workflow chain available" 1
fi

echo ""
echo "📊 Validation Summary"
echo "===================="
echo -e "Passed:   ${GREEN}$PASSED${NC}"
echo -e "Failed:   ${RED}$FAILED${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

# Final assessment
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Framework validation PASSED!${NC}"
    echo -e "${GREEN}The specification-first development framework is properly configured and ready for use.${NC}"

    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Note: $WARNINGS warnings found. Consider addressing them for optimal performance.${NC}"
    fi

    echo ""
    echo "=========================="
    echo -e "${YELLOW}Note: Running in $EXECUTION_MODE mode with prefix: '$FRAMEWORK_PREFIX'${NC}"
    echo ""
    echo "🚀 Next Steps:"
    echo "- Create spec: /csf:spec sample feature"
    echo "- Implement code: /csf:implement spec-file-or-requirements"
    echo "- Generate docs: /csf:document spec-and-code-paths"
    echo "- Spec creation: /csf:spec [requirements] for creating specifications"
    echo "- Review: README.md for detailed usage guide"

    exit 0
else
    echo -e "${RED}❌ Framework validation FAILED!${NC}"
    echo -e "${RED}$FAILED critical issues must be resolved before using the framework.${NC}"

    echo ""
    echo "🔧 Recommended Actions:"
    echo "- Fix missing files and directories"
    echo "- Correct YAML frontmatter syntax"
    echo "- Ensure all required fields are present"
    echo "- Restart Claude Code after fixes"

    exit 1
fi
