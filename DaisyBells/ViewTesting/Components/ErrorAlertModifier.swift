import SwiftUI

/// A ViewModifier that presents an error alert with a dismiss button
struct ErrorAlertModifier: ViewModifier {
    @Binding var errorMessage: String?
    var title: String = "Error"

    func body(content: Content) -> some View {
        content
            .alert(
                title,
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
    /// Presents an error alert when errorMessage is non-nil
    func errorAlert(_ errorMessage: Binding<String?>, title: String = "Error") -> some View {
        modifier(ErrorAlertModifier(errorMessage: errorMessage, title: title))
    }
}

// MARK: - Preview Helper

private struct ErrorAlertPreview: View {
    @State private var errorMessage: String? = "Failed to load exercises. Please try again."

    var body: some View {
        VStack(spacing: 20) {
            Text("Error Alert Demo")
                .font(.headline)

            Button("Show Error") {
                errorMessage = "Something went wrong. Please check your connection and try again."
            }

            Button("Show Different Error") {
                errorMessage = "Failed to save workout."
            }
        }
        .errorAlert($errorMessage)
    }
}

#Preview {
    ErrorAlertPreview()
}
