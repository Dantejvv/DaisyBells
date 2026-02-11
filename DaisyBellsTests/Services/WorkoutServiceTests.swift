import Foundation
import Testing
import SwiftData
@testable import DaisyBells

@Suite(.serialized)
struct WorkoutServiceTests {

    @Test @MainActor
    func createEmptyWorkout() async throws {
        let container = try makeTestModelContainer()
        let service = makeWorkoutService(modelContext: container.mainContext)

        let workout = try await service.createEmpty()

        #expect(workout.status == .active)
        #expect(workout.loggedExercises.isEmpty)
    }

    @Test @MainActor
    func fetchByIdReturnsWorkout() async throws {
        let container = try makeTestModelContainer()
        let service = makeWorkoutService(modelContext: container.mainContext)

        let created = try await service.createEmpty()
        let fetched = try await service.fetch(id: created.id)

        #expect(fetched.id == created.id)
    }

    @Test @MainActor
    func fetchByIdThrowsWhenNotFound() async throws {
        let container = try makeTestModelContainer()
        let service = makeWorkoutService(modelContext: container.mainContext)

        await #expect(throws: ServiceError.self) {
            try await service.fetch(id: UUID())
        }
    }

    @Test @MainActor
    func completeWorkout() async throws {
        let container = try makeTestModelContainer()
        let service = makeWorkoutService(modelContext: container.mainContext)

        let workout = try await service.createEmpty()
        try await service.complete(workout)

        #expect(workout.status == .completed)
        #expect(workout.completedAt != nil)
    }

    @Test @MainActor
    func cancelWorkout() async throws {
        let container = try makeTestModelContainer()
        let service = makeWorkoutService(modelContext: container.mainContext)

        let workout = try await service.createEmpty()
        try await service.cancel(workout)

        #expect(workout.status == .cancelled)
    }

    @Test @MainActor
    func fetchCompletedReturnsOnlyCompleted() async throws {
        let container = try makeTestModelContainer()
        let service = makeWorkoutService(modelContext: container.mainContext)

        let workout1 = try await service.createEmpty()
        _ = try await service.createEmpty() // Active workout
        try await service.complete(workout1)

        let completed = try await service.fetchCompleted()

        #expect(completed.count == 1)
        #expect(completed[0].id == workout1.id)
    }

    @Test @MainActor
    func fetchActiveReturnsActiveWorkout() async throws {
        let container = try makeTestModelContainer()
        let service = makeWorkoutService(modelContext: container.mainContext)

        let workout = try await service.createEmpty()

        let active = try await service.fetchActive()

        #expect(active?.id == workout.id)
    }

    @Test @MainActor
    func fetchActiveReturnsNilWhenNoActive() async throws {
        let container = try makeTestModelContainer()
        let service = makeWorkoutService(modelContext: container.mainContext)

        let active = try await service.fetchActive()

        #expect(active == nil)
    }

    @Test @MainActor
    func deleteRemovesWorkout() async throws {
        let container = try makeTestModelContainer()
        let service = makeWorkoutService(modelContext: container.mainContext)

        let workout = try await service.createEmpty()
        let id = workout.id
        try await service.delete(workout)

        await #expect(throws: ServiceError.self) {
            try await service.fetch(id: id)
        }
    }

    @Test @MainActor
    func addExerciseToWorkout() async throws {
        let container = try makeTestModelContainer()
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let loggedExerciseService = LoggedExerciseService(modelContext: container.mainContext)

        let workout = try await workoutService.createEmpty()
        let exercise = try await exerciseService.create(name: "Bench", type: .weightAndReps)

        let logged = try await loggedExerciseService.create(exercise: exercise, workout: workout, order: 0)

        #expect(workout.loggedExercises.count == 1)
        #expect(logged.exercise?.name == "Bench")
        #expect(logged.sets.count == 1) // Default set added
    }

    @Test @MainActor
    func addSetToLoggedExercise() async throws {
        let container = try makeTestModelContainer()
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let loggedExerciseService = LoggedExerciseService(modelContext: container.mainContext)
        let loggedSetService = LoggedSetService(modelContext: container.mainContext)

        let workout = try await workoutService.createEmpty()
        let exercise = try await exerciseService.create(name: "Squat", type: .weightAndReps)
        let logged = try await loggedExerciseService.create(exercise: exercise, workout: workout, order: 0)

        _ = try await loggedSetService.create(loggedExercise: logged, order: 1)

        #expect(logged.sets.count == 2)
    }

    @Test @MainActor
    func updateSet() async throws {
        let container = try makeTestModelContainer()
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let loggedExerciseService = LoggedExerciseService(modelContext: container.mainContext)
        let loggedSetService = LoggedSetService(modelContext: container.mainContext)

        let workout = try await workoutService.createEmpty()
        let exercise = try await exerciseService.create(name: "Deadlift", type: .weightAndReps)
        let logged = try await loggedExerciseService.create(exercise: exercise, workout: workout, order: 0)
        let set = logged.sets[0]

        try await loggedSetService.update(set, weight: 225, reps: 5, bodyweightModifier: nil, time: nil, distance: nil, notes: nil)

        #expect(set.weight == 225)
        #expect(set.reps == 5)
    }

    @Test @MainActor
    func updateNotes() async throws {
        let container = try makeTestModelContainer()
        let service = makeWorkoutService(modelContext: container.mainContext)

        let workout = try await service.createEmpty()
        try await service.updateNotes(workout, notes: "Great session")

        #expect(workout.notes == "Great session")
    }

    @Test @MainActor
    func createFromTemplate() async throws {
        let container = try makeTestModelContainer()
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let templateService = TemplateService(modelContext: container.mainContext)
        let exerciseService = ExerciseService(modelContext: container.mainContext)

        let template = try await templateService.create(name: "Push")
        let exercise = try await exerciseService.create(name: "Bench", type: .weightAndReps)
        try await templateService.addExercise(exercise, to: template)
        let templateExercise = template.templateExercises[0]
        let set1 = try await templateService.addSet(to: templateExercise)
        try await templateService.updateSet(set1, weight: 135, reps: 10, bodyweightModifier: nil, time: nil, distance: nil)
        _ = try await templateService.addSet(to: templateExercise)
        _ = try await templateService.addSet(to: templateExercise)

        let workout = try await workoutService.createFromTemplate(template)

        #expect(workout.fromTemplate?.id == template.id)
        #expect(workout.loggedExercises.count == 1)
        #expect(workout.loggedExercises[0].sets.count == 3)
        let firstLoggedSet = workout.loggedExercises[0].sets.sorted { $0.order < $1.order }[0]
        #expect(firstLoggedSet.weight == 135)
        #expect(firstLoggedSet.reps == 10)
    }
}
