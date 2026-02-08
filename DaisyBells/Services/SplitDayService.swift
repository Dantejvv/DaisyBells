import Foundation
import SwiftData

@MainActor
final class SplitDayService: SplitDayServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetch(id: UUID) async throws -> SchemaV1.SplitDay {
        var descriptor = FetchDescriptor<SchemaV1.SplitDay>()
        descriptor.predicate = #Predicate<SchemaV1.SplitDay> { day in
            day.id == id
        }
        guard let day = try modelContext.fetch(descriptor).first else {
            throw ServiceError.notFound("SplitDay")
        }
        return day
    }

    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.SplitDay? {
        modelContext.model(for: persistentId) as? SchemaV1.SplitDay
    }

    func create(name: String, split: SchemaV1.Split) async throws -> SchemaV1.SplitDay {
        // Determine next order value
        let nextOrder = split.days.count

        let day = SchemaV1.SplitDay(name: name, order: nextOrder)
        modelContext.insert(day)

        // Establish relationship
        day.split = split
        split.days.append(day)

        try modelContext.save()
        return day
    }

    func update(_ day: SchemaV1.SplitDay) async throws {
        try modelContext.save()
    }

    func delete(_ day: SchemaV1.SplitDay, from split: SchemaV1.Split) async throws {
        // Remove from split's days array
        if let index = split.days.firstIndex(where: { $0.id == day.id }) {
            split.days.remove(at: index)
        }

        modelContext.delete(day)

        // Sort remaining days by current order and reorder
        let sortedDays = split.days.sorted(by: { $0.order < $1.order })
        split.days = sortedDays

        // Reorder remaining days
        for (index, remainingDay) in split.days.enumerated() {
            remainingDay.order = index
        }

        try modelContext.save()
    }

    func reorder(days: [SchemaV1.SplitDay], in split: SchemaV1.Split) async throws {
        // Update order based on array position
        for (index, day) in days.enumerated() {
            day.order = index
        }

        // Update split's days array to match new order
        // Clear and rebuild to ensure SwiftData respects the order
        split.days.removeAll()
        for day in days {
            split.days.append(day)
        }

        try modelContext.save()
    }

    func assignWorkout(_ template: SchemaV1.WorkoutTemplate, to day: SchemaV1.SplitDay) async throws {
        // Check if already assigned
        guard !day.assignedWorkouts.contains(where: { $0.id == template.id }) else {
            return
        }

        day.assignedWorkouts.append(template)
        try modelContext.save()
    }

    func unassignWorkout(_ template: SchemaV1.WorkoutTemplate, from day: SchemaV1.SplitDay) async throws {
        if let index = day.assignedWorkouts.firstIndex(where: { $0.id == template.id }) {
            day.assignedWorkouts.remove(at: index)
            try modelContext.save()
        }
    }
}
