import SwiftUI

extension View {
    func doneKeyboardToolbar(isFocused: Bool, onDone: @escaping () -> Void) -> some View {
        toolbar {
            if isFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done", action: onDone)
                }
            }
        }
    }
}
