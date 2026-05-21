import SwiftUI
import UIKit

struct PillTextField: View {
    let value: Double?
    let placeholder: String
    let field: FocusedSetField
    @Binding var focusedField: FocusedSetField?
    var fieldKind: NumericKeypad.FieldKind = .decimal
    let previousValue: Double?
    let onCommit: (Double?) -> Void

    @Environment(KeyboardFocusCoordinator.self) private var coordinator
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
                NumericKeypad(
                    fieldKind: fieldKind,
                    canSameAsLast: previousValue != nil,
                    canNext: coordinator.hasNext(of: field),
                    draft: $draft,
                    onSameAsLast: {
                        if let prev = previousValue {
                            draft = Self.format(prev)
                        }
                    },
                    onNext: {
                        onCommit(Double(draft))
                        if let next = coordinator.next(of: field) {
                            focusedField = next
                        } else {
                            focusedField = nil
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil, from: nil, for: nil
                            )
                        }
                    },
                    onDone: {
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
    let onCommit: (Double?) -> Void

    var body: some View {
        PillTextField(
            value: value,
            placeholder: placeholder,
            field: field,
            focusedField: $focusedField,
            fieldKind: fieldKind,
            previousValue: previousValue,
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
