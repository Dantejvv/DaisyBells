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

        let split = try await service.create(name: "Push Pull Legs", notes: nil)

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

        let created = try await service.create(name: "Upper Lower", notes: nil)
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

        let created = try await service.create(name: "Full Body", notes: nil)
        let persistentId = created.persistentModelID

        let fetched = service.fetch(by: persistentId)

        #expect(fetched?.id == created.id)
        #expect(fetched?.name == "Full Body")
    }

    @Test @MainActor
    func updateSavesSplit() async throws {
        let container = try makeTestModelContainer()
        let service = SplitService(modelContext: container.mainContext)

        let split = try await service.create(name: "Original Name", notes: nil)
        split.name = "Updated Name"

        try await service.update(split)

        let fetched = try await service.fetch(id: split.id)
        #expect(fetched.name == "Updated Name")
    }

    @Test @MainActor
    func deleteRemovesSplit() async throws {
        let container = try makeTestModelContainer()
        let service = SplitService(modelContext: container.mainContext)

        let split = try await service.create(name: "To Delete", notes: nil)
        try await service.delete(split)

        let all = try await service.fetchAll()
        #expect(all.isEmpty)
    }

    @Test @MainActor
    func deleteCascadesToDays() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split", notes: nil)
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

    // MARK: - Cycle Tracking

    @Test @MainActor
    func setCurrentDayUpdatesIndex() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "PPL", notes: nil)
        _ = try await dayService.create(name: "Push", split: split)
        _ = try await dayService.create(name: "Pull", split: split)
        _ = try await dayService.create(name: "Legs", split: split)

        try await splitService.setCurrentDay(index: 2, in: split)
        #expect(split.currentDayIndex == 2)
    }

    @Test @MainActor
    func setCurrentDayThrowsForInvalidIndex() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "PPL", notes: nil)
        _ = try await dayService.create(name: "Push", split: split)

        await #expect(throws: ServiceError.self) {
            try await splitService.setCurrentDay(index: 5, in: split)
        }
    }

    @Test @MainActor
    func skipDayMarksCompletedAndAdvances() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "PPL", notes: nil)
        _ = try await dayService.create(name: "Push", split: split)
        _ = try await dayService.create(name: "Pull", split: split)
        _ = try await dayService.create(name: "Legs", split: split)

        // Skip current day (index 0)
        try await splitService.skipDay(at: 0, in: split)

        let sortedDays = split.days.sorted { $0.order < $1.order }
        #expect(sortedDays[0].isCompletedInCycle == true)
        #expect(split.currentDayIndex == 1) // Advanced to next
    }

    @Test @MainActor
    func skipDayNonCurrentDoesNotAdvance() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "PPL", notes: nil)
        _ = try await dayService.create(name: "Push", split: split)
        _ = try await dayService.create(name: "Pull", split: split)
        _ = try await dayService.create(name: "Legs", split: split)

        // Skip non-current day (index 2), current is 0
        try await splitService.skipDay(at: 2, in: split)

        let sortedDays = split.days.sorted { $0.order < $1.order }
        #expect(sortedDays[2].isCompletedInCycle == true)
        #expect(split.currentDayIndex == 0) // Did not advance
    }

    @Test @MainActor
    func advanceDayMovesToNextUncompleted() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "PPL", notes: nil)
        _ = try await dayService.create(name: "Push", split: split)
        _ = try await dayService.create(name: "Pull", split: split)
        _ = try await dayService.create(name: "Legs", split: split)

        // Mark day at index 1 as completed
        let sortedDays = split.days.sorted { $0.order < $1.order }
        sortedDays[1].isCompletedInCycle = true

        // Advance from index 0 — should skip index 1 and go to index 2
        try await splitService.advanceDay(in: split)
        #expect(split.currentDayIndex == 2)
    }

    @Test @MainActor
    func advanceDayResetsCycleWhenAllComplete() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "PPL", notes: nil)
        _ = try await dayService.create(name: "Push", split: split)
        _ = try await dayService.create(name: "Pull", split: split)

        // Mark all as completed
        let sortedDays = split.days.sorted { $0.order < $1.order }
        for day in sortedDays {
            day.isCompletedInCycle = true
        }

        try await splitService.advanceDay(in: split)

        // Should have reset
        #expect(split.currentDayIndex == 0)
        for day in split.days {
            #expect(day.isCompletedInCycle == false)
        }
    }

    @Test @MainActor
    func resetCycleIfCompleteResetsAllDays() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "PPL", notes: nil)
        _ = try await dayService.create(name: "Push", split: split)
        _ = try await dayService.create(name: "Pull", split: split)

        // Mark all as completed
        for day in split.days {
            day.isCompletedInCycle = true
        }
        split.currentDayIndex = 1

        try await splitService.resetCycleIfComplete(split)

        #expect(split.currentDayIndex == 0)
        for day in split.days {
            #expect(day.isCompletedInCycle == false)
        }
    }

    @Test @MainActor
    func resetCycleIfCompleteNoOpWhenIncomplete() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "PPL", notes: nil)
        _ = try await dayService.create(name: "Push", split: split)
        _ = try await dayService.create(name: "Pull", split: split)

        // Mark only one as completed
        split.days.sorted { $0.order < $1.order }[0].isCompletedInCycle = true
        split.currentDayIndex = 1

        try await splitService.resetCycleIfComplete(split)

        // Should not have reset
        #expect(split.currentDayIndex == 1)
        #expect(split.days.sorted { $0.order < $1.order }[0].isCompletedInCycle == true)
    }

    @Test @MainActor
    func fetchAllReturnsSortedByCreatedAtDescending() async throws {
        let container = try makeTestModelContainer()
        let service = SplitService(modelContext: container.mainContext)

        let first = try await service.create(name: "First", notes: nil)
        try await Task.sleep(for: .milliseconds(10))
        let second = try await service.create(name: "Second", notes: nil)
        try await Task.sleep(for: .milliseconds(10))
        let third = try await service.create(name: "Third", notes: nil)

        let splits = try await service.fetchAll()

        #expect(splits.count == 3)
        // Most recent first (descending order)
        #expect(splits[0].id == third.id)
        #expect(splits[1].id == second.id)
        #expect(splits[2].id == first.id)
    }
}
