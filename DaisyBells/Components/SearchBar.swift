import SwiftUI

struct SearchBar: View {
    let placeholder: String
    @Binding var text: String
    var onClear: (() -> Void)? = nil

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: .spacingSm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textTertiary)
            TextField(placeholder, text: $text)
                .focused($focused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardDoneToolbar(isFocused: focused) { focused = false }
                .foregroundStyle(Color.textPrimary)
            if !text.isEmpty {
                Button {
                    if let onClear {
                        onClear()
                    } else {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .padding(.horizontal, .spacingSm)
        .padding(.vertical, .spacingSm)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusMd))
    }
}
