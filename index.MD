# Medicine Date Alerter Code Index

This document is a beginner-friendly map of the app. It assumes you are comfortable with Java, Python, JavaScript, or TypeScript, but new to Swift and SwiftUI.

## High-Level Architecture

The app is split into a few responsibilities:

- **UI:** `ContentView.swift` and `TextScannerView.swift`
- **Data model:** `Medicine.swift`
- **Validation and parsing:** `Medicine.swift`, `MedicineDateParser.swift`, `MedicineNameParser.swift`
- **Shared UI values:** `SnoozeOption.swift`
- **Disk-backed storage:** `MedicineStore.swift`
- **Notifications:** `NotificationScheduler.swift`, `AppNotificationDelegate.swift`, `AlarmNotificationSound.swift`, `MedicineNotificationRoute.swift`
- **App launch:** `Medicine_Date_AlerterApp.swift`
- **Tests:** files under `Medicine Date AlerterTests` and `Medicine Date AlerterUITests`
- **Assets:** `Assets.xcassets`

Swift terms you will see often:

- `struct`: value type, similar to a lightweight data class.
- `class`: reference type, closer to Java/Python/JS objects.
- `protocol`: similar to a Java or TypeScript interface.
- `View`: a SwiftUI screen/component, similar to a React component.
- `@State`: SwiftUI-owned mutable state for a view.
- `async`: function does asynchronous work.
- `throws`: function can fail by throwing an error.
- `try`: required when calling a throwing function.
- `await`: required when calling an async function.

## App Files

### `Medicine Date Alerter/Medicine_Date_AlerterApp.swift`

This is the app entry point. iOS starts here.

#### `Medicine_Date_AlerterApp`

The root SwiftUI app type. The `@main` annotation tells Swift that this is the first app code to run.

#### `notificationDelegate`

Uses `@UIApplicationDelegateAdaptor` to connect a UIKit app delegate to the SwiftUI app. This is needed because notification callbacks are still delivered through UIKit-style delegate methods.

#### `body`

Creates the main app window using `WindowGroup` and displays `ContentView`.

---

### `Medicine Date Alerter/ContentView.swift`

This is the main screen. It lets the user type or scan medicine details, validate dates, save medicines, and see saved records.

#### `ContentView`

The main SwiftUI view. Similar to a React component with state.

State fields:

- `store`: disk-backed medicine storage.
- `medicineName`: text typed or scanned for the medicine name.
- `manufacturingDate`: optional selected manufacturing date. It starts empty.
- `expiryDate`: optional selected expiry date. It starts empty.
- `snoozeMinutes`: chosen snooze duration for notification action. Options are 1 day, 1 week, 1 month, and 2 months.
- `validationMessage`: optional error message shown in the form.
- `showingScanner`: controls whether the camera scanner sheet is open.
- `scannerMode`: tells the scanner whether it is scanning a name or dates.
- `notificationMedicineID`: medicine selected after the user taps an expiry notification.
- `medicineEditDraft`: temporary edit values for the saved-medicine popup.

#### `init()`

Creates the screen with the real `MedicineStore`.

#### `init(store:)`

Creates the screen with a provided store. Used by previews and tests so they can avoid real notification scheduling.

#### `body`

Declares the UI:

- Medicine name text field.
- Scan buttons.
- Manufacturing and expiry date rows.
- Centered manual date popup.
- Snooze picker.
- Save button.
- Saved medicines list.
- Swipe-left Edit and Delete actions for saved medicines.
- Scanner sheet.
- Centered medicine details popup after tapping an expiry notification.
- Centered saved-medicine edit popup.

SwiftUI recalculates `body` when `@State` changes.

#### `saveMedicine()`

Called when the user taps **Save medicine**.

It:

- Clears old validation messages.
- Calls `store.save(...)`.
- Resets the form on success.
- Shows an error message on failure.

#### `resetForm()`

