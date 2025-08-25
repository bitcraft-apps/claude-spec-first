#!/bin/bash

# Specification-First Development Framework Validation Script
# Validates all components for Claude Code compliance and functionality
# Supports dual-mode operation: repository mode (./framework/) and installed mode (~/.claude/)

set -e  # Exit on any error

echo "🔍 Validating Specification-First Development Framework..."
echo "=================================================="

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
    
    # Check for null bytes or other dangerous characters
    if [[ "$path" =~ $'\0' ]] || [[ "$path" =~ [\;\|\`\$] ]]; then
        return 1
    fi
    
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
    # Check if we're in repository mode (has ./framework/ directory)
    if [ -d "./framework" ] && [ -f "./framework/CLAUDE.md" ]; then
        EXECUTION_MODE="repository"
        FRAMEWORK_PREFIX="./framework/"
        print_info "Detected repository mode - using ./framework/ prefix"
        return 0
    fi
    
    # Check if we're in installed mode (has CLAUDE.md in current directory)
    if [ -f "./CLAUDE.md" ]; then
        EXECUTION_MODE="installed"
        FRAMEWORK_PREFIX=""
        print_info "Detected installed mode - using current directory"
        return 0
    fi
    
    # Neither mode detected
    echo -e "${RED}❌ Invalid execution context${NC}" >&2
    echo -e "${RED}This script must be run from either:${NC}" >&2
    echo -e "${RED}  - Repository root (with ./framework/ directory)${NC}" >&2
    echo -e "${RED}  - Installed location (~/.claude/ with CLAUDE.md)${NC}" >&2
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
CLAUDE_MD_PATH=$(build_safe_path "CLAUDE.md")
if [ ! -f "$CLAUDE_MD_PATH" ]; then
    echo -e "${RED}❌ Framework CLAUDE.md not found at: $CLAUDE_MD_PATH${NC}"
    exit 1
fi

print_status "CLAUDE.md exists ($EXECUTION_MODE mode)" 0

# Check agents directory
AGENTS_DIR=$(build_safe_path "agents")
if [ -d "$AGENTS_DIR" ]; then
    print_status "agents/ directory exists" 0
    AGENT_COUNT=$(find "$AGENTS_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    print_info "Found $AGENT_COUNT agent files"
else
    print_status "agents/ directory exists" 1
    AGENT_COUNT=0
fi

# Check commands directory
COMMANDS_DIR=$(build_safe_path "commands")
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
REQUIRED_AGENTS=("spec-analyst" "test-designer" "arch-designer" "impl-specialist" "qa-validator" "doc-synthesizer")
REQUIRED_COMMANDS=("spec-init" "spec-review" "impl-plan" "qa-check" "spec-workflow" "doc-generate")
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
    AGENT_FILE=$(build_safe_path "agents/${agent}.md")
    
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
echo "=========================="
echo -e "${YELLOW}Note: This script assumes CLAUDE.md is in the current directory. If you use a custom CLAUDE_DIR, paths may differ.${NC}"
echo "📋 Validating Commands..."
echo "========================"

# Using centralized REQUIRED_COMMANDS from framework configuration above

for command in "${REQUIRED_COMMANDS[@]}"; do
    COMMAND_FILE=$(build_safe_path "commands/${command}.md")
    
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

echo ""
echo "📖 Validating CLAUDE.md..."
echo "=========================="

# Check CLAUDE.md content using safe path
if grep -q "Specification-First Development" "$CLAUDE_MD_PATH"; then
    print_status "CLAUDE.md contains specification-first principles" 0
else
    print_status "CLAUDE.md contains specification-first principles" 1
fi

if grep -q "## Core Principles" "$CLAUDE_MD_PATH"; then
    print_status "CLAUDE.md has core principles section" 0
else
    print_status "CLAUDE.md has core principles section" 1
fi

if grep -q "## Workflow" "$CLAUDE_MD_PATH"; then
    print_status "CLAUDE.md has workflow section" 0
else
    print_status "CLAUDE.md has workflow section" 1
fi

if grep -q "## Instructions for Claude" "$CLAUDE_MD_PATH"; then
    print_status "CLAUDE.md has Claude instructions" 0
else
    print_status "CLAUDE.md has Claude instructions" 1
fi

echo ""
echo "📚 Checking Documentation..."
echo "============================"

README_PATH=$(build_safe_path "README.md")
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

echo ""
echo "📄 Validating Documentation Templates..."
echo "========================================"

# Check templates directory
TEMPLATES_DIR=$(build_safe_path "templates")
if [ -d "$TEMPLATES_DIR" ]; then
    print_status "templates/ directory exists" 0
    
    # Check technical templates
    TECH_TEMPLATES_DIR=$(build_safe_path "templates/technical")
    if [ -d "$TECH_TEMPLATES_DIR" ]; then
        print_status "templates/technical/ directory exists" 0
        TECH_TEMPLATE_COUNT=$(find "$TECH_TEMPLATES_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
        print_info "Found $TECH_TEMPLATE_COUNT technical template files"
    else
        print_warning "templates/technical/ directory missing (recommended)"
    fi
    
    # Check user templates
    USER_TEMPLATES_DIR=$(build_safe_path "templates/user")
    if [ -d "$USER_TEMPLATES_DIR" ]; then
        print_status "templates/user/ directory exists" 0
        USER_TEMPLATE_COUNT=$(find "$USER_TEMPLATES_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
        print_info "Found $USER_TEMPLATE_COUNT user template files"
    else
        print_warning "templates/user/ directory missing (recommended)"
    fi
    
    # Check for core template files
    CORE_TEMPLATES=("documentation-structure.md" "metadata-system.md" "archival-process.md")
    for template in "${CORE_TEMPLATES[@]}"; do
        TEMPLATE_PATH=$(build_safe_path "templates/$template")
        if [ -f "$TEMPLATE_PATH" ]; then
            print_status "$template template exists" 0
        else
            print_warning "$template template missing (recommended)"
        fi
    done
    
else
    print_warning "templates/ directory missing (recommended for doc-generate functionality)"
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

# Check workflow completeness (using centralized command list)
WORKFLOW_COMPLETE=true

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    CMD_PATH=$(build_safe_path "commands/${cmd}.md")
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
    echo "- Try: /spec-init sample feature"
    echo "- Test: /spec-workflow complete example (now includes documentation generation)"
    echo "- Generate docs: /doc-generate project-name"
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