#!/bin/bash

# Claude Spec-First Framework Updater
# Updates the Specification-First Development Framework for Claude Code

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Updating Claude Spec-First Framework...${NC}"
echo "============================================="

# Determine script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CLAUDE_DIR="$HOME/.claude"

# Check if we're in a git repository
if [ ! -d "$SCRIPT_DIR/.git" ]; then
    echo -e "${YELLOW}⚠️  Not a git repository. Attempting to update via remote download...${NC}"
    # Download latest version to temp directory
    TEMP_DIR=$(mktemp -d)
    echo -e "${BLUE}📥 Downloading latest framework...${NC}"
    # Determine repository URL (env var, arg, or default)
    REPO_URL="${CLAUDE_REPO_URL:-${1:-https://github.com/bitcraft-apps/claude-spec-first.git}}"
    if command -v git >/dev/null 2>&1; then
        git clone "$REPO_URL" "$TEMP_DIR" || {
            echo -e "${RED}❌ Failed to download updates. Please check your internet connection.${NC}"
            exit 1
        }
        SCRIPT_DIR="$TEMP_DIR"
    else
        echo -e "${RED}❌ Git not available and not in a git repository.${NC}"
        echo -e "${RED}   Please either install git or run from a cloned repository.${NC}"
        exit 1
    fi
fi

# Check if framework is currently installed
if [ ! -f "$CLAUDE_DIR/agents/spec-analyst.md" ]; then
    echo -e "${YELLOW}⚠️  Framework doesn't appear to be installed.${NC}"
    echo -e "${BLUE}🚀 Running initial installation instead...${NC}"
    exec "$SCRIPT_DIR/install.sh"
fi

echo -e "${BLUE}📡 Fetching latest updates...${NC}"

# Save current branch (compatible with older git versions)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Fetch and pull latest changes
git fetch origin
git pull origin "$CURRENT_BRANCH" || {
    echo -e "${RED}❌ Failed to pull updates. Please resolve any conflicts and try again.${NC}"
    exit 1
}

# Check if there were any changes
if git diff --quiet HEAD@{1} HEAD; then
    echo -e "${GREEN}✅ Already up to date!${NC}"
    exit 0
fi

echo -e "${BLUE}📋 Changes detected, updating installation...${NC}"

# Show what changed
echo -e "${BLUE}📝 Recent changes:${NC}"
git log --oneline -5 HEAD@{1}..HEAD

# Create backup timestamp
BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$HOME/.claude-update-backup-$BACKUP_TIMESTAMP"

echo -e "${BLUE}💾 Creating update backup...${NC}"
mkdir -p "$BACKUP_DIR"

# Backup current framework files
if [ -d "$CLAUDE_DIR/agents" ]; then
    cp -r "$CLAUDE_DIR/agents" "$BACKUP_DIR/"
fi
if [ -d "$CLAUDE_DIR/commands" ]; then
    cp -r "$CLAUDE_DIR/commands" "$BACKUP_DIR/"
fi
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    cp "$CLAUDE_DIR/CLAUDE.md" "$BACKUP_DIR/"
fi

echo -e "${GREEN}✅ Backup created: $BACKUP_DIR${NC}"

echo -e "${BLUE}🔄 Updating framework files...${NC}"

