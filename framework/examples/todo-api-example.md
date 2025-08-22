# Complete Workflow Example: Todo List API

This example demonstrates the specification-first development framework by building a simple Todo List API endpoint. Follow along to see how the framework guides you from initial requirements to deployment-ready code.

## Project Goal
Build a REST API endpoint that allows users to create, read, update, and delete todo items.

## Step 1: Initialize Specification Process

**Command Used:**
```
/spec-init todo list REST API endpoint
```

**Expected Interaction:**
The spec-analyst will ask clarifying questions such as:
- What CRUD operations should be supported?
- What data fields should a todo item have?
- What authentication is required?
- What are the performance requirements?
- What error handling is needed?

**Sample Responses:**
- Operations: GET (list), POST (create), PUT (update), DELETE (remove)
- Fields: id, title, description, completed (boolean), created_at, updated_at
- Authentication: JWT token required
- Performance: < 200ms response time, handle 100 concurrent requests
- Errors: Standard HTTP status codes with JSON error responses

**Generated Output:**
```markdown
# Todo List API - Technical Specification

## Requirements Summary
A RESTful API endpoint for managing todo items with full CRUD operations, JWT authentication, and comprehensive error handling.

### Scope Boundaries
**Included:**
- CRUD operations (GET, POST, PUT, DELETE)
- JSON request/response format
- JWT authentication
- Input validation and sanitization
- Error handling with appropriate HTTP status codes
- Performance optimization for concurrent requests

**Excluded:**
- User registration/login endpoints
- Todo sharing between users
- File attachments
- Due date reminders
- Complex filtering/search

### Success Criteria
- All CRUD operations function correctly
- Authentication properly validates JWT tokens
- Response times under 200ms for single operations
- Handles 100 concurrent requests without errors
- Comprehensive error responses with helpful messages

## Functional Specifications

### API Endpoints
#### GET /api/todos
- List all todos for authenticated user
- Support pagination (limit, offset)
- Return array of todo objects

#### POST /api/todos
- Create new todo item
- Require title field (1-200 characters)
- Optional description field (max 1000 characters)
- Auto-generate id, created_at, updated_at
- Default completed = false

#### PUT /api/todos/:id
- Update existing todo item
- Allow partial updates
- Update updated_at timestamp
- Return updated todo object

#### DELETE /api/todos/:id
- Remove todo item
- Return 204 No Content on success
- Return 404 if todo not found

### Data Model
```json
{
  "id": "uuid-string",
  "title": "string (1-200 chars)",
  "description": "string (0-1000 chars)",
  "completed": boolean,
  "created_at": "ISO 8601 timestamp",
  "updated_at": "ISO 8601 timestamp"
}
```

## Test Cases
### Happy Path Scenarios
- TC001: GET /api/todos returns empty array for new user
- TC002: POST /api/todos creates todo with valid data
- TC003: GET /api/todos returns created todo
- TC004: PUT /api/todos/:id updates todo successfully
- TC005: DELETE /api/todos/:id removes todo

### Validation Scenarios
- TC006: POST with missing title returns 400 error
- TC007: POST with title > 200 chars returns 400 error
- TC008: PUT with invalid ID returns 404 error
- TC009: Requests without JWT return 401 error

### Edge Cases
- TC010: Concurrent updates to same todo
- TC011: Delete already deleted todo
- TC012: Update with malformed JSON
```

## Step 2: Review Specifications

**Command Used:**
```
/spec-review todo list REST API endpoint
```

**What Happens:**
- spec-analyst reviews specification for completeness and consistency
- test-designer validates that test cases cover all requirements
- arch-designer checks for missing architectural considerations
- Cross-agent validation identifies any gaps or improvements

**Expected Feedback:**
- Specification quality assessment: PASS
- Test coverage: 95% of requirements covered
- Architectural considerations: Need to specify database schema, caching strategy
- Recommendations: Add rate limiting, input sanitization details

## Step 3: Implementation Planning

**Command Used:**
```
/impl-plan todo list REST API endpoint
```

