#!/usr/bin/env bash
# Seed plan.md for the current feature from the plan template.
# Usage: setup-plan.sh [--json] [feature-slug]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

JSON=false
if [[ "${1:-}" == "--json" ]]; then JSON=true; shift; fi

REPO_ROOT="$(get_repo_root)"
SLUG="${1:-$(get_current_branch)}"
FEATURE_DIR="$(get_feature_dir "$REPO_ROOT" "$SLUG")"
require_file "$FEATURE_DIR/spec.md" "spec.md (run /speckit.specify first)"

PLAN_FILE="$FEATURE_DIR/plan.md"
TEMPLATE="$REPO_ROOT/.specify/templates/plan-template.md"
[[ -f "$TEMPLATE" ]] && cp "$TEMPLATE" "$PLAN_FILE"

if $JSON; then
    printf '{"FEATURE_DIR":"%s","PLAN":"%s","SPEC":"%s"}\n' \
        "$FEATURE_DIR" "$PLAN_FILE" "$FEATURE_DIR/spec.md"
else
    echo "FEATURE_DIR=$FEATURE_DIR"
    echo "PLAN=$PLAN_FILE"
    echo "SPEC=$FEATURE_DIR/spec.md"
fi
