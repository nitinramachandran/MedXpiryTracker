---
description: Create or amend the project constitution (non-negotiable principles).
---

The user input to you can be provided directly by the agent or as a command argument — you MUST consider it before proceeding: $ARGUMENTS

You are updating the project constitution at `.specify/memory/constitution.md`.

1. Read the current constitution. Identify placeholders or the principles to amend based on $ARGUMENTS.
2. Draft the updated constitution:
   - Keep principles declarative, testable, and justified (each has a Rationale).
   - Fill every bracketed placeholder; do not leave TODOs unless the user must supply a value.
3. Determine the new semantic version:
   - MAJOR: a principle removed or redefined incompatibly.
   - MINOR: a principle/section added or materially expanded.
   - PATCH: clarifications only.
4. Update the dependent templates so they stay consistent:
   - `.specify/templates/plan-template.md` (Constitution Check gate)
   - `.specify/templates/spec-template.md`
   - `.specify/templates/tasks-template.md`
5. Prepend/refresh the HTML `SYNC IMPACT REPORT` comment at the top of the constitution
   (version change, principles touched, templates updated, follow-up TODOs).
6. Write ONLY `.specify/memory/constitution.md` (plus any template edits from step 4). Do not
   create template source files.
7. Report the version bump and any manual follow-ups.
