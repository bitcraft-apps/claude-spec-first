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
REPO_URL="https://github.com/bitcraft-apps/claude-spec-first"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CSF_PREFIX="csf"
CSF_TEMP_DIR=""

# Cleanup temp directory
cleanup_temp() {
    if [ -n "$CSF_TEMP_DIR" ] && [ -d "$CSF_TEMP_DIR" ]; then
        rm -rf "$CSF_TEMP_DIR"
    fi
}

# Resolve SCRIPT_DIR - handle pipe execution (curl | bash, bash <(...))
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." 2>/dev/null && pwd )"

if [ ! -d "$SCRIPT_DIR/framework" ]; then
    echo -e "${BLUE}📡 Remote execution detected, downloading framework...${NC}"
    CSF_TEMP_DIR="$(mktemp -d)"
    trap 'cleanup_temp' EXIT
    if ! curl -sL "$REPO_URL/archive/refs/heads/main.tar.gz" | tar xz -C "$CSF_TEMP_DIR" 2>/dev/null; then
        echo -e "${RED}❌ Failed to download or extract framework. Check your network connection.${NC}"
        exit 1
    fi
    SCRIPT_DIR="$CSF_TEMP_DIR/claude-spec-first-main"
    if [ ! -d "$SCRIPT_DIR/framework" ]; then
        echo -e "${RED}❌ Downloaded archive does not contain expected framework directory.${NC}"
        exit 1
    fi
fi

FRAMEWORK_DIR="$SCRIPT_DIR/framework"

# Read new version early
NEW_VERSION="unknown"
if [ -f "$FRAMEWORK_DIR/VERSION" ]; then
    NEW_VERSION="$(cat "$FRAMEWORK_DIR/VERSION" 2>/dev/null | tr -d '[:space:]')" || NEW_VERSION="unknown"
    [ -z "$NEW_VERSION" ] && NEW_VERSION="unknown"
fi

# Arrays to track installations for rollback
INSTALLED=()
BACKED_UP=()

# Auto-detect operation mode
OLD_VERSION="unknown"
if [ -d "$CLAUDE_DIR/.csf" ] && [ -f "$CLAUDE_DIR/.csf/.installed" ]; then
    MODE="update"
    # Capture old version BEFORE any copy operations overwrite it
    if [ -f "$CLAUDE_DIR/.csf/VERSION" ]; then
        OLD_VERSION="$(cat "$CLAUDE_DIR/.csf/VERSION" 2>/dev/null | tr -d '[:space:]')" || OLD_VERSION="unknown"
        [ -z "$OLD_VERSION" ] && OLD_VERSION="unknown"
    fi
    echo -e "${BLUE}🔄 Existing installation detected, updating Claude Spec-First Framework...${NC}"
    echo "===================================================================="
else
    MODE="install"
    echo -e "${BLUE}🚀 Installing Claude Spec-First Framework v${NEW_VERSION} (fresh installation)...${NC}"
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

    cleanup_temp
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
        if [ -d "$BACKUP_DIR/hooks-csf" ]; then
            rm -rf "$CLAUDE_DIR/hooks/$CSF_PREFIX"
            cp -r "$BACKUP_DIR/hooks-csf" "$CLAUDE_DIR/hooks/$CSF_PREFIX"
            echo "🔄 Restored hooks from backup"
        fi
        if [ -f "$BACKUP_DIR/settings.json" ]; then
            cp "$BACKUP_DIR/settings.json" "$CLAUDE_DIR/settings.json"
            echo "🔄 Restored settings.json from backup"
        fi
        echo -e "${GREEN}✅ Backup restored successfully${NC}"
    fi

    cleanup_temp
    exit 1
}

# Set appropriate error trap based on mode
if [ "$MODE" = "install" ]; then
    trap 'rollback' ERR
    trap 'cleanup_temp' EXIT
elif [ "$MODE" = "update" ]; then
    trap 'restore_backup' ERR
    trap 'cleanup_temp' EXIT
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
    if [ -d "$CLAUDE_DIR/hooks/$CSF_PREFIX" ]; then
        cp -r "$CLAUDE_DIR/hooks/$CSF_PREFIX" "$BACKUP_DIR/hooks-csf"
        echo "📦 Backed up hooks"
    fi
    if [ -f "$CLAUDE_DIR/settings.json" ]; then
        cp "$CLAUDE_DIR/settings.json" "$BACKUP_DIR/settings.json"
        echo "📦 Backed up settings.json"
    fi
    
    echo -e "${GREEN}✅ Backup created: $BACKUP_DIR${NC}"
    
    # Clean up old backups (keep only last 5)
    echo -e "${BLUE}🧹 Cleaning up old backups...${NC}"
    BACKUP_BASE_DIR="$CLAUDE_DIR/.csf/backups"
    if [ -d "$BACKUP_BASE_DIR" ]; then
        BACKUP_COUNT=$(find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -name "20*" 2>/dev/null | wc -l)
        if [ "$BACKUP_COUNT" -gt 5 ]; then
            find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -name "20*" 2>/dev/null | sort | head -n $(( BACKUP_COUNT - 5 )) | while read -r old_backup; do
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
mkdir -p "$CLAUDE_DIR/hooks/$CSF_PREFIX"
mkdir -p "$CLAUDE_DIR/.csf"