**Generated Plan:**
```markdown
# Implementation Plan: Todo List API

## Architecture Overview
- Node.js with Express.js framework
- PostgreSQL database with connection pooling
- JWT middleware for authentication
- Input validation with Joi schema
- Error handling middleware
- Response caching with Redis

## Implementation Phases

### Phase 1: Foundation (Day 1)
- Set up Express.js server with basic middleware
- Configure PostgreSQL database connection
- Create database schema and migrations
- Set up JWT authentication middleware
- Basic error handling and logging

### Phase 2: CRUD Operations (Day 2)
- Implement GET /api/todos with pagination
- Implement POST /api/todos with validation
- Implement PUT /api/todos/:id with partial updates
- Implement DELETE /api/todos/:id
- Add comprehensive input validation

### Phase 3: Testing & Optimization (Day 3)
- Write comprehensive test suite
- Add performance testing
- Implement caching with Redis
- Security hardening and rate limiting
- Documentation and deployment prep

## Database Schema
```sql
CREATE TABLE todos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Implementation Tasks
1. Express server setup with middleware
2. Database connection and schema
3. JWT authentication middleware
4. Todo model and database operations
5. Route handlers with validation
6. Error handling middleware
7. Test suite implementation
8. Performance optimization
9. Security and rate limiting
10. Documentation and deployment
```

## Step 4: Implementation

**Command Used:**
```
Use impl-specialist to implement the todo list API following the TDD approach 
with the specifications, architecture, and implementation plan.
```

**What impl-specialist Produces:**
- Complete Express.js application with all endpoints
- Database models and migrations
- Comprehensive test suite (unit and integration tests)
- JWT authentication middleware
- Input validation and error handling
- Performance optimizations
- API documentation

**Sample Generated Code:**
```javascript
// routes/todos.js
const express = require('express');
const router = express.Router();
const { validateTodo, validateTodoUpdate } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const Todo = require('../models/Todo');

// GET /api/todos - List todos with pagination
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const { limit = 50, offset = 0 } = req.query;
    const todos = await Todo.findByUserId(req.user.id, { limit, offset });
    res.json({
      data: todos,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
        total: await Todo.countByUserId(req.user.id)
      }
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/todos - Create new todo
router.post('/', authenticateToken, validateTodo, async (req, res, next) => {
  try {
    const todoData = {
      ...req.body,
      user_id: req.user.id
    };
    const todo = await Todo.create(todoData);
    res.status(201).json({ data: todo });
  } catch (error) {
    next(error);
  }
});

// PUT /api/todos/:id - Update todo
router.put('/:id', authenticateToken, validateTodoUpdate, async (req, res, next) => {
  try {
    const todo = await Todo.update(req.params.id, req.user.id, req.body);
    if (!todo) {
      return res.status(404).json({ error: 'Todo not found' });
    }
    res.json({ data: todo });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/todos/:id - Delete todo
router.delete('/:id', authenticateToken, async (req, res, next) => {
  try {
    const deleted = await Todo.delete(req.params.id, req.user.id);
    if (!deleted) {
      return res.status(404).json({ error: 'Todo not found' });
    }
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

module.exports = router;
```

## Step 5: Quality Validation

**Command Used:**
```
/qa-check todo list REST API endpoint
```

**Generated QA Report:**
```markdown
# QA Validation Report: Todo List API

## Executive Summary
**Overall Assessment**: PASS ✅
- Implementation fully meets specification requirements
- All test cases pass with 95% code coverage
- Performance benchmarks achieved (avg 150ms response time)
- Security validation passed with no critical issues

## Test Results
- **Unit Tests**: 45/45 passed
- **Integration Tests**: 20/20 passed  
- **Performance Tests**: All endpoints < 200ms
- **Security Tests**: No vulnerabilities found

## Deployment Readiness: GO ✅

### Prerequisites Met:
- ✅ All functional requirements implemented
- ✅ Test coverage above 90%
- ✅ Performance targets achieved
- ✅ Security scan passed
- ✅ Documentation complete

### Recommended Monitoring:
- Response time metrics
- Error rate tracking
- Authentication success/failure rates
- Database performance metrics
```

## Results Summary

**Total Time Invested**: ~3 hours
**Deliverables Produced**:
- ✅ Complete technical specification (15 pages)
- ✅ Comprehensive test suite (65 test cases)
- ✅ System architecture design with database schema
- ✅ Production-ready Node.js API implementation
- ✅ Professional QA validation report
- ✅ Deployment readiness assessment

**Quality Metrics**:
- Requirements Coverage: 100%
- Test Coverage: 95%
- Performance: All targets met
- Security: No critical issues
- Documentation: Complete

## Key Learnings

### What Worked Well
1. **Specification-First Approach**: Clear requirements prevented scope creep and rework
2. **Multi-Agent Validation**: Cross-validation caught potential issues early
3. **Test-Driven Development**: Failing tests guided implementation correctly
4. **Quality Gates**: Each phase validation prevented downstream problems
5. **Documentation**: Comprehensive docs made handoff smooth

### Framework Benefits Demonstrated
- **Consistency**: Same high-quality process regardless of project complexity
- **Traceability**: Clear path from business requirements to working code
- **Quality**: Multiple validation checkpoints ensured professional output
- **Speed**: Framework guidance accelerated development without sacrificing quality
- **Maintainability**: Well-documented decisions and clear architecture

### Production Readiness
This example demonstrates how the framework produces deployment-ready code with:
- Professional documentation
- Comprehensive testing
- Security considerations
- Performance optimization
- Quality validation

The todo API could be deployed to production immediately with confidence in its quality and completeness.

---

*This example showcases the specification-first development framework's ability to transform a simple request into production-ready code with professional quality assurance.*