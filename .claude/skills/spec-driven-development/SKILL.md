---
name: spec-driven-development
description: >-
  Use for ALL non-trivial feature work, changes, or bug fixes on the MedXpiryTracker
  (PillEye) iOS app — anything beyond a one-line tweak. Routes the work through this
  project's GitHub Spec Kit Spec-Driven Development pipeline (constitution → specify →
  clarify → plan → tasks → analyze → implement) instead of coding ad hoc. Trigger when
  the user asks to add/build/change a feature, redesign UI, or fix a defect.
---

# Spec-Driven Development (GitHub Spec Kit)

This project is developed with GitHub Spec Kit. Do not "vibe-code" features directly —
route every non-trivial change through the phases below. This skill is a thin router: the
authoritative content lives in the shared assets it points to (the SpecKit convention of
keeping prompts thin and deferring to templates, scripts, and the constitution).

## How the prompts are arranged (SpecKit standard)
```
.specify/memory/constitution.md     # Governing principles — every phase reads this first
.specify/templates/                 # spec / plan / tasks / checklist / agent-file blueprints
.specify/scripts/bash/              # create-new-feature, setup-plan, check-prerequisites, ...
.claude/commands/speckit.*.md       # One thin prompt per phase (the entry points below)
specs/<NNN>-<slug>/                  # Per-feature artifacts: spec.md, plan.md, tasks.md, ...
CLAUDE.md                           # Session context, refreshed by /speckit.plan
```
Each phase command is intentionally small and references the templates/scripts above. When
you extend the workflow, keep detail in the shared templates — not copied into prompts.

## The pipeline
Run phases in order. Each is a slash command under `.claude/commands/`; invoke the matching
`/speckit.<phase>` or follow that file's instructions directly.

1. **/speckit.constitution** — establish or amend `.specify/memory/constitution.md`. Rare;
   usually already done. Everything else is gated by it.
2. **/speckit.specify** `"<what & why>"` — create `specs/<NNN>-<slug>/spec.md` on a new
   feature branch. Focus on WHAT/WHY, never HOW. Mark unknowns `[NEEDS CLARIFICATION]`.
3. **/speckit.clarify** — resolve those ambiguities before planning.
4. **/speckit.plan** — technical plan + design docs (research/data-model/contracts/quickstart);
   MUST pass the Constitution Check gate. Refreshes `CLAUDE.md`.
5. **/speckit.tasks** — derive an ordered, test-first `tasks.md`.
6. **/speckit.analyze** — read-only consistency/coverage/constitution check across spec⇄plan⇄tasks.
7. **/speckit.implement** — execute tasks, build with the `BuildProject` MCP tool, run the
   xctestplan, and mark tasks `[x]` as they land.
8. **/speckit.checklist** — optional quality checklist (privacy, accessibility, spec quality).

## Non-negotiables (summary — read the full constitution before acting)
See `.specify/memory/constitution.md` for the binding text. In brief:
- **On-device privacy**: no network/analytics; sandbox storage + file protection; notifications
  carry only a medicine `UUID`.
- **Testable core, injected boundaries**: pure logic (parsers, validators, date math) is unit
  tested; system boundaries sit behind protocols (`NotificationScheduling`); write tests first.
- **Native SwiftUI + async/await only** (no Combine); `@MainActor @Observable` stores; never
  block the main actor on launch.
- **Forward-compatible persistence**: `decodeIfPresent` defaults; don't remove persisted fields.
- **Consistent, accessible design**: reuse `PillEyePalette` / `DimensionalButtonStyle`; light mode
  + portrait; stable `accessibilityIdentifier`s.
- **Simplicity**: no new dependency without a justified Complexity Tracking entry; YAGNI.

## Lightweight path
For a genuinely tiny change (typo, constant tweak) you may skip straight to implementation, but
still honor the constitution and, if it touches testable-core behavior, add or update a test.

## Worked example
`specs/001-medicine-expiry-tracker/` (the shipped app, retro-specified) and
`specs/002-compact-dates-saved-popup/` (single-row date entry + filtered saved-medicines popup)
show the full set of artifacts a feature should produce.
