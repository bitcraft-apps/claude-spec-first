---
generated_from:
  specifications: [troubleshooting requirements, error handling specs]
  architecture: [error handling design, user experience patterns]
  qa_reports: [error testing results, user experience validation]
  implementation: [error messages, diagnostic procedures]
generated_date: 2025-08-24
generated_by: doc-synthesizer
version: 1.0.0
status: current
traceability_id: troubleshooting-v1.0
---

# Troubleshooting Guide

## Overview

This guide helps you diagnose and resolve common issues with the dual-mode validation script. The enhanced validation system includes improved error messages and diagnostic capabilities to help you quickly identify and fix problems.

## Quick Diagnostic Checklist

Before diving into specific issues, run this quick diagnostic:

```bash
# 1. Check your location
pwd
echo "Current directory: $(pwd)"

# 2. Check framework files
ls -la CLAUDE.md 2>/dev/null && echo "✅ CLAUDE.md found in current directory"
ls -la framework/CLAUDE.md 2>/dev/null && echo "✅ CLAUDE.md found in framework directory"

# 3. Check script permissions
ls -la validate-framework.sh 2>/dev/null || ls -la framework/validate-framework.sh 2>/dev/null

# 4. Run validation with output capture
./validate-framework.sh 2>&1 | tee validation-debug.txt
echo "Exit code: $?"
```

## Common Issues and Solutions

### Issue 1: Mode Detection Failure

#### Symptoms
```bash
❌ Invalid execution context
This script must be run from either:
  - Repository root (with ./framework/ directory)
  - Installed location (~/.claude/ with CLAUDE.md)
```

#### Diagnosis Steps

**Step 1: Check Current Directory**
```bash
pwd
ls -la
```

**Step 2: Check for Repository Mode Requirements**
```bash
# Repository mode needs both of these:
ls -la framework/
ls -la framework/CLAUDE.md
```

**Step 3: Check for Installed Mode Requirements**
```bash
# Installed mode needs:
ls -la CLAUDE.md
```

#### Solutions

**Solution A: Fix Repository Mode**
```bash
# Navigate to repository root
cd /path/to/claude-spec-first
ls framework/  # Should show CLAUDE.md and other files

# Run validation
./framework/validate-framework.sh
```

**Solution B: Fix Installed Mode**  
```bash
# Navigate to Claude installation
cd ~/.claude
ls -la CLAUDE.md  # Should exist

# Run validation
./validate-framework.sh
```

**Solution C: Fresh Installation**
```bash
# If files are missing, reinstall
./scripts/install.sh
cd ~/.claude
./validate-framework.sh
```

### Issue 2: Permission Denied Errors

#### Symptoms
```bash
./validate-framework.sh: Permission denied
```

#### Diagnosis Steps
```bash
# Check file permissions
ls -la validate-framework.sh
# or
ls -la framework/validate-framework.sh

# Check current user
whoami
```

#### Solutions

**Solution A: Fix Execute Permissions**
```bash
# For repository mode
chmod +x framework/validate-framework.sh

# For installed mode  
chmod +x validate-framework.sh
```

**Solution B: Check Directory Permissions**
```bash
# Ensure you can access the directory
ls -la .
ls -la framework/
```

**Solution C: Reinstall with Correct Permissions**
```bash
./scripts/install.sh
# Installation script sets correct permissions
```

### Issue 3: Security Violations

#### Symptoms
```bash
Security Error: Invalid path detected: <path>
```

#### What This Means
- The security system detected a potentially dangerous path
- This could indicate file corruption, malicious modification, or system issues
- The script stopped immediately to protect your system

#### Diagnosis Steps

**Step 1: Check for Malicious File Names**
```bash
# Look for problematic files
find . -name "*\.\.*" -o -name "*;*" -o -name "*|*" 2>/dev/null
find . -name "*\$*" -o -name "*\`*" 2>/dev/null
```

**Step 2: Check Recent Changes**
```bash
# If in a git repository
git status
git log --oneline -5

# Check modification times
find . -name "*.md" -mtime -1  # Files modified in last day
```

**Step 3: Verify Framework Integrity**
```bash
# Check for unexpected files
find framework/ -type f ! -name "*.md" ! -name "*.sh" 2>/dev/null
```

#### Solutions

**Solution A: Clean Problematic Files**
```bash
# Remove files with dangerous names (BE CAREFUL)
find . -name "*\.\.*" -delete
find . -name "*;*" -delete
find . -name "*|*" -delete
```

**Solution B: Restore from Backup**
```bash
# If you have backups
mv ~/.claude ~/.claude.corrupted
tar -xzf ~/.claude-backups/claude-framework-YYYYMMDD_HHMMSS.tar.gz -C ~/
```

**Solution C: Clean Reinstallation**
```bash
# Nuclear option - complete reinstall
mv ~/.claude ~/.claude.backup.$(date +%Y%m%d)
./scripts/install.sh
```