Clears the medicine name and returns both date fields to empty after a successful save.

#### `openManualDatePopup(for:)`

Opens the manual date popup for either manufacturing date or expiry date.

#### `openMedicineEditPopup(for:)`

Opens the popup for editing a saved medicine. The current version only allows snooze changes.

#### `manualDatePopup(for:)`

Small centered date picker popup. The user selects a date and taps Okay or Cancel. Okay writes the selected date into the background form; Cancel closes the popup without changing the field.

#### `saveManualDate(for:)`

Saves the date selected in the popup into the correct field and validates it against the other date if present.

#### `listenForNotificationTaps()`

Listens for in-app notification tap events from `AppNotificationDelegate`. When the user taps an expiry notification, this function finds the matching medicine and opens the medicine details popup. It also checks whether the notification was tapped before the SwiftUI screen was ready.

#### `openNotificationMedicineDetails(for:)`

Finds the medicine selected from a notification and opens the details popup.

#### `medicineDetailsPopup(for:)`

Centered popup shown after tapping an expiry notification. It displays the selected medicine's name, manufacturing date, expiry date, reminder date, and snooze duration.

The popup has two buttons:

- `Delete`: deletes the selected medicine and cancels its reminder.
- `Cancel`: closes the popup and returns to the main screen.

#### `detailRow(title:value:)`

Reusable title/value row used inside the medicine details popup.

#### `medicineEditPopup(for:)`

Centered popup shown from the saved-medicine swipe Edit action. It displays read-only medicine name and dates, and allows changing only the snooze time.

#### `saveMedicineEdit()`

Saves the edited snooze time through `MedicineStore.update(...)`, persists the changed medicine, and refreshes its notification reminder.

#### `dateInputRow(title:date:setAction:scanAction:)`

Reusable UI row for optional dates. It shows `Not set` until a date exists, plus buttons to open the manual popup or scan.

#### `applyCapturedTexts(_:)`

Receives the user's confirmed scanner selections after the bottom button is tapped.

- In `.name` mode, the first selected text becomes `medicineName`.
- In `.manufacturingDate` mode, the selected date is parsed and saved to `manufacturingDate`.
- In `.expiryDate` mode, the selected date is parsed and saved to `expiryDate`.
- Closes the scanner sheet after applying the selected values.

#### `applyScannedManufacturingDate(from:)`

Parses one selected scanner date and applies it to the manufacturing date field. It also validates that manufacturing date is before expiry date.

#### `applyScannedExpiryDate(from:)`

Parses one selected scanner date and applies it to the expiry date field. It also validates that expiry date is after manufacturing date.

#### `snoozeLabel(for:)`

Converts a snooze duration in minutes into readable UI text: `1 Day`, `1 Week`, `1 Month`, or `2 Months`.

#### `MedicineRow`

Small SwiftUI view used for each saved medicine in the list.

#### `MedicineRow.body`

Shows:

- Medicine name.
- Expired label if applicable.
- Manufacturing date.
- Expiry date.
- Reminder date.

#### `ScannerMode`

Enum that tells the scanner what kind of text is expected.

Cases:

- `name`
- `manufacturingDate`
- `expiryDate`

#### `ScannerMode.title`

Returns the scanner sheet title for the current scanner mode.

#### `ScannerMode.instructions`

Returns mode-specific instructions shown in the scanner sheet.

#### `ScannerMode.captureMode`

Chooses whether the scanner captures general text manually or asks the user to select one detected date.

#### `ManualDateTarget`

Enum that identifies which field the manual date popup is editing.

Cases:

- `manufacturing`
- `expiry`

#### `ManualDateTarget.id`

Stable ID required by SwiftUI's `.sheet(item:)` API.

#### `ManualDateTarget.title`

Title shown at the top of the popup.

#### `ManualDateTarget.pickerTitle`

Accessibility/label text for the date picker inside the popup.

#### `MedicineEditDraft`

