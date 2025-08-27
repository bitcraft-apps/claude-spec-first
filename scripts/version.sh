#!/bin/bash

# Claude Spec-First Framework - Version Utilities
# POSIX-compliant shell functions for semantic version management
# Supports version parsing, comparison, and increment operations

# Exit on any error in strict mode
set -e

# Global constants
VERSION_REGEX='^([0-9]+)\.([0-9]+)\.([0-9]+)(-[a-zA-Z0-9][a-zA-Z0-9\-]*(\.[a-zA-Z0-9][a-zA-Z0-9\-]*)*)?(\+[a-zA-Z0-9][a-zA-Z0-9\-]*(\.[a-zA-Z0-9][a-zA-Z0-9\-]*)*)?$'
SIMPLE_VERSION_REGEX='^[0-9]+\.[0-9]+\.[0-9]+$'

# Function to get framework directory based on execution context
# Returns the appropriate path prefix for framework files
get_framework_dir() {
    # Check if we're in repository mode (has ./framework/ directory with VERSION file)
    if [ -d "./framework" ] && [ -f "./framework/VERSION" ]; then
        echo "./framework"
    # Check if we're in installed mode (has VERSION file in current directory)
    elif [ -f "./VERSION" ]; then
        echo "."
    # Check if we're in .csf subdirectory (installed mode)
    elif [ -f "./.csf/VERSION" ]; then
        echo "./.csf"
    else
        echo "ERROR: Cannot determine framework directory" >&2
        return 1
    fi
}

# Function to get the current framework version
# Returns the version string from the VERSION file
get_framework_version() {
    local framework_dir
    framework_dir=$(get_framework_dir) || return 1
    
    local version_file="${framework_dir}/VERSION"
    
    if [ ! -f "$version_file" ]; then
        echo "ERROR: VERSION file not found at $version_file" >&2
        return 1
    fi
    
    local version
    version=$(cat "$version_file" 2>/dev/null) || {
        echo "ERROR: Failed to read VERSION file" >&2
        return 1
    }
    
    # Trim whitespace
    version=$(echo "$version" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -z "$version" ]; then
        echo "ERROR: VERSION file is empty" >&2
        return 1
    fi
    
    echo "$version"
}

# Function to validate semantic version format
# Returns 0 if valid, 1 if invalid
validate_version() {
    local version="$1"
    
    if [ -z "$version" ]; then
        echo "ERROR: Version cannot be empty" >&2
        return 1
    fi
    
    # Use simple regex for basic validation (POSIX compatible)
    if echo "$version" | grep -E "$SIMPLE_VERSION_REGEX" >/dev/null 2>&1; then
        return 0
    else
        echo "ERROR: Invalid version format: $version (expected: X.Y.Z)" >&2
        return 1
    fi
}

# Function to parse version components
# Usage: parse_version "1.2.3" -> sets MAJOR, MINOR, PATCH variables
parse_version() {
    local version="$1"
    
    validate_version "$version" || return 1
    
    # Extract components using parameter expansion (POSIX compatible)
    MAJOR="${version%%.*}"
    local remaining="${version#*.}"
    MINOR="${remaining%%.*}"
    PATCH="${remaining#*.}"
    
    # Validate all components are numeric
    if ! echo "$MAJOR" | grep -E '^[0-9]+$' >/dev/null || \
       ! echo "$MINOR" | grep -E '^[0-9]+$' >/dev/null || \
       ! echo "$PATCH" | grep -E '^[0-9]+$' >/dev/null; then
        echo "ERROR: Version components must be numeric: $version" >&2
        return 1
    fi
    
    return 0
}

# Function to compare two versions
# Returns: 0 if equal, 1 if version1 > version2, 2 if version1 < version2
compare_versions() {
    local version1="$1"
    local version2="$2"
    
    validate_version "$version1" || return 1
    validate_version "$version2" || return 1
    
    # Parse first version
    local major1 minor1 patch1
    parse_version "$version1" || return 1
    major1="$MAJOR"
    minor1="$MINOR"
    patch1="$PATCH"
    
    # Parse second version
    local major2 minor2 patch2
    parse_version "$version2" || return 1
    major2="$MAJOR"
    minor2="$MINOR"
    patch2="$PATCH"
    
    # Compare major version
    if [ "$major1" -gt "$major2" ]; then
        return 1
    elif [ "$major1" -lt "$major2" ]; then
        return 2
    fi
    
    # Compare minor version
    if [ "$minor1" -gt "$minor2" ]; then
        return 1
    elif [ "$minor1" -lt "$minor2" ]; then
        return 2
    fi
    
    # Compare patch version
    if [ "$patch1" -gt "$patch2" ]; then
        return 1
    elif [ "$patch1" -lt "$patch2" ]; then
        return 2
    fi
    
    # Versions are equal
    return 0
}

