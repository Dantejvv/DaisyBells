import Foundation
import Testing
import SwiftData
@testable import DaisyBells

@Suite(.serialized)
struct LoggedExerciseServiceTests {

    @Test @MainActor
    func createAddsLoggedExerciseToWorkout() async throws {
        let container = try makeTestModelContainer()
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let service = LoggedExerciseService(modelContext: container.mainContext)

        let exercise = try await exerciseService.create(name: "Bench Press", type: .weightAndReps)
        let workout = try await workoutService.createEmpty()

        let logged = try await service.create(
            exercise: exercise, workout: workout, order: 0,
            weightUnit: .lbs, distanceUnit: nil
        )

        #expect(logged.order == 0)
        #expect(logged.exercise?.id == exercise.id)
        #expect(workout.loggedExercises.count == 1)
        #expect(logged.sets.count == 1)

        // Verify unit stamps on the default set
        let defaultSet = logged.sets[0]
        #expect(defaultSet.weightUnit == Units.lbs.rawValue)
        #expect(defaultSet.distanceUnit == nil)
    }

    @Test @MainActor
    func createWithSetsCreatesMultipleSets() async throws {
        let container = try makeTestModelContainer()
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let service = LoggedExerciseService(modelContext: container.mainContext)

        let exercise = try await exerciseService.create(name: "Squat", type: .weightAndReps)
        let workout = try await workoutService.createEmpty()

        let logged = try await service.createWithSets(
            exercise: exercise, workout: workout, order: 0,
            setCount: 3, weightUnit: .kg, distanceUnit: nil
        )

        #expect(logged.sets.count == 3)
        let sortedSets = logged.sets.sorted { $0.order < $1.order }
        #expect(sortedSets[0].order == 0)
        #expect(sortedSets[1].order == 1)
        #expect(sortedSets[2].order == 2)
        #expect(sortedSets[0].weightUnit == Units.kg.rawValue)
    }

    @Test @MainActor
    func createWithSetsGuaranteesAtLeastOneSet() async throws {
        let container = try makeTestModelContainer()
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let service = LoggedExerciseService(modelContext: container.mainContext)

        let exercise = try await exerciseService.create(name: "Deadlift", type: .weightAndReps)
        let workout = try await workoutService.createEmpty()

        // setCount=0 should still create 1 set via max(setCount, 1)
        let logged = try await service.createWithSets(
            exercise: exercise, workout: workout, order: 0,
            setCount: 0, weightUnit: .lbs, distanceUnit: nil
        )

        #expect(logged.sets.count == 1)
    }

    @Test @MainActor
    func deleteReordersRemainingExercises() async throws {
        let container = try makeTestModelContainer()
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let service = LoggedExerciseService(modelContext: container.mainContext)

        let workout = try await workoutService.createEmpty()
        let ex1 = try await exerciseService.create(name: "Bench", type: .weightAndReps)
        let ex2 = try await exerciseService.create(name: "Rows", type: .weightAndReps)
        let ex3 = try await exerciseService.create(name: "Curls", type: .weightAndReps)

        let logged1 = try await service.create(exercise: ex1, workout: workout, order: 0, weightUnit: nil, distanceUnit: nil)
        let logged2 = try await service.create(exercise: ex2, workout: workout, order: 1, weightUnit: nil, distanceUnit: nil)
        let logged3 = try await service.create(exercise: ex3, workout: workout, order: 2, weightUnit: nil, distanceUnit: nil)

        // Delete middle exercise
        try await service.delete(logged2)

        #expect(workout.loggedExercises.count == 2)
        #expect(logged1.order == 0)
        #expect(logged3.order == 1) // Shifted from 2 to 1
    }

