#!/bin/bash

# Claude Spec-First Framework Remote Installer
# Downloads and installs the framework with a single command

set -e  # Exit on any error

# Color output helper
echo_status() { echo -e "${2:-\033[0;34m}$1\033[0m"; }

# Configuration
REPO_URL="https://github.com/bitcraft-apps/claude-spec-first.git"
TEMP_DIR=$(mktemp -d)
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

# Cleanup function
cleanup() { [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

echo_status "🚀 Claude Spec-First Framework Remote Installer"

# Check dependencies
command -v git &> /dev/null || { echo_status "❌ Git required" '\033[0;31m'; exit 1; }

# Check for existing installation
[ -d "$CLAUDE_DIR/.csf" ] && [ -f "$CLAUDE_DIR/.csf/.installed" ] &&
    echo_status "🔄 Updating..." || echo_status "📦 Installing..."

# Download and install
echo_status "📡 Downloading..."
git clone --quiet "$REPO_URL" "$TEMP_DIR/claude-spec-first" ||
    { echo_status "❌ Download failed" '\033[0;31m'; exit 1; }

cd "$TEMP_DIR/claude-spec-first"
chmod +x scripts/install.sh
echo_status "🔧 Installing..."
./scripts/install.sh

# Validate
~/.claude/.csf/validate-framework.sh >/dev/null 2>&1 &&
    echo_status "✅ Validated" '\033[0;32m' ||
    echo_status "⚠️ May have issues" '\033[1;33m'

# Explicit cleanup on success (trap handles failures)
trap - EXIT
cleanup
echo_status "🎉 Complete! Restart Claude Code and use /csf commands." '\033[0;32m'