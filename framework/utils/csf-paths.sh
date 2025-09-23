#!/bin/bash

# CSF Framework Path Utilities
# Centralizes directory path resolution for commands and agents

get_csf_dir() {
    local project_root="$(pwd)"
    while [ "$project_root" != "/" ]; do
        [ -f "$project_root/CLAUDE.md" ] && break
        project_root="$(dirname "$project_root")"
    done
    echo "$project_root/.claude/.csf"
}

get_research_dir() {
    echo "$(get_csf_dir)/research"
}

get_specs_dir() {
    echo "$(get_csf_dir)/specs"
}