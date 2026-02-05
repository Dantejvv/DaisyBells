import Foundation
import Testing
import SwiftData
@testable import DaisyBells

@Suite(.serialized)
struct TemplateServiceTests {

    @Test @MainActor
    func fetchAllReturnsEmptyInitially() async throws {
        let container = try makeTestModelContainer()
        let service = TemplateService(modelContext: container.mainContext)

        let templates = try await service.fetchAll()

        #expect(templates.isEmpty)
    }

    @Test @MainActor
    func createAddsTemplate() async throws {
        let container = try makeTestModelContainer()
        let service = TemplateService(modelContext: container.mainContext)

        let template = try await service.create(name: "Push Day")

        #expect(template.name == "Push Day")
        #expect(template.templateExercises.isEmpty)
    }

    @Test @MainActor
    func fetchByIdReturnsTemplate() async throws {
        let container = try makeTestModelContainer()
        let service = TemplateService(modelContext: container.mainContext)

        let created = try await service.create(name: "Pull Day")
        let fetched = try await service.fetch(id: created.id)

        #expect(fetched.id == created.id)
        #expect(fetched.name == "Pull Day")
    }

    @Test @MainActor
    func fetchByIdThrowsWhenNotFound() async throws {
        let container = try makeTestModelContainer()
        let service = TemplateService(modelContext: container.mainContext)

        await #expect(throws: ServiceError.self) {
            try await service.fetch(id: UUID())
        }
    }

    @Test @MainActor
    func deleteRemovesTemplate() async throws {
        let container = try makeTestModelContainer()
        let service = TemplateService(modelContext: container.mainContext)

        let template = try await service.create(name: "ToDelete")
        try await service.delete(template)

        let all = try await service.fetchAll()
        #expect(all.isEmpty)
    }

    @Test @MainActor
    func addExerciseToTemplate() async throws {
        let container = try makeTestModelContainer()
        let templateService = TemplateService(modelContext: container.mainContext)
        let exerciseService = ExerciseService(modelContext: container.mainContext)

        let template = try await templateService.create(name: "Test")
        let exercise = try await exerciseService.create(name: "Bench", type: .weightAndReps)

        try await templateService.addExercise(exercise, to: template, targetSets: 3, targetReps: 10)

        #expect(template.templateExercises.count == 1)
        #expect(template.templateExercises[0].exercise?.name == "Bench")
        #expect(template.templateExercises[0].targetSets == 3)
        #expect(template.templateExercises[0].targetReps == 10)
    }

    @Test @MainActor
    func duplicateCreatesCopy() async throws {
        let container = try makeTestModelContainer()
        let templateService = TemplateService(modelContext: container.mainContext)
        let exerciseService = ExerciseService(modelContext: container.mainContext)

        let template = try await templateService.create(name: "Original")
        let exercise = try await exerciseService.create(name: "Squat", type: .weightAndReps)
        try await templateService.addExercise(exercise, to: template, targetSets: 4, targetReps: 8)

        let copy = try await templateService.duplicate(template)

        #expect(copy.name == "Original (Copy)")
        #expect(copy.id != template.id)
        #expect(copy.templateExercises.count == 1)
    }

    @Test @MainActor
    func reorderExercises() async throws {
        let container = try makeTestModelContainer()
        let templateService = TemplateService(modelContext: container.mainContext)
        let exerciseService = ExerciseService(modelContext: container.mainContext)

        let template = try await templateService.create(name: "Test")
        let ex1 = try await exerciseService.create(name: "First", type: .weightAndReps)
        let ex2 = try await exerciseService.create(name: "Second", type: .weightAndReps)
        let ex3 = try await exerciseService.create(name: "Third", type: .weightAndReps)

        try await templateService.addExercise(ex1, to: template, targetSets: nil, targetReps: nil)
        try await templateService.addExercise(ex2, to: template, targetSets: nil, targetReps: nil)
        try await templateService.addExercise(ex3, to: template, targetSets: nil, targetReps: nil)

        let newOrder = template.templateExercises.sorted { $0.order < $1.order }.reversed().map(\.id)
        try await templateService.reorderExercises(template, order: Array(newOrder))

        let sorted = template.templateExercises.sorted { $0.order < $1.order }
        #expect(sorted[0].exercise?.name == "Third")
        #expect(sorted[1].exercise?.name == "Second")
        #expect(sorted[2].exercise?.name == "First")
    }
}
