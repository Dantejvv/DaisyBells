import Foundation
import SwiftData

@MainActor
protocol LoggedExerciseServiceProtocol {
    // CRUD operations
    func create(exercise: SchemaV1.Exercise, workout: SchemaV1.Workout, order: Int) async throws -> SchemaV1.LoggedExercise
    func update(_ loggedExercise: SchemaV1.LoggedExercise) async throws
    func delete(_ loggedExercise: SchemaV1.LoggedExercise) async throws

    // Ordering
    func reorder(exercises: [SchemaV1.LoggedExercise], in workout: SchemaV1.Workout) async throws

    // Fetch
    func fetch(id: UUID) async throws -> SchemaV1.LoggedExercise
    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.LoggedExercise?
}
