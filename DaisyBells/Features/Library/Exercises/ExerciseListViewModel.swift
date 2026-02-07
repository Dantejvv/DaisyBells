import Foundation
import SwiftData

@MainActor @Observable
final class ExerciseListViewModel {
    // MARK: - State

    private(set) var exercises: [SchemaV1.Exercise] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var searchQuery: String = ""
    var showFavoritesOnly = false
    let selectedCategoryId: PersistentIdentifier?

    // MARK: - Dependencies

    private let exerciseService: ExerciseServiceProtocol
    private let categoryService: CategoryServiceProtocol
    private let router: LibraryRouter

    // MARK: - Init

    init(
        exerciseService: ExerciseServiceProtocol,
        categoryService: CategoryServiceProtocol,
        router: LibraryRouter,
        categoryId: PersistentIdentifier? = nil
    ) {
        self.exerciseService = exerciseService
        self.categoryService = categoryService
        self.router = router
        self.selectedCategoryId = categoryId
    }

    // MARK: - Intents

    func loadExercises() async {
        isLoading = true
        errorMessage = nil
        do {
            var allExercises: [SchemaV1.Exercise]

            if let categoryId = selectedCategoryId,
               let category = categoryService.fetch(by: categoryId) {
                allExercises = try await exerciseService.fetchByCategory(category)
            } else {
                allExercises = try await exerciseService.fetchAll()
            }

            exercises = filterExercises(allExercises)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func search(query: String) async {
        searchQuery = query
        await loadExercises()
    }

    func toggleFavoritesFilter() async {
        showFavoritesOnly.toggle()
        await loadExercises()
    }

    func selectExercise(_ exercise: SchemaV1.Exercise) {
        router.navigateToExerciseDetail(exerciseId: exercise.persistentModelID)
    }

    func createExercise() {
        router.navigateToCreateExercise()
    }

    // MARK: - Private

    private func filterExercises(_ allExercises: [SchemaV1.Exercise]) -> [SchemaV1.Exercise] {
        var filtered = allExercises.filter { !$0.isArchived }

        if showFavoritesOnly {
            filtered = filtered.filter { $0.isFavorite }
        }

        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter { $0.name.lowercased().contains(query) }
        }

        return filtered.sorted { $0.name < $1.name }
    }
}
