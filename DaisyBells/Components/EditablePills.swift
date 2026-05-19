import SwiftUI

struct PillTextField: View {
    let value: Double?
    let placeholder: String
    let field: FocusedSetField
    var focusedField: FocusState<FocusedSetField?>.Binding
    let onCommit: (Double?) -> Void

    @State private var draft: String = ""

    private static func format(_ value: Double?) -> String {
        value.map { String(format: "%g", $0) } ?? ""
    }

    private var isFocused: Bool {
        focusedField.wrappedValue == field
    }

    var body: some View {
        TextField(placeholder, text: $draft)
            .focused(focusedField, equals: field)
            .keyboardType(.decimalPad)
            .font(.system(size: 13))
            .foregroundStyle(Color.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.vertical, 5)
            .padding(.horizontal, 4)
            .onAppear {
                if draft.isEmpty {
                    draft = Self.format(value)
                }
            }
            .onChange(of: draft) { _, newValue in
                let cleaned = newValue.filter { $0.isNumber || $0 == "." || $0 == "-" }
                if cleaned != newValue {
                    draft = cleaned
                }
            }
            .onChange(of: focusedField.wrappedValue) { oldValue, newValue in
                let wasFocused = oldValue == field
                let nowFocused = newValue == field
                if wasFocused && !nowFocused {
                    onCommit(Double(draft))
                }
            }
            .onSubmit {
                onCommit(Double(draft))
            }
            .onChange(of: value) { _, newValue in
                let formatted = Self.format(newValue)
                if !isFocused && draft != formatted {
                    draft = formatted
                }
            }
            .doneKeyboardToolbar(isFocused: isFocused) {
                focusedField.wrappedValue = nil
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
    var focusedField: FocusState<FocusedSetField?>.Binding
    let onLeftCommit: (Double?) -> Void
    let onRightCommit: (Double?) -> Void

    var body: some View {
        HStack(spacing: 0) {
            PillTextField(
                value: leftValue,
                placeholder: leftPlaceholder,
                field: leftField,
                focusedField: focusedField,
                onCommit: onLeftCommit
            )
            Rectangle()
                .fill(Color.borderDefault)
                .frame(width: 1, height: 16)
            PillTextField(
                value: rightValue,
                placeholder: rightPlaceholder,
                field: rightField,
                focusedField: focusedField,
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
            if focusedField.wrappedValue != leftField && focusedField.wrappedValue != rightField {
                focusedField.wrappedValue = leftField
            }
        }
    }
}

struct EditableSinglePill: View {
    let value: Double?
    let placeholder: String
    let field: FocusedSetField
    var focusedField: FocusState<FocusedSetField?>.Binding
    let onCommit: (Double?) -> Void

    var body: some View {
        PillTextField(
            value: value,
            placeholder: placeholder,
            field: field,
            focusedField: focusedField,
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
            if focusedField.wrappedValue != field {
                focusedField.wrappedValue = field
            }
        }
    }
}
