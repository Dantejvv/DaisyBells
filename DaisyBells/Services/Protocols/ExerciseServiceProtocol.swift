import Foundation
import SwiftData

@MainActor
protocol ExerciseServiceProtocol {
    func fetchAll() async throws -> [SchemaV1.Exercise]
    func fetchByCategory(_ category: SchemaV1.ExerciseCategory) async throws -> [SchemaV1.Exercise]
    func search(query: String) async throws -> [SchemaV1.Exercise]
    func fetch(id: UUID) async throws -> SchemaV1.Exercise
    func create(name: String, type: ExerciseType) async throws -> SchemaV1.Exercise
    func update(_ exercise: SchemaV1.Exercise) async throws
    func delete(_ exercise: SchemaV1.Exercise) async throws
    func archive(_ exercise: SchemaV1.Exercise) async throws
    func hasHistory(_ exercise: SchemaV1.Exercise) async throws -> Bool
}
