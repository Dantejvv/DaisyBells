import Foundation
import SwiftData

@MainActor
final class LoggedExerciseService: LoggedExerciseServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func create(exercise: SchemaV1.Exercise, workout: SchemaV1.Workout, order: Int) async throws -> SchemaV1.LoggedExercise {
        let loggedExercise = SchemaV1.LoggedExercise(
            exercise: exercise,
            order: order
        )
        loggedExercise.workout = workout
        modelContext.insert(loggedExercise)

        // Create initial empty set
        let loggedSet = SchemaV1.LoggedSet(order: 0)
        loggedSet.loggedExercise = loggedExercise
        modelContext.insert(loggedSet)

        try modelContext.save()
        return loggedExercise
    }

    func update(_ loggedExercise: SchemaV1.LoggedExercise) async throws {
        try modelContext.save()
    }

    func delete(_ loggedExercise: SchemaV1.LoggedExercise) async throws {
        guard let workout = loggedExercise.workout else {
            modelContext.delete(loggedExercise)
            try modelContext.save()
            return
        }

        let removedOrder = loggedExercise.order
        modelContext.delete(loggedExercise)

        // Adjust order of remaining exercises
        for exercise in workout.loggedExercises where exercise.order > removedOrder {
            exercise.order -= 1
        }

        try modelContext.save()
    }

    func reorder(exercises: [SchemaV1.LoggedExercise], in workout: SchemaV1.Workout) async throws {
        for (index, exercise) in exercises.enumerated() {
            exercise.order = index
        }
        try modelContext.save()
    }

    func fetch(id: UUID) async throws -> SchemaV1.LoggedExercise {
        var descriptor = FetchDescriptor<SchemaV1.LoggedExercise>()
        descriptor.predicate = #Predicate<SchemaV1.LoggedExercise> { loggedExercise in
            loggedExercise.id == id
        }
        guard let loggedExercise = try modelContext.fetch(descriptor).first else {
            throw ServiceError.notFound("LoggedExercise")
        }
        return loggedExercise
    }

    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.LoggedExercise? {
        modelContext.model(for: persistentId) as? SchemaV1.LoggedExercise
    }
}
