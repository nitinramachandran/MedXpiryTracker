---
description: Execute the task list to build the feature, honoring the constitution.
---

The user input to you can be provided directly by the agent or as a command argument — you MUST consider it before proceeding: $ARGUMENTS

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks`; read `FEATURE_DIR` and
   `AVAILABLE_DOCS`.
2. Load `tasks.md` (required), plus `plan.md`, `data-model.md`, `contracts/`, and the constitution.
3. Execute tasks in order, respecting dependencies:
   - Run `[P]` tasks together only when they touch different files.
   - Honor test-first: write and run the failing test before its implementation.
   - Reuse the design system (PillEyePalette, DimensionalButtonStyle) and keep accessibility
     identifiers stable. Keep persistence backward-compatible.
   - Use `async`/`await` (no Combine); keep the main actor unblocked on launch.
4. After each phase, build with the `BuildProject` MCP tool and run the xctestplan. Fix failures
   before continuing.
5. Mark completed tasks `[x]` in `tasks.md` as you go.
6. Report what was implemented, the build/test result, and any deviations from the plan.
