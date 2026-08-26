import SwiftUI

/// The expiry-status filter applied to the saved-medicines list.
///
/// `All` shows every medicine, `expiring` shows medicines that have not yet expired and
/// expire within the next `Medicine.expiringSoonWindowDays` days, and `expired` shows
/// medicines whose expiry date has already passed. The raw values are used as stable
/// identifiers in the picker.
enum MedicineFilter: String, CaseIterable, Identifiable {
    case all
    case expiring
    case expired

    var id: String { rawValue }

    /// User-facing label for the filter option.
    var label: String {
        switch self {
        case .all:
            return "All"
        case .expiring:
            return "Expiring"
        case .expired:
            return "Expired"
        }
    }

    /// Accessibility identifier for the filter option's tappable control.
    var accessibilityIdentifier: String {
        switch self {
        case .all:
            return "filterAll"
        case .expiring:
            return "filterExpiring"
        case .expired:
            return "filterExpired"
        }
    }

    /// The label color for this filter: All = green, Expiring = orange, Expired = red.
    var color: Color {
        switch self {
        case .all:
            return PillEyePalette.filterGreen
        case .expiring:
            return PillEyePalette.filterOrange
        case .expired:
            return PillEyePalette.filterRed
        }
    }

    /// Returns `true` when the given medicine belongs in this filter.
    func includes(_ medicine: Medicine) -> Bool {
        switch self {
        case .all:
            return true
        case .expiring:
            return medicine.isExpiringSoon()
        case .expired:
            return medicine.isExpired
        }
    }
}

/// Popup listing saved medicines with a three-way expiry-status filter.
///
/// Presented as a sheet because the list is scrollable and needs swipe actions for
/// edit and delete. Styling mirrors the app's other popups (rounded font, palette
/// colors, mint accents).
struct SavedMedicinesView: View {
    let store: MedicineStore
    /// Called when the user chooses to edit a medicine; the parent opens its edit popup.
    let onEdit: (Medicine) -> Void
    /// Called when the user deletes a medicine; the parent forwards this to the store.
    let onDelete: (Medicine) async -> Void
    let onClose: () -> Void

    @State private var filter: MedicineFilter = .expiring

    /// Medicines matching the currently selected filter.
    private var filteredMedicines: [Medicine] {
        store.medicines.filter { filter.includes($0) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterPicker
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                listContent
            }
            .background(PillEyePalette.background)
            .navigationTitle("Saved Medicines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onClose)
                        .accessibilityIdentifier("savedMedicinesDoneButton")
                }
            }
            .toolbarBackground(PillEyePalette.mint, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
        }
        .fontDesign(.rounded)
        .tint(PillEyePalette.teal)
        .environment(\.colorScheme, .light)
        .preferredColorScheme(.light)
    }

    /// The three radio-style filter options, each tinted by its status color.
    private var filterPicker: some View {
        HStack(spacing: 10) {
            ForEach(MedicineFilter.allCases) { option in
                Button {
                    filter = option
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: filter == option ? "largecircle.fill.circle" : "circle")
                        Text(option.label)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(option.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(filter == option ? option.color.opacity(0.14) : Color.white.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(option.color.opacity(filter == option ? 0.9 : 0.35), lineWidth: filter == option ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(option.accessibilityIdentifier)
                .accessibilityAddTraits(filter == option ? [.isSelected] : [])
            }
        }
    }

    /// The list, the empty-store state, or the empty-filter state.
    @ViewBuilder
    private var listContent: some View {
        if store.medicines.isEmpty {
            ContentUnavailableView(
                "No medicines saved",
                systemImage: "pills",
                description: Text("Add medicine details on the main screen to schedule an expiry reminder.")
            )
            .accessibilityIdentifier("savedMedicinesEmptyState")
        } else if filteredMedicines.isEmpty {
            ContentUnavailableView(
                "Nothing here",
                systemImage: "line.3.horizontal.decrease.circle",
                description: Text("No medicines match the \(filter.label) filter.")
            )
            .accessibilityIdentifier("savedMedicinesNoMatches")
        } else {
            List {
                ForEach(filteredMedicines) { medicine in
                    MedicineRow(medicine: medicine)
                        .listRowBackground(PillEyePalette.formRowBackground)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await onDelete(medicine) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                onEdit(medicine)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(PillEyePalette.blue)
                        }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }
}

/// One row in the saved medicines list.
///
/// The medicine name is tinted by its own status: expired = red, expiring within 60 days =
/// orange, otherwise green — matching the filter categories so colors stay consistent under "All".
struct MedicineRow: View {
    let medicine: Medicine

    /// Status color for the medicine name, matching the three filter categories.
    private var nameColor: Color {
        if medicine.isExpired {
            return PillEyePalette.filterRed
        }
        if medicine.isExpiringSoon() {
            return PillEyePalette.filterOrange
        }
        return PillEyePalette.filterGreen
    }

    /// Shows the medicine name, dates, reminder time, and expired status.
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(medicine.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(nameColor)
                Spacer()
                if medicine.isExpired {
                    Text("Expired")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PillEyePalette.filterRed)
                }
            }

            Text("Mfg: \(medicine.manufacturingDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(PillEyePalette.blue)
            Text("Exp: \(medicine.expiryDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(PillEyePalette.blue)
            Text("Reminder: \(medicine.reminderDate.formatted(date: .abbreviated, time: .shortened)) (\(ReminderLeadOption.label(for: medicine.reminderLeadDays)) before expiry)")
                .font(.caption.weight(.medium))
                .foregroundStyle(PillEyePalette.deepTeal)
        }
        .padding(.vertical, 6)
    }
}