### Issue 4: Missing Framework Components

#### Symptoms
```bash
❌ agents/ directory exists
❌ spec-analyst.md exists
❌ Framework validation FAILED!
```

#### Diagnosis Steps

**Step 1: Check Directory Structure**
```bash
# Repository mode
find framework/ -type d
find framework/ -name "*.md" | head -10

# Installed mode  
find . -maxdepth 2 -type d
find . -name "*.md" | head -10
```

**Step 2: Check Installation Completeness**
```bash
# Count expected components
ls agents/*.md 2>/dev/null | wc -l      # Should be 6
ls commands/*.md 2>/dev/null | wc -l    # Should be 6
```

#### Solutions

**Solution A: Complete Installation**
```bash
# Run installation to fill missing components
./scripts/install.sh
```

**Solution B: Update Existing Installation**
```bash
# Update to get missing components
./scripts/update.sh
```

**Solution C: Manual Component Creation**
```bash
# Create missing directories
mkdir -p agents commands examples templates

# Check what specific files are missing from validation output
```

### Issue 5: YAML Frontmatter Errors

#### Symptoms
```bash
❌ spec-analyst has YAML frontmatter
❌ spec-analyst has correct name field
```

#### Diagnosis Steps

**Step 1: Check YAML Format**
```bash
# Look at the problematic file
head -10 agents/spec-analyst.md
```

**Step 2: Validate YAML Syntax**
```bash
# Extract and check YAML section
sed -n '1,/^---$/p' agents/spec-analyst.md
```

#### Solutions

**Solution A: Fix YAML Frontmatter**
```bash
# YAML must start with --- on first line
# Example correct format:
---
name: spec-analyst
description: Requirements analysis and specification creation
tools: [Read, Write, Edit, Grep, Glob]
---

# Content here...
```

**Solution B: Restore from Template**
```bash
# Use a working agent as template
cp agents/working-agent.md agents/broken-agent.md
vim agents/broken-agent.md  # Edit to match requirements
```

### Issue 6: Slow Validation Performance

#### Symptoms
- Validation takes longer than expected (> 10 seconds)
- System appears to hang during validation

#### Diagnosis Steps

**Step 1: Time the Operation**
```bash
time ./validate-framework.sh > /dev/null
```

**Step 2: Check System Resources**
```bash
# Check disk usage
df -h .
du -sh .

# Check for file system issues
find . -name "*.md" | wc -l  # Count of files being processed
```

#### Solutions

**Solution A: Clean Temporary Files**
```bash
# Remove temporary files that might slow processing
find . -name "*.tmp" -delete
find . -name "*.log" -mtime +7 -delete
```

**Solution B: Check File System**
```bash
# Check for file system errors (if permissions allow)
fsck /dev/disk-partition  # Varies by system
```

**Solution C: Optimize Environment**
```bash
# Run in clean environment
cd /tmp
cp -r ~/.claude claude-test
cd claude-test
time ./validate-framework.sh
```

### Issue 7: Unexpected Validation Results

#### Symptoms
- Tests that should pass are failing
- Tests that should fail are passing
- Inconsistent results between runs

#### Diagnosis Steps

**Step 1: Check for File Changes**
```bash
# In git repository
git status
git diff

# Check modification times
find . -name "*.md" -mmin -60  # Modified in last hour
```

**Step 2: Manual Validation**
```bash
# Check specific failing components manually
ls -la agents/spec-analyst.md
head -5 agents/spec-analyst.md
grep "name:" agents/spec-analyst.md
```

**Step 3: Compare with Known Good State**
```bash
# If you have a backup or git history
git checkout HEAD~1 -- framework/
./framework/validate-framework.sh
```

#### Solutions

**Solution A: Reset to Known Good State**
```bash
# From git
git checkout -- framework/
git clean -fd framework/

# From backup
cp -r ~/.claude.backup/* ~/.claude/
```

**Solution B: Incremental Debugging**
```bash
# Test individual components
ls agents/spec-analyst.md && echo "File exists"
head -1 agents/spec-analyst.md | grep -q "^---$" && echo "YAML frontmatter OK"
```

## Advanced Troubleshooting

### Environment Debugging

#### Complete Environment Check
```bash
#!/bin/bash
echo "=== Environment Diagnostic ==="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Shell: $SHELL ($BASH_VERSION)"
echo "OS: $(uname -a)"
echo "Working Directory: $(pwd)"
echo ""

echo "=== Directory Structure ==="
ls -la
echo ""

echo "=== Framework Files ==="
find . -name "CLAUDE.md" -exec ls -la {} \;
find . -name "validate-framework.sh" -exec ls -la {} \;
echo ""

echo "=== Recent Changes ==="
find . -name "*.md" -mtime -1 | head -10
echo ""

echo "=== Disk Usage ==="
du -sh . 2>/dev/null || echo "Cannot determine disk usage"
df -h . 2>/dev/null || echo "Cannot determine filesystem info"
```

