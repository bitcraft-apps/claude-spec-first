# Simple Workflow Example: User Login Feature

This example demonstrates the simplified 3-phase workflow for implementing a basic user login feature.

## Phase 1: Specification (/csf:spec)

**Command:** `/csf:spec Add email/password login to the web application`

**Expected Output:**
```markdown
# User Login Specification

## Requirements Summary
- **What**: Email/password authentication system for web application
- **Why**: Allow users to securely access their accounts
- **Scope**: Login form, authentication logic, session management

## Functional Specifications
- **Login Form**: Email input, password input, submit button
- **Authentication**: Validate credentials against user database
- **Session Management**: Create secure session on successful login
- **Error Handling**: Display appropriate messages for invalid credentials

## Acceptance Criteria
- User can enter email and password
- System validates credentials against database
- Successful login creates authenticated session
- Failed login shows clear error message
- Form validates email format

## Implementation Notes
- Use existing session management system
- Follow application's error message patterns
- Hash passwords using bcrypt or similar
```

## Phase 2: Implementation (/csf:implement)

**Command:** `/csf:implement docs/specifications/user-login-spec.md`

**Expected Actions:**
1. Creates login form component (HTML/React/Vue)
2. Implements authentication endpoint/service
3. Adds session management logic
4. Implements error handling and validation
5. Tests the implementation

## Phase 3: Documentation (/csf:document)

**Command:** `/csf:document docs/specifications/user-login-spec.md src/auth/`

**Expected Output:**
- Technical documentation for developers
- User guide for login functionality
- API reference for authentication endpoints
- Setup and configuration instructions

## Using the Full Workflow

**Single Command:** `/csf:workflow Add email/password login to the web application`

This executes all three phases automatically:
1. Creates specification
2. Clears context
3. Implements the feature
4. Clears context  
5. Generates documentation

## Key Benefits

- **Simple**: Only 3 phases to understand
- **Clear**: Each phase has a specific purpose
- **Focused**: Context clearing prevents information overload
- **Complete**: Delivers specification, working code, and documentation