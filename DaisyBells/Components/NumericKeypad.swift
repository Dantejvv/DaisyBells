import SwiftUI
import UIKit

@MainActor
struct NumericKeypad: View {
    enum FieldKind {
        case decimal       // weight, time, distance
        case integer       // reps
        case signedDecimal // bodyweight modifier

        var allowsDecimal: Bool {
            switch self {
            case .decimal, .signedDecimal: return true
            case .integer: return false
            }
        }
        var allowsSign: Bool {
            self == .signedDecimal
        }
    }

    let fieldKind: FieldKind
    let canSameAsLast: Bool
    let canNext: Bool
    @Binding var draft: String
    let onSameAsLast: () -> Void
    let onNext: () -> Void
    let onDone: () -> Void

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    private var canSign: Bool { fieldKind.allowsSign && !draft.isEmpty }
    private var canDecimal: Bool { fieldKind.allowsDecimal && !draft.contains(".") }
    private var canBackspace: Bool { !draft.isEmpty }

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                digitKey("1")
                digitKey("2")
                digitKey("3")
                doneKey
            }
            GridRow {
                digitKey("4")
                digitKey("5")
                digitKey("6")
                sameAsLastKey
            }
            GridRow {
                digitKey("7")
                digitKey("8")
                digitKey("9")
                nextKey
            }
            GridRow {
                signKey
                digitKey("0")
                decimalKey
                backspaceKey
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.bgPrimary)
    }

    // MARK: - Keys

    private func digitKey(_ digit: String) -> some View {
        KeypadKey(
            label: digit,
            style: .number,
            isEnabled: true,
            action: {
                haptic.impactOccurred()
                draft.append(digit)
            }
        )
    }

    private var signKey: some View {
        KeypadKey(
            label: "±",
            style: .utility,
            isEnabled: canSign,
            action: {
                haptic.impactOccurred()
                if draft.hasPrefix("-") {
                    draft = String(draft.dropFirst())
                } else if !draft.isEmpty {
                    draft = "-" + draft
                }
            }
        )
    }

    private var decimalKey: some View {
        KeypadKey(
            label: ".",
            style: .utility,
            isEnabled: canDecimal,
            action: {
                haptic.impactOccurred()
                draft.append(".")
            }
        )
    }

    private var backspaceKey: some View {
        KeypadKey(
            label: nil,
            systemImage: "delete.left",
            style: .utility,
            isEnabled: canBackspace,
            action: {
                haptic.impactOccurred()
                if !draft.isEmpty { draft.removeLast() }
            },
            longPressAction: {
                haptic.impactOccurred()
                draft = ""
            }
        )
    }

    private var sameAsLastKey: some View {
        KeypadKey(
            label: "Same as\nlast set",
            style: .utility,
            isEnabled: canSameAsLast,
            action: {
                haptic.impactOccurred()
                onSameAsLast()
            }
        )
    }

    private var nextKey: some View {
        KeypadKey(
            label: "Next",
            systemImage: "arrow.down",
            style: .utility,
            isEnabled: canNext,
            action: {
                haptic.impactOccurred()
                onNext()
            }
        )
    }

    private var doneKey: some View {
        KeypadKey(
            label: "Done",
            style: .primary,
            isEnabled: true,
            action: {
                haptic.impactOccurred()
                onDone()
            }
        )
    }
}

// MARK: - Key

private struct KeypadKey: View {
    enum Style { case number, utility, primary }

    let label: String?
    var systemImage: String? = nil
    let style: Style
    let isEnabled: Bool
    let action: () -> Void
    var longPressAction: (() -> Void)? = nil

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: .radiusSm))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.3)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4)
                .onEnded { _ in
                    if isEnabled, let longPressAction { longPressAction() }
                }
        )
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 2) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(foreground)
            }
            if let label {
                Text(label)
                    .font(font)
                    .foregroundStyle(foreground)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 4)
    }

    private var font: Font {
        switch style {
        case .number: return .system(size: 24, weight: .regular)
        case .utility: return .system(size: 13, weight: .medium)
        case .primary: return .system(size: 16, weight: .semibold)
        }
    }

    private var foreground: Color {
        switch style {
        case .number: return Color.textPrimary
        case .utility: return Color.textPrimary
        case .primary: return Color.bgPrimary
        }
    }

    private var background: Color {
        switch style {
        case .number: return Color.bgCardHover
        case .utility: return Color.bgCard
        case .primary: return Color.accent
        }
    }
}

#Preview {
    @Previewable @State var draft = ""
    return VStack {
        Spacer()
        Text("Draft: \(draft.isEmpty ? "(empty)" : draft)")
            .foregroundStyle(Color.textPrimary)
        NumericKeypad(
            fieldKind: .signedDecimal,
            canSameAsLast: true,
            canNext: true,
            draft: $draft,
            onSameAsLast: { draft = "135" },
            onNext: {},
            onDone: {}
        )
    }
    .background(Color.bgPrimary)
}
