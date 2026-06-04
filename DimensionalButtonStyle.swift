import SwiftUI

/// Reusable 3D-style button treatment for PillEye.
///
/// The style adds depth with a subtle gradient, top highlight, border, shadow, and
/// animated tap feedback. Keeping this in one place makes the app's buttons look consistent.
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

        private var backgroundGradient: LinearGradient {
            switch prominence {
            case .primary:
                LinearGradient(
                    colors: [fill.opacity(isEnabled ? 0.95 : 0.36), fill.opacity(isEnabled ? 0.78 : 0.24)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .secondary:
                LinearGradient(
                    colors: [Color.white.opacity(isEnabled ? 0.95 : 0.58), fill.opacity(isEnabled ? 0.18 : 0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }

        private var textColor: Color {
            switch prominence {
            case .primary:
                return foreground.opacity(isEnabled ? 1.0 : 0.62)
            case .secondary:
                return fill.opacity(isEnabled ? 1.0 : 0.52)
            }
        }

        /// Extra visual feedback while the user's finger is down.
        private var pressedOverlayOpacity: Double {
            configuration.isPressed && isEnabled ? 0.16 : 0.0
        }

        var body: some View {
            configuration.label
                .font(.body.weight(.semibold))
                .foregroundStyle(textColor)
                .padding(.horizontal, 15)
                .frame(minHeight: minHeight)
                .background(backgroundGradient, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color.white.opacity(isEnabled ? 0.58 : 0.22), lineWidth: 1)
                        .frame(height: minHeight / 2)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(fill.opacity(isEnabled ? 0.42 : 0.16), lineWidth: 1)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Color.white.opacity(pressedOverlayOpacity))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(
                            fill.opacity(configuration.isPressed && isEnabled ? 0.86 : 0.0),
                            lineWidth: configuration.isPressed ? 2 : 0
                        )
                        .shadow(
                            color: fill.opacity(configuration.isPressed && isEnabled ? 0.42 : 0.0),
                            radius: configuration.isPressed ? 10 : 0,
                            x: 0,
                            y: 0
                        )
                }
                .shadow(
                    color: fill.opacity(isEnabled ? (configuration.isPressed ? 0.16 : 0.30) : 0.06),
                    radius: configuration.isPressed ? 3 : 8,
                    x: 0,
                    y: configuration.isPressed ? 2 : 5
                )
                .brightness(configuration.isPressed && isEnabled ? 0.04 : 0)
                .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
                .offset(y: configuration.isPressed ? 2 : 0)
                .animation(.spring(response: 0.20, dampingFraction: 0.58), value: configuration.isPressed)
        }
    }
}
