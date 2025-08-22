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

# Install framework files with backup
for item in "$FRAMEWORK_DIR"/*; do
    base_item="$(basename "$item")"
    target_item="$CLAUDE_DIR/$base_item"
    if [ -e "$target_item" ]; then
        backup_name="$target_item.bak.$(date +%Y%m%d%H%M%S)"
        echo "🔄 Backing up existing $base_item to $(basename "$backup_name")"
        mv "$target_item" "$backup_name"
    fi
    if [ -d "$item" ]; then
        cp -r "$item" "$CLAUDE_DIR/"
    else
        cp "$item" "$CLAUDE_DIR/"
    fi
done

echo "✅ Installation completed successfully!"
echo "🚀 Restart Claude Code to load the new framework"