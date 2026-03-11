#!/bin/bash

# Specification-First Development Framework Validation Script
# Validates all components for Claude Code compliance and functionality
# Supports dual-mode operation: repository mode (./framework/) and installed mode (~/.claude/)

set -e  # Exit on any error

echo "🔍 Validating Specification-First Development Framework..."
echo "=================================================="

# Read framework version directly from VERSION file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Look for VERSION file in the same directory (installed mode) or framework directory (repo mode)
if [ -f "$SCRIPT_DIR/VERSION" ]; then
    FRAMEWORK_VERSION=$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "unknown")
elif [ -f "$SCRIPT_DIR/../framework/VERSION" ]; then
    FRAMEWORK_VERSION=$(cat "$SCRIPT_DIR/../framework/VERSION" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "unknown")
else
    FRAMEWORK_VERSION="unknown"
fi

if [ "$FRAMEWORK_VERSION" != "unknown" ] && [ -n "$FRAMEWORK_VERSION" ]; then
    echo -e "${BLUE}Framework Version: $FRAMEWORK_VERSION${NC}"
else
    echo -e "${YELLOW}Framework Version: unknown (VERSION file not found)${NC}"
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

# Only warn about legacy .csf/ in repository mode (in installed mode, .csf/ is correct)
if [ "$EXECUTION_MODE" != "installed" ] && [ -d ".csf" ]; then
    print_warning "Legacy .csf/ directory detected. Migration recommended:"
    print_info "  1. Copy .csf/ content to ${CLAUDE_DIR:-$HOME/.claude}/.csf/"
    print_info "  2. Remove old .csf/ directory"
fi

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

# Check plugin.json version matches VERSION file (repository mode only)
if [ "$EXECUTION_MODE" = "repository" ] && [ -n "$VERSION_CONTENT" ] && [ -f "./.claude-plugin/plugin.json" ] && command -v jq &>/dev/null; then
    MANIFEST_VERSION=$(jq -r '.version // empty' "./.claude-plugin/plugin.json" 2>/dev/null || true)
    if [ -n "$MANIFEST_VERSION" ]; then
        if [ "$MANIFEST_VERSION" = "$VERSION_CONTENT" ]; then
            print_status "plugin.json version matches VERSION file ($MANIFEST_VERSION)" 0
        else
            print_status "plugin.json version matches VERSION file (got $MANIFEST_VERSION, expected $VERSION_CONTENT)" 1
        fi
    fi
fi

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

# Check skills/commands directory
if [ "$EXECUTION_MODE" = "repository" ]; then
    SKILLS_DIR="./framework/skills"
    if [ -d "$SKILLS_DIR" ]; then
        print_status "skills/ directory exists" 0
        SKILL_COUNT=$(find "$SKILLS_DIR" -name "SKILL.md" -type f 2>/dev/null | wc -l | tr -d ' ')
        print_info "Found $SKILL_COUNT skill files"
    else
        print_status "skills/ directory exists" 1
        SKILL_COUNT=0
    fi
