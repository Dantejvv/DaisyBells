import Foundation
import SwiftData

@MainActor
final class LoggedSetService: LoggedSetServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func create(loggedExercise: SchemaV1.LoggedExercise, order: Int) async throws -> SchemaV1.LoggedSet {
        let loggedSet = SchemaV1.LoggedSet(order: order)
        loggedSet.loggedExercise = loggedExercise
        modelContext.insert(loggedSet)
        try modelContext.save()
        return loggedSet
    }

    func update(_ set: SchemaV1.LoggedSet, weight: Double?, reps: Int?, bodyweightModifier: Double?, time: TimeInterval?, distance: Double?, notes: String?) async throws {
        set.weight = weight
        set.reps = reps
        set.bodyweightModifier = bodyweightModifier
        set.time = time
        set.distance = distance
        set.notes = notes

        try modelContext.save()
    }

    func delete(_ set: SchemaV1.LoggedSet) async throws {
        guard let loggedExercise = set.loggedExercise else {
            modelContext.delete(set)
            try modelContext.save()
            return
        }

        let removedOrder = set.order
        modelContext.delete(set)

        // Adjust order of remaining sets
        for existingSet in loggedExercise.sets where existingSet.order > removedOrder {
            existingSet.order -= 1
        }

        try modelContext.save()
    }

    func fetch(id: UUID) async throws -> SchemaV1.LoggedSet {
        var descriptor = FetchDescriptor<SchemaV1.LoggedSet>()
        descriptor.predicate = #Predicate<SchemaV1.LoggedSet> { set in
            set.id == id
        }
        guard let set = try modelContext.fetch(descriptor).first else {
            throw ServiceError.notFound("LoggedSet")
        }
        return set
    }

    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.LoggedSet? {
        modelContext.model(for: persistentId) as? SchemaV1.LoggedSet
    }
}
