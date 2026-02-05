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

    func create(name: String, type: ExerciseType) async throws -> SchemaV1.Exercise {
        let exercise = SchemaV1.Exercise(name: name, type: type)
        modelContext.insert(exercise)
        try modelContext.save()
        return exercise
    }

    func update(_ exercise: SchemaV1.Exercise) async throws {
        try modelContext.save()
    }

    func delete(_ exercise: SchemaV1.Exercise) async throws {
        let hasExistingHistory = try await hasHistory(exercise)
        if hasExistingHistory {
            try await archive(exercise)
        } else {
            modelContext.delete(exercise)
            try modelContext.save()
        }
    }

    func archive(_ exercise: SchemaV1.Exercise) async throws {
        exercise.isArchived = true
        try modelContext.save()
    }

    func hasHistory(_ exercise: SchemaV1.Exercise) async throws -> Bool {
        return exercise.hasCompletedWorkout
    }
}
