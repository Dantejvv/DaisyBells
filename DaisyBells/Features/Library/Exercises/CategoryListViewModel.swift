import Foundation
import SwiftUI
import SwiftData

@MainActor @Observable
final class CategoryListViewModel {
    // MARK: - State

    private(set) var categories: [SchemaV1.ExerciseCategory] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let categoryService: CategoryServiceProtocol
    private let router: LibraryRouter

    // MARK: - Init

    init(categoryService: CategoryServiceProtocol, router: LibraryRouter) {
        self.categoryService = categoryService
        self.router = router
    }

    // MARK: - Intents

    func loadCategories() async {
        isLoading = true
        errorMessage = nil
        do {
            categories = try await categoryService.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createCategory(name: String) async {
        errorMessage = nil
        do {
            _ = try await categoryService.create(name: name)
            await loadCategories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteCategory(_ category: SchemaV1.ExerciseCategory) async {
        errorMessage = nil
        do {
            try await categoryService.delete(category)
            await loadCategories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectCategory(_ category: SchemaV1.ExerciseCategory) {
        router.navigateToExerciseList(categoryId: category.persistentModelID)
    }

    func updateCategory(_ category: SchemaV1.ExerciseCategory, name: String) async {
        errorMessage = nil
        do {
            try await categoryService.update(category, name: name)
            await loadCategories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reorderCategories(from source: IndexSet, to destination: Int) async {
        categories.move(fromOffsets: source, toOffset: destination)

        errorMessage = nil
        do {
            try await categoryService.reorder(categories: categories)
        } catch {
            errorMessage = error.localizedDescription
            await loadCategories() // Reload to restore original order
        }
    }
}
