#!/bin/bash

# Claude Spec-First Framework Installer/Updater
# Automatically detects and handles both fresh installation and updates

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
FRAMEWORK_DIR="$SCRIPT_DIR/framework"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CSF_PREFIX="csf"

# Arrays to track installations for rollback
INSTALLED=()
BACKED_UP=()

# Auto-detect operation mode
if [ -d "$CLAUDE_DIR/.csf" ] && [ -f "$CLAUDE_DIR/.csf/.installed" ]; then
    MODE="update"
    echo -e "${BLUE}🔄 Existing installation detected, updating Claude Spec-First Framework...${NC}"
    echo "===================================================================="
else
    MODE="install" 
    echo -e "${BLUE}🚀 Installing Claude Spec-First Framework (fresh installation)...${NC}"
    echo "======================================================================="
fi

# Rollback function for fresh installs
rollback() {
    echo -e "${RED}❌ Installation failed. Rolling back changes...${NC}"
    
    # Remove installed files
    for item in "${INSTALLED[@]}"; do
        if [ -e "$item" ]; then
            echo "🔄 Removing $item"
            rm -rf "$item"
        fi
    done
    
    echo -e "${RED}❌ Installation rolled back successfully${NC}"
    exit 1
}

# Backup restore function for updates  
restore_backup() {
    echo -e "${RED}❌ Update failed. Restoring backup...${NC}"
    
    # Restore from backup if available
    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
        if [ -d "$BACKUP_DIR/commands-csf" ]; then
            rm -rf "$CLAUDE_DIR/commands/$CSF_PREFIX"
            cp -r "$BACKUP_DIR/commands-csf" "$CLAUDE_DIR/commands/$CSF_PREFIX"
            echo "🔄 Restored commands from backup"
        fi
        if [ -d "$BACKUP_DIR/agents-csf" ]; then
            rm -rf "$CLAUDE_DIR/agents/$CSF_PREFIX" 
            cp -r "$BACKUP_DIR/agents-csf" "$CLAUDE_DIR/agents/$CSF_PREFIX"
            echo "🔄 Restored agents from backup"
        fi
        echo -e "${GREEN}✅ Backup restored successfully${NC}"
    fi
    
    exit 1
}

# Set appropriate error trap based on mode
if [ "$MODE" = "install" ]; then
    trap rollback ERR
elif [ "$MODE" = "update" ]; then
    trap restore_backup ERR
fi

# Validate framework directory exists
if [ ! -d "$FRAMEWORK_DIR" ]; then
    echo -e "${RED}❌ Framework directory not found: $FRAMEWORK_DIR${NC}"
    exit 1
fi

# Update-specific: Handle git operations and create backups
if [ "$MODE" = "update" ]; then
    # Check if we're in a git repository for updates
    if [ -d "$SCRIPT_DIR/.git" ]; then
        echo -e "${BLUE}📡 Fetching latest updates...${NC}"
        
        # Save current branch
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
        
        # Fetch and pull latest changes
        if ! git fetch origin 2>/dev/null; then
            echo -e "${YELLOW}⚠️  Could not fetch updates (offline or network issue)${NC}"
            echo -e "${BLUE}🔄 Proceeding with local files...${NC}"
        else
            if ! git pull origin "$CURRENT_BRANCH" 2>/dev/null; then
                echo -e "${YELLOW}⚠️  Could not pull updates. Using local files.${NC}"
            else
                # Check if there were any changes
                if git diff --quiet HEAD@{1} HEAD 2>/dev/null; then
                    echo -e "${GREEN}✅ Already up to date!${NC}"
                    
                    # Still update files in case of local modifications
                    echo -e "${BLUE}🔄 Refreshing installation files...${NC}"
                else
                    echo -e "${BLUE}📋 Changes detected, updating installation...${NC}"
                    
                    # Show what changed  
                    echo -e "${BLUE}📝 Recent changes:${NC}"
                    git log --oneline -5 HEAD@{1}..HEAD 2>/dev/null || echo "Unable to show change log"
                fi
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  Not in a git repository. Using local files for update.${NC}"
    fi
    
    # Create backup timestamp
    BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP_DIR="$CLAUDE_DIR/.csf/backups/$BACKUP_TIMESTAMP"
    
    echo -e "${BLUE}💾 Creating update backup...${NC}"
    mkdir -p "$BACKUP_DIR"
    
    # Backup current framework files
    if [ -d "$CLAUDE_DIR/commands/$CSF_PREFIX" ]; then
        cp -r "$CLAUDE_DIR/commands/$CSF_PREFIX" "$BACKUP_DIR/commands-csf"
        echo "📦 Backed up commands"
    fi
    if [ -d "$CLAUDE_DIR/agents/$CSF_PREFIX" ]; then
        cp -r "$CLAUDE_DIR/agents/$CSF_PREFIX" "$BACKUP_DIR/agents-csf"
        echo "📦 Backed up agents"
    fi
    
    echo -e "${GREEN}✅ Backup created: $BACKUP_DIR${NC}"
    
    # Clean up old backups (keep only last 5)
    echo -e "${BLUE}🧹 Cleaning up old backups...${NC}"
    BACKUP_BASE_DIR="$CLAUDE_DIR/.csf/backups"
    if [ -d "$BACKUP_BASE_DIR" ]; then
        BACKUP_COUNT=$(find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -name "20*" 2>/dev/null | wc -l)
        if [ "$BACKUP_COUNT" -gt 5 ]; then
            find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -name "20*" 2>/dev/null | sort | head -n -5 | while read -r old_backup; do
                rm -rf "$old_backup"
                echo "  🗑️ Removed old backup: $(basename "$old_backup")"
            done
        fi
    fi
fi

