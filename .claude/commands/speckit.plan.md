---
description: Produce the technical implementation plan and design artifacts for the feature.
---

The user input to you can be provided directly by the agent or as a command argument — you MUST consider it before proceeding: $ARGUMENTS

1. Run `.specify/scripts/bash/setup-plan.sh --json` from the repo root; parse `FEATURE_DIR`, `PLAN`,
   and `SPEC` (absolute paths).
2. Read `SPEC` and `.specify/memory/constitution.md` in full.
3. Fill `PLAN` from the plan template:
   - Complete Technical Context (Swift/Xcode versions, frameworks, storage, testing, platform).
   - Complete the **Constitution Check** table. If any principle is not met, either revise the
     approach or record a justified exception in **Complexity Tracking**. An unjustified violation
     is a STOP — do not proceed.
4. Execute Phase 0 → write `research.md` (Decision / Rationale / Alternatives). Verify any new or
   unfamiliar Apple API against current documentation; do not assume APIs.
5. Execute Phase 1 → write `data-model.md` (with Codable compatibility notes), `contracts/` (Swift
   protocol/signature sketches), and `quickstart.md` (manual validation steps).
6. Run `.specify/scripts/bash/update-agent-context.sh claude` to refresh agent context.
7. Re-run the Constitution Check against the concrete design and update Progress Tracking.
8. Report generated artifacts and the Constitution Check result. STOP before writing tasks — that is
   `/speckit.tasks`.
