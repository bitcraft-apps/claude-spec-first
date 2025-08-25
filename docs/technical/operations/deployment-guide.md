---
generated_from:
  specifications: [deployment requirements, operational procedures]
  architecture: [dual-mode system design, installation architecture]
  qa_reports: [deployment testing results, operational validation]
  implementation: [installation scripts, validation procedures]
generated_date: 2025-08-24
generated_by: doc-synthesizer
version: 1.0.0
status: current
traceability_id: deployment-guide-v1.0
---

# Deployment and Operations Guide

## Overview

This guide provides comprehensive instructions for deploying, operating, and maintaining the dual-mode validation script enhancement across different environments. The enhanced validation system supports both repository development environments and production Claude Code installations with automatic mode detection and robust security features.

## Deployment Architecture

### Deployment Modes

#### Repository Mode Deployment
- **Target Environment**: Framework development and testing
- **Location**: `./framework/validate-framework.sh`
- **Use Cases**: CI/CD pipelines, development validation, pre-release testing
- **Access Pattern**: Direct execution from repository root

#### Installed Mode Deployment  
- **Target Environment**: Production Claude Code installations
- **Location**: `~/.claude/validate-framework.sh`
- **Use Cases**: Framework health checks, installation validation, runtime verification
- **Access Pattern**: Execution from `~/.claude/` directory

### Deployment Considerations

#### Environment Requirements
- **Operating System**: Unix-like systems (Linux, macOS, WSL)
- **Shell**: Bash 4.0 or higher
- **Permissions**: Read access to framework directories
- **Dependencies**: No external dependencies required

#### Security Requirements
- Path traversal protection enabled
- Input validation active on all operations
- Secure error handling with immediate termination on security violations
- Read-only file system operations throughout

## Installation Procedures

### Fresh Installation

#### Repository Mode Installation

```bash
# Clone or create framework repository
git clone <repository-url> claude-spec-first
cd claude-spec-first

# Verify framework structure
ls -la framework/
# Expected: CLAUDE.md, agents/, commands/, examples/

# Validate installation
./framework/validate-framework.sh
```

**Expected Output**:
```
🔍 Validating Specification-First Development Framework...
==================================================

📁 Checking Directory Structure...
==================================
ℹ️  Detected repository mode - using ./framework/ prefix
✅ CLAUDE.md exists (repository mode)
✅ agents/ directory exists
✅ commands/ directory exists
```

#### Installed Mode Installation

```bash
# Install framework to Claude Code directory
./scripts/install.sh

# Navigate to installation directory
cd ~/.claude

# Validate installation
./validate-framework.sh
```

**Expected Output**:
```
🔍 Validating Specification-First Development Framework...
==================================================

📁 Checking Directory Structure...
==================================
ℹ️  Detected installed mode - using current directory
✅ CLAUDE.md exists (installed mode)
✅ agents/ directory exists
✅ commands/ directory exists
```

### Upgrade Procedures

#### In-Place Upgrades

```bash
# Repository mode upgrade
cd claude-spec-first
git pull origin main
./framework/validate-framework.sh

# Installed mode upgrade
./scripts/update.sh
cd ~/.claude
./validate-framework.sh
```

#### Migration from Previous Versions

```bash
# Backup existing installation
cp -r ~/.claude ~/.claude.backup.$(date +%Y%m%d_%H%M%S)

# Install new version
./scripts/install.sh

# Validate migration
cd ~/.claude
./validate-framework.sh

# Verify functionality
# Should show 79 validation checks passing
```

## Operational Procedures

### Regular Validation

#### Daily Health Checks

```bash
#!/bin/bash
# ~/.claude/scripts/daily-health-check.sh

echo "🏥 Daily Framework Health Check - $(date)"
echo "========================================"

cd ~/.claude
./validate-framework.sh

if [ $? -eq 0 ]; then
    echo "✅ Framework health check PASSED"
else
    echo "❌ Framework health check FAILED - intervention required"
    # Send alert or notification
fi
```

#### Continuous Integration Validation

