#!/bin/bash

# Claude Spec-First Framework Installer
# Installs the Specification-First Development Framework for Claude Code

set -e  # Exit on any error

echo "🚀 Installing Claude Spec-First Framework..."
echo "=============================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
FRAMEWORK_DIR="$SCRIPT_DIR/framework"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"  # Allow override via environment variable

# CSF prefix configuration (SuperClaude-style)
CSF_PREFIX="csf"

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

# Create Claude directory structure
mkdir -p "$CLAUDE_DIR"

# Create CSF prefix directories (SuperClaude-style approach)
mkdir -p "$CLAUDE_DIR/commands/$CSF_PREFIX"
mkdir -p "$CLAUDE_DIR/agents/$CSF_PREFIX"

echo "📦 Installing framework files with CSF prefix..."

# Install commands with CSF prefix
if [ -d "$FRAMEWORK_DIR/commands" ]; then
    for cmd_file in "$FRAMEWORK_DIR/commands"/*.md; do
        if [ -f "$cmd_file" ]; then
            cmd_name="$(basename "$cmd_file")"
            target_file="$CLAUDE_DIR/commands/$CSF_PREFIX/$cmd_name"
            
            # Copy command to prefixed directory
            if ! cp "$cmd_file" "$target_file"; then
                echo "❌ Failed to copy command $cmd_name"
                exit 1
            fi
            INSTALLED+=("$target_file")
            echo "📄 Installed command: $CSF_PREFIX/$cmd_name"
        fi
    done
fi

# Install agents with CSF prefix
if [ -d "$FRAMEWORK_DIR/agents" ]; then
    for agent_file in "$FRAMEWORK_DIR/agents"/*.md; do
        if [ -f "$agent_file" ]; then
            agent_name="$(basename "$agent_file")"
            target_file="$CLAUDE_DIR/agents/$CSF_PREFIX/$agent_name"
            
            # Copy agent to prefixed directory
            if ! cp "$agent_file" "$target_file"; then
                echo "❌ Failed to copy agent $agent_name"
                exit 1
            fi
            INSTALLED+=("$target_file")
            echo "📄 Installed agent: $CSF_PREFIX/$agent_name"
        fi
    done
fi

# Install other framework files to root (backup existing)
for item in "$FRAMEWORK_DIR"/*; do
    base_item="$(basename "$item")"
    
    # Skip commands and agents (already handled above)
    if [ "$base_item" = "commands" ] || [ "$base_item" = "agents" ]; then
        continue
    fi
    
    target_item="$CLAUDE_DIR/$base_item"
    
    # Backup existing files/directories
    if [ -e "$target_item" ]; then
        timestamp=$(date +"%Y%m%d%H%M%S")
        backup_item="$target_item.bak.$timestamp"
        
        if ! mv "$target_item" "$backup_item"; then
            echo "❌ Failed to backup existing $base_item"
            exit 1
        fi
        BACKUPS+=("$backup_item")
        echo "📦 Backed up existing $base_item"
    fi
    
    # Install new item
    if [ -d "$item" ]; then
        if ! cp -r "$item" "$CLAUDE_DIR/"; then
            echo "❌ Failed to copy directory $base_item"
            exit 1
        fi
        INSTALLED+=("$target_item")
        echo "📁 Installed $base_item/"
    else
        if ! cp "$item" "$CLAUDE_DIR/"; then
            echo "❌ Failed to copy file $base_item"
            exit 1
        fi
        INSTALLED+=("$target_item")
        echo "📄 Installed $base_item"
    fi
done

trap - ERR  # Disable rollback trap after successful install

echo "✅ Claude Spec-First Framework installation completed successfully!"
echo "📁 Commands installed to: $CLAUDE_DIR/commands/$CSF_PREFIX/"
echo "📁 Agents installed to: $CLAUDE_DIR/agents/$CSF_PREFIX/"

# Display version information if available
if [ -f "$CLAUDE_DIR/utils/version-utils.sh" ] && [ -f "$CLAUDE_DIR/VERSION" ]; then
    FRAMEWORK_VERSION=$(cat "$CLAUDE_DIR/VERSION" 2>/dev/null | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "unknown")
    echo "📋 Framework version: $FRAMEWORK_VERSION"
fi

echo "🚀 Restart Claude Code to load the framework"
echo "💡 Commands available: /csf:spec, /csf:implement, /csf:document, /csf:workflow, etc."
echo "💡 Commands show in descriptions as: (project:$CSF_PREFIX) for identification"