    @Test @MainActor
    func deleteFirstExerciseReordersAll() async throws {
        let container = try makeTestModelContainer()
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let service = LoggedExerciseService(modelContext: container.mainContext)

        let workout = try await workoutService.createEmpty()
        let ex1 = try await exerciseService.create(name: "Bench", type: .weightAndReps)
        let ex2 = try await exerciseService.create(name: "Rows", type: .weightAndReps)
        let ex3 = try await exerciseService.create(name: "Curls", type: .weightAndReps)

        let logged1 = try await service.create(exercise: ex1, workout: workout, order: 0, weightUnit: nil, distanceUnit: nil)
        let logged2 = try await service.create(exercise: ex2, workout: workout, order: 1, weightUnit: nil, distanceUnit: nil)
        let logged3 = try await service.create(exercise: ex3, workout: workout, order: 2, weightUnit: nil, distanceUnit: nil)

        try await service.delete(logged1)

        #expect(workout.loggedExercises.count == 2)
        #expect(logged2.order == 0) // Shifted from 1 to 0
        #expect(logged3.order == 1) // Shifted from 2 to 1
    }

    @Test @MainActor
    func deleteLastExerciseDoesNotReorder() async throws {
        let container = try makeTestModelContainer()
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let service = LoggedExerciseService(modelContext: container.mainContext)

        let workout = try await workoutService.createEmpty()
        let ex1 = try await exerciseService.create(name: "Bench", type: .weightAndReps)
        let ex2 = try await exerciseService.create(name: "Rows", type: .weightAndReps)
        let ex3 = try await exerciseService.create(name: "Curls", type: .weightAndReps)

        let logged1 = try await service.create(exercise: ex1, workout: workout, order: 0, weightUnit: nil, distanceUnit: nil)
        let logged2 = try await service.create(exercise: ex2, workout: workout, order: 1, weightUnit: nil, distanceUnit: nil)
        let logged3 = try await service.create(exercise: ex3, workout: workout, order: 2, weightUnit: nil, distanceUnit: nil)

        try await service.delete(logged3)

        #expect(workout.loggedExercises.count == 2)
        #expect(logged1.order == 0) // Unchanged
        #expect(logged2.order == 1) // Unchanged
    }

    @Test @MainActor
    func reorderUpdatesExerciseOrder() async throws {
        let container = try makeTestModelContainer()
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let service = LoggedExerciseService(modelContext: container.mainContext)

        let workout = try await workoutService.createEmpty()
        let ex1 = try await exerciseService.create(name: "Bench", type: .weightAndReps)
        let ex2 = try await exerciseService.create(name: "Rows", type: .weightAndReps)
        let ex3 = try await exerciseService.create(name: "Curls", type: .weightAndReps)

        let logged1 = try await service.create(exercise: ex1, workout: workout, order: 0, weightUnit: nil, distanceUnit: nil)
        let logged2 = try await service.create(exercise: ex2, workout: workout, order: 1, weightUnit: nil, distanceUnit: nil)
        let logged3 = try await service.create(exercise: ex3, workout: workout, order: 2, weightUnit: nil, distanceUnit: nil)

        // Reorder: [1,2,3] -> [3,1,2]
        try await service.reorder(exercises: [logged3, logged1, logged2], in: workout)

        #expect(logged3.order == 0)
        #expect(logged1.order == 1)
        #expect(logged2.order == 2)
    }

    @Test @MainActor
    func fetchByIdThrowsWhenNotFound() async throws {
        let container = try makeTestModelContainer()
        let service = LoggedExerciseService(modelContext: container.mainContext)

        await #expect(throws: ServiceError.self) {
            _ = try await service.fetch(id: UUID())
        }
    }

    @Test @MainActor
    func deleteExerciseWithNoWorkoutStillDeletes() async throws {
        let container = try makeTestModelContainer()
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let service = LoggedExerciseService(modelContext: container.mainContext)

        let exercise = try await exerciseService.create(name: "Orphan", type: .reps)
        let logged = SchemaV1.LoggedExercise(exercise: exercise, order: 0)
        container.mainContext.insert(logged)
        try container.mainContext.save()

        try await service.delete(logged)

        let descriptor = FetchDescriptor<SchemaV1.LoggedExercise>()
        let all = try container.mainContext.fetch(descriptor)
        #expect(all.isEmpty)
    }
}
