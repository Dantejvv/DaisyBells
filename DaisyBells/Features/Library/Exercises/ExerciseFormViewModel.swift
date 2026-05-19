import Foundation
import SwiftData

@MainActor @Observable
final class ExerciseFormViewModel {
    // MARK: - State

    var name: String = ""
    var type: ExerciseType = .weightAndReps
    var notes: String = ""
    var selectedCategories: [SchemaV1.ExerciseCategory] = []
    private(set) var availableCategories: [SchemaV1.ExerciseCategory] = []
    private(set) var isEditing = false
    private(set) var isSaving = false
    var errorMessage: String?
    var showNewCategoryAlert = false
    var newCategoryName = ""

    // MARK: - Dependencies

    private let exerciseService: ExerciseServiceProtocol
    private let categoryService: CategoryServiceProtocol
    private let router: LibraryRouter?
    private let exerciseId: PersistentIdentifier?
    private let onSaved: ((PersistentIdentifier) -> Void)?
    private let onDismiss: (() -> Void)?
    private var exercise: SchemaV1.Exercise?

    // MARK: - Init

    init(
        exerciseService: ExerciseServiceProtocol,
        categoryService: CategoryServiceProtocol,
        router: LibraryRouter? = nil,
        exerciseId: PersistentIdentifier? = nil,
        initialName: String = "",
        onSaved: ((PersistentIdentifier) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.exerciseService = exerciseService
        self.categoryService = categoryService
        self.router = router
        self.exerciseId = exerciseId
        self.onSaved = onSaved
        self.onDismiss = onDismiss
        self.isEditing = exerciseId != nil
        self.name = initialName
    }

    // MARK: - Intents

    func load() async {
        errorMessage = nil
        do {
            availableCategories = try await categoryService.fetchAll()

            if let exerciseId,
               let exerciseModel = exerciseService.fetch(by: exerciseId) {
                exercise = exerciseModel
                name = exerciseModel.name
                type = exerciseModel.type
                notes = exerciseModel.notes ?? ""
                selectedCategories = exerciseModel.categories
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateName(_ newName: String) {
        name = newName
    }

    func updateType(_ newType: ExerciseType) {
        type = newType
    }

    func updateNotes(_ newNotes: String) {
        notes = newNotes
    }

    func toggleCategory(_ category: SchemaV1.ExerciseCategory) {
        if let index = selectedCategories.firstIndex(where: { $0.id == category.id }) {
            selectedCategories.remove(at: index)
        } else {
            selectedCategories.append(category)
        }
    }

    func createCategory() async {
        let name = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        errorMessage = nil
        do {
            let newCategory = try await categoryService.create(name: name)
            newCategoryName = ""
            availableCategories = try await categoryService.fetchAll()
            selectedCategories.append(newCategory)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        guard validate() else { return }

        isSaving = true
        errorMessage = nil
        do {
            if isEditing, let exercise {
                exercise.name = name
                exercise.type = type
                exercise.notes = notes.isEmpty ? nil : notes
                exercise.categories = selectedCategories
                try await exerciseService.update(exercise)
            } else {
                let newExercise = try await exerciseService.create(name: name, type: type)
                newExercise.notes = notes.isEmpty ? nil : notes
                newExercise.categories = selectedCategories
                try await exerciseService.update(newExercise)
                onSaved?(newExercise.persistentModelID)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func cancel() {
        dismiss()
    }

    // MARK: - Private

    private func dismiss() {
        if let router {
            router.dismissSheet()
        } else {
            onDismiss?()
        }
    }

    private func validate() -> Bool {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Name is required"
            return false
        }
        return true
    }
}
