#!/usr/bin/env bash
# Create a new feature: next-numbered specs/ directory, a branch, and a spec.md from template.
# Usage: create-new-feature.sh [--json] "<feature description>"
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

JSON=false
if [[ "${1:-}" == "--json" ]]; then JSON=true; shift; fi
DESCRIPTION="${*:-}"
if [[ -z "$DESCRIPTION" ]]; then
    echo "ERROR: No feature description provided." >&2
    exit 1
fi

REPO_ROOT="$(get_repo_root)"
SPECS_DIR="$REPO_ROOT/specs"
mkdir -p "$SPECS_DIR"

# Next zero-padded feature number.
MAX=0
for d in "$SPECS_DIR"/*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    num="${name%%-*}"
    if [[ "$num" =~ ^[0-9]+$ ]]; then
        n=$((10#$num))
        (( n > MAX )) && MAX=$n
    fi
done
NEXT=$(printf "%03d" $((MAX + 1)))

# Slug from the description: lowercase, non-alphanumerics → hyphens, max ~4 words.
SLUG=$(echo "$DESCRIPTION" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
    | cut -d- -f1-4)
[[ -z "$SLUG" ]] && SLUG="feature"
FEATURE_SLUG="${NEXT}-${SLUG}"
FEATURE_DIR="$SPECS_DIR/$FEATURE_SLUG"
mkdir -p "$FEATURE_DIR"

# Create the feature branch when inside a git repo.
if git -C "$REPO_ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
    git -C "$REPO_ROOT" checkout -b "$FEATURE_SLUG" >/dev/null 2>&1 || \
        git -C "$REPO_ROOT" checkout "$FEATURE_SLUG" >/dev/null 2>&1 || true
fi

SPEC_FILE="$FEATURE_DIR/spec.md"
TEMPLATE="$REPO_ROOT/.specify/templates/spec-template.md"
if [[ -f "$TEMPLATE" ]]; then
    cp "$TEMPLATE" "$SPEC_FILE"
else
    printf '# Feature Specification: %s\n' "$DESCRIPTION" > "$SPEC_FILE"
fi

if $JSON; then
    printf '{"FEATURE_SLUG":"%s","FEATURE_DIR":"%s","SPEC":"%s"}\n' \
        "$FEATURE_SLUG" "$FEATURE_DIR" "$SPEC_FILE"
else
    echo "FEATURE_SLUG=$FEATURE_SLUG"
    echo "FEATURE_DIR=$FEATURE_DIR"
    echo "SPEC=$SPEC_FILE"
fi
