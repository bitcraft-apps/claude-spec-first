---
description: Initialize specification process for a new feature - creates detailed requirements, test cases, and implementation plan
---

# Specification Initialization

You are starting the specification-first development process for: **$ARGUMENTS**

## Process Steps:

### 1. Requirements Analysis
Ask clarifying questions about:
- What exactly should this feature do?
- What are the success criteria?
- What are the constraints and limitations?
- Who are the users and what are their needs?
- What are the performance/security requirements?

### 2. Specification Creation
Once requirements are clear, create:
- **Requirements Summary**: Clear scope and boundaries
- **Functional Specifications**: Detailed component breakdown  
- **Acceptance Criteria**: Measurable success conditions
- **Test Cases**: Both happy path and edge cases

### 3. Implementation Planning
Generate:
- **Architecture Overview**: High-level design approach
- **Implementation Tasks**: Step-by-step development plan
- **Quality Gates**: Checkpoints for validation

## Output Structure
Create the following deliverables:
1. `requirements.md` - Detailed requirements document
2. `test-cases.md` - Comprehensive test scenarios
3. `implementation-plan.md` - Development roadmap

## Instructions
- Use the spec-analyst sub-agent to handle the requirements analysis phase
- Follow our specification-first workflow principles
- Delegate to appropriate specialists for each phase
- Ensure all requirements have corresponding test cases
- Create failing tests that encode the requirements

**IMMEDIATE ACTION**: Delegate the requirements analysis for "$ARGUMENTS" to the spec-analyst sub-agent. The spec-analyst will ask clarifying questions and create detailed specifications following their specialized process.