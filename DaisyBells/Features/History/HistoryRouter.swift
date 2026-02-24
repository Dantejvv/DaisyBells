import SwiftUI
import SwiftData

// MARK: - Route Enum

enum HistoryRoute: Hashable {
    case workoutDetail(workoutId: PersistentIdentifier)
}

// MARK: - Router

@MainActor
@Observable
final class HistoryRouter {
    var path: [HistoryRoute] = []

    // MARK: - Stack Navigation

    func push(_ route: HistoryRoute) {
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

    func navigateToWorkoutDetail(workoutId: PersistentIdentifier) {
        push(.workoutDetail(workoutId: workoutId))
    }
}