```yaml
# .github/workflows/framework-validation.yml
name: Framework Validation
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Run Framework Validation
      run: |
        chmod +x framework/validate-framework.sh
        ./framework/validate-framework.sh
    - name: Check Validation Results
      run: |
        if [ $? -eq 0 ]; then
          echo "✅ Framework validation passed"
        else
          echo "❌ Framework validation failed"
          exit 1
        fi
```

### Performance Monitoring

#### Execution Time Monitoring

```bash
#!/bin/bash
# Monitor validation script performance

start_time=$(date +%s%N)
./validate-framework.sh > /dev/null 2>&1
exit_code=$?
end_time=$(date +%s%N)

execution_time=$(((end_time - start_time) / 1000000))  # Convert to milliseconds

echo "Validation execution time: ${execution_time}ms"
echo "Exit code: $exit_code"

# Alert if execution time exceeds threshold (5 seconds = 5000ms)
if [ $execution_time -gt 5000 ]; then
    echo "⚠️  WARNING: Validation took longer than expected"
fi
```

#### Resource Usage Monitoring

```bash
#!/bin/bash
# Monitor resource usage during validation

# Run with time and memory monitoring
/usr/bin/time -v ./validate-framework.sh 2>&1 | grep -E "(Maximum resident|User time|System time|Exit status)"
```

### Error Handling and Recovery

#### Common Issues and Solutions

#### Issue: Mode Detection Failure

**Symptoms**:
```
❌ Invalid execution context
This script must be run from either:
  - Repository root (with ./framework/ directory)
  - Installed location (~/.claude/ with CLAUDE.md)
```

**Diagnosis**:
```bash
# Check current directory structure
ls -la
pwd

# Verify framework files exist
ls -la framework/CLAUDE.md 2>/dev/null || echo "Repository mode not available"
ls -la ~/.claude/CLAUDE.md 2>/dev/null || echo "Installed mode not available"
```

**Resolution**:
```bash
# For repository mode
cd /path/to/repository/root
./framework/validate-framework.sh

# For installed mode  
cd ~/.claude
./validate-framework.sh
```

#### Issue: Security Violations

**Symptoms**:
```
Security Error: Invalid path detected: <path>
```

**Diagnosis**:
- Check for path traversal attempts (`../`)
- Verify no dangerous characters in paths
- Confirm no null bytes in file names

**Resolution**:
```bash
# Clean any corrupted framework files
find ~/.claude -name "*\.\.*" -delete
find ~/.claude -name "*;*" -delete
find ~/.claude -name "*|*" -delete

# Reinstall framework if necessary
./scripts/install.sh
```

#### Issue: Validation Failures

**Symptoms**:
```
❌ Framework validation FAILED!
X critical issues must be resolved before using the framework.
```

**Diagnosis**:
```bash
# Run with verbose output
./validate-framework.sh | tee validation-report.txt

# Check specific failures
grep "❌" validation-report.txt
```

**Resolution**:
```bash
# Address missing files
mkdir -p agents commands examples

# Fix YAML frontmatter issues
# Check agent files have proper frontmatter format:
---
name: agent-name
description: Agent description
tools: [Read, Write, Edit]
---
```

### Backup and Recovery

#### Framework Backup Procedures

```bash
#!/bin/bash
# Backup framework installation

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/.claude-backups"

echo "📦 Creating framework backup..."
mkdir -p "$BACKUP_DIR"

# Create compressed backup
tar -czf "$BACKUP_DIR/claude-framework-${BACKUP_DATE}.tar.gz" \
    -C "$HOME" .claude/

echo "✅ Backup created: $BACKUP_DIR/claude-framework-${BACKUP_DATE}.tar.gz"

# Clean old backups (keep last 10)
ls -t "$BACKUP_DIR"/claude-framework-*.tar.gz | tail -n +11 | xargs -r rm
```

#### Recovery Procedures

