import SwiftUI

struct PillTextField: View {
    let value: Double?
    let placeholder: String
    let onCommit: (Double?) -> Void

    var body: some View {
        let text = value.map { String(format: "%g", $0) } ?? ""
        TextField(placeholder, text: Binding(
            get: { text },
            set: { newText in
                let cleaned = newText.filter { $0.isNumber || $0 == "." || $0 == "-" }
                onCommit(Double(cleaned))
            }
        ))
        .keyboardType(.decimalPad)
        .font(.system(size: 13))
        .foregroundStyle(Color.textPrimary)
        .multilineTextAlignment(.center)
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
    }
}

struct EditableDualPill: View {
    let leftValue: Double?
    let rightValue: Double?
    let leftPlaceholder: String
    let rightPlaceholder: String
    let onLeftCommit: (Double?) -> Void
    let onRightCommit: (Double?) -> Void

    var body: some View {
        HStack(spacing: 0) {
            PillTextField(value: leftValue, placeholder: leftPlaceholder, onCommit: onLeftCommit)
            Rectangle()
                .fill(Color.borderDefault)
                .frame(width: 1, height: 16)
            PillTextField(value: rightValue, placeholder: rightPlaceholder, onCommit: onRightCommit)
        }
        .frame(width: 94, height: 30)
        .background(Color.bgInput)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }
}

struct EditableSinglePill: View {
    let value: Double?
    let placeholder: String
    let onCommit: (Double?) -> Void

    var body: some View {
        PillTextField(value: value, placeholder: placeholder, onCommit: onCommit)
            .frame(width: 46, height: 30)
            .background(Color.bgInput)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
    }
}
