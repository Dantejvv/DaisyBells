import Foundation
import SwiftData

@MainActor
protocol WorkoutServiceProtocol {
    func createFromTemplate(_ template: SchemaV1.WorkoutTemplate) async throws -> SchemaV1.Workout
    func createEmpty() async throws -> SchemaV1.Workout
    func fetch(id: UUID) async throws -> SchemaV1.Workout
    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.Workout?
    func update(_ workout: SchemaV1.Workout) async throws
    func complete(_ workout: SchemaV1.Workout) async throws
    func cancel(_ workout: SchemaV1.Workout) async throws
    func lastPerformedSets(for exercise: SchemaV1.Exercise) async throws -> [SchemaV1.LoggedSet]
    func fetchCompleted() async throws -> [SchemaV1.Workout]
    func fetchActive() async throws -> SchemaV1.Workout?
    func delete(_ workout: SchemaV1.Workout) async throws
    func deleteAll() async throws
    func updateNotes(_ workout: SchemaV1.Workout, notes: String?) async throws
    func addExercise(_ exercise: SchemaV1.Exercise, to workout: SchemaV1.Workout) async throws -> SchemaV1.LoggedExercise
    func removeExercise(_ loggedExercise: SchemaV1.LoggedExercise, from workout: SchemaV1.Workout) async throws
    func addSet(to loggedExercise: SchemaV1.LoggedExercise) async throws -> SchemaV1.LoggedSet
    func removeSet(_ set: SchemaV1.LoggedSet, from loggedExercise: SchemaV1.LoggedExercise) async throws
    func updateSet(_ set: SchemaV1.LoggedSet) async throws
    func fetchRecent(limit: Int) async throws -> [SchemaV1.Workout]
}
