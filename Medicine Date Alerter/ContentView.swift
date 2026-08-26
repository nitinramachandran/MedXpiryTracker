import SwiftUI
import UniformTypeIdentifiers

/// The main screen of the app.
///
/// In SwiftUI, a `View` is similar to a React component: it owns state and declares
/// what should appear on screen for that current state.
struct ContentView: View {
    @State private var store: MedicineStore
    @State private var medicineName = ""
    @State private var manufacturingDate: Date?
    @State private var expiryDate: Date?
    @State private var reminderLeadDays = 1
    @State private var activeDateField: ManualDateTarget = .manufacturing
    @State private var validationMessage: String?
    @State private var showingScanner = false
    @State private var scannerMode = ScannerMode.name
    @State private var manualDateTarget: ManualDateTarget?
    @State private var manualDateDraft = Date()
    @State private var notificationMedicineID: UUID?
    @State private var medicineEditDraft: MedicineEditDraft?
    @State private var showingSavedMedicines = false
    @State private var showingBackupImporter = false
    @State private var pendingImportData: Data?
    @State private var backupMessage: String?

    /// The medicine selected by tapping an expiry notification, if it still exists in the store.
    private var notificationMedicine: Medicine? {
        guard let notificationMedicineID else { return nil }
        return store.medicines.first { $0.id == notificationMedicineID }
    }

    /// The current medicines as a shareable backup, or `nil` when there is nothing to export.
    private var backupShareItem: MedicineBackupFile? {
        guard !store.medicines.isEmpty, let data = try? store.exportData() else { return nil }
        return MedicineBackupFile(data: data)
    }

    /// Shows the replace-confirmation alert while a picked backup waits for approval.
    private var isConfirmingImport: Binding<Bool> {
        Binding(
            get: { pendingImportData != nil },
            set: { isPresented in
                if !isPresented {
                    pendingImportData = nil
                }
            }
        )
    }

    /// Creates the real app screen with the disk-backed medicine store.
    @MainActor
    init() {
        _store = State(initialValue: MedicineStore())
    }

    /// Creates the screen with a supplied store.
    ///
    /// This initializer is mainly useful for previews and tests, where we do not want
    /// to use real notification scheduling.
    init(store: MedicineStore) {
        _store = State(initialValue: store)
    }

