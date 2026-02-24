import SwiftUI

/// View modifier that presents an error alert bound to a ViewModel's `errorMessage`.
///
/// When `errorMessage` is non-nil, an alert is shown. Dismissing the alert sets it back to nil.
///
/// Usage:
/// ```swift
/// SomeView()
///     .errorAlert(errorMessage: $viewModel.errorMessage)
/// ```
struct ErrorAlertModifier: ViewModifier {
    @Binding var errorMessage: String?

    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
    }
}

extension View {
    func errorAlert(errorMessage: Binding<String?>) -> some View {
        modifier(ErrorAlertModifier(errorMessage: errorMessage))
    }
}

// MARK: - Preview

private struct ErrorAlertPreview: View {
    @State private var errorMessage: String? = "Failed to save workout. Please try again."

    var body: some View {
        VStack(spacing: .spacingBase) {
            Text("Error Alert Preview")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            Button("Show Error") {
                errorMessage = "Failed to save workout. Please try again."
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary)
        .errorAlert(errorMessage: $errorMessage)
    }
}

#Preview {
    ErrorAlertPreview()
}
