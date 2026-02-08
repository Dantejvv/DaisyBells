import Foundation
import SwiftData

@MainActor
protocol TemplateServiceProtocol {
    func fetchAll() async throws -> [SchemaV1.WorkoutTemplate]
    func fetch(id: UUID) async throws -> SchemaV1.WorkoutTemplate
    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.WorkoutTemplate?
    func search(query: String) async throws -> [SchemaV1.WorkoutTemplate]
    func create(name: String) async throws -> SchemaV1.WorkoutTemplate
    func update(_ template: SchemaV1.WorkoutTemplate) async throws
    func duplicate(_ template: SchemaV1.WorkoutTemplate) async throws -> SchemaV1.WorkoutTemplate
    func delete(_ template: SchemaV1.WorkoutTemplate) async throws
    func addExercise(_ exercise: SchemaV1.Exercise, to template: SchemaV1.WorkoutTemplate, targetSets: Int?, targetReps: Int?) async throws
    func removeExercise(_ templateExercise: SchemaV1.TemplateExercise, from template: SchemaV1.WorkoutTemplate) async throws
    func reorderExercises(_ template: SchemaV1.WorkoutTemplate, order: [UUID]) async throws
}
