import Foundation
import Testing
import SwiftData
@testable import DaisyBells

@Suite(.serialized)
struct LoggedSetServiceTests {

    @Test @MainActor
    func createAddsSetToLoggedExercise() async throws {
        let container = try makeTestModelContainer()
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let loggedExerciseService = LoggedExerciseService(modelContext: container.mainContext)
        let service = LoggedSetService(modelContext: container.mainContext)

        let exercise = try await exerciseService.create(name: "Bench", type: .weightAndReps)
        let workout = try await workoutService.createEmpty()
        let logged = try await loggedExerciseService.create(
            exercise: exercise, workout: workout, order: 0,
            weightUnit: .lbs, distanceUnit: nil
        )

        // logged already has 1 default set; add a second
        let newSet = try await service.create(
            loggedExercise: logged, order: 1,
            weightUnit: .lbs, distanceUnit: nil
        )

        #expect(logged.sets.count == 2)
        #expect(newSet.order == 1)
        #expect(newSet.weightUnit == Units.lbs.rawValue)
    }

    @Test @MainActor
    func updateSetsAllFields() async throws {
        let container = try makeTestModelContainer()
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let loggedExerciseService = LoggedExerciseService(modelContext: container.mainContext)
        let service = LoggedSetService(modelContext: container.mainContext)

        let exercise = try await exerciseService.create(name: "Dip", type: .bodyweightAndReps)
        let workout = try await workoutService.createEmpty()
        let logged = try await loggedExerciseService.create(
            exercise: exercise, workout: workout, order: 0,
            weightUnit: .lbs, distanceUnit: nil
        )
        let set = logged.sets[0]

        try await service.update(
            set, weight: 225, reps: 5,
            bodyweightModifier: 45.0, time: 60.0,
            distance: 1.5, notes: "Felt strong"
        )

        #expect(set.weight == 225)
        #expect(set.reps == 5)
        #expect(set.bodyweightModifier == 45.0)
        #expect(set.time == 60.0)
        #expect(set.distance == 1.5)
        #expect(set.notes == "Felt strong")
    }

    @Test @MainActor
    func updateSetsNilFields() async throws {
        let container = try makeTestModelContainer()
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let loggedExerciseService = LoggedExerciseService(modelContext: container.mainContext)
        let service = LoggedSetService(modelContext: container.mainContext)

        let exercise = try await exerciseService.create(name: "Squat", type: .weightAndReps)
        let workout = try await workoutService.createEmpty()
        let logged = try await loggedExerciseService.create(
            exercise: exercise, workout: workout, order: 0,
            weightUnit: .lbs, distanceUnit: nil
        )
        let set = logged.sets[0]

        // Set values first
        try await service.update(set, weight: 225, reps: 5, bodyweightModifier: nil, time: nil, distance: nil, notes: nil)
        #expect(set.weight == 225)
        #expect(set.reps == 5)

        // Clear them with nil
        try await service.update(set, weight: nil, reps: nil, bodyweightModifier: nil, time: nil, distance: nil, notes: nil)
        #expect(set.weight == nil)
        #expect(set.reps == nil)
    }

    @Test @MainActor
    func deleteReordersRemainingSets() async throws {
        let container = try makeTestModelContainer()
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let loggedExerciseService = LoggedExerciseService(modelContext: container.mainContext)
        let service = LoggedSetService(modelContext: container.mainContext)

        let exercise = try await exerciseService.create(name: "Bench", type: .weightAndReps)
        let workout = try await workoutService.createEmpty()
        let logged = try await loggedExerciseService.createWithSets(
            exercise: exercise, workout: workout, order: 0,
            setCount: 3, weightUnit: .lbs, distanceUnit: nil
        )

        let sortedSets = logged.sets.sorted { $0.order < $1.order }
        let set0 = sortedSets[0]
        let set1 = sortedSets[1]
        let set2 = sortedSets[2]

        // Delete middle set (order=1)
        try await service.delete(set1)

        #expect(logged.sets.count == 2)
        #expect(set0.order == 0) // Unchanged
        #expect(set2.order == 1) // Shifted from 2 to 1
    }

    @Test @MainActor
    func deleteFirstSetReordersAll() async throws {
        let container = try makeTestModelContainer()
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let loggedExerciseService = LoggedExerciseService(modelContext: container.mainContext)
        let service = LoggedSetService(modelContext: container.mainContext)

        let exercise = try await exerciseService.create(name: "Bench", type: .weightAndReps)
        let workout = try await workoutService.createEmpty()
        let logged = try await loggedExerciseService.createWithSets(
            exercise: exercise, workout: workout, order: 0,
            setCount: 3, weightUnit: .lbs, distanceUnit: nil
        )

        let sortedSets = logged.sets.sorted { $0.order < $1.order }
        let set0 = sortedSets[0]
        let set1 = sortedSets[1]
        let set2 = sortedSets[2]

        try await service.delete(set0)

        #expect(logged.sets.count == 2)
        #expect(set1.order == 0) // Shifted from 1 to 0
        #expect(set2.order == 1) // Shifted from 2 to 1
    }

    @Test @MainActor
    func toggleCompletionFlipsBool() async throws {
        let container = try makeTestModelContainer()
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let loggedExerciseService = LoggedExerciseService(modelContext: container.mainContext)
        let service = LoggedSetService(modelContext: container.mainContext)

        let exercise = try await exerciseService.create(name: "Curl", type: .weightAndReps)
        let workout = try await workoutService.createEmpty()
        let logged = try await loggedExerciseService.create(
            exercise: exercise, workout: workout, order: 0,
            weightUnit: nil, distanceUnit: nil
        )
        let set = logged.sets[0]

        #expect(set.isCompleted == false)

        try await service.toggleCompletion(set)
        #expect(set.isCompleted == true)

        try await service.toggleCompletion(set)
        #expect(set.isCompleted == false)
    }

    @Test @MainActor
    func fetchByIdThrowsWhenNotFound() async throws {
        let container = try makeTestModelContainer()
        let service = LoggedSetService(modelContext: container.mainContext)

        await #expect(throws: ServiceError.self) {
            _ = try await service.fetch(id: UUID())
        }
    }
}
