import Foundation
import SwiftData

@MainActor @Observable
final class CategoryManagerViewModel {
    // MARK: - State

    private(set) var categories: [SchemaV1.ExerciseCategory] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var showNewCategoryAlert = false
    var newCategoryName = ""

    // MARK: - Dependencies

    private let categoryService: CategoryServiceProtocol

    // MARK: - Init

    init(categoryService: CategoryServiceProtocol) {
        self.categoryService = categoryService
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

    func createCategory() async {
        let name = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        errorMessage = nil
        do {
            _ = try await categoryService.create(name: name)
            newCategoryName = ""
            await loadCategories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateCategory(_ category: SchemaV1.ExerciseCategory, name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        errorMessage = nil
        do {
            try await categoryService.update(category, name: trimmed)
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

    func exerciseCount(for category: SchemaV1.ExerciseCategory) -> Int {
        category.exercises.count
    }
}
