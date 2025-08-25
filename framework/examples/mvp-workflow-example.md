# MVP Workflow Example: Simple User Search Feature

This example demonstrates the **streamlined MVP development approach** using the framework's efficiency improvements. We'll build a simple user search feature for an existing web application.

## Example Task
*"Add a search box to the user list page that filters users by name as you type"*

## Step 1: Complexity Evaluation (30 seconds)

**Quick Analysis:**
- **Estimated LOC**: ~150 lines (component + tests + styling)
- **Complexity**: Simple feature addition to existing system
- **Integration**: Uses existing user data and UI patterns
- **Risk**: Low - well-understood search functionality

**Decision**: Use `/spec-mvp` workflow (estimated <200 LOC, simple feature)

## Step 2: MVP Specification Process (3 minutes)

### Essential Requirements (MVP Mode Output)
- **What**: Live search input that filters user list as user types
- **Success**: Users can find specific users quickly, search works with partial names
- **Scope**: Include [search input, filtering logic, clear button] | Exclude [advanced filters, search history, keyboard shortcuts]

### Core Functionality
- Search input field in user list header
- Filter existing user list based on input value (case-insensitive)
- Show/hide users dynamically as user types
- Clear button to reset search
- Handle empty states gracefully

### Critical Tests
- **Happy path**: Typing "John" shows only users with "John" in name
- **Edge cases**: Empty search shows all users, no matches shows empty state

### Open Questions
- None - requirements are clear for MVP

## Step 3: Essential Test Design (2 minutes)

### Essential Tests (MVP Mode Output)
- **Test File**: `UserSearch.test.js`
- **Critical Tests**:
  - Renders search input field
  - Filters users when typing in search box
  - Shows all users when search is empty
  - Shows empty state when no matches found

### Test Code
```javascript
import { render, screen, fireEvent } from '@testing-library/react';
import UserSearch from './UserSearch';

const mockUsers = [
  { id: 1, name: 'John Doe' },
  { id: 2, name: 'Jane Smith' },
  { id: 3, name: 'Bob Johnson' }
];

test('filters users based on search input', () => {
  render(<UserSearch users={mockUsers} />);
  
  const searchInput = screen.getByPlaceholderText('Search users...');
  fireEvent.change(searchInput, { target: { value: 'John' } });
  
  expect(screen.getByText('John Doe')).toBeInTheDocument();
  expect(screen.getByText('Bob Johnson')).toBeInTheDocument();
  expect(screen.queryByText('Jane Smith')).not.toBeInTheDocument();
});

test('shows all users when search is empty', () => {
  render(<UserSearch users={mockUsers} />);
  
  expect(screen.getAllByTestId('user-item')).toHaveLength(3);
});

test('shows empty state for no matches', () => {
  render(<UserSearch users={mockUsers} />);
  
  const searchInput = screen.getByPlaceholderText('Search users...');
  fireEvent.change(searchInput, { target: { value: 'xyz' } });
  
  expect(screen.getByText('No users found')).toBeInTheDocument();
});
```

### Test Data
- Mock users array with varied names for filtering tests

## Step 4: Streamlined Implementation (8 minutes)

### Essential Code (MVP Mode Output)
- **Files**: `components/UserSearch.js`, `components/UserSearch.css`
- **Core Implementation**: Working search component with inline comments for complex filtering
- **Key Functions**: `handleSearchChange`, `filterUsers`

### Code Implementation

**File: `components/UserSearch.js`**
```javascript
import React, { useState, useMemo } from 'react';
import './UserSearch.css';

const UserSearch = ({ users = [] }) => {
  const [searchTerm, setSearchTerm] = useState('');

  // Filter users based on search term (case-insensitive)
  const filteredUsers = useMemo(() => {
    if (!searchTerm.trim()) return users;
    
    return users.filter(user => 
      user.name.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [users, searchTerm]);

  const handleSearchChange = (e) => {
    setSearchTerm(e.target.value);
  };

  const clearSearch = () => {
    setSearchTerm('');
  };

  return (
    <div className="user-search">
      <div className="search-input-container">
        <input
          type="text"
          placeholder="Search users..."
          value={searchTerm}
          onChange={handleSearchChange}
          className="search-input"
          data-testid="user-search-input"
        />
        {searchTerm && (
          <button onClick={clearSearch} className="clear-button">
            ✕
          </button>
        )}
      </div>
      
      <div className="user-list">
        {filteredUsers.length > 0 ? (
          filteredUsers.map(user => (
            <div key={user.id} className="user-item" data-testid="user-item">
              {user.name}
            </div>
          ))
        ) : (
          <div className="empty-state">No users found</div>
        )}
      </div>
    </div>
  );
};

export default UserSearch;
```

**File: `components/UserSearch.css`**
```css
.user-search {
  width: 100%;
}

.search-input-container {
  position: relative;
  margin-bottom: 1rem;
}

.search-input {
  width: 100%;
  padding: 0.5rem 2rem 0.5rem 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.clear-button {
  position: absolute;
  right: 0.5rem;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  cursor: pointer;
  color: #666;
}

.user-item {
  padding: 0.5rem;
  border-bottom: 1px solid #eee;
}

.empty-state {
  text-align: center;
  color: #666;
  padding: 2rem;
  font-style: italic;
}
```

### Critical Dependencies
- React hooks (useState, useMemo) - already available in project

### Basic Error Handling
- Handle undefined/null users array with default empty array
- Trim whitespace from search terms to avoid empty string matches

## Step 5: Quick Validation (1 minute)

### Testing
- Ran tests: All 3 tests pass ✅
- Manual verification: Search works as expected, clear button functions
- Integration: Fits existing user list page design

### Completion Summary
- **Total time**: ~15 minutes
- **LOC delivered**: ~120 lines (under estimated 150)
- **Features working**: Search, filter, clear, empty states
- **Tests passing**: 3/3 essential tests

## Key Efficiency Gains Demonstrated

### Compared to Full Workflow:
- **Skipped architecture phase** - Used existing React patterns
- **Essential tests only** - 3 tests vs 10+ comprehensive tests
- **No separate QA phase** - Basic validation integrated
- **Minimal documentation** - Inline comments only
- **Direct implementation** - No extensive planning phase

### Token Efficiency:
- **Concise specifications** - Bullet points vs comprehensive analysis
- **Essential tests** - Working code vs extensive test strategy documentation
- **Working implementation** - Code with minimal explanation

### Quality Maintained:
- Working, tested code that solves the problem
- Follows existing project patterns and conventions
- Essential error handling included
- Clean, readable implementation

## When to Escalate

This example would escalate to `/spec-workflow` if:
- Search requirements became complex (faceted search, saved searches, etc.)
- Implementation grew beyond 500 LOC
- Integration with multiple external search APIs needed
- Advanced performance optimization required

## Framework Configuration Used

```yaml
# Effective settings for this example
complexity_mode: mvp
max_loc: 200
token_efficiency: high
skip_phases: [architecture, qa_validation, documentation]
```

This example demonstrates how the framework's efficiency improvements enable rapid delivery of working, tested features while maintaining essential quality standards.