Temporary values used by the saved-medicine edit popup. It includes name, dates, and snooze so the same draft can support broader editing later.

#### `MedicineEditDraft.init(medicine:)`

Builds an edit draft from an existing saved medicine.

---

### `Medicine Date Alerter/SnoozeOption.swift`

This file contains the shared snooze durations and labels used across the app.

#### `SnoozeOption`

Utility enum for snooze-related constants.

#### `allDurationsInMinutes`

The supported snooze durations: 1 day, 1 week, 1 month, and 2 months.

#### `label(for:)`

Converts a stored minute value into user-friendly text. The form, edit popup, saved medicine row, and tests all use this single function.

#### `PreviewNotificationScheduler`

Fake notification scheduler used only by Xcode previews.

#### `PreviewNotificationScheduler.scheduleExpiryReminder(for:)`

No-op preview function. It does not schedule real notifications.

#### `PreviewNotificationScheduler.cancelReminder(for:)`

No-op preview function. It does not cancel real notifications.

---

### `Medicine Date Alerter/Medicine.swift`

This file contains the core medicine model and validation rules.

#### `Medicine`

Represents one saved medicine.

Properties:

- `id`: unique ID.
- `name`: medicine name.
- `manufacturingDate`: manufacturing date.
- `expiryDate`: expiry date.
- `snoozeMinutes`: snooze duration for notification action.
- `createdAt`: when the record was created.

Conformances:

- `Identifiable`: lets SwiftUI show medicines in lists.
- `Codable`: lets medicine records be converted to/from JSON.
- `Hashable`: lets Swift compare/store the object efficiently.

#### `Medicine.init(...)`

Creates a new medicine and trims whitespace from the name.

#### `Medicine.reminderDate`

Computed property that returns one day before `expiryDate`.

#### `Medicine.isExpired`

Computed property that returns `true` if `expiryDate` is before the current time.

#### `MedicineUpdate`

Describes changes to an existing medicine. The current UI only sets `snoozeMinutes`, but the struct also includes optional name and date fields for future editing.

#### `MedicineValidationError`

Enum of validation failures.

Cases:

- `missingName`
- `expiryNotAfterManufacturing`

#### `MedicineValidationError.errorDescription`

Converts validation errors into user-readable text.

#### `MedicineValidator`

Utility namespace for validation logic.

#### `MedicineValidator.validate(name:manufacturingDate:expiryDate:)`

Throws an error if:

- Name is empty.
- Expiry date is not after manufacturing date.

---

### `Medicine Date Alerter/MedicineDateParser.swift`

This file parses dates from camera-recognized text.

#### `MedicineDateParser`

Utility type for extracting dates from OCR text.

#### `numericPattern`

Regular expression that finds date-like patterns such as:

- `05/2026`
- `05-2026`
- `01/05/2026`
- `01-05-26`

#### `monthNamePattern`

Regular expression that finds month-name date patterns such as `DEC-2026`, `NOV.2026`, and `JAN 26`.

#### `monthNumbersByName`

Maps month names to month numbers. Three-letter month names are supported, plus `SEPT`.

#### `extractDates(from:calendar:)`

Finds all recognizable dates in text and returns them sorted from earliest to latest.

It also replaces `O` with `0` because OCR often confuses those characters.

#### `extractDateStrings(from:)`

Finds only date-looking strings in OCR text. The scanner uses this so manufacturing/expiry capture cannot capture unrelated words.

#### `firstDate(from:calendar:)`

Parses the first valid date from one selected OCR value. The manufacturing and expiry scanners use this after the user taps one detected date.

#### `inferredManufacturingAndExpiryDates(from:)`

Uses:

- Earliest parsed date as manufacturing date.
- Latest parsed date as expiry date.

Returns `nil` if it cannot find two valid dates.

#### `makeDate(day:month:year:calendar:)`

Builds a Swift `Date` from integer date parts.

