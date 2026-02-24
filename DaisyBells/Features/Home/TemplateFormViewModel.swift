import Foundation
import SwiftData
import SwiftUI  // Required for IndexSet

@MainActor @Observable
final class TemplateFormViewModel {
    // MARK: - State

    var name: String = ""
    var notes: String = ""
    private(set) var exercises: [SchemaV1.TemplateExercise] = []
    private(set) var isEditing = false
    private(set) var isSaving = false
    var errorMessage: String?

    // Exercise picker sheet state (managed locally, not via router)
    var showExercisePicker = false

    // MARK: - Dependencies

    private let templateService: TemplateServiceProtocol
    private let exerciseService: ExerciseServiceProtocol
    private let router: TemplateRouting
    private let templateId: PersistentIdentifier?
    private var template: SchemaV1.WorkoutTemplate?

    // MARK: - Init

    init(
        templateService: TemplateServiceProtocol,
        exerciseService: ExerciseServiceProtocol,
        router: TemplateRouting,
        templateId: PersistentIdentifier? = nil
    ) {
        self.templateService = templateService
        self.exerciseService = exerciseService
        self.router = router
        self.templateId = templateId
        self.isEditing = templateId != nil
    }

    // MARK: - Intents

    func load() async {
        errorMessage = nil

        if let templateId,
           let templateModel = templateService.fetch(by: templateId) {
            template = templateModel
            name = templateModel.name
            notes = templateModel.notes ?? ""
            exercises = templateModel.templateExercises.sorted { $0.order < $1.order }
        }
    }

    func updateName(_ newName: String) {
        name = newName
    }

    func updateNotes(_ newNotes: String) {
        notes = newNotes
    }

    func addExercise() {
        showExercisePicker = true
    }

    func onExercisesSelected(_ exerciseIds: [PersistentIdentifier]) async {
        if template == nil {
            errorMessage = nil
            do {
                let newTemplate = try await templateService.create(name: name.isEmpty ? "New Template" : name)
                newTemplate.notes = notes.isEmpty ? nil : notes
                template = newTemplate
                isEditing = true
            } catch {
                errorMessage = error.localizedDescription
                showExercisePicker = false
                return
            }
        }

        guard let template else { return }

        errorMessage = nil
        for exerciseId in exerciseIds {
            guard let exercise = exerciseService.fetch(by: exerciseId) else { continue }
            do {
                try await templateService.addExercise(exercise, to: template)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        exercises = template.templateExercises.sorted { $0.order < $1.order }
        showExercisePicker = false
    }

    func removeExercise(_ templateExercise: SchemaV1.TemplateExercise) async {
        guard let template else {
            exercises.removeAll { $0.id == templateExercise.id }
            return
        }

        errorMessage = nil
        do {
            try await templateService.removeExercise(templateExercise, from: template)
            exercises = template.templateExercises.sorted { $0.order < $1.order }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reorderExercises(from source: IndexSet, to destination: Int) async {
        exercises.move(fromOffsets: source, toOffset: destination)

        guard let template else { return }

        let newOrder = exercises.map { $0.id }
        errorMessage = nil
        do {
            try await templateService.reorderExercises(template, order: newOrder)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        guard validate() else { return }

        isSaving = true
        errorMessage = nil
        do {
            if isEditing, let template {
                template.name = name
                template.notes = notes.isEmpty ? nil : notes
                try await templateService.update(template)
            } else {
                _ = try await templateService.create(name: name)
            }
            router.dismissSheet()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func cancel() {
        router.dismissSheet()
    }

    // MARK: - Private

    private func validate() -> Bool {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Name is required"
            return false
        }
        return true
    }
}
