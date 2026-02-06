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
    private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let exerciseService: ExerciseServiceProtocol
    private let categoryService: CategoryServiceProtocol
    private let router: LibraryRouter
    private let exerciseId: PersistentIdentifier?
    private var exercise: SchemaV1.Exercise?

    // MARK: - Init

    init(
        exerciseService: ExerciseServiceProtocol,
        categoryService: CategoryServiceProtocol,
        router: LibraryRouter,
        exerciseId: PersistentIdentifier? = nil
    ) {
        self.exerciseService = exerciseService
        self.categoryService = categoryService
        self.router = router
        self.exerciseId = exerciseId
        self.isEditing = exerciseId != nil
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
            }
            router.pop()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func cancel() {
        router.pop()
    }

    // MARK: - Private

    private func validate() -> Bool {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Name is required"
            return false
        }
        return true
    }
}
