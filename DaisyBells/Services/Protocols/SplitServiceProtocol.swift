import Foundation
import SwiftData

@MainActor
protocol SplitServiceProtocol {
    func fetchAll() async throws -> [SchemaV1.Split]
    func fetch(id: UUID) async throws -> SchemaV1.Split
    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.Split?
    func create(name: String) async throws -> SchemaV1.Split
    func update(_ split: SchemaV1.Split) async throws
    func delete(_ split: SchemaV1.Split) async throws
}
