import Foundation
import SwiftData

@MainActor
final class TemplateService: TemplateServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [SchemaV1.WorkoutTemplate] {
        let descriptor = FetchDescriptor<SchemaV1.WorkoutTemplate>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetch(id: UUID) async throws -> SchemaV1.WorkoutTemplate {
        var descriptor = FetchDescriptor<SchemaV1.WorkoutTemplate>()
        descriptor.predicate = #Predicate<SchemaV1.WorkoutTemplate> { template in
            template.id == id
        }
        guard let template = try modelContext.fetch(descriptor).first else {
            throw ServiceError.notFound("WorkoutTemplate")
        }
        return template
    }

    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.WorkoutTemplate? {
        modelContext.model(for: persistentId) as? SchemaV1.WorkoutTemplate
    }

    func create(name: String) async throws -> SchemaV1.WorkoutTemplate {
        let template = SchemaV1.WorkoutTemplate(name: name)
        modelContext.insert(template)
        try modelContext.save()
        return template
    }

    func update(_ template: SchemaV1.WorkoutTemplate) async throws {
        try modelContext.save()
    }

    func duplicate(_ template: SchemaV1.WorkoutTemplate) async throws -> SchemaV1.WorkoutTemplate {
        let newTemplate = SchemaV1.WorkoutTemplate(
            name: "\(template.name) (Copy)",
            notes: template.notes
        )
        modelContext.insert(newTemplate)

        let sortedExercises = template.templateExercises.sorted { $0.order < $1.order }
        for templateExercise in sortedExercises {
            guard let exercise = templateExercise.exercise else { continue }
            let newTemplateExercise = SchemaV1.TemplateExercise(
                exercise: exercise,
                order: templateExercise.order,
                targetSets: templateExercise.targetSets,
                targetReps: templateExercise.targetReps
            )
            newTemplateExercise.template = newTemplate
            modelContext.insert(newTemplateExercise)
        }

        try modelContext.save()
        return newTemplate
    }

    func delete(_ template: SchemaV1.WorkoutTemplate) async throws {
        modelContext.delete(template)
        try modelContext.save()
    }

    func addExercise(_ exercise: SchemaV1.Exercise, to template: SchemaV1.WorkoutTemplate, targetSets: Int?, targetReps: Int?) async throws {
        let maxOrder = template.templateExercises.map(\.order).max() ?? -1
        let templateExercise = SchemaV1.TemplateExercise(
            exercise: exercise,
            order: maxOrder + 1,
            targetSets: targetSets,
            targetReps: targetReps
        )
        templateExercise.template = template
        modelContext.insert(templateExercise)
        try modelContext.save()
    }

    func removeExercise(_ templateExercise: SchemaV1.TemplateExercise, from template: SchemaV1.WorkoutTemplate) async throws {
        let removedOrder = templateExercise.order
        modelContext.delete(templateExercise)

        for exercise in template.templateExercises where exercise.order > removedOrder {
            exercise.order -= 1
        }

        try modelContext.save()
    }

    func reorderExercises(_ template: SchemaV1.WorkoutTemplate, order: [UUID]) async throws {
        for (index, exerciseId) in order.enumerated() {
            if let templateExercise = template.templateExercises.first(where: { $0.id == exerciseId }) {
                templateExercise.order = index
            }
        }
        try modelContext.save()
    }
}
