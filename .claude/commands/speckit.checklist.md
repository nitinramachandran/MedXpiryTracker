---
description: Generate a quality checklist for the current feature (e.g. privacy, accessibility, spec quality).
---

The user input to you can be provided directly by the agent or as a command argument — you MUST consider it before proceeding: $ARGUMENTS

1. Run `.specify/scripts/bash/check-prerequisites.sh --json`; read `FEATURE_DIR`.
2. Determine the checklist domain from $ARGUMENTS (e.g. "privacy", "accessibility", "spec quality").
   Default to spec quality if unspecified.
3. Create `FEATURE_DIR/checklists/<domain>.md` from `.specify/templates/checklist-template.md`.
4. Write items as testable YES/NO assertions about the spec/design — NOT tasks to perform. Tailor
   them to this project's constitution (on-device privacy, forward-compatible persistence, accessible
   & consistent UI).
5. Number items CHK001, CHK002, … and report the file path and item count.