Two-digit years are treated as 2000-based years, so `26` becomes `2026`.

#### `numericMatches(in:range:)`

Returns regex matches for numeric date formats.

#### `monthNameMatches(in:range:)`

Returns regex matches for month-name date formats.

#### `dateFromMonthNameMatch(_:in:calendar:)`

Converts one month-name regex match into a Swift `Date`.

---

### `Medicine Date Alerter/MedicineNameParser.swift`

This file filters OCR text for medicine-name scanning.

#### `MedicineNameParser`

Utility type for extracting medicine-name candidates from camera-recognized text.

#### `candidates(from:)`

Returns unique 1-3 word candidates from the same OCR row and ignores sentence-like text, date-like text without letters, and punctuation-heavy text. Registered/trademark symbols like `®` are removed before validation.

#### `candidate(from:)`

Returns one cleaned title-cased candidate, or `nil` if the OCR text is not a short medicine-name row.

---

### `Medicine Date Alerter/MedicineStore.swift`

This file stores medicines in memory, saves them to disk, and coordinates notification scheduling.

#### `MedicineStore`

Repository/service object for medicine records.

It keeps a copy in memory for the UI and writes the same list to `medicines.json` inside the app's Application Support directory. iOS removes that app sandbox when the app is deleted, so the saved medicine data is also deleted.

#### `medicines`

Array of saved medicines. Other files can read it, but only `MedicineStore` can modify it.

#### `notificationScheduler`

Object responsible for scheduling/canceling notifications.

#### `storageURL`

Optional file URL for the JSON file. The real app uses Application Support. Tests can pass a temporary URL, or `nil` to keep the store memory-only.

#### `init()`

Creates the real store with `LocalNotificationScheduler`, sets the app-sandbox JSON file location, and loads saved medicines from disk.

#### `init(notificationScheduler:storageURL:)`

Creates a store with a custom scheduler and optional storage file. Tests use this to inject a fake scheduler and temporary disk location.

#### `save(name:manufacturingDate:expiryDate:snoozeMinutes:)`

Validates input, creates a `Medicine`, schedules its expiry reminder, inserts it into the list, and writes the changed list to disk.

#### `update(medicineID:changes:)`

Applies changes to an existing medicine, validates the result, refreshes the notification reminder, and writes the changed list to disk. This is used by the snooze edit popup and is ready for future name/date edits.

#### `delete(_:)`

Removes a medicine, writes the changed list to disk, and cancels its reminder.

#### `exportData()`

Encodes the medicine array as JSON data. This is groundwork for portable export later.

#### `importData(_:)`

Replaces the current list from JSON data and writes it to disk.

#### `defaultStorageURL()`

Builds the real app's `Application Support/PillEye/medicines.json` file URL.

#### `loadFromDisk()`

Reads saved medicines from disk when the app starts. If no file exists yet, the list starts empty.

#### `persistToDisk()`

Writes the current medicine list to the app sandbox as JSON.

#### `encoder`

Shared JSON encoder that stores dates using ISO-8601 text.

#### `decoder`

Shared JSON decoder that reads the same ISO-8601 date format.

---

### `Medicine Date Alerter/NotificationScheduler.swift`

This file handles local iOS notifications.

#### `NotificationScheduling`

Protocol, similar to an interface.

It allows the app to use real notifications in production and fake notifications in tests/previews.

#### `scheduleExpiryReminder(for:)`

Protocol requirement for scheduling a medicine reminder.

#### `cancelReminder(for:)`

Protocol requirement for canceling a medicine reminder.

#### `LocalNotificationScheduler`

Real implementation using `UNUserNotificationCenter`.

#### `categoryIdentifier`

Notification category ID used to connect a reminder notification to its action buttons.

#### `snoozeActionIdentifier`

ID for the Snooze button.

#### `cancelActionIdentifier`

ID for the Cancel button.

#### `init(center:)`

Creates the scheduler. Defaults to the current app's notification center.

