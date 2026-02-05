import Foundation
import SwiftData

@MainActor
final class AnalyticsService: AnalyticsServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func workoutsThisWeek() async throws -> Int {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else {
            return 0
        }

        var descriptor = FetchDescriptor<SchemaV1.Workout>()
        let completedStatus = WorkoutStatus.completed.rawValue
        descriptor.predicate = #Predicate<SchemaV1.Workout> { workout in
            workout.statusValue == completedStatus
        }
        let workouts = try modelContext.fetch(descriptor)
        return workouts.filter { workout in
            guard let completedAt = workout.completedAt else { return false }
            return completedAt >= startOfWeek
        }.count
    }

    func workoutsThisMonth() async throws -> Int {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start else {
            return 0
        }

        var descriptor = FetchDescriptor<SchemaV1.Workout>()
        let completedStatus = WorkoutStatus.completed.rawValue
        descriptor.predicate = #Predicate<SchemaV1.Workout> { workout in
            workout.statusValue == completedStatus
        }
        let workouts = try modelContext.fetch(descriptor)
        return workouts.filter { workout in
            guard let completedAt = workout.completedAt else { return false }
            return completedAt >= startOfMonth
        }.count
    }

    func recentExercises(limit: Int) async throws -> [SchemaV1.Exercise] {
        var descriptor = FetchDescriptor<SchemaV1.Exercise>(
            sortBy: [SortDescriptor(\.lastPerformedAt, order: .reverse)]
        )
        descriptor.predicate = #Predicate<SchemaV1.Exercise> { exercise in
            exercise.lastPerformedAt != nil && exercise.isArchived == false
        }
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func personalRecords(limit: Int) async throws -> [PersonalRecord] {
        var descriptor = FetchDescriptor<SchemaV1.Exercise>(
            sortBy: [SortDescriptor(\.prAchievedAt, order: .reverse)]
        )
        descriptor.predicate = #Predicate<SchemaV1.Exercise> { exercise in
            exercise.prAchievedAt != nil && exercise.isArchived == false
        }
        descriptor.fetchLimit = limit

        let exercises = try modelContext.fetch(descriptor)

        return exercises.compactMap { exercise -> PersonalRecord? in
            guard let achievedAt = exercise.prAchievedAt else { return nil }
            return PersonalRecord(
                id: exercise.id,
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                exerciseType: exercise.type,
                achievedAt: achievedAt,
                weight: exercise.prWeight,
                reps: exercise.prReps,
                time: exercise.prTime,
                distance: exercise.prDistance,
                bodyweightModifier: nil
            )
        }
    }

    func volumeForExercise(_ exercise: SchemaV1.Exercise) async throws -> Double {
        return exercise.totalVolume
    }

    func personalBestForExercise(_ exercise: SchemaV1.Exercise) async throws -> PersonalRecord? {
        guard let achievedAt = exercise.prAchievedAt else { return nil }

        return PersonalRecord(
            id: exercise.id,
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            exerciseType: exercise.type,
            achievedAt: achievedAt,
            weight: exercise.prWeight,
            reps: exercise.prReps,
            time: exercise.prTime,
            distance: exercise.prDistance,
            bodyweightModifier: nil
        )
    }

    func lastPerformedDate(_ exercise: SchemaV1.Exercise) async throws -> Date? {
        return exercise.lastPerformedAt
    }

    func recentSetsForExercise(_ exercise: SchemaV1.Exercise, limit: Int) async throws -> [SchemaV1.LoggedSet] {
        let exerciseId = exercise.id
        var descriptor = FetchDescriptor<SchemaV1.LoggedSet>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse), SortDescriptor(\.order)]
        )
        descriptor.predicate = #Predicate<SchemaV1.LoggedSet> { set in
            set.exerciseId == exerciseId && set.completedAt != nil
        }
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }
}
