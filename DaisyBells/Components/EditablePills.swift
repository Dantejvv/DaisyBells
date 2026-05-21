import SwiftUI
import UIKit

struct PillTextField: View {
    let value: Double?
    let placeholder: String
    let field: FocusedSetField
    @Binding var focusedField: FocusedSetField?
    var fieldKind: NumericKeypad.FieldKind = .decimal
    let previousValue: Double?
    /// Resolves the next field at Next-tap time. Passed in as a closure
    /// (rather than read from @Environment) so PillTextField has no observation
    /// dependency on the coordinator. Observing the @Observable coordinator
    /// here would feed a SwiftUI AttributeGraph cycle with the keypad's
    /// hosted view tree.
    let resolveNextField: (FocusedSetField) -> FocusedSetField?
    let onCommit: (Double?) -> Void

    @State private var draft: String = ""
    @State private var isFocusedBridge: Bool = false

    private static func format(_ value: Double?) -> String {
        value.map { String(format: "%g", $0) } ?? ""
    }

    private var isFocused: Bool {
        focusedField == field
    }

    private func isAllowed(_ ch: Character) -> Bool {
        switch fieldKind {
        case .integer: return ch.isNumber
        case .decimal: return ch.isNumber || ch == "."
        case .signedDecimal: return ch.isNumber || ch == "." || ch == "-"
        }
    }

    private var accessibilityLabelText: String {
        switch field {
        case .weight: return "Weight"
        case .reps: return "Reps"
        case .bodyweightModifier: return "Bodyweight modifier"
        case .time: return "Time in seconds"
        case .distance: return "Distance"
        }
    }

    var body: some View {
        InputViewTextField(
            text: $draft,
            isFocused: $isFocusedBridge,
            placeholder: placeholder,
            textAlignment: .center,
            font: .systemFont(ofSize: 13),
            textColor: UIColor(Color.textPrimary),
            placeholderColor: UIColor(Color.textTertiary),
            keypad: {
                // canNext is always true here; if no next field exists when
                // the user taps Next the resolver returns nil and we dismiss.
                // Reading coordinator.hasNext(of:) here would observe the
                // @Observable coordinator from inside the hosted SwiftUI
                // subtree and feed an AttributeGraph cycle.
                NumericKeypad(
                    fieldKind: fieldKind,
                    canSameAsLast: previousValue != nil,
                    canNext: true,
                    draft: $draft,
                    onSameAsLast: {
                        if let prev = previousValue {
                            draft = Self.format(prev)
                        }
                    },
                    onNext: {
                        // Order matters: drop our own focus flag before the
                        // commit so the parent re-render triggered by
                        // onCommit sees `isFocused == false` and doesn't
                        // re-call becomeFirstResponder in updateUIView.
                        if let next = resolveNextField(field) {
                            isFocusedBridge = false
                            onCommit(Double(draft))
                            focusedField = next
                        } else {
                            isFocusedBridge = false
                            onCommit(Double(draft))
                            focusedField = nil
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil, from: nil, for: nil
                            )
                        }
                    },
                    onDone: {
                        isFocusedBridge = false
                        onCommit(Double(draft))
                        focusedField = nil
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                )
            }
        )
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityValue(draft.isEmpty ? "Empty" : draft)
        .onAppear {
            if draft.isEmpty {
                draft = Self.format(value)
            }
        }
        .onChange(of: draft) { _, newValue in
            let cleaned = String(newValue.filter(isAllowed))
            if cleaned != newValue {
                draft = cleaned
            }
        }
        .onChange(of: focusedField) { oldValue, newValue in
            let wasFocused = oldValue == field
            let nowFocused = newValue == field
            if wasFocused && !nowFocused {
                onCommit(Double(draft))
            }
            // Drive UIKit responder from the shared focus state.
            isFocusedBridge = nowFocused
        }
        .onChange(of: isFocusedBridge) { _, nowFocused in
            // UIKit responder gained/lost focus on its own (e.g. user tapped a pill).
            // Write back into the shared focus state so other pills resign.
            if nowFocused && focusedField != field {
                focusedField = field
            } else if !nowFocused && focusedField == field {
                focusedField = nil
            }
        }
        .onChange(of: value) { _, newValue in
            let formatted = Self.format(newValue)
            if !isFocused && draft != formatted {
                draft = formatted
            }
        }
    }
}

struct EditableDualPill: View {
    let leftValue: Double?
    let rightValue: Double?
    let leftPlaceholder: String
    let rightPlaceholder: String
    let leftField: FocusedSetField
    let rightField: FocusedSetField
    @Binding var focusedField: FocusedSetField?
    var leftFieldKind: NumericKeypad.FieldKind = .decimal
    var rightFieldKind: NumericKeypad.FieldKind = .decimal
    let leftPreviousValue: Double?
    let rightPreviousValue: Double?
    let resolveNextField: (FocusedSetField) -> FocusedSetField?
    let onLeftCommit: (Double?) -> Void
    let onRightCommit: (Double?) -> Void

    var body: some View {
        HStack(spacing: 0) {
            PillTextField(
                value: leftValue,
                placeholder: leftPlaceholder,
                field: leftField,
                focusedField: $focusedField,
                fieldKind: leftFieldKind,
                previousValue: leftPreviousValue,
                resolveNextField: resolveNextField,
                onCommit: onLeftCommit
            )
            Rectangle()
                .fill(Color.borderDefault)
                .frame(width: 1, height: 16)
            PillTextField(
                value: rightValue,
                placeholder: rightPlaceholder,
                field: rightField,
                focusedField: $focusedField,
                fieldKind: rightFieldKind,
                previousValue: rightPreviousValue,
                resolveNextField: resolveNextField,
                onCommit: onRightCommit
            )
        }
        .frame(width: 94, height: 30)
        .background(Color.bgInput)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            if focusedField != leftField && focusedField != rightField {
                focusedField = leftField
            }
        }
    }
}

struct EditableSinglePill: View {
    let value: Double?
    let placeholder: String
    let field: FocusedSetField
    @Binding var focusedField: FocusedSetField?
    var fieldKind: NumericKeypad.FieldKind = .decimal
    let previousValue: Double?
    let resolveNextField: (FocusedSetField) -> FocusedSetField?
    let onCommit: (Double?) -> Void

    var body: some View {
        PillTextField(
            value: value,
            placeholder: placeholder,
            field: field,
            focusedField: $focusedField,
            fieldKind: fieldKind,
            previousValue: previousValue,
            resolveNextField: resolveNextField,
            onCommit: onCommit
        )
        .frame(width: 46, height: 30)
        .background(Color.bgInput)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            if focusedField != field {
                focusedField = field
            }
        }
    }
}