```bash
#!/bin/bash
# Restore framework from backup

BACKUP_FILE="$1"
if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup-file>"
    ls -t "$HOME/.claude-backups"/claude-framework-*.tar.gz | head -5
    exit 1
fi

echo "🔄 Restoring framework from backup..."

# Create emergency backup of current state
mv ~/.claude ~/.claude.emergency-backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null

# Restore from backup
tar -xzf "$BACKUP_FILE" -C "$HOME"

# Validate restoration
cd ~/.claude
./validate-framework.sh

if [ $? -eq 0 ]; then
    echo "✅ Framework restoration successful"
    rm -rf ~/.claude.emergency-backup.* 2>/dev/null
else
    echo "❌ Framework restoration failed"
    echo "Emergency backup available at: ~/.claude.emergency-backup.*"
fi
```

### Security Operations

#### Security Monitoring

```bash
#!/bin/bash
# Monitor for security violations

LOGFILE="$HOME/.claude/logs/security.log"
mkdir -p "$(dirname "$LOGFILE")"

# Run validation and capture security events
./validate-framework.sh 2>&1 | grep "Security Error" >> "$LOGFILE"

# Alert on new security violations
if [ -s "$LOGFILE" ]; then
    VIOLATIONS=$(tail -n 10 "$LOGFILE")
    echo "⚠️  Security violations detected:"
    echo "$VIOLATIONS"
    
    # Send notification (customize as needed)
    # mail -s "Framework Security Alert" admin@example.com < "$LOGFILE"
fi
```

#### Security Audit Procedures

```bash
#!/bin/bash
# Comprehensive security audit

echo "🔒 Framework Security Audit - $(date)"
echo "====================================="

# Check file permissions
echo "📁 File Permissions Audit:"
find ~/.claude -type f -perm -002 | while read file; do
    echo "⚠️  World-writable file: $file"
done

# Check for dangerous file names
echo "📄 Dangerous File Name Audit:"
find ~/.claude -name "*\.\.*" -o -name "*;*" -o -name "*|*" | while read file; do
    echo "⚠️  Dangerous file name: $file"
done

# Run security validation
echo "🛡️  Security Validation:"
./validate-framework.sh 2>&1 | grep -E "(Security|security)"

# Check framework integrity
echo "🔍 Framework Integrity Check:"
md5sum ~/.claude/validate-framework.sh
```

## Maintenance Procedures

### Regular Maintenance Tasks

#### Weekly Maintenance

```bash
#!/bin/bash
# Weekly maintenance routine

echo "🔧 Weekly Framework Maintenance - $(date)"
echo "========================================="

# Update framework
./scripts/update.sh

# Run comprehensive validation  
cd ~/.claude
./validate-framework.sh

# Clean temporary files
find ~/.claude -name "*.tmp" -delete
find ~/.claude -name "*.log" -mtime +30 -delete

# Generate health report
echo "📊 Framework Health Summary:"
echo "Agents: $(ls ~/.claude/agents/*.md 2>/dev/null | wc -l)"
echo "Commands: $(ls ~/.claude/commands/*.md 2>/dev/null | wc -l)"  
echo "Examples: $(find ~/.claude/examples -name "*.md" 2>/dev/null | wc -l)"
```

#### Monthly Maintenance

```bash
#!/bin/bash
# Monthly maintenance routine

echo "🗓️  Monthly Framework Maintenance - $(date)"
echo "===========================================" 

# Full backup
./scripts/backup-framework.sh

# Security audit
./scripts/security-audit.sh

# Performance baseline
echo "⏱️  Performance Baseline:"
time ./validate-framework.sh > /dev/null

# Documentation updates
echo "📚 Checking for documentation updates..."
# Check for new framework features
# Update local documentation if needed
```

### Troubleshooting Guide

#### Diagnostic Commands

```bash
# Environment diagnosis
echo "Environment Information:"
echo "OS: $(uname -a)"
echo "Shell: $SHELL ($BASH_VERSION)"
echo "User: $(whoami)"
echo "Working Directory: $(pwd)"
echo "Claude Directory: $(ls -ld ~/.claude 2>/dev/null || echo 'Not found')"

# Framework structure diagnosis
echo "Framework Structure:"
find ~/.claude -type f -name "*.md" | head -20
echo "Total .md files: $(find ~/.claude -name "*.md" | wc -l)"

# Permission diagnosis  
echo "Permission Check:"
ls -la ~/.claude/validate-framework.sh
test -x ~/.claude/validate-framework.sh && echo "✅ Execute permission OK" || echo "❌ Execute permission missing"
```

