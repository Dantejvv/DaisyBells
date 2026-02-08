import Foundation
import SwiftData

@MainActor
final class WorkoutService: WorkoutServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createFromTemplate(_ template: SchemaV1.WorkoutTemplate) async throws -> SchemaV1.Workout {
        let workout = SchemaV1.Workout(fromTemplate: template)
        modelContext.insert(workout)

        let sortedTemplateExercises = template.templateExercises.sorted { $0.order < $1.order }
        for templateExercise in sortedTemplateExercises {
            guard let exercise = templateExercise.exercise else { continue }

            let loggedExercise = SchemaV1.LoggedExercise(
                exercise: exercise,
                order: templateExercise.order
            )
            loggedExercise.workout = workout
            modelContext.insert(loggedExercise)

            let targetSets = templateExercise.targetSets ?? 3
            for setIndex in 0..<targetSets {
                let loggedSet = SchemaV1.LoggedSet(order: setIndex)
                loggedSet.loggedExercise = loggedExercise
                modelContext.insert(loggedSet)
            }
        }

        try modelContext.save()
        return workout
    }

    func createEmpty() async throws -> SchemaV1.Workout {
        let workout = SchemaV1.Workout()
        modelContext.insert(workout)
        try modelContext.save()
        return workout
    }

    func fetch(id: UUID) async throws -> SchemaV1.Workout {
        var descriptor = FetchDescriptor<SchemaV1.Workout>()
        descriptor.predicate = #Predicate<SchemaV1.Workout> { workout in
            workout.id == id
        }
        guard let workout = try modelContext.fetch(descriptor).first else {
            throw ServiceError.notFound("Workout")
        }
        return workout
    }

    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.Workout? {
        modelContext.model(for: persistentId) as? SchemaV1.Workout
    }

    func update(_ workout: SchemaV1.Workout) async throws {
        try modelContext.save()
    }

    func complete(_ workout: SchemaV1.Workout) async throws {
        let completedAt = Date()
        workout.status = .completed
        workout.completedAt = completedAt

        updateExerciseStats(for: workout, completedAt: completedAt)
        updateLoggedSetDenormalization(for: workout, completedAt: completedAt)

        try modelContext.save()
    }

    // MARK: - Stats Update Helpers

    private func updateExerciseStats(for workout: SchemaV1.Workout, completedAt: Date) {
        for loggedExercise in workout.loggedExercises {
            guard let exercise = loggedExercise.exercise else { continue }

            exercise.lastPerformedAt = completedAt
            exercise.hasCompletedWorkout = true

            var sessionVolume: Double = 0
            for set in loggedExercise.sets {
                if let weight = set.weight, let reps = set.reps {
                    sessionVolume += weight * Double(reps)
                }

                if shouldUpdatePersonalRecord(exercise: exercise, set: set) {
                    exercise.prWeight = set.weight
                    exercise.prReps = set.reps
                    exercise.prTime = set.time
                    exercise.prDistance = set.distance
                    exercise.prAchievedAt = completedAt
                    exercise.prEstimated1RM = calculateEstimated1RM(weight: set.weight, reps: set.reps)
                }
            }
            exercise.totalVolume += sessionVolume
        }
    }

    private func updateLoggedSetDenormalization(for workout: SchemaV1.Workout, completedAt: Date) {
        for loggedExercise in workout.loggedExercises {
            let exerciseId = loggedExercise.exercise?.id
            for set in loggedExercise.sets {
                set.exerciseId = exerciseId
                set.completedAt = completedAt
            }
        }
    }

    private func shouldUpdatePersonalRecord(exercise: SchemaV1.Exercise, set: SchemaV1.LoggedSet) -> Bool {
        switch exercise.type {
        case .weightAndReps:
            guard let newEstimate = calculateEstimated1RM(weight: set.weight, reps: set.reps) else {
                return false
            }
            return newEstimate > (exercise.prEstimated1RM ?? 0)

        case .bodyweightAndReps, .reps:
            guard let newReps = set.reps else { return false }
            return newReps > (exercise.prReps ?? 0)

        case .time, .weightAndTime:
            guard let newTime = set.time else { return false }
            return newTime > (exercise.prTime ?? 0)

        case .distanceAndTime:
            guard let newDistance = set.distance else { return false }
            return newDistance > (exercise.prDistance ?? 0)
        }
    }

    private func calculateEstimated1RM(weight: Double?, reps: Int?) -> Double? {
        guard let weight, let reps, reps > 0 else { return nil }
        return weight * (1 + Double(reps) / 30.0)
    }

    func cancel(_ workout: SchemaV1.Workout) async throws {
        workout.status = .cancelled
        workout.completedAt = Date()
        try modelContext.save()
    }

    func lastPerformedSets(for exercise: SchemaV1.Exercise) async throws -> [SchemaV1.LoggedSet] {
        let exerciseId = exercise.id
        var descriptor = FetchDescriptor<SchemaV1.LoggedSet>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse), SortDescriptor(\.order)]
        )
        descriptor.predicate = #Predicate<SchemaV1.LoggedSet> { set in
            set.exerciseId == exerciseId && set.completedAt != nil
        }

        let allSets = try modelContext.fetch(descriptor)

        guard let mostRecentDate = allSets.first?.completedAt else { return [] }

        return allSets.filter { $0.completedAt == mostRecentDate }
    }

    func fetchCompleted() async throws -> [SchemaV1.Workout] {
        var descriptor = FetchDescriptor<SchemaV1.Workout>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        let completedStatus = WorkoutStatus.completed.rawValue
        descriptor.predicate = #Predicate<SchemaV1.Workout> { workout in
            workout.statusValue == completedStatus
        }
        return try modelContext.fetch(descriptor)
    }

    func fetchActive() async throws -> SchemaV1.Workout? {
        var descriptor = FetchDescriptor<SchemaV1.Workout>()
        let activeStatus = WorkoutStatus.active.rawValue
        descriptor.predicate = #Predicate<SchemaV1.Workout> { workout in
            workout.statusValue == activeStatus
        }
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func delete(_ workout: SchemaV1.Workout) async throws {
        modelContext.delete(workout)
        try modelContext.save()
    }

    func deleteAll() async throws {
        let descriptor = FetchDescriptor<SchemaV1.Workout>()
        let workouts = try modelContext.fetch(descriptor)
        for workout in workouts {
            modelContext.delete(workout)
        }
        try modelContext.save()
    }

    func updateNotes(_ workout: SchemaV1.Workout, notes: String?) async throws {
        workout.notes = notes
        try modelContext.save()
    }

    func addExercise(_ exercise: SchemaV1.Exercise, to workout: SchemaV1.Workout) async throws -> SchemaV1.LoggedExercise {
        let maxOrder = workout.loggedExercises.map(\.order).max() ?? -1
        let loggedExercise = SchemaV1.LoggedExercise(
            exercise: exercise,
            order: maxOrder + 1
        )
        loggedExercise.workout = workout
        modelContext.insert(loggedExercise)

        let loggedSet = SchemaV1.LoggedSet(order: 0)
        loggedSet.loggedExercise = loggedExercise
        modelContext.insert(loggedSet)

        try modelContext.save()
        return loggedExercise
    }

    func removeExercise(_ loggedExercise: SchemaV1.LoggedExercise, from workout: SchemaV1.Workout) async throws {
        let removedOrder = loggedExercise.order
        modelContext.delete(loggedExercise)

        for exercise in workout.loggedExercises where exercise.order > removedOrder {
            exercise.order -= 1
        }

        try modelContext.save()
    }

    func addSet(to loggedExercise: SchemaV1.LoggedExercise) async throws -> SchemaV1.LoggedSet {
        let maxOrder = loggedExercise.sets.map(\.order).max() ?? -1
        let loggedSet = SchemaV1.LoggedSet(order: maxOrder + 1)
        loggedSet.loggedExercise = loggedExercise
        modelContext.insert(loggedSet)
        try modelContext.save()
        return loggedSet
    }

    func removeSet(_ set: SchemaV1.LoggedSet, from loggedExercise: SchemaV1.LoggedExercise) async throws {
        let removedOrder = set.order
        modelContext.delete(set)

        for existingSet in loggedExercise.sets where existingSet.order > removedOrder {
            existingSet.order -= 1
        }

        try modelContext.save()
    }

    func updateSet(_ set: SchemaV1.LoggedSet) async throws {
        try modelContext.save()
    }
    
    func fetchRecent(limit: Int) async throws -> [SchemaV1.Workout] {
        let completedRawValue = WorkoutStatus.completed.rawValue
        var descriptor = FetchDescriptor<SchemaV1.Workout>(
            sortBy: [
                SortDescriptor(\.completedAt, order: .reverse)
            ]
        )
        // Keep predicate simple for SwiftData reliability
        descriptor.predicate = #Predicate<SchemaV1.Workout> { workout in
            workout.completedAt != nil &&
            workout.statusValue == completedRawValue
        }
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }
}
