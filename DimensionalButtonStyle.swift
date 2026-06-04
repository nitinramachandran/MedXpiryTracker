import SwiftUI

/// Reusable raised button treatment for PillEye.
///
/// The style adds professional depth with a restrained gradient, crisp border, soft
/// shadow, and clear press feedback. Keeping this in one place makes the app's buttons
/// look consistent across forms, popups, and scanner screens.
struct DimensionalButtonStyle: ButtonStyle {
    enum Prominence {
        case primary
        case secondary
    }

    let fill: Color
    var foreground: Color = .white
    var prominence: Prominence = .primary
    var minHeight: CGFloat = 42

    func makeBody(configuration: Configuration) -> some View {
        DimensionalButton(
            configuration: configuration,
            fill: fill,
            foreground: foreground,
            prominence: prominence,
            minHeight: minHeight
        )
    }

    private struct DimensionalButton: View {
        @Environment(\.isEnabled) private var isEnabled

        let configuration: Configuration
        let fill: Color
        let foreground: Color
        let prominence: Prominence
        let minHeight: CGFloat

        private let cornerRadius: CGFloat = 12

        private var backgroundGradient: LinearGradient {
            switch prominence {
            case .primary:
                LinearGradient(
                    colors: [
                        fill.opacity(isEnabled ? 0.98 : 0.35),
                        fill.opacity(isEnabled ? 0.86 : 0.24)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .secondary:
                LinearGradient(
                    colors: [
                        Color.white.opacity(isEnabled ? 0.96 : 0.55),
                        fill.opacity(isEnabled ? 0.16 : 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }

        private var textColor: Color {
            switch prominence {
            case .primary:
                return foreground.opacity(isEnabled ? 1.0 : 0.60)
            case .secondary:
                return fill.opacity(isEnabled ? 0.95 : 0.46)
            }
        }

        private var borderColor: Color {
            switch prominence {
            case .primary:
                return fill.opacity(isEnabled ? 0.62 : 0.18)
            case .secondary:
                return fill.opacity(isEnabled ? 0.42 : 0.14)
            }
        }

        private var pressOverlay: Color {
            switch prominence {
            case .primary:
                return Color.black.opacity(configuration.isPressed && isEnabled ? 0.08 : 0.0)
            case .secondary:
                return fill.opacity(configuration.isPressed && isEnabled ? 0.12 : 0.0)
            }
        }

        var body: some View {
            configuration.label
                .font(.body.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .foregroundStyle(textColor)
                .padding(.horizontal, 15)
                .frame(minHeight: minHeight)
                .background(backgroundGradient, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.white.opacity(isEnabled && !configuration.isPressed ? 0.28 : 0.12))
                        .frame(height: 1)
                        .padding(.horizontal, 14)
                        .padding(.top, 1)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(pressOverlay)
                }
                .shadow(
                    color: fill.opacity(isEnabled ? (configuration.isPressed ? 0.12 : 0.22) : 0.04),
                    radius: configuration.isPressed ? 2 : 6,
                    x: 0,
                    y: configuration.isPressed ? 1 : 4
                )
                .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                .offset(y: configuration.isPressed ? 1 : 0)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
}
