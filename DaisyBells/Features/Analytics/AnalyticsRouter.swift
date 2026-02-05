import SwiftUI
import SwiftData

// MARK: - Route Enum

enum AnalyticsRoute: Hashable {
    case exerciseAnalytics(exerciseId: PersistentIdentifier)
}

// MARK: - Sheet Enum

enum AnalyticsSheet: Identifiable {
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
final class AnalyticsRouter {
    var path: [AnalyticsRoute] = []
    var presentedSheet: AnalyticsSheet?

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

    // MARK: - Sheet Presentation

    func presentSettings() {
        presentedSheet = .settings
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    // MARK: - Convenience Navigation

    func navigateToExerciseAnalytics(exerciseId: PersistentIdentifier) {
        push(.exerciseAnalytics(exerciseId: exerciseId))
    }
}
