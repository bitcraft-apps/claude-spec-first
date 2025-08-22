#!/bin/bash

# Claude Spec-First Framework Installer
# Installs the Specification-First Development Framework for Claude Code

set -e  # Exit on any error

echo "🚀 Installing Claude Spec-First Framework..."
echo "=============================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
FRAMEWORK_DIR="$SCRIPT_DIR/framework"
CLAUDE_DIR="$HOME/.claude"

# Arrays to track backups and installations for rollback
BACKUPS=()
INSTALLED=()

# Rollback function
rollback() {
    echo "❌ Installation failed. Rolling back changes..."
    
    # Remove installed files
    for item in "${INSTALLED[@]}"; do
        if [ -e "$item" ]; then
            echo "🔄 Removing $item"
            rm -rf "$item"
        fi
    done
    
    # Restore backups
    for backup in "${BACKUPS[@]}"; do
        if [ -e "$backup" ]; then
            original="${backup%.bak.*}"
            echo "🔄 Restoring $original from backup"
            mv "$backup" "$original"
        fi
    done
    
    echo "❌ Installation rolled back successfully"
    exit 1
}

# Set trap for cleanup on error
trap rollback ERR

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
        if ! mv "$target_item" "$backup_name"; then
            echo "❌ Failed to backup $base_item"
            exit 1
        fi
        BACKUPS+=("$backup_name")
    fi
    if [ -d "$item" ]; then
        if ! cp -r "$item" "$CLAUDE_DIR/"; then
            echo "❌ Failed to copy directory $base_item"
            exit 1
        fi
        INSTALLED+=("$target_item")
    else
        if ! cp "$item" "$CLAUDE_DIR/"; then
            echo "❌ Failed to copy file $base_item"
            exit 1
        fi
        INSTALLED+=("$target_item")
    fi
done

trap - ERR  # Disable rollback trap after successful install

echo "✅ Installation completed successfully!"
echo "🚀 Restart Claude Code to load the new framework"