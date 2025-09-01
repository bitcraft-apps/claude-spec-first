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

**This command is ideal for critical work** where you need clean context boundaries. Use `/clear` after implementation phase to ensure clean documentation context.

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
**Prompt:** Create comprehensive documentation for the completed feature.

Please:
1. Read development artifacts from `.csf/` directory (spec.md, implementation-summary.md) if they exist, or ask user for artifact locations if missing
2. Analyze the actual implementation files and code structure
3. Create technical documentation for developers including:
   - Architecture overview
   - API reference
   - Setup and usage instructions
4. Generate user-facing documentation including:
   - Feature guides
   - Getting started instructions
   - Common use cases and examples
5. Ensure all documentation is accurate against the actual implementation
6. Use clear, consistent writing throughout
7. Organize documentation in a logical, navigable structure

Create documentation files in the appropriate project locations (docs/, docs/user/, etc.) rather than in the `.csf/` directory. Provide a summary of generated documentation to the terminal.

Focus on creating documentation that serves both technical and non-technical audiences effectively.