#### `scheduleExpiryReminder(for:)`

Requests permission if needed, builds notification content, and schedules a reminder.

Normally schedules one day before expiry. If that time is already past, schedules about 60 seconds in the future so it can be tested.

#### `cancelReminder(for:)`

Removes pending and delivered notifications for the medicine.

#### `identifier(for:)`

Creates a stable notification identifier from a medicine UUID.

#### `configureNotificationActions(on:)`

Registers Snooze and Cancel actions with iOS.

#### `requestAuthorizationIfNeeded()`

Requests notification permission if the app does not already have it.

---

### `Medicine Date Alerter/AlarmNotificationSound.swift`

This file keeps notification sound and urgency settings in one place.

#### `AlarmNotificationSound`

Utility enum used by both the first expiry reminder and snoozed reminders.

#### `AlarmNotificationSound.sound`

Returns a custom `alarm.caf` notification sound if that file is bundled with the app. If the app does not contain `alarm.caf`, it falls back to iOS's default notification sound so alerts still produce audio.

#### `AlarmNotificationSound.applyUrgency(to:)`

Applies the chosen sound and marks the notification as time-sensitive. Time-sensitive notifications are treated as more urgent by iOS, but they do not bypass the mute switch. Apple only allows that with Critical Alerts, which require a special Apple entitlement.

---

### `Medicine Date Alerter/AppNotificationDelegate.swift`

This file receives notification callbacks from iOS.

#### `AppNotificationDelegate`

UIKit delegate object used by the SwiftUI app.

#### `application(_:didFinishLaunchingWithOptions:)`

Runs when the app launches. Registers notification actions and sets the notification delegate.

#### `userNotificationCenter(_:willPresent:)`

Controls how a notification appears while the app is open. This app shows banner, sound, and list presentation.

#### `userNotificationCenter(_:didReceive:)`

Handles notification actions:

- Snooze: reschedules the reminder after the configured snooze duration.
- Cancel: removes pending and delivered reminders.
- Tapping the notification body: asks the SwiftUI screen to show the tapped medicine's details.

---

### `Medicine Date Alerter/MedicineNotificationRoute.swift`

This file bridges notification taps from UIKit delegate code into the SwiftUI screen.

#### `MedicineNotificationRoute`

Utility enum that sends and reads local `NotificationCenter` events.

#### `medicineTapped`

Local event name used when the user taps a medicine expiry notification.

#### `medicineIDKey`

Key used to store the medicine UUID inside the local event's `userInfo` dictionary.

#### `postMedicineTapped(medicineID:)`

Posts a local event saying the user tapped the notification for one medicine.

#### `consumePendingMedicineID()`

Returns a notification tap that happened before `ContentView` started listening, then clears it so the popup only opens once.

#### `medicineID(from:)`

Reads the medicine UUID from the local event so `ContentView` can find the matching medicine.

---

### `Medicine Date Alerter/TextScannerView.swift`

This file bridges SwiftUI to VisionKit camera text scanning and provides the user-friendly capture workflow.

#### `TextScannerCaptureMode`

Enum that controls scanner behavior.

Cases:

- `manualText`: used for medicine names. The user chooses which text to keep.
- `singleDate`: used for manufacturing date and expiry date. The scanner shows only date-like values and the user taps exactly one.

#### `TextScannerCaptureMode.confirmButtonTitle`

Returns the bottom confirmation button text, such as `OK` or `Capture`.

#### `TextScannerView`

SwiftUI scanner screen. It displays:

- A rectangular camera capture area.
- Detected text or detected date values.
- Captured values that the user can remove.
- Bottom Cancel and confirmation buttons for easier one-handed use.

#### `TextScannerView.body`

Builds the full scanner UI.

#### `TextScannerView.confirmableTexts`

Returns the values that will be sent back to `ContentView`. In single-date mode, this is the selected date chip.

