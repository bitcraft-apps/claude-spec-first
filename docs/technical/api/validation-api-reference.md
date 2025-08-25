---
generated_from:
  specifications: [dual-mode validation requirements, security specifications]
  architecture: [function-based design, security architecture]
  qa_reports: [function testing results, security validation]
  implementation: [framework/validate-framework.sh function definitions]
generated_date: 2025-08-24
generated_by: doc-synthesizer
version: 1.0.0
status: current
traceability_id: validation-api-v1.0
---

# Validation Script API Reference

## Overview

The dual-mode validation script provides a comprehensive API of functions for framework validation, security, and mode detection. This reference documents all public and internal functions, their parameters, return values, and usage patterns.

## Core API Functions

### Mode Detection API

#### `detect_execution_mode()`

**Purpose**: Automatically detect and configure the appropriate execution mode based on directory structure.

**Parameters**: None

**Return Values**:
- `0`: Success - Mode detected and configured
- `1`: Failure - Invalid execution context

**Side Effects**:
- Sets global variable `EXECUTION_MODE` to "repository" or "installed"
- Sets global variable `FRAMEWORK_PREFIX` to appropriate path prefix
- Outputs informational message about detected mode

**Usage**:
```bash
detect_execution_mode
if [ $? -eq 0 ]; then
    echo "Mode detection successful: $EXECUTION_MODE"
else
    echo "Mode detection failed"
    exit 1
fi
```

**Logic Flow**:
1. Check for repository mode: `./framework/` directory + `./framework/CLAUDE.md`
2. Check for installed mode: `./CLAUDE.md` in current directory
3. Fail if neither pattern matches

**Error Handling**:
- Provides clear guidance on valid execution contexts
- Lists specific directory structures expected for each mode
- Exits with code 1 on detection failure

---

### Security API

#### `validate_path_security(path)`

**Purpose**: Validate file system paths against security threats including directory traversal and injection attacks.

**Parameters**:
- `$1` (string): Path to validate

**Return Values**:
- `0`: Path is secure and safe to use
- `1`: Path contains security risks

**Security Checks**:
- Directory traversal patterns: `..`, `/./`, `//`
- Null byte injection: `\0`
- Shell metacharacters: `;`, `|`, `` ` ``, `$`

**Usage**:
```bash
if validate_path_security "/path/to/file"; then
    echo "Path is secure"
else
    echo "Security violation detected"
fi
```

**Security Considerations**:
- Does not modify input path
- Pure validation function with no side effects
- Designed to prevent common file system attacks

#### `build_safe_path(relative_path)`

**Purpose**: Construct secure absolute paths with proper mode prefix and security validation.

**Parameters**:
- `$1` (string): Relative path within framework structure

**Return Values**:
- Outputs: Secure absolute path on success
- Exit Code: `1` on security violation (script termination)

**Side Effects**:
- Terminates script execution on security violations
- Outputs security error message to stderr

**Usage**:
```bash
AGENT_FILE=$(build_safe_path "agents/spec-analyst.md")
if [ -f "$AGENT_FILE" ]; then
    echo "Agent file exists: $AGENT_FILE"
fi
```

**Implementation**:
```bash
build_safe_path() {
    local relative_path="$1"
    local full_path="${FRAMEWORK_PREFIX}${relative_path}"
    
    if ! validate_path_security "$full_path"; then
        echo -e "${RED}Security Error: Invalid path detected: $full_path${NC}" >&2
        exit 1
    fi
    
    echo "$full_path"
}
```

---

### Output Formatting API

#### `print_status(message, exit_code)`

**Purpose**: Print formatted status messages with consistent color coding and test result tracking.

**Parameters**:
- `$1` (string): Status message to display
- `$2` (integer): Exit code (0 for success, non-zero for failure)

**Return Values**: None (pure output function)

**Side Effects**:
- Increments global `PASSED` counter on success
- Increments global `FAILED` counter on failure
- Outputs colored status line

**Usage**:
```bash
if [ -f "required-file.txt" ]; then
    print_status "Required file exists" 0
else
    print_status "Required file exists" 1
fi
```

**Output Format**:
- Success: `✅ message` (green)
- Failure: `❌ message` (red)

#### `print_warning(message)`

**Purpose**: Display warning messages for non-critical issues.

**Parameters**:
- `$1` (string): Warning message to display

**Return Values**: None

**Side Effects**:
- Increments global `WARNINGS` counter
- Outputs colored warning line

**Usage**:
```bash
if [ ! -d "optional-directory" ]; then
    print_warning "Optional directory missing (recommended)"
fi
```

**Output Format**: `⚠️ message` (yellow)

#### `print_info(message)`

**Purpose**: Display informational messages with consistent formatting.

**Parameters**:
- `$1` (string): Information message to display

**Return Values**: None

**Side Effects**: None (pure output function)

**Usage**:
```bash
print_info "Found $AGENT_COUNT agent files"
```

**Output Format**: `ℹ️ message` (blue)

---

## Validation Function API

### Component Validation

#### Agent Validation Functions

The script implements comprehensive agent validation through a standardized process:

```bash
for agent in "${REQUIRED_AGENTS[@]}"; do
    AGENT_FILE=$(build_safe_path "agents/${agent}.md")
    
    # File existence check
    if [ -f "$AGENT_FILE" ]; then
        print_status "$agent.md exists" 0
        
        # YAML frontmatter validation
        if head -1 "$AGENT_FILE" | grep -q "^---$"; then
            print_status "$agent has YAML frontmatter" 0
        else
            print_status "$agent has YAML frontmatter" 1
        fi
        
        # Required field validation
        validate_agent_fields "$AGENT_FILE" "$agent"
    else
        print_status "$agent.md exists" 1
    fi
