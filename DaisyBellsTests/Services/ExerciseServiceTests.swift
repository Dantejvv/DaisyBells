import Foundation
import Testing
import SwiftData
@testable import DaisyBells

@Suite(.serialized)
struct ExerciseServiceTests {

    @Test @MainActor
    func fetchAllReturnsEmptyInitially() async throws {
        let container = try makeTestModelContainer()
        let service = ExerciseService(modelContext: container.mainContext)

        let exercises = try await service.fetchAll()

        #expect(exercises.isEmpty)
    }

    @Test @MainActor
    func createAddsExercise() async throws {
        let container = try makeTestModelContainer()
        let service = ExerciseService(modelContext: container.mainContext)

        let exercise = try await service.create(name: "Bench Press", type: .weightAndReps)

        #expect(exercise.name == "Bench Press")
        #expect(exercise.type == .weightAndReps)
        #expect(!exercise.isArchived)
        #expect(!exercise.isFavorite)
    }

    @Test @MainActor
    func fetchByIdReturnsExercise() async throws {
        let container = try makeTestModelContainer()
        let service = ExerciseService(modelContext: container.mainContext)

        let created = try await service.create(name: "Squat", type: .weightAndReps)
        let fetched = try await service.fetch(id: created.id)

        #expect(fetched.id == created.id)
        #expect(fetched.name == "Squat")
    }

    @Test @MainActor
    func fetchByIdThrowsWhenNotFound() async throws {
        let container = try makeTestModelContainer()
        let service = ExerciseService(modelContext: container.mainContext)

        await #expect(throws: ServiceError.self) {
            try await service.fetch(id: UUID())
        }
    }

    @Test @MainActor
    func fetchAllExcludesArchived() async throws {
        let container = try makeTestModelContainer()
        let service = ExerciseService(modelContext: container.mainContext)

        let exercise1 = try await service.create(name: "Active", type: .weightAndReps)
        let exercise2 = try await service.create(name: "Archived", type: .weightAndReps)
        try await service.archive(exercise2)

        let all = try await service.fetchAll()

        #expect(all.count == 1)
        #expect(all[0].id == exercise1.id)
    }

    @Test @MainActor
    func searchFindsMatchingExercises() async throws {
        let container = try makeTestModelContainer()
        let service = ExerciseService(modelContext: container.mainContext)

        _ = try await service.create(name: "Bench Press", type: .weightAndReps)
        _ = try await service.create(name: "Incline Bench", type: .weightAndReps)
        _ = try await service.create(name: "Squat", type: .weightAndReps)

        let results = try await service.search(query: "bench")

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.name.lowercased().contains("bench") })
    }

    @Test @MainActor
    func searchWithEmptyQueryReturnsAll() async throws {
        let container = try makeTestModelContainer()
        let service = ExerciseService(modelContext: container.mainContext)

        _ = try await service.create(name: "Exercise 1", type: .weightAndReps)
        _ = try await service.create(name: "Exercise 2", type: .reps)

        let results = try await service.search(query: "")

        #expect(results.count == 2)
    }

    @Test @MainActor
    func deletePermanentlyRemovesExerciseWithoutHistory() async throws {
        let container = try makeTestModelContainer()
        let service = ExerciseService(modelContext: container.mainContext)

        let exercise = try await service.create(name: "NoHistory", type: .weightAndReps)
        let exerciseId = exercise.id

        try await service.delete(exercise)

        await #expect(throws: ServiceError.self) {
            try await service.fetch(id: exerciseId)
        }
    }

    @Test @MainActor
    func hasHistoryReturnsFalseForNewExercise() async throws {
        let container = try makeTestModelContainer()
        let service = ExerciseService(modelContext: container.mainContext)

        let exercise = try await service.create(name: "New", type: .weightAndReps)

        let hasHistory = try await service.hasHistory(exercise)

        #expect(!hasHistory)
    }
}
