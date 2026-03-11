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

    func delete(_ split: SchemaV1.Split) async throws {
        // Cascade delete will automatically remove all SplitDays due to relationship deleteRule
        modelContext.delete(split)
        try modelContext.save()
    }

    func setCurrentDay(index: Int, in split: SchemaV1.Split) async throws {
        let sortedDays = split.days.sorted { $0.order < $1.order }
        guard index >= 0 && index < sortedDays.count else {
            throw ServiceError.invalidOperation("Day index \(index) out of range")
        }
        split.currentDayIndex = index
        try modelContext.save()
    }

    func skipDay(at index: Int, in split: SchemaV1.Split) async throws {
        let sortedDays = split.days.sorted { $0.order < $1.order }
        guard index >= 0 && index < sortedDays.count else {
            throw ServiceError.invalidOperation("Day index \(index) out of range")
        }
        sortedDays[index].isCompletedInCycle = true

        if index == split.currentDayIndex {
            try await advanceDay(in: split)
        }

        try await resetCycleIfComplete(split)
    }

    func advanceDay(in split: SchemaV1.Split) async throws {
        let sortedDays = split.days.sorted { $0.order < $1.order }
        guard !sortedDays.isEmpty else { return }

        // Find next uncompleted day after currentDayIndex (wrapping)
        let count = sortedDays.count
        for offset in 1...count {
            let candidateIndex = (split.currentDayIndex + offset) % count
            if !sortedDays[candidateIndex].isCompletedInCycle {
                split.currentDayIndex = candidateIndex
                try modelContext.save()
                return
            }
        }

        // All complete — reset cycle
        try await resetCycleIfComplete(split)
    }

    func resetCycleIfComplete(_ split: SchemaV1.Split) async throws {
        let sortedDays = split.days.sorted { $0.order < $1.order }
        guard !sortedDays.isEmpty else { return }

        let allComplete = sortedDays.allSatisfy(\.isCompletedInCycle)
        guard allComplete else { return }

        for day in sortedDays {
            day.isCompletedInCycle = false
        }
        split.currentDayIndex = 0
        try modelContext.save()
    }
}
