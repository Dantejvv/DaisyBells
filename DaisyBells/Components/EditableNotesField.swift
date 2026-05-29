import SwiftUI
import UIKit

struct EditableNotesField: View {
    let currentNotes: String?
    let previousNotes: String?
    let onChange: (String?) -> Void

    @State private var isFocused: Bool = false

    var body: some View {
        let current = currentNotes ?? ""
        let placeholderText = previousNotes ?? "Notes"
        let baseFont = UIFont.systemFont(ofSize: 11)
        let italicFont = UIFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(.traitItalic) ?? baseFont.fontDescriptor, size: 11)

        BridgedTextField(
            text: Binding(
                get: { current },
                set: { newValue in
                    onChange(newValue.isEmpty ? nil : newValue)
                }
            ),
            placeholder: placeholderText,
            isFocused: $isFocused,
            autocapitalization: .sentences,
            font: current.isEmpty ? italicFont : baseFont,
            textColor: .textPrimary,
            onSubmit: { isFocused = false }
        )
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
