# PillEye App Creation Skill

Use this skill to create, configure, build, test, and run the PillEye iOS application after cloning this repository.

## Goal

Build a SwiftUI iOS app named `PillEye` that tracks medicines or any item with an expiry date. The app uses the iPhone camera to capture medicine names, manufacturing dates, and expiry dates, stores records locally on the phone, and schedules expiry notifications with snooze support.

All saved data must live inside the app sandbox so iOS deletes it automatically when the user deletes the app.

## Prerequisites

- macOS with Xcode installed.
- An Apple ID added in Xcode.
- An iPhone or iOS Simulator.
- For camera scanning, use a physical iPhone that supports VisionKit Live Text scanning.
- For device installation and tests, configure a Development Team in Xcode.

## Repository Setup

1. Clone the repository.
2. Open `Medicine Date Alerter.xcodeproj` in Xcode.
3. Select the app target.
4. Set the display name to `PillEye` if it is not already set.
5. In `Signing & Capabilities`, enable `Automatically manage signing`.
6. Select your Apple development team for:
   - `Medicine Date Alerter`
   - `Medicine Date AlerterTests`
   - `Medicine Date AlerterUITests`
7. In app target Info settings, add:

```text
Privacy - Camera Usage Description
Scan medicine labels and dates so you can edit and save expiry reminders.
```

8. Confirm notification permissions when the app asks on first run.

## App Features To Implement Or Verify

### Medicine Entry

- Main screen heading: `Track my Meds`.
- App display name on iPhone: `PillEye`.
- Portrait-only orientation.
- Medicine name field starts empty.
- Manufacturing date and expiry date fields start empty.
- Snooze options:
  - `1 Day`
  - `1 Week`
  - `1 Month`
  - `2 Months`

### Medicine Name Scanning

- Use VisionKit camera text scanning.
- Show the camera in a rectangular capture area.
- Allow the user to tap highlighted OCR text.
- Prefer the visually largest OCR text row as the suggested medicine name.
- Accept medicine name candidates that are 1 to 3 words from the same OCR row.
- Ignore longer sentence-like OCR text.
- Strip medicine symbols like `®`, `™`, and `℠`.
- Store captured names in Title Case.

### Date Scanning

- Use separate scanners for:
  - Manufacturing date
  - Expiry date
- Show only date-like OCR values.
- Let the user tap the correct date and then tap `Capture`.
- Validate that expiry date is after manufacturing date.
- Support numeric date formats:
  - `05/2026`
  - `05-2026`
  - `01/05/2026`
  - `01-05-26`
- Support month-name date formats:
  - `DEC-2026`
  - `NOV.2026`
  - `JAN 26`
- Support separators between month and year:
  - `.`
  - `-`
  - `/`
  - space

### Manual Date Entry

- Manual date entry should open a centered popup.
- Popup should match the main app color style.
- Popup should have:
  - `Okay`
  - `Cancel`
- `Okay` applies the selected date.
- `Cancel` closes without changing the date.

### Saved Medicines

- Save medicine records locally using JSON in the app sandbox.
- Use the app container `Application Support` directory.
- Protect the JSON file with iOS complete file protection so it is unavailable while the iPhone is locked.
- Delete saved app data automatically when the app is deleted.
- Show saved medicines with:
  - Name
  - Manufacturing date
  - Expiry date
  - Reminder date
  - Snooze value
- Swipe left on a saved medicine to show:
  - `Edit`
  - `Delete`
- `Delete` removes the medicine and cancels its notification.
- `Edit` opens a centered popup where only snooze can be changed for now.
- Keep the edit flow ready for future name/date editing.

### Notifications

- Schedule a local notification one day before expiry.
- Keep lock-screen notification text generic and store only the medicine UUID plus snooze duration in notification metadata.
- Notification should include sound.
- Use a custom `alarm.caf` if one is bundled.
- Fall back to iOS default notification sound if no custom sound exists.
- Mark reminders as time-sensitive.
- Notification actions:
  - `Snooze`
  - `Cancel`
- Tapping the notification body should open the app and show a centered popup for the matching medicine.
- The popup should show medicine details and have:
  - `Delete`
  - `Cancel`

## Important iOS Limitations

- A custom notification alarm tone must be bundled in the app as a supported audio file such as `alarm.caf`.
- Critical alerts that bypass mute or Do Not Disturb require Apple approval and a special entitlement.
- VisionKit can provide OCR text and bounds. It can rank candidates by visual size, but it does not reliably expose font weight or thickness.

## Build

In Xcode:

1. Select the `Medicine Date Alerter` scheme.
2. Select an iPhone simulator or connected iPhone.
3. Press `Cmd+B`.

Expected result:

```text
Build succeeded
```

## Test

In Xcode:

1. Select the `Medicine Date Alerter` scheme.
2. Press `Cmd+U`.

If tests on a physical device fail because of signing, verify the Development Team is set for the app, unit test, and UI test targets.

Key tests should cover:

- Medicine validation.
- Title Case medicine names.
- Medicine-name OCR filtering.
- Numeric date parsing.
- Month-name date parsing.
- Disk persistence.
- Protected local storage and safe delete behavior.
- Snooze editing and notification rescheduling.

## Run On iPhone

1. Connect the iPhone.
2. Trust the computer if prompted.
3. Select the iPhone as the run destination in Xcode.
4. Press `Cmd+R`.
5. Allow camera access.
6. Allow notification access.

## Suggested Coding-Agent Prompt

Use this prompt if asking a coding assistant to recreate or repair the app:

```text
Create a SwiftUI iOS app named PillEye. The app tracks medicines and expiry dates. It must scan medicine names and dates using VisionKit, store records as JSON in Application Support, schedule local expiry notifications with sound and snooze actions, and show a medicine-details popup when a notification is tapped. Keep the UI portrait-only, light, friendly, and accessible. Add unit tests for validation, OCR parsing, date parsing, persistence, and snooze updates. Build the Xcode project and report any test limitations.
```

## Main Files

- `Medicine Date Alerter/ContentView.swift`: main SwiftUI UI.
- `Medicine.swift`: medicine model and validation.
- `MedicineStore.swift`: local JSON persistence and notification coordination.
- `MedicineDateParser.swift`: numeric and month-name expiry date parsing.
- `MedicineNameParser.swift`: OCR medicine-name filtering.
- `TextScannerView.swift`: VisionKit scanner UI.
- `NotificationScheduler.swift`: local notification scheduling.
- `AppNotificationDelegate.swift`: notification callbacks and portrait lock.
- `AlarmNotificationSound.swift`: notification sound selection.
- `MedicineNotificationRoute.swift`: notification tap routing into SwiftUI.
- `SnoozeOption.swift`: shared snooze durations and labels.
- `index.MD`: detailed file/function index.
