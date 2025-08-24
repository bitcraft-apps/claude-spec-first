#!/bin/bash

# Claude Spec-First Framework Uninstaller
# Removes the Specification-First Development Framework from Claude Code

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🗑️  Uninstalling Claude Spec-First Framework...${NC}"
echo "==============================================="

CLAUDE_DIR="$HOME/.claude"

# Check if framework is installed
if [ ! -f "$CLAUDE_DIR/agents/spec-analyst.md" ]; then
    echo -e "${YELLOW}⚠️  Framework doesn't appear to be installed.${NC}"
    echo -e "${BLUE}Nothing to uninstall.${NC}"
    exit 0
fi

echo -e "${BLUE}📋 Analyzing current installation...${NC}"

# Find the most recent backup directory
BACKUP_DIR=""
if ls "$HOME"/.claude-backup-* 1> /dev/null 2>&1; then
    BACKUP_DIR=$(ls -td "$HOME"/.claude-backup-* | head -n1)
    echo -e "${GREEN}📦 Found backup directory: $BACKUP_DIR${NC}"
fi

echo -e "${YELLOW}⚠️  This will remove all framework components:${NC}"
echo "• 6 specialized agents (spec-analyst, test-designer, doc-synthesizer, etc.)"
echo "• 6 workflow commands (spec-init, spec-review, doc-generate, etc.)" 
echo "• Framework examples and validation tools"
echo "• Framework section from CLAUDE.md"
echo ""

# Confirmation prompt
read -p "Are you sure you want to uninstall? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}❌ Uninstallation cancelled.${NC}"
    exit 0
fi

echo -e "${BLUE}🗑️  Removing framework files...${NC}"

# Remove framework agents
FRAMEWORK_AGENTS=("spec-analyst.md" "test-designer.md" "arch-designer.md" "impl-specialist.md" "qa-validator.md" "doc-synthesizer.md")
for agent in "${FRAMEWORK_AGENTS[@]}"; do
    if [ -f "$CLAUDE_DIR/agents/$agent" ]; then
        rm "$CLAUDE_DIR/agents/$agent"
        echo "  ✅ Removed: agents/$agent"
    fi
done

# Remove framework commands
FRAMEWORK_COMMANDS=("spec-init.md" "spec-review.md" "impl-plan.md" "qa-check.md" "spec-workflow.md" "doc-generate.md")
for command in "${FRAMEWORK_COMMANDS[@]}"; do
    if [ -f "$CLAUDE_DIR/commands/$command" ]; then
        rm "$CLAUDE_DIR/commands/$command"
        echo "  ✅ Removed: commands/$command"
    fi
done

# Remove framework examples
if [ -f "$CLAUDE_DIR/examples/todo-api-example.md" ]; then
    rm "$CLAUDE_DIR/examples/todo-api-example.md"
    echo "  ✅ Removed: examples/todo-api-example.md"
fi

# Remove validation script
if [ -f "$CLAUDE_DIR/validate-framework.sh" ]; then
    rm "$CLAUDE_DIR/validate-framework.sh"
    echo "  ✅ Removed: validate-framework.sh"
fi

echo -e "${BLUE}📝 Cleaning up CLAUDE.md...${NC}"

