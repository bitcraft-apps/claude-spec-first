#!/bin/bash

# Claude Spec-First Framework Installer
# Installs the Specification-First Development Framework for Claude Code

set -e  # Exit on any error

echo "🚀 Installing Claude Spec-First Framework..."
echo "=============================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
FRAMEWORK_DIR="$SCRIPT_DIR/framework"
CLAUDE_DIR="$HOME/.claude"

# Validate framework directory exists
if [ ! -d "$FRAMEWORK_DIR" ]; then
    echo "❌ Framework directory not found: $FRAMEWORK_DIR"
    exit 1
fi

# Create Claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/examples"

echo "📦 Installing framework files..."

# Install framework files
cp -r "$FRAMEWORK_DIR"/* "$CLAUDE_DIR/"

echo "✅ Installation completed successfully!"
echo "🚀 Restart Claude Code to load the new framework"