import SwiftUI

/// Generic empty state placeholder for list views with no content.
///
/// Usage:
/// ```swift
/// EmptyStateView(
///     icon: "dumbbell",
///     title: "No Exercises Yet",
///     message: "Create your first exercise to start building your library."
/// ) {
///     Button("Create Exercise") { viewModel.createExercise() }
/// }
/// ```
struct EmptyStateView<Action: View>: View {
    let icon: String
    let title: String
    let message: String
    let action: Action

    init(
        icon: String,
        title: String,
        message: String,
        @ViewBuilder action: () -> Action
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action()
    }

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(Color.accent)
            }
        } description: {
            Text(message)
                .foregroundStyle(Color.textSecondary)
        } actions: {
            action
        }
    }
}

// Convenience init when no action button is needed
extension EmptyStateView where Action == EmptyView {
    init(icon: String, title: String, message: String) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = EmptyView()
    }
}

#Preview("With Action") {
    EmptyStateView(
        icon: "dumbbell",
        title: "No Exercises Yet",
        message: "Create your first exercise to start building your workout library."
    ) {
        Button("Create Exercise") {}
            .buttonStyle(.borderedProminent)
            .tint(.accent)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.bgPrimary)
}

#Preview("Without Action") {
    EmptyStateView(
        icon: "chart.bar",
        title: "No Analytics Yet",
        message: "Train consistently and insights will appear automatically."
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.bgPrimary)
}
