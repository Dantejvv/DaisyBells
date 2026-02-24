import SwiftUI

/// Reusable confirmation dialog for destructive actions.
///
/// Usage:
/// ```swift
/// SomeView()
///     .confirmationDialog(
///         title: "Delete Workout",
///         message: "This action cannot be undone.",
///         isPresented: $showDeleteConfirmation,
///         onConfirm: { viewModel.deleteWorkout() }
///     )
/// ```
struct ConfirmationDialogModifier: ViewModifier {
    let title: String
    let message: String
    @Binding var isPresented: Bool
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                title,
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                Button(title, role: .destructive) {
                    onConfirm()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(message)
            }
    }
}

extension View {
    func destructiveConfirmation(
        title: String,
        message: String,
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(
            ConfirmationDialogModifier(
                title: title,
                message: message,
                isPresented: isPresented,
                onConfirm: onConfirm
            )
        )
    }
}

// MARK: - Preview

private struct ConfirmationDialogPreview: View {
    @State private var showConfirmation = true

    var body: some View {
        VStack(spacing: .spacingBase) {
            Text("Confirmation Dialog Preview")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            Button("Delete Workout", role: .destructive) {
                showConfirmation = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.destructive)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary)
        .destructiveConfirmation(
            title: "Delete Workout",
            message: "This action cannot be undone. All logged sets will be permanently removed.",
            isPresented: $showConfirmation,
            onConfirm: {}
        )
    }
}

#Preview {
    ConfirmationDialogPreview()
}
