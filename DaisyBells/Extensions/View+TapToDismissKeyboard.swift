import SwiftUI
import UIKit

extension View {
    /// Dismisses any active first responder when the user taps a non-interactive
    /// background of this view. Works for both the system alphabetic keyboard
    /// and our custom numeric `inputView`, because both ride on
    /// `UITextField.resignFirstResponder`.
    ///
    /// The dismissal is **app-wide** by design: `sendAction(... to: nil)` walks
    /// the responder chain from the key window's first responder. This is the
    /// iOS-idiomatic "tap outside to dismiss" gesture. If the app ever needs
    /// scoped dismissal (e.g. nested focusable regions in a sheet), prefer
    /// `@FocusState`-based dismissal at that scope instead of layering this
    /// modifier inside.
    func tapToDismissKeyboard() -> some View {
        background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
        )
    }
}
