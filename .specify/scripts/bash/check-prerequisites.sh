#!/usr/bin/env bash
# Report which SDD artifacts exist for the current feature, for /speckit.tasks,
# /speckit.analyze, and /speckit.implement to consume.
# Usage: check-prerequisites.sh [--json] [--require-tasks] [feature-slug]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

JSON=false; REQUIRE_TASKS=false
ARGS=()
for a in "$@"; do
    case "$a" in
        --json) JSON=true ;;
        --require-tasks) REQUIRE_TASKS=true ;;
        *) ARGS+=("$a") ;;
    esac
done

REPO_ROOT="$(get_repo_root)"
SLUG="${ARGS[0]:-$(get_current_branch)}"
FEATURE_DIR="$(get_feature_dir "$REPO_ROOT" "$SLUG")"

require_file "$FEATURE_DIR/plan.md" "plan.md (run /speckit.plan first)"
if $REQUIRE_TASKS; then
    require_file "$FEATURE_DIR/tasks.md" "tasks.md (run /speckit.tasks first)"
fi

exists() { [[ -e "$1" ]] && echo true || echo false; }

if $JSON; then
    printf '{"FEATURE_DIR":"%s","AVAILABLE_DOCS":{"spec":%s,"plan":%s,"tasks":%s,"research":%s,"data-model":%s,"quickstart":%s,"contracts":%s}}\n' \
        "$FEATURE_DIR" \
        "$(exists "$FEATURE_DIR/spec.md")" \
        "$(exists "$FEATURE_DIR/plan.md")" \
        "$(exists "$FEATURE_DIR/tasks.md")" \
        "$(exists "$FEATURE_DIR/research.md")" \
        "$(exists "$FEATURE_DIR/data-model.md")" \
        "$(exists "$FEATURE_DIR/quickstart.md")" \
        "$(exists "$FEATURE_DIR/contracts")"
else
    echo "FEATURE_DIR=$FEATURE_DIR"
    echo "spec.md=$(exists "$FEATURE_DIR/spec.md")"
    echo "plan.md=$(exists "$FEATURE_DIR/plan.md")"
    echo "tasks.md=$(exists "$FEATURE_DIR/tasks.md")"
    echo "research.md=$(exists "$FEATURE_DIR/research.md")"
    echo "data-model.md=$(exists "$FEATURE_DIR/data-model.md")"
    echo "quickstart.md=$(exists "$FEATURE_DIR/quickstart.md")"
    echo "contracts=$(exists "$FEATURE_DIR/contracts")"
fi