done
```

#### Command Validation Functions

Command validation follows a similar pattern with command-specific checks:

```bash
for command in "${REQUIRED_COMMANDS[@]}"; do
    COMMAND_FILE=$(build_safe_path "commands/${command}.md")
    
    if [ -f "$COMMAND_FILE" ]; then
        validate_command_structure "$COMMAND_FILE" "$command"
        validate_command_integration "$COMMAND_FILE" "$command"
    fi
done
```

### Pattern Validation Functions

#### `build_agent_pattern()`

**Purpose**: Dynamically construct regex patterns for agent name matching.

**Parameters**: None (uses global `REQUIRED_AGENTS` array)

**Return Values**: 
- Outputs: Pipe-separated regex pattern for all required agents

**Usage**:
```bash
AGENT_PATTERN=$(build_agent_pattern)
AGENT_MENTIONS=$(grep -c "$AGENT_PATTERN" "$COMMAND_FILE" || true)
```

**Implementation**:
```bash
build_agent_pattern() {
    local pattern=""
    local first=true
    for agent in "${REQUIRED_AGENTS[@]}"; do
        if [ "$first" = true ]; then
            pattern="$agent"
            first=false
        else
            pattern="$pattern\|$agent"
        fi
    done
    echo "$pattern"
}
```

---

## Global Variables API

### Execution State Variables

- `EXECUTION_MODE`: Current execution mode ("repository" or "installed")
- `FRAMEWORK_PREFIX`: Path prefix for all framework operations
- `CLAUDE_MD_PATH`: Resolved path to main CLAUDE.md file

### Test Result Counters

- `PASSED`: Count of successful validation checks
- `FAILED`: Count of failed validation checks  
- `WARNINGS`: Count of warning conditions

### Component Configuration

- `REQUIRED_AGENTS[]`: Array of required agent names
- `REQUIRED_COMMANDS[]`: Array of required command names
- `VALID_TOOLS[]`: Array of valid tool names for agents

### Color Codes

- `RED`: ANSI escape code for red text (`\033[0;31m`)
- `GREEN`: ANSI escape code for green text (`\033[0;32m`)
- `YELLOW`: ANSI escape code for yellow text (`\033[1;33m`)
- `BLUE`: ANSI escape code for blue text (`\033[0;34m`)
- `NC`: No color reset (`\033[0m`)

---

## Configuration API

### Framework Component Lists

#### Required Agents
```bash
REQUIRED_AGENTS=("spec-analyst" "test-designer" "arch-designer" "impl-specialist" "qa-validator" "doc-synthesizer")
```

#### Required Commands
```bash
REQUIRED_COMMANDS=("spec-init" "spec-review" "impl-plan" "qa-check" "spec-workflow" "doc-generate")
```

#### Valid Tools
```bash
VALID_TOOLS=("Read" "Write" "Edit" "MultiEdit" "Bash" "Grep" "Glob")
```

### Validation Rules

#### YAML Frontmatter Requirements

**Agents**:
- Must start with `---`
- Must contain `name: [agent-name]` field
- Must contain `description:` field
- Should contain `tools:` field (warning if missing)

**Commands**:
- Must start with `---`
- Must contain `description:` field
- Should use `$ARGUMENTS` placeholder
- Should delegate to agents (warning if no agent mentions)

---

## Error Handling API

### Exit Codes

- `0`: All validations passed successfully
- `1`: Critical validation failures or security violations

### Error Categories

#### Security Errors
- Immediate script termination
- Clear security violation messages
- No recovery path (by design)

#### Validation Errors
- Continued execution with error tracking
- Detailed failure reporting
- Final assessment after all checks

#### Mode Detection Errors
- Immediate termination with helpful guidance
- Clear instructions for valid execution contexts

---

## Extension API

### Adding New Validation Checks

To add new validation checks:

1. Add to appropriate `REQUIRED_*` array
2. Implement validation logic using `build_safe_path()` for file access
3. Use `print_status()` for result reporting
4. Follow established error handling patterns

Example:
```bash
# Add to configuration
REQUIRED_PLUGINS=("custom-plugin")

# Implement validation
for plugin in "${REQUIRED_PLUGINS[@]}"; do
    PLUGIN_FILE=$(build_safe_path "plugins/${plugin}.md")
    
    if [ -f "$PLUGIN_FILE" ]; then
        print_status "$plugin plugin exists" 0
        # Additional validation logic...
    else
        print_status "$plugin plugin exists" 1
    fi
done
```

### Custom Output Functions

Follow the established pattern for new output functions:

```bash
print_custom() {
    local message="$1"
    local color="$2"
    echo -e "${color}🔧 $message${NC}"
}
```

---

## Best Practices

### Function Usage Guidelines

1. **Always use `build_safe_path()`** for file system operations
2. **Use appropriate output functions** for consistent formatting
3. **Follow error handling patterns** established in existing code
4. **Validate inputs** before processing in custom functions
5. **Maintain backward compatibility** when extending the API

### Security Guidelines

1. **Never bypass path security validation**
2. **Sanitize all user inputs**
3. **Use fail-secure error handling**
4. **Log security violations clearly**
5. **Exit immediately on security violations**

### Performance Guidelines

1. **Minimize file system operations**
2. **Use efficient pattern matching**
3. **Cache expensive operations when possible**
4. **Avoid unnecessary subprocess creation**
5. **Keep validation checks focused and minimal**