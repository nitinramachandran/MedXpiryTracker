---
description: Generate an ordered, test-first task list from the design artifacts.
---

The user input to you can be provided directly by the agent or as a command argument — you MUST consider it before proceeding: $ARGUMENTS

1. Run `.specify/scripts/bash/check-prerequisites.sh --json` from the repo root; parse `FEATURE_DIR`
   and `AVAILABLE_DOCS`.
2. Read the available design docs: always `plan.md`; plus `data-model.md`, `contracts/`, `research.md`,
   and `quickstart.md` when present.
3. Generate `FEATURE_DIR/tasks.md` from `.specify/templates/tasks-template.md`:
   - Derive tasks from contracts, entities, and scenarios.
   - Enforce test-first ordering (Principle II): a failing-test task precedes its implementation task.
   - Each task names the exact file path. Mark `[P]` only when tasks touch different files with no
     ordering dependency.
   - Number tasks sequentially (T001, T002, …) and list Dependencies.
4. Report the task count and the parallelizable groups.
