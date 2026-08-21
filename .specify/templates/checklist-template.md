# [DOMAIN] Checklist: [FEATURE NAME]

**Purpose**: [What this checklist verifies — e.g. spec quality, privacy, accessibility.]
**Created**: [DATE]
**Feature**: `specs/[###-feature-slug]/spec.md`

> A checklist item is a testable assertion about the spec or design, not a task to do.
> Each item should be answerable YES/NO from the artifacts alone.

## [Category, e.g. Privacy & Data]
- [ ] CHK001 Does the spec confirm all data stays on-device with no network calls?
- [ ] CHK002 Is file protection / sandbox storage stated for any new persisted data?
- [ ] CHK003 Do notification payloads carry identifiers only (no medicine names/dates)?

## [Category, e.g. Requirement Quality]
- [ ] CHK004 Is every functional requirement testable and unambiguous?
- [ ] CHK005 Are permission-denied paths specified (camera, notifications)?
- [ ] CHK006 Are `Codable` backward-compatibility expectations stated?

## [Category, e.g. Accessibility & Design]
- [ ] CHK007 Are stable accessibility identifiers specified for new interactive elements?
- [ ] CHK008 Does the design reuse PillEyePalette / DimensionalButtonStyle?

## Notes
[Findings, gaps, or `[NEEDS CLARIFICATION]` raised while completing this checklist.]