#### Log Analysis

```bash
# Analyze validation logs
grep -E "(PASSED|FAILED|WARNING)" ~/.claude/logs/validation.log | \
    awk '{print $NF}' | sort | uniq -c | sort -nr
```

## Performance Optimization

### Performance Tuning

#### Execution Optimization

```bash
# Optimized validation execution
export FRAMEWORK_VALIDATION_QUIET=1  # Reduce output verbosity
export FRAMEWORK_VALIDATION_FAST=1   # Skip optional checks

./validate-framework.sh
```

#### Resource Optimization

```bash
# Resource-constrained environments
ulimit -v 102400  # Limit virtual memory to 100MB
ulimit -t 30      # Limit CPU time to 30 seconds

./validate-framework.sh
```

### Scaling Considerations

#### Large Framework Deployments

For frameworks with many components:

```bash
# Parallel validation (where safe)
validate_agents_parallel() {
    for agent in "${REQUIRED_AGENTS[@]}"; do
        (validate_single_agent "$agent") &
    done
    wait
}
```

#### High-Frequency Validation

For environments requiring frequent validation:

```bash
# Incremental validation
if [ -f ~/.claude/.validation-cache ]; then
    # Only validate changed files
    find ~/.claude -newer ~/.claude/.validation-cache -name "*.md" | \
        xargs ./scripts/validate-components.sh
else
    # Full validation
    ./validate-framework.sh
fi

touch ~/.claude/.validation-cache
```

## Monitoring and Alerting

### Health Monitoring

```bash
#!/bin/bash
# Framework health monitoring

HEALTH_FILE="$HOME/.claude/health-status.txt"

# Run validation and capture metrics
VALIDATION_START=$(date +%s)
./validate-framework.sh > /tmp/validation-output.txt 2>&1
VALIDATION_EXIT=$?
VALIDATION_END=$(date +%s)
VALIDATION_TIME=$((VALIDATION_END - VALIDATION_START))

# Extract metrics
PASSED=$(grep -c "✅" /tmp/validation-output.txt)
FAILED=$(grep -c "❌" /tmp/validation-output.txt)  
WARNINGS=$(grep -c "⚠️" /tmp/validation-output.txt)

# Write health status
cat > "$HEALTH_FILE" << EOF
timestamp=$(date -Iseconds)
validation_time_seconds=$VALIDATION_TIME
exit_code=$VALIDATION_EXIT
tests_passed=$PASSED
tests_failed=$FAILED
warnings=$WARNINGS
health_status=$([ $VALIDATION_EXIT -eq 0 ] && echo "healthy" || echo "unhealthy")
EOF

echo "📊 Framework Health Metrics written to $HEALTH_FILE"
```

### Alert Configuration

```bash
#!/bin/bash
# Alert configuration for framework issues

ALERT_THRESHOLD_FAILURES=5
ALERT_THRESHOLD_TIME=10  # seconds

# Check health status
source "$HOME/.claude/health-status.txt"

# Generate alerts
if [ "$tests_failed" -gt "$ALERT_THRESHOLD_FAILURES" ]; then
    echo "🚨 ALERT: Framework validation has $tests_failed failures (threshold: $ALERT_THRESHOLD_FAILURES)"
fi

if [ "$validation_time_seconds" -gt "$ALERT_THRESHOLD_TIME" ]; then
    echo "🚨 ALERT: Framework validation took ${validation_time_seconds}s (threshold: ${ALERT_THRESHOLD_TIME}s)"
fi

if [ "$health_status" = "unhealthy" ]; then
    echo "🚨 ALERT: Framework health status is UNHEALTHY"
fi
```

This comprehensive deployment and operations guide provides the foundation for successfully deploying, maintaining, and monitoring the dual-mode validation script enhancement across all environments and use cases.