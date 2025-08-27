#!/bin/bash

# Claude Spec-First Framework Installer
# Installs commands and agents only

set -e  # Exit on any error

echo "🚀 Installing Claude Spec-First Framework (commands and agents only)..."
echo "======================================================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
FRAMEWORK_DIR="$SCRIPT_DIR/framework"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"  # Allow override via environment variable

# CSF prefix configuration
CSF_PREFIX="csf"

# Arrays to track installations for rollback
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

# Create CSF prefix directories (Claude Code requirements)
mkdir -p "$CLAUDE_DIR/commands/$CSF_PREFIX"
mkdir -p "$CLAUDE_DIR/agents/$CSF_PREFIX"

# Create framework metadata directory
mkdir -p "$CLAUDE_DIR/.csf"

echo "📦 Installing commands and agents with CSF prefix..."

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

trap - ERR  # Disable rollback trap after successful install

# Create installation marker
echo "$(date +"%Y-%m-%d %H:%M:%S")" > "$CLAUDE_DIR/.csf/.installed"

# Copy VERSION file if it exists
if [ -f "$FRAMEWORK_DIR/VERSION" ]; then
    cp "$FRAMEWORK_DIR/VERSION" "$CLAUDE_DIR/.csf/"
    echo "📋 VERSION file installed"
fi

# Create utils directory and copy version utilities
mkdir -p "$CLAUDE_DIR/utils"
if [ -f "$SCRIPT_DIR/scripts/version.sh" ]; then
    target_file="$CLAUDE_DIR/utils/version.sh"
    cp "$SCRIPT_DIR/scripts/version.sh" "$target_file"
    chmod +x "$target_file"
    INSTALLED+=("$target_file")
    echo "🔧 Version utilities installed"
fi

# Copy validation script
if [ -f "$FRAMEWORK_DIR/validate-framework.sh" ]; then
    if cp "$FRAMEWORK_DIR/validate-framework.sh" "$CLAUDE_DIR/.csf/"; then
        chmod +x "$CLAUDE_DIR/.csf/validate-framework.sh"
        echo "🔍 Validation script installed"
    else
        echo "❌ Failed to install validation script"
    fi
fi

echo "✅ Claude Spec-First Framework installation completed successfully!"
echo "📁 Commands installed to: $CLAUDE_DIR/commands/$CSF_PREFIX/"
echo "📁 Agents installed to: $CLAUDE_DIR/agents/$CSF_PREFIX/"
echo ""
echo "🔍 To validate the installation:"
echo "   cd ~/.claude && ./.csf/validate-framework.sh"
echo ""
echo "🚀 Restart Claude Code to load the framework"