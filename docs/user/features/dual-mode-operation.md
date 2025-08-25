---
generated_from:
  specifications: [dual-mode requirements, user experience specifications]
  architecture: [mode detection system, user interaction design]
  qa_reports: [user testing results, usability validation]
  implementation: [mode detection logic, user interface elements]
generated_date: 2025-08-24
generated_by: doc-synthesizer
version: 1.0.0
status: current
traceability_id: user-dual-mode-v1.0
---

# Dual-Mode Operation

## Overview

The enhanced validation script now supports intelligent dual-mode operation, automatically detecting whether you're working in a framework development environment or using an installed Claude Code framework. This eliminates configuration complexity while providing the same powerful validation capabilities in both contexts.

## What is Dual-Mode Operation?

Dual-mode operation means the validation script automatically adapts to your working environment:

- **Repository Mode**: When you're developing or testing the framework itself
- **Installed Mode**: When you're using the framework in your normal Claude Code workflow

The script detects which mode to use based on your current directory structure, requiring no configuration or command-line flags.

## How It Works

### Automatic Detection

The validation script examines your current directory to determine the appropriate mode:

```bash
./framework/validate-framework.sh
```

**Repository Mode Detected When**:
- You have a `./framework/` directory
- The directory contains `CLAUDE.md`
- You're working on framework development

**Installed Mode Detected When**:
- You have `CLAUDE.md` in your current directory  
- You're in `~/.claude/` or similar installation location
- You're using the framework for normal development work

### User Experience

When you run the validation script, you'll see clear feedback about which mode is detected:

**Repository Mode Output**:
```
🔍 Validating Specification-First Development Framework...
==================================================

📁 Checking Directory Structure...
==================================
ℹ️  Detected repository mode - using ./framework/ prefix
✅ CLAUDE.md exists (repository mode)
```

**Installed Mode Output**:
```
🔍 Validating Specification-First Development Framework...
==================================================

📁 Checking Directory Structure...
==================================  
ℹ️  Detected installed mode - using current directory
✅ CLAUDE.md exists (installed mode)
```

## Repository Mode Usage

### When to Use Repository Mode

Repository mode is automatically used when you're:
- Developing new framework features
- Testing framework changes
- Contributing to the framework project
- Running CI/CD validation pipelines
- Preparing framework releases

### Repository Mode Features

**Development Focus**:
- Validates framework source code in `./framework/`
- Checks development directory structure
- Verifies framework component completeness
- Ensures CI/CD readiness

**Example Workflow**:
```bash
# Clone framework repository
git clone <repository-url> claude-spec-first
cd claude-spec-first

# Make framework changes
vim framework/agents/spec-analyst.md

# Validate changes
./framework/validate-framework.sh
# Output: Repository mode automatically detected
```

### Repository Mode Validation Scope

The validation covers:
- Framework source files in `./framework/`
- Agent definitions and YAML frontmatter
- Command implementations and integration
- Documentation structure and completeness
- Template system validation
- Integration testing capabilities

## Installed Mode Usage

### When to Use Installed Mode

Installed mode is automatically used when you're:
- Working on regular development projects with Claude Code
- Validating your installed framework health
- Troubleshooting framework issues
- Verifying framework installation integrity
- Performing routine maintenance checks

### Installed Mode Features

**Production Focus**:
- Validates installed framework in current directory
- Checks runtime component health
- Verifies framework operational readiness
- Ensures user experience quality

**Example Workflow**:
```bash
# Navigate to Claude installation
cd ~/.claude

# Check framework health
./validate-framework.sh
# Output: Installed mode automatically detected

# Use framework for development
claude-code /spec-init "new feature"
```

### Installed Mode Validation Scope

The validation covers:
- Installed framework components
- Agent availability and functionality  
- Command accessibility and integration
- User documentation completeness
- Runtime configuration validation
- Production environment readiness

## Benefits of Dual-Mode Operation

### For Framework Developers

**Simplified Testing**:
- No need to specify modes or paths
- Consistent validation across development stages
- Automatic CI/CD integration

**Reduced Errors**:
- Eliminates path configuration mistakes  
- Prevents wrong-directory execution
- Automatic environment adaptation

### For Framework Users

**Effortless Validation**:
- No configuration required
- Works out-of-the-box with installations
- Consistent user experience

**Clear Feedback**:
- Always know which mode is active
- Understand validation scope
- Get appropriate guidance for your context

### For DevOps Teams

**Deployment Flexibility**:
- Same script works in all environments
- Simplified automation scripts
- Reduced maintenance overhead

**Environment Awareness**:
- Automatic production vs. development detection
- Context-appropriate validation rules
- Consistent monitoring across stages

## Common Usage Scenarios

### Scenario 1: Framework Development

