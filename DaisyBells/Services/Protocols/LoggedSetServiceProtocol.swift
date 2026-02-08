import Foundation
import SwiftData

@MainActor
protocol LoggedSetServiceProtocol {
    // CRUD operations
    func create(loggedExercise: SchemaV1.LoggedExercise, order: Int) async throws -> SchemaV1.LoggedSet
    func update(_ set: SchemaV1.LoggedSet, weight: Double?, reps: Int?, bodyweightModifier: Double?, time: TimeInterval?, distance: Double?, notes: String?) async throws
    func delete(_ set: SchemaV1.LoggedSet) async throws

    // Fetch
    func fetch(id: UUID) async throws -> SchemaV1.LoggedSet
    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.LoggedSet?
}
