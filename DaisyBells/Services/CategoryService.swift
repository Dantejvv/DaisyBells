import Foundation
import SwiftData

@MainActor
final class CategoryService: CategoryServiceProtocol {
    static let maxNameLength = 20

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

    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.ExerciseCategory? {
        modelContext.model(for: persistentId) as? SchemaV1.ExerciseCategory
    }

    func create(name: String) async throws -> SchemaV1.ExerciseCategory {
        guard name.count <= Self.maxNameLength else {
            throw ServiceError.invalidOperation("Category name must be \(Self.maxNameLength) characters or less")
        }
        let category = SchemaV1.ExerciseCategory(name: name)
        modelContext.insert(category)
        try modelContext.save()
        return category
    }

    func update(_ category: SchemaV1.ExerciseCategory, name: String) async throws {
        guard name.count <= Self.maxNameLength else {
            throw ServiceError.invalidOperation("Category name must be \(Self.maxNameLength) characters or less")
        }
        category.name = name
        try modelContext.save()
    }

    func reorder(categories: [SchemaV1.ExerciseCategory]) async throws {
        for (index, category) in categories.enumerated() {
            category.order = index
        }
        try modelContext.save()
    }

    func delete(_ category: SchemaV1.ExerciseCategory) async throws {
        modelContext.delete(category)
        try modelContext.save()
    }
}
