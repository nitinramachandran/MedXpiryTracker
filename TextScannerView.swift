import SwiftUI

#if os(iOS) && canImport(VisionKit)
import AVFoundation
import VisionKit

/// Controls how the scanner should treat recognized camera text.
///
/// Name capture is manual because the user should choose the best medicine name.
/// It shows only short same-row candidates and ignores sentence-like OCR results.
/// Single-date capture shows only date-like values and requires the user to tap one.
enum TextScannerCaptureMode {
    case manualText
    case singleDate

    /// Text shown on the bottom-middle confirmation button.
    var confirmButtonTitle: String {
        switch self {
        case .manualText:
            return "OK"
        case .singleDate:
            return "Capture"
        }
    }
}

/// User-friendly scanner screen shown inside the sheet.
///
/// The camera is displayed inside a rectangular area so users can aim at only the useful
/// label text. For medicine names, the user selects the right text. For dates, the scanner
/// automatically filters OCR output down to date-like values only.
struct TextScannerView: View {
    let title: String
    let instructions: String
    let captureMode: TextScannerCaptureMode
    let onConfirm: ([String]) -> Void
    let onClose: () -> Void

    @State private var detectedTexts: [String] = []
    @State private var capturedTexts: [String] = []
    @State private var selectedDateText: String?
    @State private var selectedDateIsValid = false

    /// First detected name candidate. Live OCR sends larger text first, so this is the
    /// best guess for the medicine name.
    private var suggestedName: String? {
        detectedTexts.first
    }

    /// The values that will be sent back to `ContentView` when the user taps the bottom button.
    private var confirmableTexts: [String] {
        switch captureMode {
        case .manualText:
            return capturedTexts
        case .singleDate:
            return selectedDateText.map { [$0] } ?? []
        }
    }

    /// Whether the bottom confirmation button should be enabled.
    private var canConfirm: Bool {
        switch captureMode {
        case .manualText: return !capturedTexts.isEmpty
        case .singleDate: return selectedDateIsValid
        }
    }

