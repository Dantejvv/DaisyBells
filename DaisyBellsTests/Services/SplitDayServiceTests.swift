import Foundation
import Testing
import SwiftData
@testable import DaisyBells

@Suite(.serialized)
struct SplitDayServiceTests {

    @Test @MainActor
    func createAddsSplitDay() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        let day = try await dayService.create(name: "Push Day", split: split)

        #expect(day.name == "Push Day")
        #expect(day.order == 0)
        #expect(day.split?.id == split.id)
        #expect(split.days.count == 1)
        #expect(split.days[0].id == day.id)
    }

    @Test @MainActor
    func createAutomaticallyOrdersDays() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        let day1 = try await dayService.create(name: "Day 1", split: split)
        let day2 = try await dayService.create(name: "Day 2", split: split)
        let day3 = try await dayService.create(name: "Day 3", split: split)

        #expect(day1.order == 0)
        #expect(day2.order == 1)
        #expect(day3.order == 2)
        #expect(split.days.count == 3)
    }

    @Test @MainActor
    func fetchByIdReturnsSplitDay() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        let created = try await dayService.create(name: "Leg Day", split: split)

        let fetched = try await dayService.fetch(id: created.id)

        #expect(fetched.id == created.id)
        #expect(fetched.name == "Leg Day")
    }

    @Test @MainActor
    func fetchByIdThrowsWhenNotFound() async throws {
        let container = try makeTestModelContainer()
        let dayService = SplitDayService(modelContext: container.mainContext)

        await #expect(throws: ServiceError.self) {
            _ = try await dayService.fetch(id: UUID())
        }
    }

    @Test @MainActor
    func fetchByPersistentIdReturnsSplitDay() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        let created = try await dayService.create(name: "Pull Day", split: split)
        let persistentId = created.persistentModelID

        let fetched = dayService.fetch(by: persistentId)

        #expect(fetched?.id == created.id)
        #expect(fetched?.name == "Pull Day")
    }

    @Test @MainActor
    func updateSavesSplitDay() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        let day = try await dayService.create(name: "Original Name", split: split)

        day.name = "Updated Name"
        try await dayService.update(day)

        let fetched = try await dayService.fetch(id: day.id)
        #expect(fetched.name == "Updated Name")
    }

    @Test @MainActor
    func deleteRemovesSplitDay() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        let day = try await dayService.create(name: "To Delete", split: split)

        try await dayService.delete(day, from: split)

        #expect(split.days.isEmpty)

        // Verify it's actually deleted
        let descriptor = FetchDescriptor<SchemaV1.SplitDay>()
        let allDays = try container.mainContext.fetch(descriptor)
        #expect(allDays.isEmpty)
    }

    @Test @MainActor
    func deleteReordersRemainingDays() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        let day1 = try await dayService.create(name: "Day 1", split: split)
        let day2 = try await dayService.create(name: "Day 2", split: split)
        let day3 = try await dayService.create(name: "Day 3", split: split)

        // Delete middle day
        try await dayService.delete(day2, from: split)

        #expect(split.days.count == 2)
        #expect(day1.order == 0)
        #expect(day3.order == 1) // Reordered from 2 to 1
    }

    @Test @MainActor
    func reorderUpdatesDayOrder() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        let day1 = try await dayService.create(name: "Day 1", split: split)
        let day2 = try await dayService.create(name: "Day 2", split: split)
        let day3 = try await dayService.create(name: "Day 3", split: split)

        // Reorder: [day1, day2, day3] -> [day3, day1, day2]
        try await dayService.reorder(days: [day3, day1, day2], in: split)

        #expect(day3.order == 0)
        #expect(day1.order == 1)
        #expect(day2.order == 2)

        // Verify array order by sorting by order property (SwiftData may not preserve array index order)
        let sortedDays = split.days.sorted(by: { $0.order < $1.order })
        #expect(sortedDays[0].id == day3.id)
        #expect(sortedDays[1].id == day1.id)
        #expect(sortedDays[2].id == day2.id)
    }

    @Test @MainActor
    func assignWorkoutAddsTemplateToDay() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        let day = try await dayService.create(name: "Push Day", split: split)

        let template = SchemaV1.WorkoutTemplate(name: "Push Workout")
        container.mainContext.insert(template)
        try container.mainContext.save()

        try await dayService.assignWorkout(template, to: day)

        #expect(day.assignedWorkouts.count == 1)
        #expect(day.assignedWorkouts[0].id == template.id)
    }

    @Test @MainActor
    func assignWorkoutIsIdempotent() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        let day = try await dayService.create(name: "Push Day", split: split)

        let template = SchemaV1.WorkoutTemplate(name: "Push Workout")
        container.mainContext.insert(template)
        try container.mainContext.save()

        // Assign same workout twice
        try await dayService.assignWorkout(template, to: day)
        try await dayService.assignWorkout(template, to: day)

        // Should only be assigned once
        #expect(day.assignedWorkouts.count == 1)
    }

    @Test @MainActor
    func assignMultipleWorkoutsToOneDay() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        let day = try await dayService.create(name: "Full Body", split: split)

        let template1 = SchemaV1.WorkoutTemplate(name: "Workout A")
        let template2 = SchemaV1.WorkoutTemplate(name: "Workout B")
        let template3 = SchemaV1.WorkoutTemplate(name: "Workout C")
        container.mainContext.insert(template1)
        container.mainContext.insert(template2)
        container.mainContext.insert(template3)
        try container.mainContext.save()

        try await dayService.assignWorkout(template1, to: day)
        try await dayService.assignWorkout(template2, to: day)
        try await dayService.assignWorkout(template3, to: day)

        #expect(day.assignedWorkouts.count == 3)
    }

    @Test @MainActor
    func assignOneWorkoutToMultipleDays() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        let day1 = try await dayService.create(name: "Monday", split: split)
        let day2 = try await dayService.create(name: "Friday", split: split)

        let template = SchemaV1.WorkoutTemplate(name: "Full Body")
        container.mainContext.insert(template)
        try container.mainContext.save()

        try await dayService.assignWorkout(template, to: day1)
        try await dayService.assignWorkout(template, to: day2)

        #expect(day1.assignedWorkouts.count == 1)
        #expect(day2.assignedWorkouts.count == 1)
        #expect(day1.assignedWorkouts[0].id == template.id)
        #expect(day2.assignedWorkouts[0].id == template.id)
    }

    @Test @MainActor
    func unassignWorkoutRemovesTemplateFromDay() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        let day = try await dayService.create(name: "Push Day", split: split)

        let template = SchemaV1.WorkoutTemplate(name: "Push Workout")
        container.mainContext.insert(template)
        try container.mainContext.save()

        try await dayService.assignWorkout(template, to: day)
        #expect(day.assignedWorkouts.count == 1)

        try await dayService.unassignWorkout(template, from: day)
        #expect(day.assignedWorkouts.isEmpty)
    }

    @Test @MainActor
    func deleteDayPreservesTemplates() async throws {
        let container = try makeTestModelContainer()
        let splitService = SplitService(modelContext: container.mainContext)
        let dayService = SplitDayService(modelContext: container.mainContext)

        let split = try await splitService.create(name: "Test Split")
        let day = try await dayService.create(name: "Push Day", split: split)

        let template = SchemaV1.WorkoutTemplate(name: "Push Workout")
        container.mainContext.insert(template)
        try container.mainContext.save()

        try await dayService.assignWorkout(template, to: day)

        // Delete the day
        try await dayService.delete(day, from: split)

        // Verify template still exists
        let descriptor = FetchDescriptor<SchemaV1.WorkoutTemplate>()
        let templates = try container.mainContext.fetch(descriptor)
        #expect(templates.count == 1)
        #expect(templates[0].id == template.id)
    }
}
