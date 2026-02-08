import SwiftUI
import SwiftData

// MARK: - Route Enum

enum HomeRoute: Hashable {
    case templateDetail(templateId: PersistentIdentifier)
    case templateForm(templateId: PersistentIdentifier?) // nil = create, non-nil = edit
    case activeWorkout(workoutId: PersistentIdentifier)
    case splitDetail(splitId: PersistentIdentifier)
    case splitForm(splitId: PersistentIdentifier?) // nil = create, non-nil = edit
    case splitDayDetail(dayId: PersistentIdentifier)
    case splitDayForm(splitId: PersistentIdentifier, dayId: PersistentIdentifier?) // nil = create
}

// MARK: - Sheet Enum

enum HomeSheet: Identifiable {
    case exercisePicker
    case workoutPicker
    case splitDayPicker
    case settings

    var id: String {
        switch self {
        case .exercisePicker: return "exercisePicker"
        case .workoutPicker: return "workoutPicker"
        case .splitDayPicker: return "splitDayPicker"
        case .settings: return "settings"
        }
    }
}

// MARK: - Router

@MainActor
@Observable
final class HomeRouter {
    var path: [HomeRoute] = []
    var presentedSheet: HomeSheet?

    // Callbacks for picker selections
    var onExerciseSelected: ((PersistentIdentifier) -> Void)?
    var onWorkoutSelected: ((PersistentIdentifier) -> Void)?
    var onSplitDaySelected: ((PersistentIdentifier) -> Void)?

    // MARK: - Stack Navigation

    func push(_ route: HomeRoute) {
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

    func presentWorkoutPicker(onSelect: @escaping (PersistentIdentifier) -> Void) {
        onWorkoutSelected = onSelect
        presentedSheet = .workoutPicker
    }

    func presentSplitDayPicker(onSelect: @escaping (PersistentIdentifier) -> Void) {
        onSplitDaySelected = onSelect
        presentedSheet = .splitDayPicker
    }

    func presentSettings() {
        presentedSheet = .settings
    }

    func dismissSheet() {
        presentedSheet = nil
        onExerciseSelected = nil
        onWorkoutSelected = nil
        onSplitDaySelected = nil
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

    func navigateToSplitDetail(splitId: PersistentIdentifier) {
        push(.splitDetail(splitId: splitId))
    }

    func navigateToCreateSplit() {
        push(.splitForm(splitId: nil))
    }

    func navigateToEditSplit(splitId: PersistentIdentifier) {
        push(.splitForm(splitId: splitId))
    }

    func navigateToSplitDayDetail(dayId: PersistentIdentifier) {
        push(.splitDayDetail(dayId: dayId))
    }

    func navigateToAddDay(splitId: PersistentIdentifier) {
        push(.splitDayForm(splitId: splitId, dayId: nil))
    }

    func navigateToEditDay(splitId: PersistentIdentifier, dayId: PersistentIdentifier) {
        push(.splitDayForm(splitId: splitId, dayId: dayId))
    }
}