    /// Declares the full user interface for this screen.
    ///
    /// SwiftUI recalculates `body` whenever `@State` changes, then updates the screen.
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    headerPanel
                }
                .listRowBackground(Color.clear)

                Section("Medicine details") {
                    TextField("Medicine name", text: $medicineName)
                        .font(.body.weight(.semibold))
                        .textInputAutocapitalization(.words)
                        .foregroundStyle(PillEyePalette.deepTeal)
                        .accessibilityIdentifier("medicineNameField")

                    Button {
                        scannerMode = .name
                        showingScanner = true
                    } label: {
                        Label("Scan medicine name", systemImage: "camera.viewfinder")
                    }
                    .buttonStyle(DimensionalButtonStyle(fill: PillEyePalette.teal))

                    dateEntryRow

                    Picker("Remind before expiry", selection: $reminderLeadDays) {
                        ForEach(ReminderLeadOption.allDays, id: \.self) { days in
                            Text(ReminderLeadOption.label(for: days)).tag(days)
                        }
                    }
                }
                .listRowBackground(PillEyePalette.formRowBackground)

                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PillEyePalette.coral)
                            .accessibilityIdentifier("validationMessage")
                    }
                    .listRowBackground(PillEyePalette.formRowBackground)
                }

                Section {
                    Button {
                        Task { await saveMedicine() }
                    } label: {
                        Label("Save medicine", systemImage: "tray.and.arrow.down.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DimensionalButtonStyle(fill: PillEyePalette.coral, minHeight: 46))
                    .accessibilityIdentifier("saveMedicineButton")
                }
                .listRowBackground(PillEyePalette.formRowBackground)

                Section {
                    Button {
                        showingSavedMedicines = true
                    } label: {
                        Label("Saved medicines", systemImage: "list.bullet.rectangle.portrait.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DimensionalButtonStyle(fill: PillEyePalette.teal, minHeight: 46))
                    .accessibilityIdentifier("savedMedicinesButton")
                }
                .listRowBackground(PillEyePalette.formRowBackground)

                Section {
                    if let backup = backupShareItem {
                        ShareLink(
                            item: backup,
                            preview: SharePreview(
                                "MedXpiryTracker medicines backup",
                                image: Image(systemName: "cross.case.fill")
                            )
                        ) {
                            Label("Export medicines", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(DimensionalButtonStyle(fill: PillEyePalette.blue))
                        .accessibilityIdentifier("exportMedicinesButton")
                    }

                    Button {
                        backupMessage = nil
                        showingBackupImporter = true
                    } label: {
                        Label("Import from backup", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(DimensionalButtonStyle(fill: PillEyePalette.blue, prominence: .secondary))
                    .accessibilityIdentifier("importMedicinesButton")

                    if let backupMessage {
                        Label(backupMessage, systemImage: "info.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(PillEyePalette.deepTeal)
                            .accessibilityIdentifier("backupMessage")
                    }
                } header: {
                    Text("Backup & transfer")
                } footer: {
                    Text("Backups are plain files. AirDrop one to another iPhone or keep it in Files, then import it after switching phones or reinstalling.")
                }
                .listRowBackground(PillEyePalette.formRowBackground)
            }
            .fontDesign(.rounded)
            .environment(\.colorScheme, .light)
            .tint(PillEyePalette.teal)
            .scrollContentBackground(.hidden)
            .background(PillEyePalette.background)
            .navigationTitle("Track my Meds")
            .toolbarBackground(PillEyePalette.mint, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .sheet(isPresented: $showingScanner) {
                NavigationStack {
                    TextScannerView(
                        title: scannerMode.title,
                        instructions: scannerMode.instructions,
                        captureMode: scannerMode.captureMode,
                        onConfirm: applyCapturedTexts,
                        onClose: { showingScanner = false }
                    )
                    .fontDesign(.rounded)
                    .tint(PillEyePalette.teal)
                    .navigationTitle(scannerMode.title)
                }
            }
            .sheet(isPresented: $showingSavedMedicines) {
                SavedMedicinesView(
                    store: store,
                    onEdit: { medicine in
                        showingSavedMedicines = false
                        openMedicineEditPopup(for: medicine)
                    },
                    onDelete: { medicine in
                        await deleteMedicine(medicine)
                    },
                    onClose: { showingSavedMedicines = false }
                )
            }
            .overlay {
                if let manualDateTarget {
                    manualDatePopup(for: manualDateTarget)
                } else if let medicineEditDraft {
                    medicineEditPopup(for: medicineEditDraft)
                } else if let notificationMedicine {
                    medicineDetailsPopup(for: notificationMedicine)
                }
            }
            .fileImporter(
                isPresented: $showingBackupImporter,
                allowedContentTypes: [.json]
            ) { result in
                handleBackupSelection(result)
            }
            .alert("Replace saved medicines?", isPresented: isConfirmingImport) {
                Button("Replace", role: .destructive) {
                    if let pendingImportData {
                        Task { await importBackup(pendingImportData) }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Importing replaces your \(store.medicines.count) saved medicine\(store.medicines.count == 1 ? "" : "s") with the contents of the backup file.")
            }
            .task { await store.load() }
            .task { await listenForNotificationTaps() }
        }
        .preferredColorScheme(.light)
    }

    /// Waits for notification-tap events from `AppNotificationDelegate`.
    ///
    /// `for await` is Swift's async-loop syntax. It keeps listening while this view is
    /// on screen and updates state when the user taps an expiry notification.
    private func listenForNotificationTaps() async {
        if let pendingMedicineID = MedicineNotificationRoute.consumePendingMedicineID() {
            openNotificationMedicineDetails(for: pendingMedicineID)
        }

        for await notification in NotificationCenter.default.notifications(named: MedicineNotificationRoute.medicineTapped) {
            guard let medicineID = MedicineNotificationRoute.medicineID(from: notification) else { continue }
            openNotificationMedicineDetails(for: medicineID)
        }
    }

    /// Opens the details popup for the medicine selected from a notification.
    private func openNotificationMedicineDetails(for medicineID: UUID) {
        if store.medicines.contains(where: { $0.id == medicineID }) {
            notificationMedicineID = medicineID
        } else {
            validationMessage = "This medicine is no longer available."
        }
    }

    /// Deletes one medicine and shows any disk-write failure instead of hiding it.
    @discardableResult
    private func deleteMedicine(_ medicine: Medicine) async -> Bool {
        do {
            try await store.delete(medicine)
            validationMessage = nil
            return true
        } catch {
            validationMessage = "Could not delete medicine: \(error.localizedDescription)"
            return false
        }
    }

    /// Friendly banner shown at the top of the form.
    ///
    /// This gives the app a lighter, less default-looking first impression without
    /// changing the form workflow below it.
    private var headerPanel: some View {
        HStack(spacing: 14) {
            Image(systemName: "pills.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(PillEyePalette.coral)

            VStack(alignment: .leading, spacing: 4) {
                Text("Track my Meds")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(PillEyePalette.ink)
                Text("Scan labels, save dates, and let PillEye remind you before expiry.")
                    .font(.subheadline)
                    .foregroundStyle(PillEyePalette.ink.opacity(0.72))
            }
        }
        .padding(.vertical, 10)
    }

    /// Opens the manual date popup and preloads it with the current date value if one exists.
    private func openManualDatePopup(for target: ManualDateTarget) {
        switch target {
        case .manufacturing:
            manualDateDraft = manufacturingDate ?? Date()
        case .expiry:
            manualDateDraft = expiryDate ?? Date()
        }
        manualDateTarget = target
    }

    /// Opens the saved-medicine edit popup.
    ///
    /// The draft mirrors the full medicine even though only the reminder lead is editable today.
    /// That keeps this popup ready for future name/date editing without changing the
    /// save pipeline.
    private func openMedicineEditPopup(for medicine: Medicine) {
        medicineEditDraft = MedicineEditDraft(medicine: medicine)
    }

    /// Center popup used for manually selecting a date.
    ///
    /// This is an overlay instead of a bottom sheet, so it appears in the middle of the
    /// phone and keeps the main screen visible behind a dimmed background.
    private func manualDatePopup(for target: ManualDateTarget) -> some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()
                .onTapGesture {
                    manualDateTarget = nil
                }

            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(target.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(PillEyePalette.deepTeal)
                    Text("Choose a date")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(PillEyePalette.blue)
                }

                DatePicker(
                    target.pickerTitle,
                    selection: $manualDateDraft,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(PillEyePalette.teal)

                HStack(spacing: 12) {
                    Button("Cancel") {
                        manualDateTarget = nil
                    }
                    .buttonStyle(DimensionalButtonStyle(fill: PillEyePalette.blue, prominence: .secondary, minHeight: 40))

                    Button("Okay") {
                        saveManualDate(for: target)
                    }
                    .buttonStyle(DimensionalButtonStyle(fill: PillEyePalette.coral, minHeight: 40))
                }
            }
            .padding(20)
            .frame(maxWidth: 310)
            .background(PillEyePalette.popupBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(PillEyePalette.mint, lineWidth: 2)
            }
            .shadow(color: PillEyePalette.deepTeal.opacity(0.22), radius: 20, x: 0, y: 10)
            .fontDesign(.rounded)
        }
    }

    /// Center popup shown when the user taps an expiry notification.
    ///
    /// It uses the same colors as the main screen and exposes only the two requested
    /// actions: Delete removes this medicine, Cancel closes the popup.
    private func medicineDetailsPopup(for medicine: Medicine) -> some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "pills.circle.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(PillEyePalette.coral)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(medicine.name)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(PillEyePalette.deepTeal)
                        Text(medicine.isExpired ? "Expired medicine" : "Expiry reminder")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PillEyePalette.blue)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    detailRow(title: "Manufacturing", value: medicine.manufacturingDate.formatted(date: .abbreviated, time: .omitted))
                    detailRow(title: "Expiry", value: medicine.expiryDate.formatted(date: .abbreviated, time: .omitted))
                    detailRow(title: "Reminder", value: medicine.reminderDate.formatted(date: .abbreviated, time: .shortened))
                    detailRow(title: "Reminder lead", value: ReminderLeadOption.label(for: medicine.reminderLeadDays))
                }

                HStack(spacing: 12) {
                    Button(role: .destructive) {
                        Task {
                            let didDelete = await deleteMedicine(medicine)
                            if didDelete {
                                notificationMedicineID = nil
                            }
                        }
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DimensionalButtonStyle(fill: PillEyePalette.coral, minHeight: 42))

                    Button {
                        notificationMedicineID = nil
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DimensionalButtonStyle(fill: PillEyePalette.blue, prominence: .secondary, minHeight: 42))
                }
            }
            .padding(20)
            .frame(maxWidth: 330)
            .background(PillEyePalette.popupBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(PillEyePalette.mint, lineWidth: 2)
            }
            .shadow(color: PillEyePalette.deepTeal.opacity(0.22), radius: 20, x: 0, y: 10)
            .fontDesign(.rounded)
        }
    }

    /// Center popup for editing saved medicine settings.
    ///
    /// Name and dates are shown as read-only details. Only the reminder lead can be changed in this
    /// version, then Save writes the update to disk and refreshes the notification.
    private func medicineEditPopup(for draft: MedicineEditDraft) -> some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit Reminder")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(PillEyePalette.deepTeal)
                    Text(draft.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(PillEyePalette.coral)
                }

                VStack(alignment: .leading, spacing: 10) {
                    detailRow(title: "Manufacturing", value: draft.manufacturingDate.formatted(date: .abbreviated, time: .omitted))
                    detailRow(title: "Expiry", value: draft.expiryDate.formatted(date: .abbreviated, time: .omitted))
                }

                Picker("Remind before expiry", selection: Binding(
                    get: { medicineEditDraft?.reminderLeadDays ?? draft.reminderLeadDays },
                    set: { medicineEditDraft?.reminderLeadDays = $0 }
                )) {
                    ForEach(ReminderLeadOption.allDays, id: \.self) { days in
                        Text(ReminderLeadOption.label(for: days)).tag(days)
                    }
                }
                .pickerStyle(.menu)
                .tint(PillEyePalette.teal)

                HStack(spacing: 12) {
                    Button {
                        medicineEditDraft = nil
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DimensionalButtonStyle(fill: PillEyePalette.blue, prominence: .secondary, minHeight: 42))

                    Button {
                        saveMedicineEdit()
                    } label: {
                        Label("Save", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DimensionalButtonStyle(fill: PillEyePalette.coral, minHeight: 42))
                }
            }
            .padding(20)
            .frame(maxWidth: 330)
            .background(PillEyePalette.popupBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(PillEyePalette.mint, lineWidth: 2)
            }
            .shadow(color: PillEyePalette.deepTeal.opacity(0.22), radius: 20, x: 0, y: 10)
            .fontDesign(.rounded)
        }
    }

    /// Saves the edited reminder lead time for an existing medicine.
    private func saveMedicineEdit() {
        guard let medicineEditDraft else { return }

        Task {
            do {
                try await store.update(
                    medicineID: medicineEditDraft.id,
                    changes: MedicineUpdate(reminderLeadDays: medicineEditDraft.reminderLeadDays)
                )
                self.medicineEditDraft = nil
                validationMessage = nil
            } catch {
                validationMessage = error.localizedDescription
            }
        }
    }

    /// One title/value line inside the medicine notification popup.
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PillEyePalette.deepTeal)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PillEyePalette.blue)
                .multilineTextAlignment(.trailing)
        }
    }

    /// Handles the backup file picked in the Files browser.
    ///
    /// When medicines already exist, the import waits for the user to confirm replacing
    /// them. Importing into an empty list proceeds immediately.
    private func handleBackupSelection(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                let data = try readBackupFile(at: url)
                if store.medicines.isEmpty {
                    Task { await importBackup(data) }
                } else {
                    pendingImportData = data
                }
            } catch {
                backupMessage = "Could not read that file. Choose a MedXpiryTracker backup."
            }
        case .failure:
            backupMessage = "Could not open the selected file."
        }
    }

    /// Reads a picked file, which may live outside the app sandbox (iCloud Drive, AirDrop inbox, ...).
    private func readBackupFile(at url: URL) throws -> Data {
        let hasScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try Data(contentsOf: url)
    }

    /// Replaces the saved medicines with the backup contents and reschedules reminders.
    private func importBackup(_ data: Data) async {
        do {
            try await store.importData(data)
            let count = store.medicines.count
            backupMessage = "Imported \(count) medicine\(count == 1 ? "" : "s")."
        } catch {
            backupMessage = "Import failed. That file is not a valid MedXpiryTracker backup."
        }
    }

    /// Saves the manually selected date into the correct field.
    private func saveManualDate(for target: ManualDateTarget) {
        switch target {
        case .manufacturing:
            manufacturingDate = manualDateDraft
            if let expiryDate {
                validationMessage = manualDateDraft < expiryDate ? nil : "Manufacturing date must be before the expiry date."
            } else {
                validationMessage = nil
            }
        case .expiry:
            expiryDate = manualDateDraft
            if let manufacturingDate {
                validationMessage = manualDateDraft > manufacturingDate ? nil : "Expiry date must be after the manufacturing date."
            } else {
                validationMessage = nil
            }
        }
        manualDateTarget = nil
    }

    /// The date currently targeted by the dropdown (manufacturing or expiry).
    private var activeDateValue: Date? {
        switch activeDateField {
        case .manufacturing:
            return manufacturingDate
        case .expiry:
            return expiryDate
        }
    }

    /// A single compact row that captures whichever date the dropdown selects.
    ///
    /// This replaces the previous two full-height rows to save vertical space. A menu
    /// picker chooses the field being set, Set/Scan act on that field, and a summary line
    /// keeps both captured dates visible at once so nothing is hidden by the collapse.
    private var dateEntryRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Date")
                    .fontWeight(.semibold)
                    .foregroundStyle(PillEyePalette.deepTeal)
                Spacer()
                Picker("Date to set", selection: $activeDateField) {
                    Text("Manufacturing").tag(ManualDateTarget.manufacturing)
                    Text("Expiry").tag(ManualDateTarget.expiry)
                }
                .pickerStyle(.menu)
                .tint(PillEyePalette.teal)
                .accessibilityIdentifier("dateFieldPicker")
            }

            HStack {
                Text(activeDateValue?.formatted(date: .abbreviated, time: .omitted) ?? "Not set")
                    .fontWeight(activeDateValue == nil ? .regular : .semibold)
                    .foregroundStyle(activeDateValue == nil ? PillEyePalette.blue.opacity(0.72) : PillEyePalette.deepTeal)
                Spacer()
                Button(activeDateValue == nil ? "Set" : "Change") {
                    openManualDatePopup(for: activeDateField)
                }
                .buttonStyle(DimensionalButtonStyle(fill: PillEyePalette.blue, prominence: .secondary, minHeight: 38))

                Button {
                    scannerMode = activeDateField == .manufacturing ? .manufacturingDate : .expiryDate
                    showingScanner = true
                } label: {
                    Label("Scan", systemImage: "text.viewfinder")
                }
                .buttonStyle(DimensionalButtonStyle(fill: PillEyePalette.teal, prominence: .secondary, minHeight: 38))
            }

            HStack(spacing: 14) {
                dateSummaryChip(title: "Mfg", date: manufacturingDate)
                dateSummaryChip(title: "Exp", date: expiryDate)
            }
        }
    }

    /// A compact "Mfg: … / Exp: …" chip keeping both captured dates visible.
    private func dateSummaryChip(title: String, date: Date?) -> some View {
        HStack(spacing: 4) {
            Text("\(title):")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PillEyePalette.deepTeal)
            Text(date?.formatted(date: .abbreviated, time: .omitted) ?? "—")
                .font(.caption.weight(.medium))
                .foregroundStyle(date == nil ? PillEyePalette.blue.opacity(0.6) : PillEyePalette.blue)
        }
    }

    /// Validates and saves the current form values.
    ///
    /// If the store throws an error, the message is shown in the form instead of saving.
    private func saveMedicine() async {
        validationMessage = nil

        guard let manufacturingDate else {
            validationMessage = "Set the manufacturing date."
            return
        }

        guard let expiryDate else {
            validationMessage = "Set the expiry date."
            return
        }

        do {
            try await store.save(
                name: medicineName,
                manufacturingDate: manufacturingDate,
                expiryDate: expiryDate,
                reminderLeadDays: reminderLeadDays
            )
            resetForm()
        } catch {
            validationMessage = error.localizedDescription
        }
    }

    /// Resets the input form after a successful save.
    private func resetForm() {
        medicineName = ""
        manufacturingDate = nil
        expiryDate = nil
    }

    /// Receives the user's confirmed text selection from the scanner.
    ///
    /// Name scanning returns selected text. Date scanning returns exactly one selected
    /// date string, which is parsed and applied to the correct date field.
    private func applyCapturedTexts(_ texts: [String]) {
        switch scannerMode {
        case .name:
            medicineName = (texts.first ?? "").localizedCapitalized
            validationMessage = nil
        case .manufacturingDate:
            applyScannedManufacturingDate(from: texts.first)
        case .expiryDate:
            applyScannedExpiryDate(from: texts.first)
        }

        showingScanner = false
    }

    /// Parses and applies a scanned manufacturing date.
    private func applyScannedManufacturingDate(from text: String?) {
        guard let text, let date = MedicineDateParser.firstDate(from: text) else {
            validationMessage = "Could not read a valid manufacturing date. You can still edit it manually."
            return
        }

        manufacturingDate = date
        if let expiryDate {
            validationMessage = date < expiryDate ? nil : "Manufacturing date must be before the expiry date."
        } else {
            validationMessage = nil
        }
    }

    /// Parses and applies a scanned expiry date.
    private func applyScannedExpiryDate(from text: String?) {
        guard let text, let date = MedicineDateParser.firstDate(from: text) else {
            validationMessage = "Could not read a valid expiry date. You can still edit it manually."
            return
        }

        expiryDate = date
        if let manufacturingDate {
            validationMessage = date > manufacturingDate ? nil : "Expiry date must be after the manufacturing date."
        } else {
            validationMessage = nil
        }
    }

}

