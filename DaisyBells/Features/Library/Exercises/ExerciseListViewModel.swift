import Foundation
import SwiftData

@MainActor @Observable
final class ExerciseListViewModel {
    // MARK: - State

    private(set) var exercises: [SchemaV1.Exercise] = []
    private(set) var allCategories: [SchemaV1.ExerciseCategory] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var searchQuery: String = ""
    var showFavoritesOnly = false
    var showArchived: Bool = false
    var sortOption: ExerciseSortOption = .alphabetical
    var selectedCategoryFilter: SchemaV1.ExerciseCategory?
    var selectedTypeFilter: ExerciseType?
    let selectedCategoryId: PersistentIdentifier?

    // Sheet state
    var showCategoryManager = false

    // Delete confirmation state
    var exercisePendingDelete: SchemaV1.Exercise?

    // MARK: - Dependencies

    private let exerciseService: ExerciseServiceProtocol
    let categoryService: CategoryServiceProtocol
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
            allCategories = try await categoryService.fetchAll()

            var allExercises: [SchemaV1.Exercise]

            if showArchived {
                allExercises = try await exerciseService.fetchArchived()
            } else if let categoryId = selectedCategoryId,
               let category = categoryService.fetch(by: categoryId) {
                allExercises = try await exerciseService.fetchByCategory(category)
            } else {
                allExercises = try await exerciseService.fetchAll()
            }

            exercises = filterAndSortExercises(allExercises)
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

    func editExercise(_ exercise: SchemaV1.Exercise) {
        router.presentExerciseForm(exerciseId: exercise.persistentModelID)
    }

    func createExercise() {
        router.presentExerciseForm()
    }

    func toggleArchivedFilter() async {
        showArchived.toggle()
        await loadExercises()
    }

    func setSortOption(_ option: ExerciseSortOption) async {
        sortOption = option
        await loadExercises()
    }

    func setCategoryFilter(_ category: SchemaV1.ExerciseCategory?) async {
        selectedCategoryFilter = category
        await loadExercises()
    }

    func setTypeFilter(_ type: ExerciseType?) async {
        selectedTypeFilter = type
        await loadExercises()
    }

    // MARK: - Delete Flow

    func requestDelete(_ exercise: SchemaV1.Exercise) {
        exercisePendingDelete = exercise
    }

    func cancelDelete() {
        exercisePendingDelete = nil
    }

    func confirmDelete() async {
        guard let exercise = exercisePendingDelete else { return }
        errorMessage = nil
        do {
            try await exerciseService.delete(exercise)
            exercisePendingDelete = nil
            await loadExercises()
        } catch {
            errorMessage = error.localizedDescription
            exercisePendingDelete = nil
        }
    }

    // MARK: - Private

    private func filterAndSortExercises(_ allExercises: [SchemaV1.Exercise]) -> [SchemaV1.Exercise] {
        var filtered = allExercises

        if showFavoritesOnly {
            filtered = filtered.filter { $0.isFavorite }
        }

        if let categoryFilter = selectedCategoryFilter {
            filtered = filtered.filter { exercise in
                exercise.categories.contains { $0.id == categoryFilter.id }
            }
        }

        if let typeFilter = selectedTypeFilter {
            filtered = filtered.filter { $0.type == typeFilter }
        }

        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter { $0.name.lowercased().contains(query) }
        }

        switch sortOption {
        case .alphabetical:
            filtered.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .creationDate:
            filtered.sort { $0.createdAt > $1.createdAt }
        case .favoritesFirst:
            filtered.sort {
                if $0.isFavorite != $1.isFavorite {
                    return $0.isFavorite
                }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }

        return filtered
    }
}
