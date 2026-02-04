import SwiftUI

/// A configurable empty state view with icon, title, message, and optional action button
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var buttonTitle: String?
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let buttonTitle, let action {
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview("No Exercises") {
    EmptyStateView(
        systemImage: "dumbbell",
        title: "No Exercises",
        message: "Add your first exercise to get started.",
        buttonTitle: "Add Exercise",
        action: {}
    )
}

#Preview("No History") {
    EmptyStateView(
        systemImage: "calendar",
        title: "No Workout History",
        message: "Complete a workout to see it here."
    )
}

#Preview("No Templates") {
    EmptyStateView(
        systemImage: "list.bullet.clipboard",
        title: "No Templates",
        message: "Create a template for your favorite workout routines.",
        buttonTitle: "Create Template",
        action: {}
    )
}

#Preview("No Search Results") {
    EmptyStateView(
        systemImage: "magnifyingglass",
        title: "No Results",
        message: "Try a different search term."
    )
}
