import Foundation
import SwiftData

@MainActor @Observable
final class ExercisePickerViewModel {
    // MARK: - State

    private(set) var exercises: [SchemaV1.Exercise] = []
    private(set) var categories: [SchemaV1.ExerciseCategory] = []
    var searchQuery: String = ""
    var selectedCategoryFilter: SchemaV1.ExerciseCategory?
    var selectedTypeFilter: ExerciseType?
    var sortOption: ExerciseSortOption = .alphabetical
    var showFavoritesOnly = false
    var showArchived = false
    var selectedIds: Set<PersistentIdentifier> = []
    private(set) var isLoading = false
    private(set) var shouldDismiss = false

    // MARK: - Dependencies

    private let exerciseService: ExerciseServiceProtocol
    private let categoryService: CategoryServiceProtocol
    private let onSelect: ([PersistentIdentifier]) -> Void
    private var allExercises: [SchemaV1.Exercise] = []

    // MARK: - Init

    init(
        exerciseService: ExerciseServiceProtocol,
        categoryService: CategoryServiceProtocol,
        onSelect: @escaping ([PersistentIdentifier]) -> Void
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

    func setCategoryFilter(_ category: SchemaV1.ExerciseCategory?) {
        selectedCategoryFilter = category
        applyFilters()
    }

    func setTypeFilter(_ type: ExerciseType?) {
        selectedTypeFilter = type
        applyFilters()
    }

    func setSortOption(_ option: ExerciseSortOption) {
        sortOption = option
        applyFilters()
    }

    func toggleFavoritesFilter() {
        showFavoritesOnly.toggle()
        applyFilters()
    }

    func toggleArchivedFilter() {
        showArchived.toggle()
        applyFilters()
    }

    func toggleExercise(_ exercise: SchemaV1.Exercise) {
        let id = exercise.persistentModelID
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    func confirmSelection() {
        guard !selectedIds.isEmpty else { return }
        onSelect(Array(selectedIds))
        shouldDismiss = true
    }

    // MARK: - Private

    private func applyFilters() {
        var filtered = allExercises

        if !showArchived {
            filtered = filtered.filter { !$0.isArchived }
        }

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

        exercises = filtered
    }
}
