#!/bin/bash

# Claude Spec-First Framework Updater
# Updates commands and agents only

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Updating Claude Spec-First Framework (commands and agents only)...${NC}"
echo "===================================================================="

# Determine script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )\" &> /dev/null && pwd )"
CLAUDE_DIR="$HOME/.claude"
CSF_PREFIX="csf"

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
if [ ! -d "$CLAUDE_DIR/commands/$CSF_PREFIX" ] && [ ! -d "$CLAUDE_DIR/agents/$CSF_PREFIX" ] && [ ! -d "$CLAUDE_DIR/.csf" ]; then
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
BACKUP_DIR="$CLAUDE_DIR/.csf/backups/$BACKUP_TIMESTAMP"

echo -e "${BLUE}💾 Creating update backup...${NC}"
mkdir -p "$BACKUP_DIR"

# Backup current framework files
if [ -d "$CLAUDE_DIR/commands/$CSF_PREFIX" ]; then
    cp -r "$CLAUDE_DIR/commands/$CSF_PREFIX" "$BACKUP_DIR/commands-csf"
fi
if [ -d "$CLAUDE_DIR/agents/$CSF_PREFIX" ]; then
    cp -r "$CLAUDE_DIR/agents/$CSF_PREFIX" "$BACKUP_DIR/agents-csf"
fi

echo -e "${GREEN}✅ Backup created: $BACKUP_DIR${NC}"

# Clean up old backups (keep only last 5)
echo -e "${BLUE}🧹 Cleaning up old backups...${NC}"
BACKUP_BASE_DIR="$CLAUDE_DIR/.csf/backups"
if [ -d "$BACKUP_BASE_DIR" ]; then
    # Count current backups and remove oldest if more than 5
    BACKUP_COUNT=$(find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -name "20*" | wc -l)
    if [ "$BACKUP_COUNT" -gt 5 ]; then
        # Remove oldest backups, keeping only the 5 most recent
        find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -name "20*" | sort | head -n -5 | while read -r old_backup; do
            rm -rf "$old_backup"
            echo "  🗑️ Removed old backup: $(basename "$old_backup")"
        done
    fi
fi

echo -e "${BLUE}🔄 Updating framework files...${NC}"

# Update agents with CSF prefix structure
echo "Updating agents..."
mkdir -p "$CLAUDE_DIR/agents/$CSF_PREFIX"
shopt -s nullglob
agent_files=("$SCRIPT_DIR/framework/agents"/*.md)
if [ ${#agent_files[@]} -eq 0 ]; then
    echo "  ⚠️  No agent files found to update."
else
    for agent_file in "${agent_files[@]}"; do
        agent_name=$(basename "$agent_file")
        cp "$agent_file" "$CLAUDE_DIR/agents/$CSF_PREFIX/"
        echo "  ✅ Updated: $CSF_PREFIX/$agent_name"
    done
fi
shopt -u nullglob

# Update commands with CSF prefix structure
echo "Updating commands..."
mkdir -p "$CLAUDE_DIR/commands/$CSF_PREFIX"
shopt -s nullglob
command_files=("$SCRIPT_DIR/framework/commands"/*.md)
if [ ${#command_files[@]} -eq 0 ]; then
    echo "  ⚠️  No command files found to update."
else
    for command_file in "${command_files[@]}"; do
        command_name=$(basename "$command_file")
        cp "$command_file" "$CLAUDE_DIR/commands/$CSF_PREFIX/"
        echo "  ✅ Updated: $CSF_PREFIX/$command_name"
    done
fi
shopt -u nullglob

# Clean up temp directory if it was created
if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

echo ""
echo -e "${GREEN}🎉 Update completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Update Summary:${NC}"
echo "• Commands and agents updated to latest version"
echo "• Previous configuration backed up to: $BACKUP_DIR"
echo "• Old backups cleaned up (keeping last 5)"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Restart Claude Code to load updated agents and commands"
echo ""
echo -e "${GREEN}✨ Framework updated successfully!${NC}"