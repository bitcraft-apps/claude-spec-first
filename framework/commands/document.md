---
description: Generate comprehensive documentation from specifications and implementation
---

# Document Command

This command delegates to the `csf-document` agent to create documentation from specifications and code.

## Usage
```
/csf:document [SPECIFICATION_AND_IMPLEMENTATION_PATHS]
```

## What it does
- Analyzes specifications and implementation code
- Creates technical documentation for developers
- Generates user-facing documentation for end users
- Extracts API documentation from code
- Ensures documentation accuracy and consistency
- Creates clear, comprehensive guides

## Example
```
/csf:document docs/specifications/user-auth-spec.md src/auth/
```

## Agent
Uses the `csf-document` agent with the following capabilities:
- Read, Write, Edit, MultiEdit, Grep, Glob tools
- Documentation synthesis and generation
- Technical and user documentation creation
- API extraction and formatting

---

Use the Task tool to delegate to the csf-document agent:

**Task Description:** Generate documentation from specification and implementation
**Agent Type:** csf-document  
**Prompt:** Create comprehensive documentation based on: $ARGUMENTS

Please:
1. Read and analyze the specification and implementation code
2. Create technical documentation for developers including:
   - Architecture overview
   - API reference
   - Setup and usage instructions
3. Generate user-facing documentation including:
   - Feature guides
   - Getting started instructions
   - Common use cases and examples
4. Ensure all documentation is accurate against the actual implementation
5. Use clear, consistent writing throughout
6. Organize documentation in a logical, navigable structure

Focus on creating documentation that serves both technical and non-technical audiences effectively.