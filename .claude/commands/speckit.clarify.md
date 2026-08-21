---
description: Surface and resolve ambiguities in the current feature spec before planning.
---

The user input to you can be provided directly by the agent or as a command argument — you MUST consider it before proceeding: $ARGUMENTS

Goal: reduce under-specification in the active feature's `spec.md` before `/speckit.plan`.

1. Run `.specify/scripts/bash/check-prerequisites.sh --json` and read `FEATURE_DIR`; open its `spec.md`.
2. Scan for ambiguity across: user roles, data & entities, validation rules, error/permission-denied
   paths, privacy handling, accessibility, and measurable success criteria.
3. Ask the user up to 5 targeted questions, ONE at a time, highest-impact first. Prefer concrete
   options. Stop early once the spec is sufficient to plan.
4. After each answer, integrate it into the spec immediately: update the relevant section and remove
   the corresponding `[NEEDS CLARIFICATION]` marker. Record Q&A under a `## Clarifications` section
   with a dated session subheading.
5. Report which sections changed and whether any ambiguities remain.
