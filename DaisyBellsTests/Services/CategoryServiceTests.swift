import Foundation
import Testing
import SwiftData
@testable import DaisyBells

@Suite(.serialized)
struct CategoryServiceTests {

    @Test @MainActor
    func fetchAllReturnsEmptyInitially() async throws {
        let container = try makeTestModelContainer()
        let service = CategoryService(modelContext: container.mainContext)

        let categories = try await service.fetchAll()

        #expect(categories.isEmpty)
    }

    @Test @MainActor
    func createAddsCategory() async throws {
        let container = try makeTestModelContainer()
        let service = CategoryService(modelContext: container.mainContext)

        let category = try await service.create(name: "Test Category")

        #expect(category.name == "Test Category")
        #expect(!category.isDefault)

        let all = try await service.fetchAll()
        #expect(all.count == 1)
    }

    @Test @MainActor
    func fetchAllReturnsSortedByName() async throws {
        let container = try makeTestModelContainer()
        let service = CategoryService(modelContext: container.mainContext)

        _ = try await service.create(name: "Zebra")
        _ = try await service.create(name: "Apple")
        _ = try await service.create(name: "Mango")

        let categories = try await service.fetchAll()

        #expect(categories.count == 3)
        #expect(categories[0].name == "Apple")
        #expect(categories[1].name == "Mango")
        #expect(categories[2].name == "Zebra")
    }

    @Test @MainActor
    func deleteRemovesCategory() async throws {
        let container = try makeTestModelContainer()
        let service = CategoryService(modelContext: container.mainContext)

        let category = try await service.create(name: "ToDelete")
        try await service.delete(category)

        let all = try await service.fetchAll()
        #expect(all.isEmpty)
    }

    @Test @MainActor
    func deleteThrowsForDefaultCategory() async throws {
        let container = try makeTestModelContainer()
        let service = CategoryService(modelContext: container.mainContext)

        let defaultCategory = SchemaV1.ExerciseCategory(name: "Default", isDefault: true)
        container.mainContext.insert(defaultCategory)
        try container.mainContext.save()

        await #expect(throws: ServiceError.self) {
            try await service.delete(defaultCategory)
        }
    }
}
