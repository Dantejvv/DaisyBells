import SwiftUI
import SwiftData

// MARK: - Route Enum

enum AnalyticsRoute: Hashable {
    case exerciseAnalytics(exerciseId: PersistentIdentifier)
}

// MARK: - Router

@MainActor
@Observable
final class AnalyticsRouter {
    var path: [AnalyticsRoute] = []

    // MARK: - Stack Navigation

    func push(_ route: AnalyticsRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    // MARK: - Convenience Navigation

    func navigateToExerciseAnalytics(exerciseId: PersistentIdentifier) {
        push(.exerciseAnalytics(exerciseId: exerciseId))
    }
}
