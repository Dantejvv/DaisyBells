import Foundation
import SwiftData

@MainActor
final class ExerciseService: ExerciseServiceProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() async throws -> [SchemaV1.Exercise] {
        var descriptor = FetchDescriptor<SchemaV1.Exercise>(
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.predicate = #Predicate<SchemaV1.Exercise> { exercise in
            exercise.isArchived == false
        }
        return try modelContext.fetch(descriptor)
    }
    
    func fetchByCategory(_ category: SchemaV1.ExerciseCategory) async throws -> [SchemaV1.Exercise] {
        // SwiftData #Predicate doesn't support complex relationship queries well,
        // so we filter in memory after fetching non-archived exercises
        let allExercises = try await fetchAll()
        return allExercises.filter { exercise in
            exercise.categories.contains { $0.id == category.id }
        }
    }
    
    func search(query: String) async throws -> [SchemaV1.Exercise] {
        guard !query.isEmpty else {
            return try await fetchAll()
        }
        var descriptor = FetchDescriptor<SchemaV1.Exercise>(
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.predicate = #Predicate<SchemaV1.Exercise> { exercise in
            exercise.isArchived == false && exercise.name.localizedStandardContains(query)
        }
        return try modelContext.fetch(descriptor)
    }
    
    func fetch(id: UUID) async throws -> SchemaV1.Exercise {
        var descriptor = FetchDescriptor<SchemaV1.Exercise>()
        descriptor.predicate = #Predicate<SchemaV1.Exercise> { exercise in
            exercise.id == id
        }
        guard let exercise = try modelContext.fetch(descriptor).first else {
            throw ServiceError.notFound("Exercise")
        }
        return exercise
    }
    
    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.Exercise? {
        modelContext.model(for: persistentId) as? SchemaV1.Exercise
    }
    
    func create(name: String, type: ExerciseType) async throws -> SchemaV1.Exercise {
        if let existing = try await findDuplicate(name: name, type: type, excluding: nil) {
            throw ExerciseServiceError.duplicateNameAndType(existing: existing)
        }
        let exercise = SchemaV1.Exercise(name: name, type: type)
        modelContext.insert(exercise)
        try modelContext.save()
        return exercise
    }

    func update(_ exercise: SchemaV1.Exercise) async throws {
        if let existing = try await findDuplicate(
            name: exercise.name,
            type: exercise.type,
            excluding: exercise.persistentModelID
        ) {
            throw ExerciseServiceError.duplicateNameAndType(existing: existing)
        }
        try modelContext.save()
    }

    func findDuplicate(
        name: String,
        type: ExerciseType,
        excluding: PersistentIdentifier?
    ) async throws -> SchemaV1.Exercise? {
        let normalized = Self.normalize(name)
        guard !normalized.isEmpty else { return nil }
        // SwiftData #Predicate on enum-typed fields fails at runtime on the persistent store
        // (works in in-memory test stores). Fetch all and filter in memory.
        let all = try modelContext.fetch(FetchDescriptor<SchemaV1.Exercise>())
        return all.first { candidate in
            candidate.type == type
                && Self.normalize(candidate.name) == normalized
                && candidate.persistentModelID != excluding
        }
    }

    static func normalize(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    func fetchArchived() async throws -> [SchemaV1.Exercise] {
        var descriptor = FetchDescriptor<SchemaV1.Exercise>(
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.predicate = #Predicate<SchemaV1.Exercise> { exercise in
            exercise.isArchived == true
        }
        return try modelContext.fetch(descriptor)
    }

    func delete(_ exercise: SchemaV1.Exercise) async throws {
        let hasExistingHistory = try await hasHistory(exercise)
        let usedInTemplate = try await isReferencedByTemplate(exercise)
        if hasExistingHistory || usedInTemplate {
            try await archive(exercise)
        } else {
            modelContext.delete(exercise)
            try modelContext.save()
        }
    }

    func isReferencedByTemplate(_ exercise: SchemaV1.Exercise) async throws -> Bool {
        let exerciseId = exercise.persistentModelID
        var descriptor = FetchDescriptor<SchemaV1.TemplateExercise>()
        descriptor.fetchLimit = 1
        let templateExercises = try modelContext.fetch(descriptor)
        return templateExercises.contains { $0.exercise?.persistentModelID == exerciseId }
    }
    
    func archive(_ exercise: SchemaV1.Exercise) async throws {
        exercise.isArchived = true
        try modelContext.save()
    }
    
    func hasHistory(_ exercise: SchemaV1.Exercise) async throws -> Bool {
        return exercise.hasCompletedWorkout
    }
}
