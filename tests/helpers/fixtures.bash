#!/usr/bin/env bash

# Shared Fixture Setup for Unit Tests
# Creates minimal valid plugin structures in temp directories

load 'common'

# Create a minimal valid plugin fixture directory
# Sets FIXTURE_DIR to the created path
create_plugin_fixture() {
    FIXTURE_DIR="$(mktemp -d)"
    export FIXTURE_DIR

    # Minimal valid structure
    echo "1.0.0" > "$FIXTURE_DIR/VERSION"
    mkdir -p "$FIXTURE_DIR/agents"
    mkdir -p "$FIXTURE_DIR/skills/test-skill"

    # Minimal valid agent
    cat > "$FIXTURE_DIR/agents/test-agent.md" <<'AGENT'
---
name: test-agent
description: A test agent
tools: Read, Write
---

# Test Agent

Does test things.
AGENT

    # Minimal valid skill
    cat > "$FIXTURE_DIR/skills/test-skill/SKILL.md" <<'SKILL'
---
name: test-skill
description: A test skill
---

# Test Skill

Uses test-agent to do things.
SKILL

    # AGENTS.md, CLAUDE.md, README.md
    cat > "$FIXTURE_DIR/AGENTS.md" <<'EOF'
# AGENTS.md

Spec First — minimalist development workflow.

## Core Philosophy

## Principles
EOF

    echo "@AGENTS.md" > "$FIXTURE_DIR/CLAUDE.md"
    printf "# README\n\n## Quick Start\n\n## Command Reference\n" > "$FIXTURE_DIR/README.md"
}

# Clean up fixture directory
destroy_plugin_fixture() {
    if [ -n "$FIXTURE_DIR" ] && [ -d "$FIXTURE_DIR" ]; then
        rm -rf "$FIXTURE_DIR"
        unset FIXTURE_DIR
    fi
}