```bash
# Working on framework improvements
cd ~/dev/claude-spec-first

# Add new agent
cp framework/agents/spec-analyst.md framework/agents/new-agent.md
vim framework/agents/new-agent.md

# Validate changes (repository mode auto-detected)
./framework/validate-framework.sh
```

**Expected Experience**:
- Repository mode automatically detected
- Validation covers framework source files
- Development-focused error messages
- Integration testing capabilities

### Scenario 2: Framework Usage

```bash
# Using framework for project development
cd ~/.claude

# Periodic health check (installed mode auto-detected)  
./validate-framework.sh

# Use framework
claude-code
# Framework commands now available
```

**Expected Experience**:
- Installed mode automatically detected
- Validation covers installed components
- User-focused status messages
- Production readiness confirmation

### Scenario 3: Mixed Environment

```bash
# Framework developer who also uses framework
cd ~/dev/claude-spec-first
./framework/validate-framework.sh  # Repository mode

cd ~/.claude  
./validate-framework.sh            # Installed mode
```

**Expected Experience**:
- Seamless mode switching between directories
- Appropriate validation for each context
- No configuration or flag management needed

## Troubleshooting Dual-Mode Issues

### Issue: Mode Detection Failure

**Problem**: Script can't determine which mode to use

**Error Message**:
```
❌ Invalid execution context
This script must be run from either:
  - Repository root (with ./framework/ directory)  
  - Installed location (~/.claude/ with CLAUDE.md)
```

**Solution**:
1. Check your current directory: `pwd`
2. For repository mode: Navigate to repository root with `./framework/` directory
3. For installed mode: Navigate to directory with `CLAUDE.md` file

### Issue: Wrong Mode Detection

**Problem**: Script detects wrong mode for your intended use

**Diagnosis**:
```bash
# Check current directory structure
ls -la
ls -la framework/ 2>/dev/null
ls -la CLAUDE.md 2>/dev/null
```

**Solution**:
- Ensure you're in the correct directory for your intended use case
- Repository mode requires `./framework/CLAUDE.md`
- Installed mode requires `./CLAUDE.md`

### Issue: Permission Problems

**Problem**: Script can't access files in detected mode

**Solution**:
```bash
# Check script permissions
ls -la validate-framework.sh
chmod +x validate-framework.sh

# Check directory permissions  
ls -la .
ls -la framework/ 2>/dev/null
```

## Advanced Configuration

### Environment Variables

While dual-mode operation is automatic, you can influence behavior with environment variables:

```bash
# Force quiet mode (less output)
FRAMEWORK_VALIDATION_QUIET=1 ./validate-framework.sh

# Enable debug mode (more detailed output)
FRAMEWORK_VALIDATION_DEBUG=1 ./validate-framework.sh
```

### Custom Installation Locations

The validation script works with custom installation locations:

```bash
# Custom Claude directory location
cd /custom/path/claude-framework
./validate-framework.sh
# Automatically detects installed mode if CLAUDE.md exists
```

## Best Practices

### For Regular Users

1. **Run from correct directory**: Navigate to `~/.claude` for installed mode
2. **Regular health checks**: Run validation weekly or after framework updates
3. **Understand output**: Pay attention to mode detection messages
4. **Report issues**: Include mode information when reporting problems

### For Framework Developers

1. **Test both modes**: Validate changes in repository and installed contexts
2. **CI/CD integration**: Use repository mode for automated testing
3. **Documentation**: Update user guides when changing validation behavior
4. **Backward compatibility**: Ensure changes work in both modes

### For DevOps Teams

1. **Automated validation**: Use dual-mode capability in deployment scripts
2. **Monitoring**: Include mode information in health monitoring
3. **Troubleshooting**: Check mode detection first when debugging issues
4. **Documentation**: Maintain runbooks for both operational modes

## Migration from Previous Versions

### For Existing Users

**Good News**: No changes required! Your existing validation workflows continue to work exactly as before.

**What's New**: The script now provides better feedback about its operating mode and has enhanced security features.

**Optional Improvements**: 
- Take advantage of the new security features by updating any custom scripts
- Use the improved error messages for better troubleshooting

### For Framework Developers

**Backward Compatibility**: All existing development workflows continue unchanged.

**New Capabilities**: 
- Enhanced testing in both development and production contexts
- Improved security validation
- Better error handling and reporting

**Recommended Actions**:
- Update CI/CD scripts to leverage improved error reporting
- Review security enhancements for additional hardening opportunities

## Summary

Dual-mode operation represents a significant usability improvement that:

- Eliminates configuration complexity through automatic detection
- Provides appropriate validation for your specific context  
- Maintains full backward compatibility with existing workflows
- Enhances security through improved path handling
- Offers better user experience with clear mode indication

The feature works transparently, requiring no changes to existing workflows while providing enhanced capabilities for both framework development and daily usage scenarios.