# Handle CLAUDE.md restoration
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    if grep -q "Claude Spec-First Framework Integration" "$CLAUDE_DIR/CLAUDE.md"; then
        # Check if we have a backup to restore
        if [ -n "$BACKUP_DIR" ] && [ -f "$BACKUP_DIR/CLAUDE.md" ]; then
            echo -e "${BLUE}🔄 Restoring original CLAUDE.md from backup...${NC}"
            cp "$BACKUP_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
            echo -e "${GREEN}✅ Original CLAUDE.md restored${NC}"
        else
            echo -e "${YELLOW}⚠️  No backup found. Removing framework section from CLAUDE.md...${NC}"
            # Create temporary file without framework section
            TEMP_CLAUDE=$(mktemp)
            sed '/# Claude Spec-First Framework Integration/,/^$/d' "$CLAUDE_DIR/CLAUDE.md" > "$TEMP_CLAUDE"
            
            # Use portable sed: output to a new temp file, then move it back
            TEMP_CLAUDE2=$(mktemp)
            sed '/^# ========================================$/,/^# ========================================$/d' "$TEMP_CLAUDE" > "$TEMP_CLAUDE2"
            if [ $? -ne 0 ] || [ ! -s "$TEMP_CLAUDE2" ]; then
                echo -e "${RED}❌ Error: Failed to remove framework separator from CLAUDE.md.${NC}"
                rm -f "$TEMP_CLAUDE2"
                rm -f "$TEMP_CLAUDE"
                exit 1
            fi
            mv "$TEMP_CLAUDE2" "$TEMP_CLAUDE"
            
            # Only keep the file if it has content (not just the framework)
            if [ -s "$TEMP_CLAUDE" ]; then
                mv "$TEMP_CLAUDE" "$CLAUDE_DIR/CLAUDE.md"
                echo -e "${GREEN}✅ Framework section removed from CLAUDE.md${NC}"
            else
                rm "$TEMP_CLAUDE"
                rm "$CLAUDE_DIR/CLAUDE.md"
                echo -e "${GREEN}✅ CLAUDE.md removed (contained only framework content)${NC}"
            fi
        fi
    else
        echo -e "${BLUE}ℹ️  No framework content found in CLAUDE.md - leaving unchanged${NC}"
    fi
fi

# Restore other backed up files if they exist
if [ -n "$BACKUP_DIR" ]; then
    echo -e "${BLUE}🔄 Restoring other backed up configurations...${NC}"
    
    # Restore backed up agents (non-framework ones)
    if [ -d "$BACKUP_DIR/agents" ]; then
        for agent_file in "$BACKUP_DIR/agents"/*; do
            if [ -f "$agent_file" ]; then
                agent_name=$(basename "$agent_file")
                # Only restore if it's not a framework agent
                if [[ ! " ${FRAMEWORK_AGENTS[@]} " =~ " ${agent_name} " ]]; then
                    cp "$agent_file" "$CLAUDE_DIR/agents/"
                    echo "  ✅ Restored custom agent: $agent_name"
                fi
            fi
        done
    fi
    
    # Restore backed up commands (non-framework ones)
    if [ -d "$BACKUP_DIR/commands" ]; then
        for command_file in "$BACKUP_DIR/commands"/*; do
            if [ -f "$command_file" ]; then
                command_name=$(basename "$command_file")
                # Only restore if it's not a framework command
                if [[ ! " ${FRAMEWORK_COMMANDS[@]} " =~ " ${command_name} " ]]; then
                    cp "$command_file" "$CLAUDE_DIR/commands/"
                    echo "  ✅ Restored custom command: $command_name"
                fi
            fi
        done
    fi
fi

# Clean up empty directories
rmdir "$CLAUDE_DIR/agents" 2>/dev/null && echo "  ✅ Removed empty agents directory" || true
rmdir "$CLAUDE_DIR/commands" 2>/dev/null && echo "  ✅ Removed empty commands directory" || true
rmdir "$CLAUDE_DIR/examples" 2>/dev/null && echo "  ✅ Removed empty examples directory" || true

echo ""
echo -e "${GREEN}🎉 Uninstallation completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Uninstallation Summary:${NC}"
echo "• All framework agents removed"
echo "• All framework commands removed"
echo "• Framework examples removed"
echo "• Validation tools removed"
if [ -n "$BACKUP_DIR" ]; then
    echo "• Original configuration restored from backup"
    echo "• Custom agents and commands preserved"
fi

echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Restart Claude Code to unload framework components"
echo "2. Your original Claude Code configuration has been restored"
if [ -n "$BACKUP_DIR" ]; then
    echo "3. Backup directory preserved at: $BACKUP_DIR"
    echo "   (You can safely delete this after confirming everything works)"
fi
echo ""
echo -e "${GREEN}✨ Framework successfully uninstalled!${NC}"
echo ""
echo -e "${BLUE}💡 Want to reinstall later?${NC}"
echo "   Run: curl -sSL https://raw.githubusercontent.com/bitcraft-apps/claude-spec-first/main/install.sh | bash"