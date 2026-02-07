import SwiftUI
import SwiftData

// MARK: - Route Enum

enum LibraryRoute: Hashable {
    // Exercise routes
    case exerciseList(categoryId: PersistentIdentifier?)
    case exerciseDetail(exerciseId: PersistentIdentifier)
    case exerciseForm(exerciseId: PersistentIdentifier?) // nil = create, non-nil = edit
}

// MARK: - Sheet Enum

enum LibrarySheet: Identifiable {
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
final class LibraryRouter {
    var path: [LibraryRoute] = []
    var presentedSheet: LibrarySheet?

    // MARK: - Stack Navigation

    func push(_ route: LibraryRoute) {
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

    func navigateToExerciseList(categoryId: PersistentIdentifier? = nil) {
        push(.exerciseList(categoryId: categoryId))
    }

    func navigateToExerciseDetail(exerciseId: PersistentIdentifier) {
        push(.exerciseDetail(exerciseId: exerciseId))
    }

    func navigateToCreateExercise() {
        push(.exerciseForm(exerciseId: nil))
    }

    func navigateToEditExercise(exerciseId: PersistentIdentifier) {
        push(.exerciseForm(exerciseId: exerciseId))
    }
}
