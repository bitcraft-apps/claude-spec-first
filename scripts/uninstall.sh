#!/bin/bash

# Claude Spec-First Framework Uninstaller
# Removes commands and agents only

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🗑️  Uninstalling Claude Spec-First Framework (commands and agents only)...${NC}"
echo "========================================================================="

# Find project root (directory containing CLAUDE.md)
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ]; do
    if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
        break
    fi
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done

if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
    echo -e "${RED}❌ Not in a Claude Spec-First Framework project directory${NC}"
    echo "Please run this script from within a project containing CLAUDE.md"
    exit 1
fi

CLAUDE_DIR="$PROJECT_ROOT/.claude"
CSF_PREFIX="csf"

# Check if framework is installed
if [ ! -d "$CLAUDE_DIR/commands/$CSF_PREFIX" ] && [ ! -d "$CLAUDE_DIR/agents/$CSF_PREFIX" ] && [ ! -d "$CLAUDE_DIR/.csf" ]; then
    echo -e "${YELLOW}⚠️  Framework doesn't appear to be installed.${NC}"
    echo -e "${BLUE}Nothing to uninstall.${NC}"
    exit 0
fi

echo -e "${BLUE}📋 Analyzing current installation...${NC}"

echo -e "${YELLOW}⚠️  This will remove:${NC}"
echo "• All CSF commands from $CLAUDE_DIR/commands/$CSF_PREFIX/"
echo "• All CSF agents from $CLAUDE_DIR/agents/$CSF_PREFIX/"
echo "• Framework metadata and backups from $CLAUDE_DIR/.csf/"
echo ""

# Confirmation prompt
echo -n "Are you sure you want to uninstall? (y/N): "
read -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}❌ Uninstallation cancelled.${NC}"
    exit 0
fi

echo -e "${BLUE}🗑️  Removing framework commands and agents...${NC}"

# Remove CSF commands directory
if [ -d "$CLAUDE_DIR/commands/$CSF_PREFIX" ]; then
    rm -rf "$CLAUDE_DIR/commands/$CSF_PREFIX"
    echo "  ✅ Removed: commands/$CSF_PREFIX/"
fi

# Remove CSF agents directory
if [ -d "$CLAUDE_DIR/agents/$CSF_PREFIX" ]; then
    rm -rf "$CLAUDE_DIR/agents/$CSF_PREFIX"
    echo "  ✅ Removed: agents/$CSF_PREFIX/"
fi

# Remove framework metadata directory
if [ -d "$CLAUDE_DIR/.csf" ]; then
    rm -rf "$CLAUDE_DIR/.csf"
    echo "  ✅ Removed: .csf/ (metadata and backups)"
fi

# Note: Legacy directories in other locations should be cleaned manually

# Clean up empty parent directories
rmdir "$CLAUDE_DIR/commands" 2>/dev/null && echo "  ✅ Removed empty commands directory" || true
rmdir "$CLAUDE_DIR/agents" 2>/dev/null && echo "  ✅ Removed empty agents directory" || true

echo ""
echo -e "${GREEN}🎉 Uninstallation completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Uninstallation Summary:${NC}"
echo "• All CSF commands removed"
echo "• All CSF agents removed"
echo "• Framework metadata and backups removed"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Restart Claude Code to unload framework components"
echo ""
echo -e "${GREEN}✨ Framework successfully uninstalled!${NC}"