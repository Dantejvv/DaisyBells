import Foundation
import SwiftData

@MainActor
protocol CategoryServiceProtocol {
    static var maxNameLength: Int { get }
    func fetchAll() async throws -> [SchemaV1.ExerciseCategory]
    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.ExerciseCategory?
    func create(name: String) async throws -> SchemaV1.ExerciseCategory
    func update(_ category: SchemaV1.ExerciseCategory, name: String) async throws
    func reorder(categories: [SchemaV1.ExerciseCategory]) async throws
    func delete(_ category: SchemaV1.ExerciseCategory) async throws
}
