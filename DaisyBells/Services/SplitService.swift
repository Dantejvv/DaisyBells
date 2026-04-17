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

    func create(name: String, notes: String?) async throws -> SchemaV1.Split {
        let split = SchemaV1.Split(name: name, notes: notes)
        modelContext.insert(split)
        try modelContext.save()
        return split
    }

    func update(_ split: SchemaV1.Split) async throws {
        try modelContext.save()
    }

    func delete(id: UUID) async throws {
        // Fetch fresh from ModelContext to avoid stale references after async boundaries
        let split = try await fetch(id: id)
        // Cascade delete will automatically remove all SplitDays due to relationship deleteRule
        modelContext.delete(split)
        try modelContext.save()
    }

    func skipDay(at index: Int, in split: SchemaV1.Split) async throws {
        let sortedDays = split.days.sorted { $0.order < $1.order }
        guard index >= 0 && index < sortedDays.count else {
            throw ServiceError.invalidOperation("Day index \(index) out of range")
        }
        sortedDays[index].isCompletedInCycle = true
        try modelContext.save()
    }

    func uncompleteDay(at index: Int, in split: SchemaV1.Split) async throws {
        let sortedDays = split.days.sorted { $0.order < $1.order }
        guard index >= 0 && index < sortedDays.count else {
            throw ServiceError.invalidOperation("Day index \(index) out of range")
        }
        sortedDays[index].isCompletedInCycle = false
        try modelContext.save()
    }

    func resetCycle(_ split: SchemaV1.Split) async throws {
        for day in split.days {
            day.isCompletedInCycle = false
        }
        try modelContext.save()
    }
}
