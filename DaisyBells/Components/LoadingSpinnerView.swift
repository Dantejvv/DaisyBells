import SwiftUI

/// Centered progress indicator for loading states.
///
/// Usage:
/// ```swift
/// if viewModel.isLoading {
///     LoadingSpinnerView()
/// }
/// ```
struct LoadingSpinnerView: View {
    var body: some View {
        ProgressView()
            .controlSize(.regular)
            .tint(.accent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingSpinnerView()
        .background(Color.bgPrimary)
}
