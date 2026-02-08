import Foundation
import Testing
import SwiftData
@testable import DaisyBells

@Suite(.serialized)
struct SplitServiceTests {

    @Test @MainActor
    func fetchAllReturnsEmptyInitially() async throws {
        let container = try makeTestModelContainer()
        let service = SplitService(modelContext: container.mainContext)

        let splits = try await service.fetchAll()

        #expect(splits.isEmpty)
    }

    @Test @MainActor
    func createAddsSplit() async throws {
        let container = try makeTestModelContainer()
        let service = SplitService(modelContext: container.mainContext)

        let split = try await service.create(name: "Push Pull Legs")

        #expect(split.name == "Push Pull Legs")
        #expect(!split.days.isEmpty == false) // No days yet
        #expect(split.createdAt <= Date())

        let all = try await service.fetchAll()
        #expect(all.count == 1)
    }

    @Test @MainActor
    func fetchByIdReturnsSplit() async throws {
        let container = try makeTestModelContainer()
        let service = SplitService(modelContext: container.mainContext)

        let created = try await service.create(name: "Upper Lower")
        let fetched = try await service.fetch(id: created.id)

        #expect(fetched.id == created.id)
        #expect(fetched.name == "Upper Lower")
    }

    @Test @MainActor
    func fetchByIdThrowsWhenNotFound() async throws {
        let container = try makeTestModelContainer()
        let service = SplitService(modelContext: container.mainContext)

        await #expect(throws: ServiceError.self) {
            _ = try await service.fetch(id: UUID())
        }
    }

    @Test @MainActor
    func fetchByPersistentIdReturnsSplit() async throws {
        let container = try makeTestModelContainer()
        let service = SplitService(modelContext: container.mainContext)

        let created = try await service.create(name: "Full Body")
        let persistentId = created.persistentModelID

        let fetched = service.fetch(by: persistentId)

        #expect(fetched?.id == created.id)
        #expect(fetched?.name == "Full Body")
    }

    @Test @MainActor
    func updateSavesSplit() async throws {
        let container = try makeTestModelContainer()
        let service = SplitService(modelContext: container.mainContext)

        let split = try await service.create(name: "Original Name")
        split.name = "Updated Name"

        try await service.update(split)

        let fetched = try await service.fetch(id: split.id)
        #expect(fetched.name == "Updated Name")
    }

    @Test @MainActor
    func deleteRemovesSplit() async throws {
        let container = try makeTestModelContainer()
        let service = SplitService(modelContext: container.mainContext)

        let split = try await service.create(name: "To Delete")
        try await service.delete(split)

        let all = try await service.fetchAll()
        #expect(all.isEmpty)
    }

    @Test @MainActor
    func deleteCascadesToDays() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        _ = try await dayService.create(name: "Day 1", split: split)
        _ = try await dayService.create(name: "Day 2", split: split)

        #expect(split.days.count == 2)

        try await splitService.delete(split)

        // Verify split is deleted
        let allSplits = try await splitService.fetchAll()
        #expect(allSplits.isEmpty)

        // Verify days are cascade deleted
        let descriptor = FetchDescriptor<SchemaV1.SplitDay>()
        let allDays = try container.mainContext.fetch(descriptor)
        #expect(allDays.isEmpty)
    }

    @Test @MainActor
    func fetchAllReturnsSortedByCreatedAtDescending() async throws {
        let container = try makeTestModelContainer()
        let service = SplitService(modelContext: container.mainContext)

        let first = try await service.create(name: "First")
        try await Task.sleep(for: .milliseconds(10))
        let second = try await service.create(name: "Second")
        try await Task.sleep(for: .milliseconds(10))
        let third = try await service.create(name: "Third")

        let splits = try await service.fetchAll()

        #expect(splits.count == 3)
        // Most recent first (descending order)
        #expect(splits[0].id == third.id)
        #expect(splits[1].id == second.id)
        #expect(splits[2].id == first.id)
    }
}
