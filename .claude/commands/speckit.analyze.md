---
description: Cross-check spec, plan, and tasks for consistency, coverage, and constitution compliance.
---

The user input to you can be provided directly by the agent or as a command argument — you MUST consider it before proceeding: $ARGUMENTS

Read-only analysis. Do NOT modify artifacts; report findings for the user to act on.

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks`; read `FEATURE_DIR`.
2. Load `spec.md`, `plan.md`, `tasks.md`, and `.specify/memory/constitution.md`.
3. Check for:
   - **Coverage**: every functional requirement maps to at least one task; every task traces to a
     requirement or design element.
   - **Consistency**: no contradictions between spec, plan, and tasks (dates, entities, terminology).
   - **Constitution compliance**: no task or design choice violates a principle without a justified
     Complexity Tracking entry.
   - **Ambiguity**: any remaining `[NEEDS CLARIFICATION]` markers.
4. Output a findings table (Severity | Location | Issue | Suggested fix). Call out CRITICAL items that
   should block `/speckit.implement`.
