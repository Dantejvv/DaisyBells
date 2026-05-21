import Foundation
import SwiftData

enum ExerciseServiceError: LocalizedError {
    case duplicateNameAndType(existing: SchemaV1.Exercise)

    var errorDescription: String? {
        switch self {
        case .duplicateNameAndType(let existing):
            let state = existing.isArchived ? " (archived)" : ""
            return "An exercise named \"\(existing.name)\" with type \(existing.type.displayName) already exists\(state)."
        }
    }
}

@MainActor
protocol ExerciseServiceProtocol {
    func fetchAll() async throws -> [SchemaV1.Exercise]
    func fetchByCategory(_ category: SchemaV1.ExerciseCategory) async throws -> [SchemaV1.Exercise]
    func search(query: String) async throws -> [SchemaV1.Exercise]
    func fetch(id: UUID) async throws -> SchemaV1.Exercise
    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.Exercise?
    func create(name: String, type: ExerciseType) async throws -> SchemaV1.Exercise
    func update(_ exercise: SchemaV1.Exercise) async throws
    func fetchArchived() async throws -> [SchemaV1.Exercise]
    func delete(_ exercise: SchemaV1.Exercise) async throws
    func archive(_ exercise: SchemaV1.Exercise) async throws
    func hasHistory(_ exercise: SchemaV1.Exercise) async throws -> Bool
    func isReferencedByTemplate(_ exercise: SchemaV1.Exercise) async throws -> Bool
    func findDuplicate(
        name: String,
        type: ExerciseType,
        excluding: PersistentIdentifier?
    ) async throws -> SchemaV1.Exercise?
}
