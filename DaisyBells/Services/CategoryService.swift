import Foundation
import SwiftData

@MainActor
final class CategoryService: CategoryServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [SchemaV1.ExerciseCategory] {
        let descriptor = FetchDescriptor<SchemaV1.ExerciseCategory>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func create(name: String) async throws -> SchemaV1.ExerciseCategory {
        let category = SchemaV1.ExerciseCategory(name: name)
        modelContext.insert(category)
        try modelContext.save()
        return category
    }

    func delete(_ category: SchemaV1.ExerciseCategory) async throws {
        if category.isDefault {
            throw ServiceError.invalidOperation("Cannot delete default categories")
        }
        modelContext.delete(category)
        try modelContext.save()
    }
}