    /// Builds the scanner screen with camera, detected values, and bottom actions.
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(ScannerPalette.ink)
                Text(instructions)
                    .font(.subheadline)
                    .foregroundStyle(ScannerPalette.ink.opacity(0.68))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ScannerCameraView(
                onTextTapped: handleTappedText,
                onDetectedTextsChanged: updateDetectedTexts
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(4 / 3, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white, lineWidth: 3)
                    .shadow(radius: 4)
            }
            .overlay(alignment: .bottom) {
                Text("Keep label text inside this box")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.bottom, 10)
            }

            textSelectionArea

            Spacer(minLength: 0)

            HStack(spacing: 14) {
                Button("Cancel", action: onClose)
                    .buttonStyle(DimensionalButtonStyle(fill: ScannerPalette.blue, prominence: .secondary, minHeight: 42))

                Button {
                    onConfirm(confirmableTexts)
                } label: {
                    Text(captureMode.confirmButtonTitle)
                        .frame(minWidth: 140)
                }
                .buttonStyle(DimensionalButtonStyle(fill: ScannerPalette.coral, minHeight: 42))
                .disabled(!canConfirm)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
        }
        .padding()
        .fontDesign(.rounded)
        .environment(\.colorScheme, .light)
        .background(ScannerPalette.background)
        .preferredColorScheme(.light)
        .onChange(of: selectedDateText) { _, newValue in
            selectedDateIsValid = newValue.map { MedicineDateParser.firstDate(from: $0) != nil } ?? false
        }
    }

    /// Shows either manual text selection or automatic date detection, depending on mode.
    @ViewBuilder
    private var textSelectionArea: some View {
        switch captureMode {
        case .manualText:
            manualTextSelectionArea
        case .singleDate:
            singleDateCaptureArea
        }
    }

    /// UI for selecting a medicine name from detected OCR text.
    private var manualTextSelectionArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !detectedTexts.isEmpty {
                    Text("Suggested name")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ScannerPalette.ink)

                VStack(alignment: .leading, spacing: 8) {
                    if let suggestedName {
                        Button {
                            addCapturedText(suggestedName)
                        } label: {
                            Label(suggestedName, systemImage: "text.magnifyingglass")
                                .font(.headline.weight(.bold))
                        }
                        .buttonStyle(DimensionalButtonStyle(fill: ScannerPalette.teal, minHeight: 42))
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(detectedTexts, id: \.self) { text in
                                Button {
                                    addCapturedText(text)
                                } label: {
                                    Text(text)
                                        .lineLimit(1)
                                }
                                .buttonStyle(DimensionalButtonStyle(fill: ScannerPalette.blue, prominence: .secondary, minHeight: 36))
                            }
                        }
                    }
                }
            }

            Text("Captured values")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ScannerPalette.ink)

            if capturedTexts.isEmpty {
                Text("Point at the biggest/boldest medicine name, then tap the suggestion or highlighted text.")
                    .font(.footnote)
                    .foregroundStyle(ScannerPalette.ink.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                capturedTextList
            }
        }
    }

    /// UI for selecting one date from detected OCR date values.
    private var singleDateCaptureArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected dates")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ScannerPalette.ink)

            if detectedTexts.isEmpty {
                Text("No dates detected yet. Hold the date inside the box.")
                    .font(.footnote)
                    .foregroundStyle(ScannerPalette.ink.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(detectedTexts, id: \.self) { text in
                            Button {
                                selectedDateText = text
                            } label: {
                                HStack(spacing: 6) {
                                    if selectedDateText == text {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                    Text(text)
                                        .font(.body.monospacedDigit())
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(DimensionalButtonStyle(
                                fill: selectedDateText == text ? ScannerPalette.teal : ScannerPalette.blue,
                                prominence: selectedDateText == text ? .primary : .secondary,
                                minHeight: 38
                            ))
                        }
                    }
                }

                if selectedDateText == nil {
                    Label("Tap the correct date, then press Capture.", systemImage: "hand.tap.fill")
                        .font(.footnote)
                        .foregroundStyle(ScannerPalette.ink.opacity(0.6))
                } else if canConfirm {
                    Label("Selected date is valid.", systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(ScannerPalette.teal)
                }
            }
        }
    }

    /// List of manually captured text values with remove buttons.
    private var capturedTextList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(capturedTexts, id: \.self) { text in
                    HStack {
                        Text(text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)

                        Button {
                            removeCapturedText(text)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(ScannerPalette.ink.opacity(0.6))
                        .accessibilityLabel("Remove \(text)")
                    }
                    .padding(10)
                    .background(ScannerPalette.mint.opacity(0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .frame(maxHeight: 140)
    }

    /// Updates detected values from the camera.
    ///
    /// Name mode filters raw OCR down to short medicine-name candidates, so sentences from the
    /// medicine label are ignored.
    /// Date mode filters the raw OCR strings down to date-like values only before showing
    /// them, so unrelated medicine text cannot be captured into the date fields.
    private func updateDetectedTexts(_ texts: [String]) {
        switch captureMode {
        case .manualText:
            detectedTexts = MedicineNameParser.candidates(from: texts)
        case .singleDate:
            let dates = dateValues(from: texts)
            detectedTexts = dates
            if let selectedDateText, !dates.contains(selectedDateText) {
                self.selectedDateText = nil
            }
        }
    }

    /// Handles text tapped inside VisionKit's camera highlight layer.
    ///
    /// In date mode this updates detected dates automatically instead of manually adding
    /// arbitrary text to the captured list.
    private func handleTappedText(_ text: String) {
        switch captureMode {
        case .manualText:
            if let candidate = MedicineNameParser.candidate(from: text) {
                addCapturedText(candidate)
            }
        case .singleDate:
            let dates = dateValues(from: [text])
            if let firstDate = dates.first {
                detectedTexts = dates
                selectedDateText = firstDate
            }
        }
    }

    /// Adds a recognized text value if it is not blank or already selected.
    private func addCapturedText(_ text: String) {
        let cleaned = cleanedText(text)
        guard !cleaned.isEmpty, !capturedTexts.contains(cleaned) else { return }
        capturedTexts.append(cleaned)
    }

    /// Removes one selected value from the captured list.
    private func removeCapturedText(_ text: String) {
        capturedTexts.removeAll { $0 == text }
    }

    /// Extracts unique date strings from OCR text.
    private func dateValues(from texts: [String]) -> [String] {
        var seen: Set<String> = []
        var dates: [String] = []

        for text in texts {
            for date in MedicineDateParser.extractDateStrings(from: text) {
                guard !seen.contains(date) else { continue }
                seen.insert(date)
                dates.append(date)
            }
        }

        return dates
    }

    /// Normalizes camera text before showing it to the user.
    private func cleanedText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// SwiftUI wrapper around the UIKit camera scanner.
///
/// `DataScannerViewController` is a UIKit view controller, not a native SwiftUI view.
/// `UIViewControllerRepresentable` is the bridge that lets SwiftUI display UIKit screens.
private struct ScannerCameraView: UIViewControllerRepresentable {
    let onTextTapped: (String) -> Void
    let onDetectedTextsChanged: ([String]) -> Void

    /// Creates the UIKit controller that SwiftUI embeds inside the rectangular camera area.
    func makeUIViewController(context: Context) -> UIViewController {
        ScannerHostViewController(
            delegate: context.coordinator,
            onDetectedTextsChanged: onDetectedTextsChanged
        )
    }

    /// Updates the UIKit controller when SwiftUI state changes.
    ///
    /// This scanner does not need update logic because all setup happens in the host controller.
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    /// Creates the coordinator object that receives callbacks from VisionKit.
    ///
    /// A coordinator is similar to an adapter/listener object in Java UI frameworks.
    func makeCoordinator() -> Coordinator {
        Coordinator(onTextTapped: onTextTapped)
    }

    /// Receives VisionKit scanner events and forwards useful text back to SwiftUI.
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onTextTapped: (String) -> Void

        /// Stores the callback that should run when the user taps recognized text.
        init(onTextTapped: @escaping (String) -> Void) {
            self.onTextTapped = onTextTapped
        }

        /// Runs when the user taps a recognized item in the camera view.
        ///
        /// VisionKit can recognize different item types. This app only uses `.text`.
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            if case let .text(text) = item {
                onTextTapped(text.transcript)
            }
        }
    }
}

/// Owns the actual camera scanner and camera-permission flow.
///
/// Keeping this in a UIKit controller makes it easier to embed VisionKit cleanly and
/// show clear fallback messages when permission or device support is missing.
private final class ScannerHostViewController: UIViewController {
    private weak var scannerDelegate: DataScannerViewControllerDelegate?
    private let onDetectedTextsChanged: ([String]) -> Void
    private var scanner: DataScannerViewController?
    private var recognizedItemsTask: Task<Void, Never>?
    private var lastDetectedTexts: [String] = []
    private var lastDetectedUpdate = Date.distantPast

    /// Creates the scanner host with a delegate and live detected-text callback.
    init(
        delegate: DataScannerViewControllerDelegate,
        onDetectedTextsChanged: @escaping ([String]) -> Void
    ) {
        self.scannerDelegate = delegate
        self.onDetectedTextsChanged = onDetectedTextsChanged
        super.init(nibName: nil, bundle: nil)
    }

    /// Required by UIKit for storyboard-based creation.
    ///
    /// This app creates the controller in code, so this initializer should never run.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        recognizedItemsTask?.cancel()
    }

    /// Runs after UIKit has loaded the controller's root view.
    ///
    /// We use it to show an initial message and then start the camera-permission checks.
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        showStatus("Preparing camera...")
        configureCameraAccess()
    }

    /// Stops scanning when the embedded camera view is removed.
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scanner?.stopScanning()
        recognizedItemsTask?.cancel()
    }

    /// Checks the app's camera setup and requests permission if needed.
    ///
    /// The app must have `NSCameraUsageDescription` in its Info settings or iOS will not
    /// allow camera access. After permission is granted, this method starts the scanner.
    private func configureCameraAccess() {
        guard Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil else {
            showUnavailable(
                "Camera permission text is missing. Add Privacy - Camera Usage Description to the app target Info settings, then reinstall the app."
            )
            return
        }

        guard DataScannerViewController.isSupported else {
            showUnavailable("Live text scanning is not supported on this device.")
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startScanner()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor [weak self] in
                    if granted {
                        self?.startScanner()
                    } else {
                        self?.showUnavailable("Camera access was denied. Enable it in Settings to scan medicine labels.")
                    }
                }
            }
        case .denied, .restricted:
            showUnavailable("Camera access is disabled. Enable it in Settings to scan medicine labels.")
        @unknown default:
            showUnavailable("Camera access is unavailable on this device.")
        }
    }

    /// Creates and starts VisionKit's live text scanner.
    ///
    /// The scanner fills this controller's rectangular view and highlights text the camera can read.
    private func startScanner() {
        guard DataScannerViewController.isAvailable else {
            showUnavailable("Text scanning is currently unavailable. Check Camera permission and device restrictions.")
            return
        }

        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = scannerDelegate
        self.scanner = scanner

        addChild(scanner)
        scanner.view.translatesAutoresizingMaskIntoConstraints = false
        view.subviews.forEach { $0.removeFromSuperview() }
        view.addSubview(scanner.view)
        NSLayoutConstraint.activate([
            scanner.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scanner.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scanner.view.topAnchor.constraint(equalTo: view.topAnchor),
            scanner.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        scanner.didMove(toParent: self)

        do {
            try scanner.startScanning()
            observeRecognizedItems(from: scanner)
        } catch {
            showUnavailable("Could not start camera scanning. Try closing and reopening the scanner.")
        }
    }

    /// Watches VisionKit's live recognized text stream and sends readable strings to SwiftUI.
    private func observeRecognizedItems(from scanner: DataScannerViewController) {
        recognizedItemsTask?.cancel()
        recognizedItemsTask = Task { @MainActor [weak self, weak scanner] in
            guard let scanner else { return }
            for await items in scanner.recognizedItems {
                let texts = Self.texts(from: items)
                self?.publishDetectedTextsIfNeeded(texts)
            }
        }
    }

    /// Publishes detected text to SwiftUI only when useful.
    ///
    /// VisionKit updates very frequently while focusing. Updating SwiftUI on every camera
    /// frame makes the text area look like it is constantly refreshing, so this method
    /// ignores duplicate updates, throttles rapid changes, and keeps the previous useful
    /// result when the camera briefly reports no text.
    private func publishDetectedTextsIfNeeded(_ texts: [String]) {
        guard !texts.isEmpty else { return }
        guard texts != lastDetectedTexts else { return }

        let now = Date()
        guard now.timeIntervalSince(lastDetectedUpdate) > 0.6 else { return }

        lastDetectedTexts = texts
        lastDetectedUpdate = now
        onDetectedTextsChanged(texts)
    }

    /// Pulls unique text transcripts out of VisionKit recognized items.
    ///
    /// Larger text is a useful clue for medicine-name labels, so recognized items are
    /// sorted by their on-screen area before their transcripts are sent to SwiftUI.
    private static func texts(from items: [RecognizedItem]) -> [String] {
        var seen: Set<String> = []
        var results: [String] = []

        for item in items.sorted(by: { textArea(for: $0) > textArea(for: $1) }) {
            guard case let .text(text) = item else { continue }
            let transcript = text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !transcript.isEmpty, !seen.contains(transcript) else { continue }
            seen.insert(transcript)
            results.append(transcript)
        }

        return results
    }

    /// Approximates how visually large a recognized item is in the camera view.
    ///
    /// VisionKit gives four corners instead of a simple rectangle. Multiplying the top
    /// edge width by the left edge height gives a stable enough area for ranking labels.
    private static func textArea(for item: RecognizedItem) -> CGFloat {
        guard case let .text(text) = item else { return 0 }

        let bounds = text.bounds
        let width = hypot(bounds.topRight.x - bounds.topLeft.x, bounds.topRight.y - bounds.topLeft.y)
        let height = hypot(bounds.bottomLeft.x - bounds.topLeft.x, bounds.bottomLeft.y - bounds.topLeft.y)
        return width * height
    }

    private func showStatus(_ message: String) {
        showMessage(message)
    }

    private func showUnavailable(_ message: String) {
        showMessage(message)
    }

    private func showMessage(_ message: String) {
        view.subviews.forEach { $0.removeFromSuperview() }

        let label = UILabel()
        label.text = message
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .footnote)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
/// Light scanner-sheet colors that match the main PillEye screen.
private enum ScannerPalette {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.94, green: 0.99, blue: 0.97),
            Color(red: 0.98, green: 0.97, blue: 1.00)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let mint = PillEyePalette.mint
    static let teal = PillEyePalette.teal
    static let coral = PillEyePalette.coral
    static let blue = PillEyePalette.blue
    static let ink = PillEyePalette.ink
}
#else
/// Fallback scanner view for platforms where VisionKit is not available.
struct TextScannerView: View {
    let title: String
    let instructions: String
    let captureMode: TextScannerCaptureMode
    let onConfirm: ([String]) -> Void
    let onClose: () -> Void

    /// Shows a simple unsupported-platform message.
    var body: some View {
        VStack(spacing: 16) {
            Text("Camera text scanning is only available on supported iOS devices.")
                .multilineTextAlignment(.center)
            Button("Close", action: onClose)
                .buttonStyle(DimensionalButtonStyle(fill: .blue, minHeight: 42))
        }
        .padding()
    }
}
#endif