#### `TextScannerView.canConfirm`

Controls whether the bottom button is enabled. Single-date mode requires the user to select one valid detected date.

#### `TextScannerView.suggestedName`

Returns the first detected name candidate. The camera scanner sorts larger text first, so this is the best current guess for the medicine name.

#### `TextScannerView.textSelectionArea`

Shows live detected text and the user's selected/captured values.

#### `TextScannerView.manualTextSelectionArea`

Shows the medicine-name capture UI. The largest detected row is shown as the suggested name, and the user can still tap another detected candidate or highlighted camera text.

#### `TextScannerView.singleDateCaptureArea`

Shows only detected date values. The user taps the correct one before pressing Capture.

#### `TextScannerView.capturedTextList`

Shows manually captured text values with remove buttons.

#### `TextScannerView.updateDetectedTexts(_:)`

Updates detected values from the camera. Medicine-name mode filters raw OCR text through `MedicineNameParser.candidates(from:)`. Single-date mode filters raw OCR text through `MedicineDateParser.extractDateStrings(from:)`.

#### `TextScannerView.handleTappedText(_:)`

Handles text tapped in the camera. In name mode it adds the text manually; in single-date mode it selects a date only.

#### `TextScannerView.addCapturedText(_:)`

Adds a detected value to the selected list if it is not blank or duplicated.

#### `TextScannerView.removeCapturedText(_:)`

Removes one selected value.

#### `TextScannerView.dateValues(from:)`

Extracts unique date strings from detected OCR text.

#### `TextScannerView.cleanedText(_:)`

Trims whitespace from camera-recognized text.

#### `ScannerCameraView`

SwiftUI wrapper around the UIKit `DataScannerViewController`.

#### `makeUIViewController(context:)`

Creates the UIKit scanner host embedded inside the rectangular camera area.

#### `updateUIViewController(_:context:)`

Required by `UIViewControllerRepresentable`. This app does not need update logic here.

#### `makeCoordinator()`

Creates a coordinator object that receives VisionKit delegate callbacks.

#### `Coordinator`

Adapter object that receives scanner events from VisionKit.

#### `Coordinator.init(onTextTapped:)`

Stores the callback that receives recognized text.

#### `Coordinator.dataScanner(_:didTapOn:)`

Runs when the user taps highlighted recognized text in the camera view.

#### `ScannerHostViewController`

UIKit controller that owns the camera scanner and permission flow.

#### `ScannerHostViewController.init(delegate:onDetectedTextsChanged:)`

Creates the scanner host.

#### `ScannerHostViewController.init(coder:)`

Required by UIKit. This app does not use storyboards, so this function intentionally crashes if called.

#### `viewDidLoad()`

Runs after the controller's view loads. Starts the camera setup flow.

#### `viewDidDisappear(_:)`

Stops camera scanning and cancels live-recognition observation when the scanner disappears.

#### `configureCameraAccess()`

Checks:

- Camera usage description exists.
- Device supports VisionKit scanning.
- Camera permission is granted or can be requested.

Then starts the scanner if allowed.

#### `startScanner()`

Creates and starts the VisionKit scanner.

#### `observeRecognizedItems(from:)`

Watches VisionKit's live recognized text stream and sends detected strings back to SwiftUI.

#### `publishDetectedTextsIfNeeded(_:)`

Throttles VisionKit's rapid camera updates before sending them to SwiftUI. This prevents the detected text area from constantly refreshing while the camera is focusing.

#### `texts(from:)`

Extracts unique text values from VisionKit recognized items, sorted with larger on-screen text first.

#### `textArea(for:)`

Approximates the visual size of one recognized text item from its VisionKit bounds. The scanner uses this as a signal because medicine names are often printed larger than surrounding text.

#### `showStatus(_:)`

Shows a temporary status message.

#### `showUnavailable(_:)`

Shows an error or unsupported-state message.

#### `showMessage(_:includeCloseButton:)`

