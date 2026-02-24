import SwiftUI
import SwiftData

// MARK: - Route Enum

enum HomeRoute: Hashable {
    case templateDetail(templateId: PersistentIdentifier)
    case splitList
}

// MARK: - Sheet Enum

enum HomeSheet: Identifiable {
    case exercisePicker
    case workoutPicker
    case templateForm(templateId: PersistentIdentifier?)
    case splitForm(splitId: PersistentIdentifier?) // nil = create, non-nil = edit

    var id: String {
        switch self {
        case .exercisePicker: return "exercisePicker"
        case .workoutPicker: return "workoutPicker"
        case .templateForm(let templateId): return "templateForm-\(templateId?.hashValue ?? 0)"
        case .splitForm(let splitId): return "splitForm-\(splitId?.hashValue ?? 0)"
        }
    }
}

// MARK: - Router

@MainActor
@Observable
final class HomeRouter: TemplateRouting {
    var path: [HomeRoute] = []
    var presentedSheet: HomeSheet?

    // Callbacks for picker selections
    var onExerciseSelected: (([PersistentIdentifier]) -> Void)?
    var onWorkoutSelected: ((PersistentIdentifier) -> Void)?

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

    func presentExercisePicker(onSelect: @escaping ([PersistentIdentifier]) -> Void) {
        onExerciseSelected = onSelect
        presentedSheet = .exercisePicker
    }

    func presentWorkoutPicker(onSelect: @escaping (PersistentIdentifier) -> Void) {
        onWorkoutSelected = onSelect
        presentedSheet = .workoutPicker
    }

    func dismissSheet() {
        presentedSheet = nil
        onExerciseSelected = nil
        onWorkoutSelected = nil
    }

    // MARK: - Convenience Navigation

    func navigateToTemplateDetail(templateId: PersistentIdentifier) {
        push(.templateDetail(templateId: templateId))
    }

    func presentTemplateForm(templateId: PersistentIdentifier? = nil) {
        presentedSheet = .templateForm(templateId: templateId)
    }

    func navigateToSplitList() {
        push(.splitList)
    }

    func presentCreateSplit() {
        presentedSheet = .splitForm(splitId: nil)
    }

    func presentEditSplit(splitId: PersistentIdentifier) {
        presentedSheet = .splitForm(splitId: splitId)
    }
}
