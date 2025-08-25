# Implement-Now Example: Fix Button Alignment

This example demonstrates the **ultra-streamlined `/implement-now` workflow** for obvious, simple tasks that require no ceremony.

## Example Task
*"The 'Submit' button on the contact form is misaligned - it should be right-aligned instead of left-aligned"*

## Step 1: Immediate Assessment (15 seconds)

**Quick Check - Can I implement this right now?**
- [x] Requirements are crystal clear (right-align the submit button)
- [x] Solution approach is obvious (CSS text-align or flexbox)
- [x] Implementation is <100 LOC (probably 1-2 lines)
- [x] No new external dependencies needed
- [x] Follows existing project patterns (CSS styling)
- [x] No complex business logic involved

**Decision**: Perfect for `/implement-now` - proceed immediately

## Step 2: Direct Implementation (2 minutes)

### Files Changed:
- `styles/contact-form.css` - Updated button container alignment

### Code Changes:
```diff
 .contact-form .button-container {
-  text-align: left;
+  text-align: right;
   margin-top: 1rem;
 }
```

### Testing:
- Manual verification: Button now appears right-aligned on contact form page ✅

**Done.**

## Step 3: Result (Total: 3 minutes)

### What Was Delivered:
- Submit button is now right-aligned as requested
- Consistent with existing form styling patterns
- No functionality broken, just visual alignment improved

### Why This Was Perfect for `/implement-now`:
- **Obvious solution** - Simple CSS change
- **Clear requirements** - No ambiguity about what "right-aligned" means
- **Minimal scope** - Single property change in existing CSS
- **No dependencies** - Uses existing styling approach
- **Immediate verification** - Can see the change instantly

## Alternative Scenarios

### If This Had Been More Complex:

**Scenario**: *"Make the contact form responsive and improve the button layout"*
- **Assessment**: Requirements unclear (how responsive? what improvements?)
- **LOC estimate**: Unknown, could be 50-200 lines
- **Solution**: Not obvious - multiple approaches possible
- **Action**: Escalate to `/complexity-eval` then likely `/spec-mvp`

### If Requirements Were Unclear:

**Scenario**: *"Fix the submit button styling issues"*
- **Problem**: What specific issues? Alignment? Color? Size? Hover states?
- **Action**: Ask clarifying questions first, then decide on workflow

## Framework Efficiency Benefits

### Time Saved:
- **No specification phase** (0 minutes vs 5-10 minutes)
- **No testing design** (0 minutes vs 5 minutes) 
- **No architecture consideration** (0 minutes vs 2-5 minutes)
- **Total time**: 3 minutes vs 15-30 minutes for MVP workflow

### Token Efficiency:
- **Minimal output** - Just show the change, no verbose explanation
- **No process overhead** - Skip all ceremony and documentation
- **Direct result** - Working solution immediately

### Quality Maintained:
- Simple change following existing patterns
- Manual verification performed
- No regressions introduced
- Clear commit message for future reference

## When NOT to Use `/implement-now`

### Red Flags That Should Escalate:

1. **"Fix the performance issues with the contact form"**
   - Too vague, needs analysis, likely complex

2. **"Add validation to all form fields"**  
   - Multiple components, business logic, testing needed

3. **"Make the button look more modern"**
   - Subjective requirements, design decisions needed

4. **"Integrate the form with our CRM system"**
   - External dependencies, API integration, complex scope

5. **"The button doesn't work on mobile"**
   - Debugging needed, responsive design, unknown complexity

### Decision Tree:
```
Can I fix this in 1-2 lines of code with an obvious solution?
├─ Yes → /implement-now
└─ No → Is the scope and solution clear?
    ├─ Yes → /spec-mvp
    └─ No → /complexity-eval → appropriate workflow
```

## Configuration Context

This task used the framework's most efficient mode:
```yaml
# Effective approach
workflow: implement-now
ceremony: none
documentation: commit message only
testing: manual verification
time_target: under 10 minutes
```

## Commit Message Example

```
fix: right-align submit button in contact form

- Updated .contact-form .button-container to text-align: right
- Addresses visual alignment issue reported by user
```

This example shows how the framework can handle the simplest category of development tasks with maximum efficiency while still maintaining basic quality practices.