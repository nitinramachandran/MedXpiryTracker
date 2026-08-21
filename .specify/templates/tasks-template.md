# Tasks: [FEATURE NAME]

**Input**: Design documents from `specs/[###-feature-slug]/`
**Prerequisites**: plan.md (required), spec.md, research.md, data-model.md, contracts/

## Conventions
- **[P]** = can run in parallel (touches different files, no ordering dependency).
- Every task names the exact file path it creates or edits.
- **Test-first (Principle II)**: for testable-core changes, the failing test task precedes
  its implementation task.

## Phase 3.1: Setup
- [ ] T001 Confirm the feature branch and that the target/test plan build cleanly.
- [ ] T002 [P] Add any new file stubs referenced by contracts.

## Phase 3.2: Tests First ⚠️ MUST precede 3.3
- [ ] T003 [P] Unit tests for [entity/parser/validator] in `Medicine Date AlerterTests/[Name]Tests.swift`.
- [ ] T004 [P] UI test for [primary scenario] in `Medicine Date AlerterUITests/[Name]UITests.swift`.

## Phase 3.3: Core Implementation (only after tests exist and fail)
- [ ] T005 [P] Model/entity changes in `Medicine.swift` (keep `Codable` decodeIfPresent-compatible).
- [ ] T006 Store/service logic in `MedicineStore.swift` (behind injected boundaries).
- [ ] T007 Parsing/validation logic in `[Parser].swift`.
- [ ] T008 UI wiring in `ContentView.swift` (reuse PillEyePalette / DimensionalButtonStyle; add identifiers).

## Phase 3.4: Integration
- [ ] T009 Notification/scheduling changes in `NotificationScheduler.swift` / `AppNotificationDelegate.swift`.
- [ ] T010 Persistence/backup compatibility checks (old files and backups still import).

## Phase 3.5: Polish
- [ ] T011 [P] Accessibility identifiers and VoiceOver labels verified.
- [ ] T012 [P] Update `quickstart.md` and run the manual validation steps.
- [ ] T013 Build via BuildProject and run the xctestplan; all green.

## Dependencies
- Tests (T003–T004) before implementation (T005–T008).
- T005 (model) before T006 (store) before T008 (UI).

## Parallel Execution Example
```
# Launch independent test tasks together:
T003 Unit tests for the parser
T004 UI test for the primary scenario
```
