import SwiftUI

struct EditableNotesField: View {
    let currentNotes: String?
    let previousNotes: String?
    let onChange: (String?) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        let current = currentNotes ?? ""
        let placeholderText = previousNotes ?? "Notes"

        TextField(
            placeholderText,
            text: Binding(
                get: { current },
                set: { newValue in
                    onChange(newValue.isEmpty ? nil : newValue)
                }
            )
        )
        .focused($isFocused)
        .doneKeyboardToolbar(isFocused: isFocused) { isFocused = false }
        .font(.system(size: 11))
        .italic(current.isEmpty)
        .foregroundStyle(Color.textPrimary)
        .padding(.horizontal, .spacingSm)
        .frame(height: 30)
        .background(current.isEmpty ? Color.clear : Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: .radiusSm))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusSm)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }
}
