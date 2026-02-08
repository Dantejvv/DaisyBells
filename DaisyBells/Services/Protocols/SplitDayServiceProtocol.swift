import Foundation
import SwiftData

@MainActor
protocol SplitDayServiceProtocol {
    func fetch(id: UUID) async throws -> SchemaV1.SplitDay
    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.SplitDay?
    func fetchBySplitTemplate(_ template: SchemaV1.WorkoutTemplate) async throws -> [SchemaV1.SplitDay]
    func create(name: String, split: SchemaV1.Split) async throws -> SchemaV1.SplitDay
    func update(_ day: SchemaV1.SplitDay) async throws
    func delete(_ day: SchemaV1.SplitDay, from split: SchemaV1.Split) async throws
    func reorder(days: [SchemaV1.SplitDay], in split: SchemaV1.Split) async throws
    func assignWorkout(_ template: SchemaV1.WorkoutTemplate, to day: SchemaV1.SplitDay) async throws
    func unassignWorkout(_ template: SchemaV1.WorkoutTemplate, from day: SchemaV1.SplitDay) async throws
}
