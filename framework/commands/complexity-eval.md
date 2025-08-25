---
description: Complexity evaluation and workflow recommendation - analyzes task requirements and recommends optimal development approach with configuration settings
---

# Complexity Evaluation & Workflow Recommendation

You are **analyzing task complexity and recommending optimal workflow** for: **$ARGUMENTS**

## Overview
This command analyzes a given task to determine its complexity, estimate implementation scope, and recommend the most efficient development workflow and configuration settings. Use this when you're unsure which approach to take or want to validate your complexity assessment.

## Analysis Framework

### Step 1: Task Analysis (1-2 minutes)
Analyze the task across multiple dimensions:

#### Functional Complexity
- **Simple**: Basic CRUD, UI tweaks, configuration changes, obvious fixes
- **Medium**: Business logic implementation, API integration, data processing  
- **Complex**: Multi-system integration, complex algorithms, new architecture

#### Technical Complexity  
- **Simple**: Uses existing patterns, single component, no new dependencies
- **Medium**: Some new patterns, multiple components, few new dependencies
- **Complex**: New architecture, many dependencies, multiple system changes

#### Integration Complexity
- **Simple**: No external integrations or well-established APIs
- **Medium**: 1-2 external service integrations with good documentation
- **Complex**: Multiple integrations, custom protocols, legacy system interfaces

#### Risk & Uncertainty
- **Low**: Well-understood domain, clear requirements, established patterns
- **Medium**: Some unknowns, partially understood requirements  
- **High**: Many unknowns, unclear requirements, experimental territory

### Step 2: LOC Estimation
Estimate lines of code based on similar implementations:
- **Tiny**: <50 LOC (configuration, simple fixes)
- **Small**: 50-200 LOC (simple features, straightforward implementations)
- **Medium**: 200-500 LOC (moderate features, some business logic)
- **Large**: 500-1000 LOC (complex features, multiple components)
- **Very Large**: >1000 LOC (major systems, comprehensive features)

### Step 3: Time Estimation
Consider development time including specification, testing, implementation:
- **Quick**: <30 minutes total
- **Short**: 30 minutes - 2 hours
- **Medium**: 2-8 hours  
- **Long**: 1-3 days
- **Extended**: >3 days

## Output Format

### Complexity Assessment Report

#### Task Analysis Summary
- **Task**: [One-line description of what needs to be built]
- **Domain**: [Technical domain - web UI, API, data processing, etc.]
- **Estimated LOC**: [Number estimate with range, e.g., "150-250 LOC"]
- **Time Estimate**: [Development time with range, e.g., "2-4 hours"]

#### Complexity Scoring
- **Functional Complexity**: [Simple/Medium/Complex] - [brief reason]
- **Technical Complexity**: [Simple/Medium/Complex] - [brief reason]  
- **Integration Complexity**: [Simple/Medium/Complex] - [brief reason]
- **Risk & Uncertainty**: [Low/Medium/High] - [brief reason]

#### **Overall Complexity**: [Simple/Medium/Complex]

#### Risk Factors
- [List 1-3 main risks or unknowns that could increase complexity]

#### Scope Boundaries
- **Definitely Included**: [2-3 core features that must be implemented]
- **Likely Excluded**: [2-3 features that would increase complexity significantly]

### Workflow Recommendation

#### **Recommended Command**: `/[command-name]`

#### **Recommended Configuration**:
```yaml
complexity_mode: [mvp/standard/enterprise]
max_loc: [recommended limit]
token_efficiency: [high/medium/low]
skip_phases: [list of phases to skip, if any]
```

#### **Rationale**: 
[2-3 sentences explaining why this workflow is optimal]

#### **Alternative Workflows**:
- **If simpler than expected**: Use `/[alternative]` 
- **If more complex than expected**: Use `/[alternative]`

### Implementation Strategy

#### **Suggested Approach**:
- [Key implementation strategy - incremental, all-at-once, etc.]

#### **Critical Success Factors**:
- [2-3 things that must go right for this to succeed]

#### **Early Warning Signs** (escalation triggers):
- [2-3 signs that complexity is higher than estimated]

## Workflow Decision Matrix

### Use `/implement-now` when:
- Overall complexity: Simple
- LOC estimate: <100
- Time estimate: <30 minutes
- Requirements crystal clear
- Solution obvious and well-understood

### Use `/spec-mvp` when:  
- Overall complexity: Simple to Medium
- LOC estimate: 50-500
- Time estimate: 30 minutes - 4 hours
- Requirements mostly clear with minor questions
- Solution approach is straightforward

### Use `/spec-workflow` when:
- Overall complexity: Medium to Complex
- LOC estimate: >500 or uncertain
- Time estimate: >4 hours or uncertain
- Requirements need significant clarification
- Multiple implementation approaches possible
- High risk or uncertainty factors

## Configuration Recommendations

### MVP Mode Settings:
```yaml
complexity_mode: mvp
max_loc: 200
token_efficiency: high
skip_phases: [architecture, qa_validation, documentation]
```
**When**: Simple, well-understood tasks with time pressure

### Standard Mode Settings:
```yaml
complexity_mode: standard  
max_loc: 500
token_efficiency: medium
skip_phases: [documentation]
```
**When**: Medium complexity with moderate risk and quality requirements

### Enterprise Mode Settings:
```yaml
complexity_mode: enterprise
max_loc: 1000
token_efficiency: low
skip_phases: []
```
**When**: Complex, high-risk, or production-critical implementations

## Quick Decision Tree

```
Is solution obvious and <100 LOC?
├─ Yes → /implement-now
└─ No → Is it well-understood and <500 LOC?
    ├─ Yes → /spec-mvp  
    └─ No → /spec-workflow
```

## Instructions

**Analyze "$ARGUMENTS" and provide:**
1. Detailed complexity assessment
2. Clear workflow recommendation with rationale
3. Specific configuration settings
4. Implementation strategy and risk factors

**Be conservative with complexity estimates** - it's better to start with a simpler workflow and escalate if needed than to over-engineer from the beginning.

**Focus on actionable recommendations** - the goal is to help choose the right development approach immediately.