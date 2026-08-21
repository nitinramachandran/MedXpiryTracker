#!/usr/bin/env bash
# Refresh the agent context file (CLAUDE.md by default) from the agent-file template,
# preserving anything between the MANUAL ADDITIONS markers.
# Usage: update-agent-context.sh [claude|copilot|cursor|agents]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

REPO_ROOT="$(get_repo_root)"
AGENT="${1:-claude}"
case "$AGENT" in
    claude) TARGET="$REPO_ROOT/CLAUDE.md" ;;
    copilot) TARGET="$REPO_ROOT/.github/copilot-instructions.md" ;;
    cursor) TARGET="$REPO_ROOT/.cursorrules" ;;
    agents) TARGET="$REPO_ROOT/AGENTS.md" ;;
    *) echo "Unknown agent: $AGENT" >&2; exit 1 ;;
esac

TEMPLATE="$REPO_ROOT/.specify/templates/agent-file-template.md"
mkdir -p "$(dirname "$TARGET")"

# Preserve existing manual additions if the target already exists.
MANUAL=""
if [[ -f "$TARGET" ]]; then
    MANUAL="$(awk '/MANUAL ADDITIONS START/{f=1;next}/MANUAL ADDITIONS END/{f=0}f' "$TARGET" || true)"
fi

cp "$TEMPLATE" "$TARGET"
if [[ -n "$MANUAL" ]]; then
    tmp="$(mktemp)"
    awk -v add="$MANUAL" '
        /MANUAL ADDITIONS START/{print;print add;skip=1;next}
        /MANUAL ADDITIONS END/{skip=0}
        skip{next}
        {print}
    ' "$TARGET" > "$tmp" && mv "$tmp" "$TARGET"
fi

echo "Updated agent context: $TARGET"