else
    COMMANDS_DIR=$(build_safe_path "commands/csf")
    if [ -d "$COMMANDS_DIR" ]; then
        print_status "commands/ directory exists" 0
        SKILL_COUNT=$(find "$COMMANDS_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
        print_info "Found $SKILL_COUNT command files"
    else
        print_status "commands/ directory exists" 1
        SKILL_COUNT=0
    fi
fi

echo ""
echo "🤖 Validating Sub-Agents..."
echo "=========================="

# Framework Configuration - read from plugin manifest with hardcoded fallback
MANIFEST_FILE=""
if [ "$EXECUTION_MODE" = "repository" ]; then
    MANIFEST_FILE="./.claude-plugin/plugin.json"
else
    # In installed mode, check repo root relative to script dir
    MANIFEST_FILE="$SCRIPT_DIR/../../.claude-plugin/plugin.json"
fi

if [ -f "$MANIFEST_FILE" ] && command -v jq &>/dev/null && jq empty "$MANIFEST_FILE" 2>/dev/null; then
    REQUIRED_AGENTS=()
    while IFS= read -r agent; do
        REQUIRED_AGENTS+=("$agent")
    done < <(jq -r '.agents[]' "$MANIFEST_FILE")
    REQUIRED_SKILLS=()
    while IFS= read -r skill; do
        REQUIRED_SKILLS+=("$skill")
    done < <(jq -r '.skills[]' "$MANIFEST_FILE")
    print_info "Loaded component lists from plugin.json"
else
    REQUIRED_AGENTS=("define-scope" "create-criteria" "identify-risks" "synthesize-spec" "implement-minimal" "analyze-artifacts" "analyze-implementation" "analyze-existing-docs" "create-technical-docs" "create-user-docs" "integrate-docs" "manage-spec-directory")
    REQUIRED_SKILLS=("spec" "implement" "document")
fi
VALID_TOOLS=("Read" "Write" "Edit" "MultiEdit" "Bash" "Grep" "Glob" "LSP")
VALID_MODELS=("haiku")

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

        # Check model field (optional, but must be valid if present)
        if grep -q "^model:" "$AGENT_FILE"; then
            MODEL_VALUE=$(grep "^model:" "$AGENT_FILE" | head -1 | sed 's/^model:[[:space:]]*//')
            MODEL_VALID=false
            for valid_model in "${VALID_MODELS[@]}"; do
                if [ "$MODEL_VALUE" = "$valid_model" ]; then
                    MODEL_VALID=true
                    break
                fi
            done
            if [ "$MODEL_VALID" = true ]; then
                print_status "$agent has valid model field ($MODEL_VALUE)" 0
            else
                print_status "$agent has invalid model field (got '$MODEL_VALUE', expected one of: ${VALID_MODELS[*]})" 1
            fi
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
echo "📋 Validating Skills..."
echo "========================"

for skill in "${REQUIRED_SKILLS[@]}"; do
    # Set skill file path
    if [ "$EXECUTION_MODE" = "repository" ]; then
        SKILL_FILE="./framework/skills/${skill}/SKILL.md"
    else
        SKILL_FILE=$(build_safe_path "commands/csf/${skill}.md")
    fi

    if [ -f "$SKILL_FILE" ]; then
        print_status "$skill skill exists" 0

        # Check YAML frontmatter
        if head -1 "$SKILL_FILE" | grep -q "^---$"; then
            print_status "$skill has YAML frontmatter" 0
        else
            print_status "$skill has YAML frontmatter" 1
        fi

        # Check description field
        if grep -q "^description:" "$SKILL_FILE"; then
            print_status "$skill has description field" 0
        else
            print_status "$skill has description field" 1
        fi

        # Check for $ARGUMENTS usage
        if grep -q '\$ARGUMENTS' "$SKILL_FILE"; then
            print_status "$skill uses \$ARGUMENTS placeholder" 0
        else
            print_warning "$skill doesn't use \$ARGUMENTS (may be intentional)"
        fi

        # Check for agent delegation
        AGENT_MENTIONS=$(grep -c "$AGENT_PATTERN" "$SKILL_FILE" || true)
        if [ $AGENT_MENTIONS -gt 0 ]; then
            print_status "$skill delegates to agents ($AGENT_MENTIONS mentions)" 0
        else
            print_warning "$skill doesn't delegate to agents"
        fi

    else
        print_status "$skill skill exists" 1
    fi
done

# AGENTS.md / CLAUDE.md validation only applies to repository mode
if [ "$EXECUTION_MODE" = "repository" ]; then
    echo ""
    echo "📖 Validating AGENTS.md..."
    echo "=========================="

    AGENTS_MD_PATH="./AGENTS.md"
    CLAUDE_MD_PATH="./CLAUDE.md"

    if [ -f "$AGENTS_MD_PATH" ]; then
        print_status "AGENTS.md exists at repository root" 0

        if grep -q "Claude Spec-First Framework" "$AGENTS_MD_PATH"; then
            print_status "AGENTS.md contains spec-first framework" 0
        else
            print_status "AGENTS.md contains spec-first framework" 1
        fi

        if grep -q "## Core Philosophy" "$AGENTS_MD_PATH"; then
            print_status "AGENTS.md has core philosophy section" 0
        else
            print_status "AGENTS.md has core philosophy section" 1
        fi

        if grep -q "## Principles" "$AGENTS_MD_PATH"; then
            print_status "AGENTS.md has principles section" 0
        else
            print_status "AGENTS.md has principles section" 1
        fi
    else
        print_status "AGENTS.md exists at repository root" 1
    fi

    # CLAUDE.md should reference AGENTS.md
    if [ -f "$CLAUDE_MD_PATH" ]; then
        if grep -q "@AGENTS.md" "$CLAUDE_MD_PATH"; then
            print_status "CLAUDE.md references @AGENTS.md" 0
        else
            print_status "CLAUDE.md references @AGENTS.md" 1
        fi
    else
        print_warning "CLAUDE.md not found (optional — AGENTS.md is the source of truth)"
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

# Check for consistency between agents and skills
SKILL_AGENT_REFS=0
if [ "$EXECUTION_MODE" = "repository" ]; then
    if [ -d "./framework/skills" ]; then
        SKILL_AGENT_REFS=$(grep -rh "$AGENT_PATTERN" ./framework/skills/*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
        print_info "Found $SKILL_AGENT_REFS agent references in skills"
    else
        print_warning "skills/ directory missing"
    fi
else
    if [ -d "$COMMANDS_DIR" ] && ls "$COMMANDS_DIR"/*.md >/dev/null 2>&1; then
        SKILL_AGENT_REFS=$(grep -h "$AGENT_PATTERN" "$COMMANDS_DIR"/*.md | wc -l | tr -d ' ')
        print_info "Found $SKILL_AGENT_REFS agent references in commands"
    else
        print_warning "commands/ directory missing or contains no .md files"
    fi
fi

if [ $SKILL_AGENT_REFS -gt 0 ]; then
    print_status "Skills integrate with agents" 0
else
    print_status "Skills integrate with agents" 1
fi

# Documentation consistency validation
echo ""
echo "📋 Documentation Consistency..."
echo "=============================="

# Only validate documentation consistency in repository mode
if [ "$EXECUTION_MODE" = "repository" ]; then
    # Count actual agents and skills
    ACTUAL_AGENT_COUNT=$(echo "${#REQUIRED_AGENTS[@]}")
    ACTUAL_SKILL_COUNT=$(echo "${#REQUIRED_SKILLS[@]}")

    # AGENTS.md is the source of truth — no agent/skill counts to validate there
    # (counts are derived from REQUIRED_AGENTS/REQUIRED_SKILLS arrays above)
fi

# Check workflow completeness (using centralized skill list)
WORKFLOW_COMPLETE=true

for skill in "${REQUIRED_SKILLS[@]}"; do
    # Set skill path
    if [ "$EXECUTION_MODE" = "repository" ]; then
        SKILL_PATH="./framework/skills/${skill}/SKILL.md"
    else
        SKILL_PATH=$(build_safe_path "commands/csf/${skill}.md")
    fi
    if [ ! -f "$SKILL_PATH" ]; then
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
