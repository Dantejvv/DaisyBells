import SwiftUI
import SwiftData

// MARK: - Route Enum

enum RoutinesRoute: Hashable {
    case templateDetail(templateId: PersistentIdentifier)
    case templateForm(templateId: PersistentIdentifier?) // nil = create, non-nil = edit
    case activeWorkout(workoutId: PersistentIdentifier)
}

// MARK: - Sheet Enum

enum RoutinesSheet: Identifiable {
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
final class RoutinesRouter {
    var path: [RoutinesRoute] = []
    var presentedSheet: RoutinesSheet?

    // Callback for exercise picker selection
    var onExerciseSelected: ((PersistentIdentifier) -> Void)?

    // MARK: - Stack Navigation

    func push(_ route: RoutinesRoute) {
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