# Clean stale files (files in target that don't exist in source)
clean_stale_files() {
    local source_dir="$1"
    local target_dir="$2"
    local artifact_type="$3"
    local extension="${4:-md}"

    if [ ! -d "$target_dir" ] || [ ! -d "$source_dir" ]; then
        return 0
    fi

    local stale_count=0
    for target_file in "$target_dir"/*."$extension"; do
        [ -f "$target_file" ] || continue
        local filename="$(basename "$target_file")"
        if [ ! -f "$source_dir/$filename" ]; then
            rm -f "$target_file"
            echo "🗑️  Removed stale $artifact_type: $filename"
            stale_count=$((stale_count + 1))
        fi
    done

    if [ "$stale_count" -gt 0 ]; then
        echo "✅ Removed $stale_count stale $artifact_type(s)"
    fi
}

# Core installation function
install_framework_files() {
    local operation="$1"
    echo -e "${BLUE}📦 ${operation} commands, agents, and hooks with CSF prefix...${NC}"

    # Clean stale files before installing (only on update)
    if [ "$MODE" = "update" ]; then
        echo -e "${BLUE}🧹 Cleaning stale files...${NC}"
        clean_stale_files "$FRAMEWORK_DIR/commands" "$CLAUDE_DIR/commands/$CSF_PREFIX" "command"
        clean_stale_files "$FRAMEWORK_DIR/agents" "$CLAUDE_DIR/agents/$CSF_PREFIX" "agent"
        clean_stale_files "$FRAMEWORK_DIR/hooks" "$CLAUDE_DIR/hooks/$CSF_PREFIX" "hook" "sh"
    fi

    # Check for plugin manifest
    local MANIFEST="$SCRIPT_DIR/.claude-plugin/plugin.json"
    local USE_MANIFEST=false
    if [ -f "$MANIFEST" ] && command -v jq &>/dev/null; then
        if jq empty "$MANIFEST" 2>/dev/null; then
            USE_MANIFEST=true
        else
            echo -e "${YELLOW}⚠️  Malformed plugin.json, falling back to directory glob${NC}"
        fi
    fi

    # Install commands with CSF prefix
    local cmd_count=0
    if [ "$USE_MANIFEST" = true ]; then
        while IFS= read -r cmd_name; do
            local cmd_file="$FRAMEWORK_DIR/commands/${cmd_name}.md"
            local target_file="$CLAUDE_DIR/commands/$CSF_PREFIX/${cmd_name}.md"
            if [ -f "$cmd_file" ]; then
                if ! cp "$cmd_file" "$target_file"; then
                    echo -e "${RED}❌ Failed to copy command ${cmd_name}.md${NC}"
                    exit 1
                fi
                INSTALLED+=("$target_file")
                echo "📄 ${operation}: $CSF_PREFIX/${cmd_name}.md"
                cmd_count=$((cmd_count + 1))
            else
                echo -e "${YELLOW}⚠️  Command listed in manifest not found: ${cmd_name}.md${NC}"
            fi
        done < <(jq -r '.commands[]' "$MANIFEST")
    elif [ -d "$FRAMEWORK_DIR/commands" ]; then
        for cmd_file in "$FRAMEWORK_DIR/commands"/*.md; do
            if [ -f "$cmd_file" ]; then
                local cmd_name="$(basename "$cmd_file")"
                local target_file="$CLAUDE_DIR/commands/$CSF_PREFIX/$cmd_name"
                if ! cp "$cmd_file" "$target_file"; then
                    echo -e "${RED}❌ Failed to copy command $cmd_name${NC}"
                    exit 1
                fi
                INSTALLED+=("$target_file")
                echo "📄 ${operation}: $CSF_PREFIX/$cmd_name"
                cmd_count=$((cmd_count + 1))
            fi
        done
    fi
    echo "✅ $cmd_count commands $(echo "$operation" | tr '[:upper:]' '[:lower:]')"

    # Install agents with CSF prefix
    local agent_count=0
    if [ "$USE_MANIFEST" = true ]; then
        while IFS= read -r agent_name; do
            local agent_file="$FRAMEWORK_DIR/agents/${agent_name}.md"
            local target_file="$CLAUDE_DIR/agents/$CSF_PREFIX/${agent_name}.md"
            if [ -f "$agent_file" ]; then
                if ! cp "$agent_file" "$target_file"; then
                    echo -e "${RED}❌ Failed to copy agent ${agent_name}.md${NC}"
                    exit 1
                fi
                INSTALLED+=("$target_file")
                echo "📄 ${operation}: $CSF_PREFIX/${agent_name}.md"
                agent_count=$((agent_count + 1))
            else
                echo -e "${YELLOW}⚠️  Agent listed in manifest not found: ${agent_name}.md${NC}"
            fi
        done < <(jq -r '.agents[]' "$MANIFEST")
    elif [ -d "$FRAMEWORK_DIR/agents" ]; then
        for agent_file in "$FRAMEWORK_DIR/agents"/*.md; do
            if [ -f "$agent_file" ]; then
                local agent_name="$(basename "$agent_file")"
                local target_file="$CLAUDE_DIR/agents/$CSF_PREFIX/$agent_name"
                if ! cp "$agent_file" "$target_file"; then
                    echo -e "${RED}❌ Failed to copy agent $agent_name${NC}"
                    exit 1
                fi
                INSTALLED+=("$target_file")
                echo "📄 ${operation}: $CSF_PREFIX/$agent_name"
                agent_count=$((agent_count + 1))
            fi
        done
    fi
    echo "✅ $agent_count agents $(echo "$operation" | tr '[:upper:]' '[:lower:]')"

    # Install hooks with CSF prefix
    local hook_count=0
    if [ "$USE_MANIFEST" = true ]; then
        while IFS= read -r hook_name; do
            local hook_file="$FRAMEWORK_DIR/hooks/${hook_name}"
            local target_file="$CLAUDE_DIR/hooks/$CSF_PREFIX/${hook_name}"
            if [ -f "$hook_file" ]; then
                if ! cp "$hook_file" "$target_file"; then
                    echo -e "${RED}❌ Failed to copy hook ${hook_name}${NC}"
                    exit 1
                fi
                chmod +x "$target_file"
                INSTALLED+=("$target_file")
                echo "📄 ${operation}: $CSF_PREFIX/${hook_name}"
                hook_count=$((hook_count + 1))
            else
                echo -e "${YELLOW}⚠️  Hook listed in manifest not found: ${hook_name}${NC}"
            fi
        done < <(jq -r '.hooks[]' "$MANIFEST")
    elif [ -d "$FRAMEWORK_DIR/hooks" ]; then
        for hook_file in "$FRAMEWORK_DIR/hooks"/*.sh; do
            if [ -f "$hook_file" ]; then
                local hook_name="$(basename "$hook_file")"
                local target_file="$CLAUDE_DIR/hooks/$CSF_PREFIX/$hook_name"
                if ! cp "$hook_file" "$target_file"; then
                    echo -e "${RED}❌ Failed to copy hook $hook_name${NC}"
                    exit 1
                fi
                chmod +x "$target_file"
                INSTALLED+=("$target_file")
                echo "📄 ${operation}: $CSF_PREFIX/$hook_name"
                hook_count=$((hook_count + 1))
            fi
        done
    fi
    echo "✅ $hook_count hooks $(echo "$operation" | tr '[:upper:]' '[:lower:]')"

}

# Merge CSF hooks into settings.json
merge_settings_json() {
    local settings_file="$CLAUDE_DIR/settings.json"
    local hooks_dir="$CLAUDE_DIR/hooks/$CSF_PREFIX"

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}⚠️  jq not found - skipping settings.json merge${NC}"
        echo -e "${YELLOW}   Install jq and re-run to enable stop hooks${NC}"
        return 0
    fi

    # Build Stop hooks configuration
    local csf_stop_hooks
    csf_stop_hooks=$(cat <<EOF
{
  "hooks": [
    {"type": "command", "command": "$hooks_dir/validate-spec.sh"},
    {"type": "command", "command": "$hooks_dir/validate-implementation.sh"}
  ]
}
EOF
)

    # Build SubagentStop hooks configuration
    local csf_subagent_hooks
    csf_subagent_hooks=$(cat <<EOF
{
  "matcher": "*",
  "hooks": [
    {"type": "command", "command": "$hooks_dir/validate-subagent.sh"}
  ]
}
EOF
)

    local temp_file
    temp_file=$(mktemp)

    if [ -f "$settings_file" ]; then
        # Validate existing JSON
        if ! jq empty "$settings_file" 2>/dev/null; then
            echo -e "${YELLOW}⚠️  Invalid settings.json - creating backup and new file${NC}"
            cp "$settings_file" "$settings_file.bak"
            echo '{}' > "$settings_file"
        fi

        # Merge: remove existing CSF hooks, add new ones
        jq --argjson csf_stop "$csf_stop_hooks" --argjson csf_subagent "$csf_subagent_hooks" '
            # Ensure hooks.Stop exists as array
            .hooks.Stop = (.hooks.Stop // [])
            # Remove existing CSF Stop hooks (containing /hooks/csf/)
            | .hooks.Stop = [.hooks.Stop[] | select(.hooks | all((.command // "") | contains("/hooks/csf/") | not))]
            # Add our CSF Stop hooks
            | .hooks.Stop += [$csf_stop]
            # Ensure hooks.SubagentStop exists as array
            | .hooks.SubagentStop = (.hooks.SubagentStop // [])
            # Remove existing CSF SubagentStop hooks
            | .hooks.SubagentStop = [.hooks.SubagentStop[] | select(.hooks | all((.command // "") | contains("/hooks/csf/") | not))]
            # Add our CSF SubagentStop hooks
            | .hooks.SubagentStop += [$csf_subagent]
        ' "$settings_file" > "$temp_file"
    else
        # Create new settings.json
        jq -n --argjson csf_stop "$csf_stop_hooks" --argjson csf_subagent "$csf_subagent_hooks" \
            '{hooks: {Stop: [$csf_stop], SubagentStop: [$csf_subagent]}}' > "$temp_file"
    fi

    # Validate result and move into place
    if jq empty "$temp_file" 2>/dev/null; then
        mv "$temp_file" "$settings_file"
        echo "⚙️  Stop and SubagentStop hooks configured in settings.json"
    else
        echo -e "${YELLOW}⚠️  Failed to merge settings.json${NC}"
        rm -f "$temp_file"
        return 1
    fi
}

# Install/Update framework files
if [ "$MODE" = "install" ]; then
    install_framework_files "Installing"
else
    install_framework_files "Updating"
fi

# Merge settings.json with CSF hooks
merge_settings_json

# Disable error trap after successful file operations
trap - ERR

# Create/Update installation marker
echo "$(date +"%Y-%m-%d %H:%M:%S")" > "$CLAUDE_DIR/.csf/.installed"

# Copy/Update VERSION file
if [ -f "$FRAMEWORK_DIR/VERSION" ]; then
    cp "$FRAMEWORK_DIR/VERSION" "$CLAUDE_DIR/.csf/"
    echo "📋 VERSION file $(echo "$MODE" | tr '[:upper:]' '[:lower:]')d"
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
    echo -e "${GREEN}✅ Claude Spec-First Framework v${NEW_VERSION} installed successfully!${NC}"
elif [ "$MODE" = "update" ]; then
    # Normalize versions for comparison (strip v-prefix)
    old_normalized="${OLD_VERSION#v}"
    new_normalized="${NEW_VERSION#v}"

    if [ -n "$old_normalized" ] && [ "$old_normalized" != "unknown" ] && [ "$old_normalized" = "$new_normalized" ]; then
        echo -e "${GREEN}🎉 Framework v${NEW_VERSION} reinstalled successfully!${NC}"
        echo ""
        echo -e "${BLUE}📋 Update Summary:${NC}"
        echo "• Commands, agents, and hooks refreshed at v${NEW_VERSION}"
    else
        echo -e "${GREEN}🎉 Update completed successfully! (v${OLD_VERSION} → v${NEW_VERSION})${NC}"
        echo ""
        echo -e "${BLUE}📋 Update Summary:${NC}"
        echo "• Commands, agents, and hooks updated from v${OLD_VERSION} to v${NEW_VERSION}"
    fi
    if [ -n "$BACKUP_DIR" ]; then
        echo "• Previous configuration backed up to: $BACKUP_DIR"
    fi
    echo "• Old backups cleaned up (keeping last 5)"
fi

echo "📁 Commands installed to: $CLAUDE_DIR/commands/$CSF_PREFIX/"
echo "📁 Agents installed to: $CLAUDE_DIR/agents/$CSF_PREFIX/"
echo "📁 Hooks installed to: $CLAUDE_DIR/hooks/$CSF_PREFIX/"
echo ""
echo -e "${BLUE}🔍 To validate the installation:${NC}"
echo "   cd ~/.claude && ./.csf/validate-framework.sh"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Restart Claude Code to load the updated framework"
if [ "$MODE" = "update" ]; then
    echo ""
    echo -e "${GREEN}✨ Framework v${NEW_VERSION} updated successfully!${NC}"
else
    echo ""
    echo -e "${GREEN}🚀 Ready to use the Claude Spec-First Framework v${NEW_VERSION}!${NC}"
fi
