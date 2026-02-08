import Foundation
import SwiftData

@MainActor
final class SplitService: SplitServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [SchemaV1.Split] {
        let descriptor = FetchDescriptor<SchemaV1.Split>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetch(id: UUID) async throws -> SchemaV1.Split {
        var descriptor = FetchDescriptor<SchemaV1.Split>()
        descriptor.predicate = #Predicate<SchemaV1.Split> { split in
            split.id == id
        }
        guard let split = try modelContext.fetch(descriptor).first else {
            throw ServiceError.notFound("Split")
        }
        return split
    }

    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.Split? {
        modelContext.model(for: persistentId) as? SchemaV1.Split
    }

    func create(name: String) async throws -> SchemaV1.Split {
        let split = SchemaV1.Split(name: name)
        modelContext.insert(split)
        try modelContext.save()
        return split
    }

    func update(_ split: SchemaV1.Split) async throws {
        try modelContext.save()
    }

    func delete(_ split: SchemaV1.Split) async throws {
        // Cascade delete will automatically remove all SplitDays due to relationship deleteRule
        modelContext.delete(split)
        try modelContext.save()
    }
}