Shared helper that builds the message UI.

#### Fallback `TextScannerView`

Used only on platforms where VisionKit is unavailable.

#### Fallback `TextScannerView.body`

Shows a message explaining that camera text scanning needs a supported iOS device.

---

## Test Files

### `Medicine Date AlerterTests/Medicine_Date_AlerterTests.swift`

Unit tests for non-UI logic.

#### `validatorRejectsMissingName()`

Verifies blank names fail validation.

#### `validatorRejectsExpiryBeforeManufacturingDate()`

Verifies expiry date must be after manufacturing date.

#### `medicineNameParserKeepsOneToThreeWordRows()`

Verifies medicine-name OCR keeps 1-3 word row candidates and ignores sentences.

#### `snoozeOptionLabelsAreUserFriendly()`

Verifies the shared snooze durations and labels.

#### `reminderDateIsOneDayBeforeExpiry()`

Verifies reminder date calculation.

#### `dateParserExtractsOnlyDateStrings()`

Verifies OCR date extraction returns only date-looking strings, including month-name formats.

#### `dateParserParsesSingleSelectedDate()`

Verifies one selected OCR date can be parsed by itself.

#### `dateParserParsesMonthNameDates()`

Verifies month-name dates with dash, dot, and space separators are parsed correctly.

#### `dateParserInfersManufacturingAndExpiryDates()`

Verifies OCR-like date text is parsed correctly.

#### `storeSavesMedicineAndSchedulesReminder()`

Verifies saving inserts a medicine and asks the scheduler to create a reminder.

#### `storePersistsMedicinesToDisk()`

Verifies one store writes medicines to a temporary JSON file and a second store can load them from that file.

#### `storeUpdatesSnoozeAndReschedulesReminder()`

Verifies editing snooze changes the saved medicine and asks the scheduler to refresh the reminder.

#### `makeDate(year:month:day:)`

Helper for creating predictable dates in tests.

#### `temporaryStorageURL()`

Builds a unique temporary JSON file URL for persistence tests.

#### `SpyNotificationScheduler`

Fake notification scheduler used by unit tests.

#### `SpyNotificationScheduler.scheduleExpiryReminder(for:)`

Records scheduled medicine names without talking to iOS notifications.

#### `SpyNotificationScheduler.cancelReminder(for:)`

No-op cancellation function for tests.

---

### `Medicine Date AlerterUITests/Medicine_Date_AlerterUITests.swift`

UI tests that launch the full app.

#### `setUpWithError()`

Runs before each UI test and stops the test after the first failure.

#### `tearDownWithError()`

Runs after each UI test. Currently empty.

#### `testExample()`

Launches the app.

#### `testLaunchPerformance()`

Measures app launch performance.

---

### `Medicine Date AlerterUITests/Medicine_Date_AlerterUITestsLaunchTests.swift`

Launch screenshot tests generated by Xcode.

#### `runsForEachTargetApplicationUIConfiguration`

Tells XCTest to run for each configured UI environment.

#### `setUpWithError()`

Runs before the launch test.

#### `testLaunch()`

Launches the app and attaches a screenshot to the test report.

---

## Assets

### `Medicine Date Alerter/Assets.xcassets/AppIcon.appiconset`

Contains the app icon.

Current icon file:

- `AppIcon.png`

### `Medicine Date Alerter/Assets.xcassets/AccentColor.colorset`

Contains the app accent color used by SwiftUI where applicable.

---

## Important Runtime Setup

For camera scanning to work on a physical iPhone, the app target must include:

- `Privacy - Camera Usage Description`

Recommended value:

```text
Scan medicine labels and dates so you can edit and save expiry reminders.
```

For notifications to work:

- Run the app on device.
- Allow notifications when iOS prompts.
- Save a medicine with an expiry date.

For tests on a physical iPhone:

- The app target, unit test target, and UI test target all need a development team configured in Xcode.
