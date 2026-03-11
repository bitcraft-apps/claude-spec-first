#!/usr/bin/env bats

# Plugin Artifact Validation Tests
# Validates plugin.json, agent frontmatter, skill frontmatter, and hooks.json

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

@test "plugin.json is valid JSON with required fields" {
    run cat "$PROJECT_ROOT/.claude-plugin/plugin.json"
    [ "$status" -eq 0 ]

    # Parse with python (available on macOS/CI)
    echo "$output" | python3 -c "
import sys, json
data = json.load(sys.stdin)
assert 'name' in data, 'missing name'
assert 'version' in data, 'missing version'
assert 'agents' in data, 'missing agents'
assert 'skills' in data, 'missing skills'
assert 'hooks' in data, 'missing hooks'
"
}

@test "plugin.json agents match framework/agents directory" {
    local manifest_agents
    manifest_agents=$(python3 -c "
import json
data = json.load(open('$PROJECT_ROOT/.claude-plugin/plugin.json'))
print('\n'.join(sorted(data['agents'])))
")

    local dir_agents
    dir_agents=$(ls "$PROJECT_ROOT/framework/agents/"*.md | xargs -n1 basename | sed 's/\.md$//' | sort)

    [ "$manifest_agents" = "$dir_agents" ]
}

@test "plugin.json skills match framework/skills directory" {
    local manifest_skills
    manifest_skills=$(python3 -c "
import json
data = json.load(open('$PROJECT_ROOT/.claude-plugin/plugin.json'))
print('\n'.join(sorted(data['skills'])))
")

    local dir_skills
    dir_skills=$(ls -d "$PROJECT_ROOT/framework/skills/"*/ | xargs -n1 basename | sort)

    [ "$manifest_skills" = "$dir_skills" ]
}

@test "agent frontmatter is parseable YAML" {
    for agent in "$PROJECT_ROOT/framework/agents/"*.md; do
        # Extract YAML frontmatter between --- delimiters
        local frontmatter
        frontmatter=$(sed -n '/^---$/,/^---$/p' "$agent" | sed '1d;$d')

        # Must have name and tools fields
        echo "$frontmatter" | grep -q "^name:" || {
            echo "Missing 'name:' in $(basename "$agent")" >&2
            return 1
        }
        echo "$frontmatter" | grep -q "^tools:" || {
            echo "Missing 'tools:' in $(basename "$agent")" >&2
            return 1
        }
    done
}

@test "skill frontmatter is parseable YAML" {
    for skill_dir in "$PROJECT_ROOT/framework/skills/"*/; do
        local skill_file="$skill_dir/SKILL.md"
        [ -f "$skill_file" ] || {
            echo "Missing SKILL.md in $(basename "$skill_dir")" >&2
            return 1
        }

        local frontmatter
        frontmatter=$(sed -n '/^---$/,/^---$/p' "$skill_file" | sed '1d;$d')

        echo "$frontmatter" | grep -q "^description:" || {
            echo "Missing 'description:' in $(basename "$skill_dir")/SKILL.md" >&2
            return 1
        }
    done
}

@test "hooks.json is valid JSON with expected structure" {
    run cat "$PROJECT_ROOT/framework/hooks/hooks.json"
    [ "$status" -eq 0 ]

    echo "$output" | python3 -c "
import sys, json
data = json.load(sys.stdin)
assert 'hooks' in data, 'missing hooks key'
hooks = data['hooks']
assert 'Stop' in hooks or 'SubagentStop' in hooks, 'missing hook events'
"
}

@test "hooks reference existing shell scripts" {
    local hooks_dir="$PROJECT_ROOT/framework/hooks"
    for hook_script in "$hooks_dir"/*.sh; do
        [ -f "$hook_script" ] || continue
        [ -s "$hook_script" ] || {
            echo "Empty hook script: $(basename "$hook_script")" >&2
            return 1
        }
    done
}