# Function to increment version
# Usage: increment_version "1.2.3" "major|minor|patch"
increment_version() {
    local version="$1"
    local increment_type="$2"
    
    validate_version "$version" || return 1
    
    if [ -z "$increment_type" ]; then
        echo "ERROR: Increment type required (major|minor|patch)" >&2
        return 1
    fi
    
    # Parse version components
    parse_version "$version" || return 1
    local major="$MAJOR"
    local minor="$MINOR"
    local patch="$PATCH"
    
    case "$increment_type" in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            echo "ERROR: Invalid increment type: $increment_type (must be major, minor, or patch)" >&2
            return 1
            ;;
    esac
    
    echo "${major}.${minor}.${patch}"
}

# Function to set framework version
# Updates the VERSION file with a new version
set_framework_version() {
    local new_version="$1"
    
    validate_version "$new_version" || return 1
    
    local framework_dir
    framework_dir=$(get_framework_dir) || return 1
    
    local version_file="${framework_dir}/VERSION"
    
    # Create backup of current version file if it exists
    if [ -f "$version_file" ]; then
        local backup_file="${version_file}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$version_file" "$backup_file" || {
            echo "ERROR: Failed to create backup of VERSION file" >&2
            return 1
        }
    fi
    
    # Write new version
    echo "$new_version" > "$version_file" || {
        echo "ERROR: Failed to write new version to $version_file" >&2
        return 1
    }
    
    echo "SUCCESS: Framework version updated to $new_version"
}

# Function to get version information in a readable format
get_version_info() {
    local current_version
    current_version=$(get_framework_version) || return 1
    
    local framework_dir
    framework_dir=$(get_framework_dir) || return 1
    
    echo "Claude Spec-First Framework"
    echo "Version: $current_version"
    echo "Location: $framework_dir"
    echo "VERSION file: ${framework_dir}/VERSION"
}

# Function to validate version file integrity
validate_version_file() {
    local framework_dir
    framework_dir=$(get_framework_dir) || return 1
    
    local version_file="${framework_dir}/VERSION"
    
    # Check if file exists
    if [ ! -f "$version_file" ]; then
        echo "ERROR: VERSION file missing at $version_file" >&2
        return 1
    fi
    
    # Check if file is readable
    if [ ! -r "$version_file" ]; then
        echo "ERROR: VERSION file not readable at $version_file" >&2
        return 1
    fi
    
    # Check if version is valid
    local current_version
    current_version=$(get_framework_version) || return 1
    
    validate_version "$current_version" || return 1
    
    echo "SUCCESS: VERSION file is valid ($current_version)"
    return 0
}

# Command-line interface for standalone usage
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-}" in
        "get")
            get_framework_version
            ;;
        "set")
            if [ -z "${2:-}" ]; then
                echo "ERROR: Version required" >&2
                echo "Usage: $0 set <version>" >&2
                exit 1
            fi
            set_framework_version "$2"
            ;;
        "increment")
            if [ -z "${2:-}" ]; then
                echo "ERROR: Increment type required" >&2
                echo "Usage: $0 increment <major|minor|patch>" >&2
                exit 1
            fi
            current_version=$(get_framework_version) || exit 1
            new_version=$(increment_version "$current_version" "$2") || exit 1
            echo "Current: $current_version"
            echo "New: $new_version"
            set_framework_version "$new_version"
            ;;
        "compare")
            if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
                echo "ERROR: Two versions required for comparison" >&2
                echo "Usage: $0 compare <version1> <version2>" >&2
                exit 1
            fi
            set +e  # Temporarily disable strict error handling
            compare_versions "$2" "$3"
            result=$?
            set -e  # Re-enable strict error handling
            case $result in
                0) echo "$2 == $3" ;;
                1) echo "$2 > $3" ;;
                2) echo "$2 < $3" ;;
            esac
            ;;
        "validate")
            if [ -z "${2:-}" ]; then
                validate_version_file
            else
                validate_version "$2"
            fi
            ;;
        "info")
            get_version_info
            ;;
        "help"|"--help"|"-h"|"")
            echo "Claude Spec-First Framework - Version Utilities"
            echo ""
            echo "Usage: $0 <command> [arguments]"
            echo ""
            echo "Commands:"
            echo "  get                     Get current framework version"
            echo "  set <version>          Set framework version"
            echo "  increment <type>       Increment version (major|minor|patch)"
            echo "  compare <v1> <v2>      Compare two versions"
            echo "  validate [version]     Validate version format or VERSION file"
            echo "  info                   Show version information"
            echo "  help                   Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 get"
            echo "  $0 set 1.2.3"
            echo "  $0 increment patch"
            echo "  $0 compare 1.2.3 1.2.4"
            echo "  $0 validate 1.2.3"
            ;;
        *)
            echo "ERROR: Unknown command: $1" >&2
            echo "Use '$0 help' for usage information" >&2
            exit 1
            ;;
    esac
fi