# Update agents (preserve any custom agents by checking names)
echo "Updating agents..."
shopt -s nullglob
agent_files=("$SCRIPT_DIR/framework/agents"/*.md)
if [ ${#agent_files[@]} -eq 0 ]; then
    echo "  ⚠️  No agent files found to update."
else
    for agent_file in "${agent_files[@]}"; do
        agent_name=$(basename "$agent_file")
        cp "$agent_file" "$CLAUDE_DIR/agents/"
        echo "  ✅ Updated: $agent_name"
    done
fi
shopt -u nullglob

# Update commands (preserve any custom commands by checking names)  
echo "Updating commands..."
shopt -s nullglob
command_files=("$SCRIPT_DIR/framework/commands"/*.md)
if [ ${#command_files[@]} -eq 0 ]; then
    echo "  ⚠️  No command files found to update."
else
    for command_file in "${command_files[@]}"; do
        command_name=$(basename "$command_file")
        cp "$command_file" "$CLAUDE_DIR/commands/"
        echo "  ✅ Updated: $command_name"
    done
fi
shopt -u nullglob

# Update examples
echo "Updating examples..."
cp -r "$SCRIPT_DIR/framework/examples/." "$CLAUDE_DIR/examples/"
echo "  ✅ Examples updated"

# Update validation script
echo "Updating validation script..."
cp "$SCRIPT_DIR/framework/validate-framework.sh" "$CLAUDE_DIR/"
chmod +x "$CLAUDE_DIR/validate-framework.sh"
echo "  ✅ Validation script updated"

echo -e "${BLUE}📝 Updating CLAUDE.md...${NC}"

# Handle CLAUDE.md update (preserve user customizations)
FRAMEWORK_CLAUDE="$SCRIPT_DIR/framework/CLAUDE.md"
USER_CLAUDE="$CLAUDE_DIR/CLAUDE.md"

if [ -f "$USER_CLAUDE" ]; then
    # Check if user has framework section
    if grep -q "Claude Spec-First Framework Integration" "$USER_CLAUDE"; then
        echo -e "${YELLOW}⚠️  Found existing framework integration in CLAUDE.md${NC}"
        echo -e "${BLUE}🔀 Updating framework section...${NC}"
        
        # Create temporary file with updated content
        TEMP_CLAUDE=$(mktemp)
        
        # Copy everything before framework section
        sed '/# Claude Spec-First Framework Integration/,$d' "$USER_CLAUDE" > "$TEMP_CLAUDE"
        
        # Add updated framework section
        echo "# ========================================" >> "$TEMP_CLAUDE"
        echo "# Claude Spec-First Framework Integration" >> "$TEMP_CLAUDE"
        echo "# ========================================" >> "$TEMP_CLAUDE"
        echo "" >> "$TEMP_CLAUDE"
        tail -n +2 "$FRAMEWORK_CLAUDE" >> "$TEMP_CLAUDE"
        
        # Replace original file
        mv "$TEMP_CLAUDE" "$USER_CLAUDE"
        echo -e "${GREEN}✅ Framework section updated in CLAUDE.md${NC}"
    else
        echo -e "${YELLOW}⚠️  No framework section found in CLAUDE.md - adding it${NC}"
        echo "" >> "$USER_CLAUDE"
        echo "# ========================================" >> "$USER_CLAUDE"
        echo "# Claude Spec-First Framework Integration" >> "$USER_CLAUDE"
        echo "# ========================================" >> "$USER_CLAUDE"
        echo "" >> "$USER_CLAUDE"
        tail -n +2 "$FRAMEWORK_CLAUDE" >> "$USER_CLAUDE"
        echo -e "${GREEN}✅ Framework section added to CLAUDE.md${NC}"
    fi
else
    # No CLAUDE.md exists, create it
    cp "$FRAMEWORK_CLAUDE" "$USER_CLAUDE"
    echo -e "${GREEN}✅ CLAUDE.md created${NC}"
fi

# Clean up temp directory if it was created
if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

echo ""
echo -e "${GREEN}🎉 Update completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Update Summary:${NC}"
echo "• Framework files updated to latest version"
echo "• Previous configuration backed up to: $BACKUP_DIR"
echo "• User customizations preserved"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Restart Claude Code to load updated agents and commands"
echo "2. Run validation to ensure everything works:"
echo -e "   ${YELLOW}~/.claude/validate-framework.sh${NC}"
echo "3. Check changelog for new features:"
echo -e "   ${YELLOW}git log --oneline -10${NC}"
echo ""
echo -e "${GREEN}✨ Framework updated successfully!${NC}"