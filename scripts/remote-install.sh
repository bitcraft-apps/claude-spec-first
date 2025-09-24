#!/bin/bash

# Claude Spec-First Framework Remote Installer
# Downloads and installs the framework with a single command

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/bitcraft-apps/claude-spec-first.git"
TEMP_DIR=$(mktemp -d)
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Set cleanup trap
trap cleanup EXIT

echo -e "${BLUE}🚀 Claude Spec-First Framework Remote Installer${NC}"
echo "================================================================"

# Check if git is available
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git is required but not installed.${NC}"
    echo "Please install git and try again."
    exit 1
fi

# Check for existing installation
if [ -d "$CLAUDE_DIR/.csf" ] && [ -f "$CLAUDE_DIR/.csf/.installed" ]; then
    echo -e "${BLUE}🔄 Existing installation detected, updating...${NC}"
    MODE="update"
else
    echo -e "${BLUE}📦 Fresh installation starting...${NC}"
    MODE="install"
fi

# Clone the repository to temporary directory
echo -e "${BLUE}📡 Downloading Claude Spec-First Framework...${NC}"
if ! git clone --quiet "$REPO_URL" "$TEMP_DIR/claude-spec-first"; then
    echo -e "${RED}❌ Failed to download framework from GitHub${NC}"
    echo "Please check your internet connection and try again."
    exit 1
fi

# Change to the cloned directory
cd "$TEMP_DIR/claude-spec-first"

# Make installation script executable
chmod +x scripts/install.sh

# Run the installation script
echo -e "${BLUE}🔧 Running installation script...${NC}"
./scripts/install.sh

# Success message
echo ""
echo -e "${GREEN}🎉 Remote installation completed successfully!${NC}"
echo ""
echo -e "${BLUE}🔍 To validate the installation:${NC}"
echo "   ~/.claude/.csf/validate-framework.sh"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Restart Claude Code to load the framework"
echo "2. Use /csf:spec, /csf:implement, /csf:document commands"
echo ""
echo -e "${GREEN}✨ Ready to use the Claude Spec-First Framework!${NC}"