/// Light, friendly colors used by the PillEye interface.
///
/// Grouping colors here keeps styling consistent and easier to change later.
enum PillEyePalette {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.94, green: 0.99, blue: 0.97),
            Color(red: 0.98, green: 0.97, blue: 1.00),
            Color(red: 1.00, green: 0.97, blue: 0.94)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let popupBackground = LinearGradient(
        colors: [
            Color(red: 0.98, green: 1.00, blue: 0.99),
            Color(red: 0.96, green: 0.98, blue: 1.00)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let formRowBackground = Color(red: 0.985, green: 1.00, blue: 0.99)
    static let mint = Color(red: 0.82, green: 0.96, blue: 0.91)
    static let teal = Color(red: 0.00, green: 0.58, blue: 0.58)
    static let deepTeal = Color(red: 0.00, green: 0.36, blue: 0.42)
    static let coral = Color(red: 0.96, green: 0.36, blue: 0.33)
    static let blue = Color(red: 0.25, green: 0.50, blue: 0.92)
    static let ink = Color(red: 0.12, green: 0.18, blue: 0.24)

    // Status colors for the saved-medicines filter: All = green, Expiring = orange,
    // Expired = red. Red reads as an alert color consistent with `coral` warnings.
    static let filterGreen = Color.green
    static let filterOrange = Color.orange
    static let filterRed = Color.red
}

/// Identifies which date field is being edited in the manual date popup.
private enum ManualDateTarget: Hashable, Identifiable {
    case manufacturing
    case expiry

    var id: Self { self }

    var title: String {
        switch self {
        case .manufacturing:
            return "Manufacturing Date"
        case .expiry:
            return "Expiry Date"
        }
    }

    var pickerTitle: String {
        switch self {
        case .manufacturing:
            return "Select manufacturing date"
        case .expiry:
            return "Select expiry date"
        }
    }
}

/// Identifies what kind of text the scanner is currently expected to capture.
private enum ScannerMode {
    case name
    case manufacturingDate
    case expiryDate

    /// Title shown at the top of the scanner sheet.
    var title: String {
        switch self {
        case .name:
            return "Scan Name"
        case .manufacturingDate:
            return "Scan Manufacturing Date"
        case .expiryDate:
            return "Scan Expiry Date"
        }
    }

    /// Short user guidance shown inside the scanner sheet.
    var instructions: String {
        switch self {
        case .name:
            return "Place the medicine name inside the rectangle, tap the best detected text, then press OK."
        case .manufacturingDate:
            return "Place the manufacturing date inside the rectangle. Tap the correct detected date, then press Capture."
        case .expiryDate:
            return "Place the expiry date inside the rectangle. Tap the correct detected date, then press Capture."
        }
    }

    /// Controls whether the scanner should capture general text or one selected date value.
    var captureMode: TextScannerCaptureMode {
        switch self {
        case .name:
            return .manualText
        case .manufacturingDate, .expiryDate:
            return .singleDate
        }
    }
}

/// Draft values used by the saved-medicine edit popup.
///
/// The fields include name and dates even though they are read-only today. If those
/// become editable later, the popup can bind to this same draft and send one
/// `MedicineUpdate` to the store.
private struct MedicineEditDraft: Identifiable {
    let id: UUID
    var name: String
    var manufacturingDate: Date
    var expiryDate: Date
    var reminderLeadDays: Int

    init(medicine: Medicine) {
        id = medicine.id
        name = medicine.name
        manufacturingDate = medicine.manufacturingDate
        expiryDate = medicine.expiryDate
        reminderLeadDays = medicine.reminderLeadDays
    }
}

#Preview {
    ContentView(store: MedicineStore(notificationScheduler: PreviewNotificationScheduler()))
}

/// Fake scheduler used only by the SwiftUI preview.
///
/// This avoids asking for real notification permissions when Xcode renders previews.
private struct PreviewNotificationScheduler: NotificationScheduling {
    func scheduleExpiryReminder(for medicine: Medicine) async throws {}
    func cancelReminder(for medicineID: UUID) async {}
}
