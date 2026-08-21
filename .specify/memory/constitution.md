<!--
SYNC IMPACT REPORT
==================
Version change: (none) → 1.0.0
Rationale: Initial ratification of the project constitution, retro-fitting
Spec-Driven Development onto the existing MedXpiryTracker (PillEye) codebase.

Principles defined:
  I.   On-Device Privacy First
  II.  Testable Core, Injected Boundaries
  III. Native SwiftUI + Structured Concurrency
  IV.  Forward-Compatible Persistence
  V.   Accessible, Consistent Design System
  VI.  Simplicity & Scope Discipline

Added sections: Platform & Technical Constraints; Development Workflow; Governance
Removed sections: none
Templates requiring updates:
  ✅ .specify/templates/plan-template.md (Constitution Check gate references these principles)
  ✅ .specify/templates/spec-template.md (no change required)
  ✅ .specify/templates/tasks-template.md (test-first ordering reflects Principle II)
Follow-up TODOs: none
-->

# MedXpiryTracker Constitution

MedXpiryTracker (internal target name "Medicine Date Alerter", brand "PillEye") is a
privacy-first iPhone app that scans medicine labels, stores manufacturing/expiry dates,
and schedules local reminders before medicines expire. This constitution defines the
non-negotiable principles every specification, plan, and implementation must uphold.

## Core Principles

### I. On-Device Privacy First
All medicine data stays on the user's device. The app MUST NOT send medicine names,
dates, images, or any user data over the network, and MUST NOT add analytics, tracking,
or third-party SDKs that transmit data.

- Persistent storage MUST live inside the app sandbox (Application Support) and MUST use
  `.completeFileProtection` so data is encrypted while the device is locked.
- Notifications MUST carry only opaque identifiers (a medicine `UUID`), never medicine
  names or dates in payloads that could surface on a locked screen from an unprotected file.
- Backups are plain user-controlled files (export/import via Files/AirDrop). The app MUST
  NOT upload backups anywhere on the user's behalf.

*Rationale: Health-adjacent data is sensitive. The app's entire value proposition depends
on users trusting that their medicine list never leaves the phone.*

### II. Testable Core, Injected Boundaries
Business logic MUST be expressed as pure, deterministic functions or types that can be
unit-tested without a device, network, or user permission prompt.

- Parsing, validation, date math, and reminder-lead logic MUST NOT depend on live system
  state. Inject `Calendar`/`Date` where behavior varies by locale or time.
- System boundaries (notifications, disk) MUST sit behind protocols (e.g.
  `NotificationScheduling`) so tests and previews inject fakes. `MedicineStore` MUST accept
  an injected scheduler and an optional storage URL (nil = memory-only).
- New behavior in the testable core is added test-first: write the failing test using the
  Swift `Testing` framework, then implement. UI flows are covered with `XCUIAutomation`.

*Rationale: The app's correctness lives in OCR date parsing and reminder scheduling. These
must be verifiable in milliseconds, not by manually pointing a camera at a pill box.*

### III. Native SwiftUI + Structured Concurrency
The UI is SwiftUI and state flows through native mechanisms. Asynchronous work uses Swift
`async`/`await`.

- Combine MUST NOT be used. Prefer `async`/`await`, `Task`, and `for await` over
  publishers and sinks.
- Observable state uses the `Observation` framework (`@Observable`) and SwiftUI property
  wrappers (`@State`, bindings). Store types are `@MainActor`.
- The main actor MUST NOT be blocked on launch: disk loads run off-main (e.g.
  `Task.detached`) with only the result assigned back on the main actor.
- New Apple APIs are verified against current documentation before use rather than assumed.

*Rationale: A single, modern concurrency and UI model keeps the codebase small, consistent,
and free of the state-synchronization bugs that mixed paradigms invite.*

### IV. Forward-Compatible Persistence
Saved data and exported backups MUST remain readable across app versions.

- `Codable` decoding MUST tolerate missing newer fields via `decodeIfPresent` with sensible
  defaults, and MUST ignore removed/legacy fields rather than failing.