#### Script Debugging Mode

```bash
# Enable bash debugging
bash -x ./validate-framework.sh 2>debug.log

# Or add to script temporarily
set -x  # Add at top of script
# ... script content ...
set +x  # Add at end
```

### Log Analysis

#### Extracting Validation Metrics
```bash
# Analyze validation output
./validate-framework.sh 2>&1 | tee validation.log

# Count results
grep -c "✅" validation.log  # Passed tests
grep -c "❌" validation.log  # Failed tests  
grep -c "⚠️" validation.log  # Warnings

# Extract specific failures
grep "❌" validation.log
```

#### Performance Analysis
```bash
# Time each validation phase
time ./validate-framework.sh 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' > timed-validation.log
```

### Network and External Dependencies

#### Checking External Dependencies
```bash
# Test network connectivity (if needed)
ping -c 1 github.com >/dev/null 2>&1 && echo "Network OK"

# Check git connectivity  
git ls-remote origin >/dev/null 2>&1 && echo "Git remote OK"

# Verify no external dependencies required
ldd validate-framework.sh 2>/dev/null || echo "No binary dependencies (expected for shell script)"
```

## Recovery Procedures

### Complete System Recovery

#### Emergency Reset Procedure
```bash
#!/bin/bash
echo "🚨 Emergency Framework Recovery Procedure"
echo "========================================"

# 1. Backup current state
BACKUP_DIR="$HOME/.framework-recovery-$(date +%Y%m%d_%H%M%S)"
echo "Creating emergency backup at $BACKUP_DIR..."
cp -r ~/.claude "$BACKUP_DIR" 2>/dev/null || echo "No existing installation to backup"

# 2. Clean installation
echo "Performing clean installation..."
rm -rf ~/.claude
./scripts/install.sh

# 3. Validate installation
echo "Validating recovery..."
cd ~/.claude
./validate-framework.sh

if [ $? -eq 0 ]; then
    echo "✅ Recovery successful!"
    echo "Emergency backup available at: $BACKUP_DIR"
else
    echo "❌ Recovery failed - manual intervention required"
    exit 1
fi
```

### Incremental Recovery

#### Step-by-Step Component Restoration
```bash
# 1. Fix directory structure
mkdir -p ~/.claude/{agents,commands,examples,templates}

# 2. Restore core configuration
cp framework/CLAUDE.md ~/.claude/

# 3. Restore agents one by one
for agent in spec-analyst test-designer arch-designer impl-specialist qa-validator doc-synthesizer; do
    cp "framework/agents/${agent}.md" ~/.claude/agents/ 2>/dev/null && echo "✅ $agent restored" || echo "❌ $agent missing"
done

# 4. Restore commands
for command in spec-init spec-review impl-plan qa-check spec-workflow doc-generate; do
    cp "framework/commands/${command}.md" ~/.claude/commands/ 2>/dev/null && echo "✅ $command restored" || echo "❌ $command missing"
done

# 5. Validate restoration
cd ~/.claude
./validate-framework.sh
```

## Getting Help

### Information to Collect Before Asking for Help

1. **Environment Information**:
   ```bash
   uname -a
   echo $SHELL $BASH_VERSION
   pwd
   ```

2. **Validation Output**:
   ```bash
   ./validate-framework.sh > validation-output.txt 2>&1
   ```

3. **Directory Structure**:
   ```bash
   find . -name "*.md" | head -20 > directory-structure.txt
   ls -la > directory-listing.txt
   ```

4. **Recent Changes**:
   ```bash
   # If git repository
   git log --oneline -10
   git status
   ```

### Common Support Scenarios

**When Reporting Issues**:
- Include exact error messages
- Specify which mode (repository/installed) you're using
- Provide the diagnostic information above
- Describe what you were trying to accomplish

**When Requesting Features**:
- Explain the use case
- Describe current workaround (if any)
- Specify if it affects security or compatibility

## Prevention Strategies

### Regular Maintenance

```bash
#!/bin/bash
# Weekly framework health check
echo "📅 Weekly Framework Maintenance - $(date)"

# 1. Backup
cp -r ~/.claude ~/.claude.backup.$(date +%Y%m%d)

# 2. Update
./scripts/update.sh

# 3. Validate
cd ~/.claude
./validate-framework.sh

# 4. Clean old backups
find ~/.claude.backup.* -mtime +30 -exec rm -rf {} \; 2>/dev/null

echo "✅ Maintenance complete"
```

### Monitoring

```bash
# Set up simple monitoring
echo "*/15 * * * * cd ~/.claude && ./validate-framework.sh >/dev/null || echo 'Framework validation failed at $(date)' >> ~/.claude/health.log" | crontab -
```

Remember: Most issues are resolved by ensuring you're in the correct directory and that framework files are properly installed. When in doubt, try a clean installation - it's designed to be safe and preserve your work.