# Create Claude directory structure
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/commands/$CSF_PREFIX"
mkdir -p "$CLAUDE_DIR/agents/$CSF_PREFIX"
mkdir -p "$CLAUDE_DIR/.csf"

# Core installation function
install_framework_files() {
    local operation="$1"
    echo -e "${BLUE}📦 ${operation} commands and agents with CSF prefix...${NC}"
    
    # Install commands with CSF prefix
    if [ -d "$FRAMEWORK_DIR/commands" ]; then
        local cmd_count=0
        for cmd_file in "$FRAMEWORK_DIR/commands"/*.md; do
            if [ -f "$cmd_file" ]; then
                cmd_name="$(basename "$cmd_file")"
                target_file="$CLAUDE_DIR/commands/$CSF_PREFIX/$cmd_name"
                
                if ! cp "$cmd_file" "$target_file"; then
                    echo -e "${RED}❌ Failed to copy command $cmd_name${NC}"
                    exit 1
                fi
                INSTALLED+=("$target_file")
                echo "📄 ${operation}: $CSF_PREFIX/$cmd_name"
                ((cmd_count++))
            fi
        done
        echo "✅ $cmd_count commands $(echo "$operation" | tr '[:upper:]' '[:lower:]')"
    fi
    
    # Install agents with CSF prefix
    if [ -d "$FRAMEWORK_DIR/agents" ]; then
        local agent_count=0
        for agent_file in "$FRAMEWORK_DIR/agents"/*.md; do
            if [ -f "$agent_file" ]; then
                agent_name="$(basename "$agent_file")"
                target_file="$CLAUDE_DIR/agents/$CSF_PREFIX/$agent_name"
                
                if ! cp "$agent_file" "$target_file"; then
                    echo -e "${RED}❌ Failed to copy agent $agent_name${NC}"
                    exit 1
                fi
                INSTALLED+=("$target_file")
                echo "📄 ${operation}: $CSF_PREFIX/$agent_name"
                ((agent_count++))
            fi
        done
        echo "✅ $agent_count agents $(echo "$operation" | tr '[:upper:]' '[:lower:]')"
    fi
}

# Install/Update framework files
if [ "$MODE" = "install" ]; then
    install_framework_files "Installing"
else
    install_framework_files "Updating"
fi

# Disable error trap after successful file operations
trap - ERR

# Create/Update installation marker
echo "$(date +"%Y-%m-%d %H:%M:%S")" > "$CLAUDE_DIR/.csf/.installed"

# Copy/Update VERSION file
if [ -f "$FRAMEWORK_DIR/VERSION" ]; then
    cp "$FRAMEWORK_DIR/VERSION" "$CLAUDE_DIR/.csf/"
    echo "📋 VERSION file $(echo "$MODE" | tr '[:upper:]' '[:lower:]')d"
fi

# Create/Update utils directory and copy version utilities
mkdir -p "$CLAUDE_DIR/utils"
echo "🔍 DEBUG: Looking for version.sh at: $SCRIPT_DIR/scripts/version.sh"
echo "🔍 DEBUG: File exists check: $([ -f "$SCRIPT_DIR/scripts/version.sh" ] && echo "YES" || echo "NO")"
if [ -f "$SCRIPT_DIR/scripts/version.sh" ]; then
    target_file="$CLAUDE_DIR/utils/version.sh"
    echo "🔍 DEBUG: Copying to: $target_file"
    if cp "$SCRIPT_DIR/scripts/version.sh" "$target_file"; then
        chmod +x "$target_file"
        INSTALLED+=("$target_file")
        echo "🔧 Version utilities $(echo "$MODE" | tr '[:upper:]' '[:lower:]')d"
        echo "🔍 DEBUG: Successfully copied and made executable"
    else
        echo "🔍 DEBUG: Failed to copy version utilities"
        exit 1
    fi
else
    echo "🔍 DEBUG: version.sh not found, checking directory contents:"
    ls -la "$SCRIPT_DIR/scripts/" || echo "🔍 DEBUG: scripts directory doesn't exist"
fi

# Copy/Update validation script
if [ -f "$FRAMEWORK_DIR/validate-framework.sh" ]; then
    if cp "$FRAMEWORK_DIR/validate-framework.sh" "$CLAUDE_DIR/.csf/"; then
        chmod +x "$CLAUDE_DIR/.csf/validate-framework.sh"
        echo "🔍 Validation script $(echo "$MODE" | tr '[:upper:]' '[:lower:]')d"
    else
        echo -e "${YELLOW}⚠️  Failed to ${MODE} validation script${NC}"
    fi
fi

# Success messages
echo ""
if [ "$MODE" = "install" ]; then
    echo -e "${GREEN}✅ Claude Spec-First Framework installation completed successfully!${NC}"
elif [ "$MODE" = "update" ]; then
    echo -e "${GREEN}🎉 Update completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}📋 Update Summary:${NC}"
    echo "• Commands and agents updated to latest version"
    if [ -n "$BACKUP_DIR" ]; then
        echo "• Previous configuration backed up to: $BACKUP_DIR"
    fi
    echo "• Old backups cleaned up (keeping last 5)"
fi

echo "📁 Commands installed to: $CLAUDE_DIR/commands/$CSF_PREFIX/"
echo "📁 Agents installed to: $CLAUDE_DIR/agents/$CSF_PREFIX/"
echo ""
echo -e "${BLUE}🔍 To validate the installation:${NC}"
echo "   cd ~/.claude && ./.csf/validate-framework.sh"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Restart Claude Code to load the updated framework"
if [ "$MODE" = "update" ]; then
    echo ""
    echo -e "${GREEN}✨ Framework updated successfully!${NC}"
else
    echo ""
    echo -e "${GREEN}🚀 Ready to use the Claude Spec-First Framework!${NC}"
fi