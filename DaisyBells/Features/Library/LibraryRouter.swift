import SwiftUI
import SwiftData

// MARK: - Route Enum

enum LibraryRoute: Hashable {
    // Exercise routes
    case exerciseList(categoryId: PersistentIdentifier?)
    case exerciseDetail(exerciseId: PersistentIdentifier)
    case exerciseForm(exerciseId: PersistentIdentifier?) // nil = create, non-nil = edit

    // Template routes
    case templateDetail(templateId: PersistentIdentifier)
    case templateForm(templateId: PersistentIdentifier?) // nil = create, non-nil = edit

    // Workout routes
    case activeWorkout(workoutId: PersistentIdentifier)
}

// MARK: - Sheet Enum

enum LibrarySheet: Identifiable {
    case exercisePicker
    case settings

    var id: String {
        switch self {
        case .exercisePicker: return "exercisePicker"
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

    // Callback for exercise picker selection
    var onExerciseSelected: ((PersistentIdentifier) -> Void)?

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

    func presentExercisePicker(onSelect: @escaping (PersistentIdentifier) -> Void) {
        onExerciseSelected = onSelect
        presentedSheet = .exercisePicker
    }

    func presentSettings() {
        presentedSheet = .settings
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

    func navigateToCreateExercise() {
        push(.exerciseForm(exerciseId: nil))
    }

    func navigateToEditExercise(exerciseId: PersistentIdentifier) {
        push(.exerciseForm(exerciseId: exerciseId))
    }

    func navigateToTemplateDetail(templateId: PersistentIdentifier) {
        push(.templateDetail(templateId: templateId))
    }

    func navigateToCreateTemplate() {
        push(.templateForm(templateId: nil))
    }

    func navigateToEditTemplate(templateId: PersistentIdentifier) {
        push(.templateForm(templateId: templateId))
    }

    func navigateToActiveWorkout(workoutId: PersistentIdentifier) {
        push(.activeWorkout(workoutId: workoutId))
    }
}
