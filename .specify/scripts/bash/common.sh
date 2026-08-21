#!/usr/bin/env bash
# Shared helpers for Spec-Driven Development scripts.
set -euo pipefail

# Absolute path to the repository root (works even when the path contains spaces).
get_repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        # Fallback: two levels up from this script's directory (.specify/scripts/bash).
        cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd
    fi
}

# Current git branch, or empty string if not in a git repo.
get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""
}

# Given a branch/slug like "003-scan-history", echo the matching specs directory.
get_feature_dir() {
    local repo_root="$1" slug="$2"
    echo "$repo_root/specs/$slug"
}

# Print KEY=VALUE pairs describing paths for the given feature slug.
get_feature_paths() {
    local repo_root; repo_root="$(get_repo_root)"
    local branch; branch="$(get_current_branch)"
    local slug="${1:-$branch}"
    local feature_dir; feature_dir="$(get_feature_dir "$repo_root" "$slug")"
    cat <<EOF
REPO_ROOT=$repo_root
BRANCH=$branch
FEATURE_SLUG=$slug
FEATURE_DIR=$feature_dir
SPEC=$feature_dir/spec.md
PLAN=$feature_dir/plan.md
TASKS=$feature_dir/tasks.md
RESEARCH=$feature_dir/research.md
DATA_MODEL=$feature_dir/data-model.md
QUICKSTART=$feature_dir/quickstart.md
CONTRACTS_DIR=$feature_dir/contracts
EOF
}

require_file() {
    local path="$1" label="$2"
    if [[ ! -f "$path" ]]; then
        echo "ERROR: missing required $label at: $path" >&2
        return 1
    fi
}
