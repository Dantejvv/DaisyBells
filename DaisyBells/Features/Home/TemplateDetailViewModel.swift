import Foundation
import SwiftData

@MainActor @Observable
final class TemplateDetailViewModel {
    // MARK: - State

    private(set) var template: SchemaV1.WorkoutTemplate?
    private(set) var exercises: [SchemaV1.TemplateExercise] = []
    private(set) var assignedSplitDays: [SchemaV1.SplitDay] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let templateService: TemplateServiceProtocol
    private let workoutService: WorkoutServiceProtocol
    private let splitDayService: SplitDayServiceProtocol
    private let router: HomeRouter
    private let templateId: PersistentIdentifier

    // MARK: - Init

    init(
        templateService: TemplateServiceProtocol,
        workoutService: WorkoutServiceProtocol,
        splitDayService: SplitDayServiceProtocol,
        router: HomeRouter,
        templateId: PersistentIdentifier
    ) {
        self.templateService = templateService
        self.workoutService = workoutService
        self.splitDayService = splitDayService
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

        // Load assigned split days
        do {
            assignedSplitDays = try await splitDayService.fetchBySplitTemplate(templateModel)
        } catch {
            // Don't fail loading if split days can't be loaded
            assignedSplitDays = []
        }

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

    func assignToSplit() {
        router.presentSplitDayPicker { [weak self] dayId in
            guard let self else { return }
            Task {
                await self.handleSplitDaySelection(dayId)
            }
        }
    }

    // MARK: - Private

    private func handleSplitDaySelection(_ dayId: PersistentIdentifier) async {
        guard let template else { return }

        guard let day = splitDayService.fetch(by: dayId) else {
            errorMessage = "Split day not found"
            router.dismissSheet()
            return
        }

        errorMessage = nil
        do {
            try await splitDayService.assignWorkout(template, to: day)
            await loadTemplate()
            router.dismissSheet()
        } catch {
            errorMessage = error.localizedDescription
            router.dismissSheet()
        }
    }
}
