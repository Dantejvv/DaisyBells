import Foundation
import SwiftData

@MainActor @Observable
final class ExercisePickerViewModel {
    // MARK: - State

    private(set) var exercises: [SchemaV1.Exercise] = []
    private(set) var categories: [SchemaV1.ExerciseCategory] = []
    var searchQuery: String = ""
    var selectedCategoryId: PersistentIdentifier?
    private(set) var isLoading = false
    private(set) var shouldDismiss = false

    // MARK: - Dependencies

    private let exerciseService: ExerciseServiceProtocol
    private let categoryService: CategoryServiceProtocol
    private let onSelect: (PersistentIdentifier) -> Void
    private var allExercises: [SchemaV1.Exercise] = []

    // MARK: - Init

    init(
        exerciseService: ExerciseServiceProtocol,
        categoryService: CategoryServiceProtocol,
        onSelect: @escaping (PersistentIdentifier) -> Void
    ) {
        self.exerciseService = exerciseService
        self.categoryService = categoryService
        self.onSelect = onSelect
    }

    // MARK: - Intents

    func loadExercises() async {
        isLoading = true
        do {
            allExercises = try await exerciseService.fetchAll()
            categories = try await categoryService.fetchAll()
            applyFilters()
        } catch {
            exercises = []
        }
        isLoading = false
    }

    func search(query: String) {
        searchQuery = query
        applyFilters()
    }

    func filterByCategory(_ categoryId: PersistentIdentifier?) {
        selectedCategoryId = categoryId
        applyFilters()
    }

    func selectExercise(_ exercise: SchemaV1.Exercise) {
        onSelect(exercise.persistentModelID)
        shouldDismiss = true
    }

    // MARK: - Private

    private func applyFilters() {
        var filtered = allExercises.filter { !$0.isArchived }

        if let categoryId = selectedCategoryId,
           let category = categoryService.fetch(by: categoryId) {
            filtered = filtered.filter { $0.categories.contains { $0.id == category.id } }
        }

        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter { $0.name.lowercased().contains(query) }
        }

        exercises = filtered.sorted { $0.name < $1.name }
    }
}
