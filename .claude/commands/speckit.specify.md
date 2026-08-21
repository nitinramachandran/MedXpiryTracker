---
description: Create a feature specification from a natural-language description.
---

The user input to you can be provided directly by the agent or as a command argument — you MUST consider it before proceeding: $ARGUMENTS

Given the feature description in $ARGUMENTS, do this:

1. Run `.specify/scripts/bash/create-new-feature.sh --json "$ARGUMENTS"` from the repo root.
   Parse the JSON for `FEATURE_SLUG`, `FEATURE_DIR`, and `SPEC`. All paths must be absolute.
2. Load `.specify/templates/spec-template.md` to understand the required sections.
3. Write the specification to `SPEC` using the template structure, replacing placeholders with
   concrete detail derived from the description. Focus on WHAT and WHY, never HOW.
4. Mark every genuine ambiguity with `[NEEDS CLARIFICATION: specific question]` rather than guessing.
5. Honor the constitution: privacy (on-device, no network), accessibility, and consistent design
   are requirements, not options.
6. Report the branch name and spec path, and list any `[NEEDS CLARIFICATION]` items for the user.
