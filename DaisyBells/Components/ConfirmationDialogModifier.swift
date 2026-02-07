import SwiftUI

/// Configuration for a confirmation alert
struct ConfirmationDialogConfig {
    let title: String
    let message: String
    let confirmTitle: String
    let confirmRole: ButtonRole?
    let onConfirm: () -> Void

    init(
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        confirmRole: ButtonRole? = .destructive,
        onConfirm: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.confirmRole = confirmRole
        self.onConfirm = onConfirm
    }
}

/// A ViewModifier that presents a centered confirmation alert
struct ConfirmationDialogModifier: ViewModifier {
    @Binding var config: ConfirmationDialogConfig?

    func body(content: Content) -> some View {
        content
            .alert(
                config?.title ?? "",
                isPresented: Binding(
                    get: { config != nil },
                    set: { if !$0 { config = nil } }
                )
            ) {
                if let config {
                    Button(config.confirmTitle, role: config.confirmRole) {
                        config.onConfirm()
                        self.config = nil
                    }
                    Button("Cancel", role: .cancel) {
                        self.config = nil
                    }
                }
            } message: {
                if let config {
                    Text(config.message)
                }
            }
    }
}

extension View {
    /// Presents a confirmation alert when config is non-nil
    func confirmationDialog(_ config: Binding<ConfirmationDialogConfig?>) -> some View {
        modifier(ConfirmationDialogModifier(config: config))
    }
}
