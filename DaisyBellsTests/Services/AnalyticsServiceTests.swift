import Foundation
import Testing
import SwiftData
@testable import DaisyBells

@Suite(.serialized)
struct AnalyticsServiceTests {

    @Test @MainActor
    func workoutsThisWeekCountsCorrectly() async throws {
        let container = try makeTestModelContainer()
        let analyticsService = AnalyticsService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)

        let workout = try await workoutService.createEmpty()
        try await workoutService.complete(workout)

        let count = try await analyticsService.workoutsThisWeek()

        #expect(count == 1)
    }

    @Test @MainActor
    func workoutsThisMonthCountsCorrectly() async throws {
        let container = try makeTestModelContainer()
        let analyticsService = AnalyticsService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)

        let workout1 = try await workoutService.createEmpty()
        let workout2 = try await workoutService.createEmpty()
        try await workoutService.complete(workout1)
        try await workoutService.complete(workout2)

        let count = try await analyticsService.workoutsThisMonth()

        #expect(count == 2)
    }

    @Test @MainActor
    func recentExercisesReturnsUnique() async throws {
        let container = try makeTestModelContainer()
        let analyticsService = AnalyticsService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let loggedExerciseService = LoggedExerciseService(modelContext: container.mainContext)

        let exercise = try await exerciseService.create(name: "Bench", type: .weightAndReps)
        let workout = try await workoutService.createEmpty()
        _ = try await loggedExerciseService.create(exercise: exercise, workout: workout, order: 0)
        try await workoutService.complete(workout)

        let recent = try await analyticsService.recentExercises(limit: 10)

        #expect(recent.count == 1)
        #expect(recent[0].name == "Bench")
    }

    @Test @MainActor
    func volumeForExerciseCalculatesCorrectly() async throws {
        let container = try makeTestModelContainer()
        let analyticsService = AnalyticsService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let loggedExerciseService = LoggedExerciseService(modelContext: container.mainContext)
        let loggedSetService = LoggedSetService(modelContext: container.mainContext)

        let exercise = try await exerciseService.create(name: "Squat", type: .weightAndReps)
        let workout = try await workoutService.createEmpty()
        let logged = try await loggedExerciseService.create(exercise: exercise, workout: workout, order: 0)

        try await loggedSetService.update(logged.sets[0], weight: 100, reps: 10, bodyweightModifier: nil, time: nil, distance: nil, notes: nil)

        try await workoutService.complete(workout)

        let volume = try await analyticsService.volumeForExercise(exercise)

        #expect(volume == 1000) // 100 * 10
    }

    @Test @MainActor
    func lastPerformedDateReturnsCorrectDate() async throws {
        let container = try makeTestModelContainer()
        let analyticsService = AnalyticsService(modelContext: container.mainContext)
        let workoutService = makeWorkoutService(modelContext: container.mainContext)
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let loggedExerciseService = LoggedExerciseService(modelContext: container.mainContext)

        let exercise = try await exerciseService.create(name: "Deadlift", type: .weightAndReps)
        let workout = try await workoutService.createEmpty()
        _ = try await loggedExerciseService.create(exercise: exercise, workout: workout, order: 0)
        try await workoutService.complete(workout)

        let lastDate = try await analyticsService.lastPerformedDate(exercise)

        #expect(lastDate != nil)
    }

    @Test @MainActor
    func lastPerformedDateReturnsNilForUnusedExercise() async throws {
        let container = try makeTestModelContainer()
        let analyticsService = AnalyticsService(modelContext: container.mainContext)
        let exerciseService = ExerciseService(modelContext: container.mainContext)

        let exercise = try await exerciseService.create(name: "Unused", type: .weightAndReps)

        let lastDate = try await analyticsService.lastPerformedDate(exercise)

        #expect(lastDate == nil)
    }
}
