import SwiftUI
import SwiftData

// MARK: - Route Enum

enum HistoryRoute: Hashable {
    case workoutDetail(workoutId: PersistentIdentifier)
}

// MARK: - Sheet Enum

enum HistorySheet: Identifiable {
    case settings

    var id: String {
        switch self {
        case .settings: return "settings"
        }
    }
}

// MARK: - Router

@MainActor
@Observable
final class HistoryRouter {
    var path: [HistoryRoute] = []
    var presentedSheet: HistorySheet?

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

    // MARK: - Sheet Presentation

    func presentSettings() {
        presentedSheet = .settings
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    // MARK: - Convenience Navigation

    func navigateToWorkoutDetail(workoutId: PersistentIdentifier) {
        push(.workoutDetail(workoutId: workoutId))
    }
}
