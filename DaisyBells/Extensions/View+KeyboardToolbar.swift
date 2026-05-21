import SwiftUI

extension View {
    @ViewBuilder
    func keyboardDoneToolbar(isFocused: Bool, onDone: @escaping () -> Void) -> some View {
        self.toolbar {
            if isFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done", action: onDone)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accent)
                }
            }
        }
    }
}
