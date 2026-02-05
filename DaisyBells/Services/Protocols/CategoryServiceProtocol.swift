import Foundation
import SwiftData

@MainActor
protocol CategoryServiceProtocol {
    func fetchAll() async throws -> [SchemaV1.ExerciseCategory]
    func create(name: String) async throws -> SchemaV1.ExerciseCategory
    func delete(_ category: SchemaV1.ExerciseCategory) async throws
}
