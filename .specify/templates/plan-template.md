# Implementation Plan: [FEATURE NAME]

**Branch**: `[###-feature-slug]` | **Date**: [DATE] | **Spec**: [link to spec.md]
**Input**: Feature specification from `specs/[###-feature-slug]/spec.md`

## Summary
[One paragraph: the feature's primary requirement + the chosen technical approach.]

## Technical Context
**Language/Version**: Swift [version] (Xcode [version])
**Primary Frameworks**: SwiftUI, Swift Concurrency, Observation, [VisionKit / UserNotifications / ...]
**Storage**: [JSON in app sandbox / N/A]
**Testing**: Testing framework (unit), XCUIAutomation (UI)
**Target Platform**: iPhone (iOS [min version]), portrait, light mode
**Project Type**: Single iOS app target
**Performance Goals**: [e.g. no main-actor blocking on launch]
**Constraints**: [on-device only, no network, permissions requested lazily]
**Scale/Scope**: [screens/entities affected]

## Constitution Check
*GATE: MUST pass before Phase 0. Re-check after Phase 1 design.*

| Principle | Compliant? | Notes |
|-----------|-----------|-------|
| I. On-Device Privacy First | [ ] | No network, sandbox + file protection, IDs-only notifications |
| II. Testable Core, Injected Boundaries | [ ] | Pure logic + protocol-injected system boundaries; test-first |
| III. Native SwiftUI + Structured Concurrency | [ ] | No Combine; async/await; @MainActor stores |
| IV. Forward-Compatible Persistence | [ ] | decodeIfPresent defaults; no breaking field removals |
| V. Accessible, Consistent Design System | [ ] | PillEyePalette/DimensionalButtonStyle; stable identifiers |
| VI. Simplicity & Scope Discipline | [ ] | No unjustified dependencies; YAGNI |

**Violations** (if any) MUST be recorded in Complexity Tracking with justification.

## Project Structure

### Documentation (this feature)
```
specs/[###-feature-slug]/
├── plan.md          # This file
├── spec.md          # The feature specification
├── research.md      # Phase 0 output
├── data-model.md    # Phase 1 output (if the feature has entities)
├── quickstart.md    # Phase 1 output (manual validation steps)
├── contracts/       # Phase 1 output (protocol/interface sketches)
└── tasks.md         # Phase 2 output (/speckit.tasks — NOT created by /speckit.plan)
```

### Source (repository root)
```
Medicine Date Alerter/          # App target sources
  Medicine Date Alerter/        # App entry, ContentView, Assets
  *.swift                       # Models, stores, parsers, schedulers, views
Medicine Date AlerterTests/     # Unit tests (Testing framework)
Medicine Date AlerterUITests/   # UI tests (XCUIAutomation)
```

## Phase 0: Outline & Research
1. Extract every unknown from Technical Context and every `[NEEDS CLARIFICATION]` from the spec.
2. Verify any unfamiliar/new Apple API against current documentation (do not assume).
3. Record decisions in `research.md`: **Decision / Rationale / Alternatives considered**.

**Output**: `research.md` with no remaining unknowns.

## Phase 1: Design & Contracts
*Prerequisite: research.md complete.*

1. `data-model.md`: entities, fields, validation rules, and `Codable` compatibility notes.
2. `contracts/`: the protocols/interfaces the feature introduces or extends (e.g. a new
   scheduler or store method), expressed as Swift signatures — no implementation.
3. `quickstart.md`: manual steps to validate the feature on device/simulator.
4. Re-run the Constitution Check against the concrete design.

**Output**: data-model.md, contracts/, quickstart.md, updated agent context.

## Phase 2: Task Planning Approach
*Described here; executed by `/speckit.tasks`.*
- Derive tasks from contracts and the data model, ordered test-first (Principle II).
- Mark independent files `[P]` for parallel execution.

## Complexity Tracking
*Fill ONLY if the Constitution Check has a justified violation.*

| Violation | Why needed | Simpler alternative rejected because |
|-----------|-----------|--------------------------------------|
| [e.g. add dependency X] | [reason] | [why the plain approach is insufficient] |

## Progress Tracking
- [ ] Phase 0: Research complete
- [ ] Phase 1: Design complete
- [ ] Constitution Check: initial PASS
- [ ] Constitution Check: post-design PASS
- [ ] Phase 2: Task planning approach described