- Adding a field is a backward-compatible change; removing or renaming a persisted field
  requires an explicit migration and is a breaking change.
- JSON encoding is stable and human-inspectable (ISO-8601 dates, sorted keys).

*Rationale: Users keep old backups and skip app updates. A decode failure means silent data
loss of an entire medicine list, which is unacceptable.*

### V. Accessible, Consistent Design System
The interface is intentionally light, friendly, and consistent.

- Colors and reusable styles route through the shared design system (`PillEyePalette`,
  `DimensionalButtonStyle`); features MUST NOT hardcode ad-hoc colors.
- The app is locked to light mode and portrait orientation on iPhone by design; features
  MUST NOT introduce dark-mode-only or landscape-only affordances.
- Interactive and status elements that a test or assistive technology must find MUST expose
  a stable `accessibilityIdentifier`.

*Rationale: A tiny, focused app earns trust through visual consistency and predictable,
testable UI, not through per-screen styling.*

### VI. Simplicity & Scope Discipline
Prefer the smallest solution that satisfies the specification.

- No new third-party dependency, framework, or persistence engine is added without a
  documented justification in the feature's plan (Complexity Tracking).
- Structures may be modeled slightly ahead of the UI (e.g. `MedicineUpdate` carrying fields
  not yet editable) ONLY when it removes a foreseeable future rewrite, not speculatively.
- YAGNI applies: features not in the current spec are not built.

*Rationale: The product is deliberately narrow. Every added concept is a maintenance and
review cost that must pay for itself.*

## Platform & Technical Constraints

- **Platform**: iPhone only, portrait, light mode. Built with Xcode, SwiftUI, Swift
  concurrency, VisionKit/`DataScanner` for on-device OCR, and `UserNotifications` for local
  reminders.
- **No backend**: there is no server, account, or sign-in. The app is fully functional
  offline.
- **Permissions**: camera (scanning) and notifications (reminders) are requested lazily,
  only when the feature is first used. The app MUST degrade gracefully if either is denied
  (manual date entry remains available; reminders simply don't fire).
- **Testing**: unit tests use the `Testing` framework; UI tests use `XCUIAutomation`. The
  test plan (`Medicine Date Alerter.xctestplan`) is the source of truth for what runs in CI.

## Development Workflow

All non-trivial change follows Spec-Driven Development using the `.specify/` toolkit:

1. `/speckit.constitution` — establish or amend these principles (rare).
2. `/speckit.specify` — write the feature spec (the WHAT and WHY) under `specs/<n>-<slug>/`.
3. `/speckit.clarify` — resolve ambiguities before planning.
4. `/speckit.plan` — produce the technical plan (the HOW), gated by the Constitution Check.
5. `/speckit.tasks` — derive an ordered, test-first task list.
6. `/speckit.analyze` — cross-check spec ⇄ plan ⇄ tasks for consistency and coverage.
7. `/speckit.implement` — execute tasks, honoring every principle above.

Gates:
- A plan that violates a principle MUST either be revised or record an explicit, justified
  exception in its Complexity Tracking section. Unjustified violations block implementation.
- Changes to testable-core behavior land with tests. UI-affecting changes preserve the
  accessibility identifiers existing tests rely on.

## Governance

- This constitution supersedes ad-hoc conventions. When guidance conflicts, the constitution
  wins; the plan template's Constitution Check enforces it per feature.
- **Amendments** are made via `/speckit.constitution`, which updates this file, propagates
  changes into the dependent templates, and records a Sync Impact Report at the top.
- **Versioning** follows semantic versioning:
  - MAJOR: a principle is removed or redefined in a backward-incompatible way.
  - MINOR: a new principle/section is added or materially expanded.
  - PATCH: clarifications and wording that do not change obligations.
- **Compliance**: reviewers verify each PR against the relevant principles. The
  `/speckit.analyze` step is the automated consistency check before implementation.

**Version**: 1.0.0 | **Ratified**: 2026-08-21 | **Last Amended**: 2026-08-21
