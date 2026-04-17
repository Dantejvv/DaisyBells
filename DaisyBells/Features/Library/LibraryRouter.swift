import SwiftUI
import SwiftData

// MARK: - Route Enum

enum LibraryRoute: Hashable {
    // Exercise routes
    case exerciseList(categoryId: PersistentIdentifier?)
    case exerciseDetail(exerciseId: PersistentIdentifier)
}

// MARK: - Sheet Enum

enum LibrarySheet: Identifiable {
    case exerciseForm(exerciseId: PersistentIdentifier?)
    case exercisePicker

    var id: String {
        switch self {
        case .exerciseForm(let exerciseId):
            return "exerciseForm-\(exerciseId?.hashValue ?? 0)"
        case .exercisePicker:
            return "exercisePicker"
        }
    }
}

// MARK: - Router

@MainActor
@Observable
final class LibraryRouter {
    var path: [LibraryRoute] = []
    var presentedSheet: LibrarySheet?

    // Callbacks for picker selections
    var onExerciseSelected: (([PersistentIdentifier]) -> Void)?

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

    func presentExerciseForm(exerciseId: PersistentIdentifier? = nil) {
        presentedSheet = .exerciseForm(exerciseId: exerciseId)
    }

    func presentExercisePicker(onSelect: @escaping ([PersistentIdentifier]) -> Void) {
        onExerciseSelected = onSelect
        presentedSheet = .exercisePicker
    }

    func dismissSheet() {
        presentedSheet = nil
        onExerciseSelected = nil
    }

    // MARK: - Convenience Navigation

    func navigateToExerciseList(categoryId: PersistentIdentifier? = nil) {
        push(.exerciseList(categoryId: categoryId))
    }

    func navigateToExerciseDetail(exerciseId: PersistentIdentifier) {
        push(.exerciseDetail(exerciseId: exerciseId))
    }
}
