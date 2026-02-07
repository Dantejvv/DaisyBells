import Foundation
import SwiftData

@MainActor @Observable
final class TemplateDetailViewModel {
    // MARK: - State

    private(set) var template: SchemaV1.WorkoutTemplate?
    private(set) var exercises: [SchemaV1.TemplateExercise] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let templateService: TemplateServiceProtocol
    private let workoutService: WorkoutServiceProtocol
    private let router: RoutinesRouter
    private let templateId: PersistentIdentifier

    // MARK: - Init

    init(
        templateService: TemplateServiceProtocol,
        workoutService: WorkoutServiceProtocol,
        router: RoutinesRouter,
        templateId: PersistentIdentifier
    ) {
        self.templateService = templateService
        self.workoutService = workoutService
        self.router = router
        self.templateId = templateId
    }

    // MARK: - Intents

    func loadTemplate() async {
        isLoading = true
        errorMessage = nil

        guard let templateModel = templateService.fetch(by: templateId) else {
            errorMessage = "Template not found"
            isLoading = false
            return
        }

        template = templateModel
        exercises = templateModel.templateExercises.sorted { $0.order < $1.order }
        isLoading = false
    }

    func startWorkout() async {
        guard let template else { return }
        errorMessage = nil
        do {
            let workout = try await workoutService.createFromTemplate(template)
            router.navigateToActiveWorkout(workoutId: workout.persistentModelID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func editTemplate() {
        router.navigateToEditTemplate(templateId: templateId)
    }

    func duplicateTemplate() async {
        guard let template else { return }
        errorMessage = nil
        do {
            let copy = try await templateService.duplicate(template)
            router.navigateToTemplateDetail(templateId: copy.persistentModelID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTemplate() async {
        guard let template else { return }
        errorMessage = nil
        do {
            try await templateService.delete(template)
            router.pop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
