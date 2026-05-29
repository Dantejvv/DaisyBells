import SwiftUI

struct SearchBar: View {
    let placeholder: String
    @Binding var text: String
    var onClear: (() -> Void)? = nil

    @State private var focused: Bool = false

    var body: some View {
        HStack(spacing: .spacingSm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textTertiary)
            BridgedTextField(
                text: $text,
                placeholder: placeholder,
                isFocused: $focused,
                autocapitalization: .none,
                autocorrection: .no,
                returnKey: .search,
                textColor: .textPrimary,
                onSubmit: { focused = false }
            )
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
