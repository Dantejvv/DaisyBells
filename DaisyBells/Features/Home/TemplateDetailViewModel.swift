import Foundation
import SwiftData

@MainActor @Observable
final class TemplateDetailViewModel {
    // MARK: - State

    private(set) var template: SchemaV1.WorkoutTemplate?
    private(set) var exercises: [SchemaV1.TemplateExercise] = []
    private(set) var assignedSplitDays: [SchemaV1.SplitDay] = []
    private(set) var previousPerformance: [UUID: [SchemaV1.LoggedSet]] = [:]
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Availability

    var canStartWorkout: Bool { workoutService != nil }
    var canAssignToSplit: Bool { splitDayService != nil }

    // MARK: - Dependencies

    private let templateService: TemplateServiceProtocol
    private let workoutService: WorkoutServiceProtocol?
    private let splitDayService: SplitDayServiceProtocol?
    private let activeWorkoutManager: ActiveWorkoutManager?
    private let router: TemplateRouting
    private let templateId: PersistentIdentifier

    // MARK: - Init

    init(
        templateService: TemplateServiceProtocol,
        workoutService: WorkoutServiceProtocol? = nil,
        splitDayService: SplitDayServiceProtocol? = nil,
        activeWorkoutManager: ActiveWorkoutManager? = nil,
        router: TemplateRouting,
        templateId: PersistentIdentifier
    ) {
        self.templateService = templateService
        self.workoutService = workoutService
        self.splitDayService = splitDayService
        self.activeWorkoutManager = activeWorkoutManager
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
        if let splitDayService {
            do {
                assignedSplitDays = try await splitDayService.fetchBySplitTemplate(templateModel)
            } catch {
                assignedSplitDays = []
            }
        }

        // Load previous performance for each exercise
        if let workoutService {
            for templateExercise in exercises {
                guard let exercise = templateExercise.exercise else { continue }
                do {
                    let sets = try await workoutService.lastPerformedSets(for: exercise)
                    previousPerformance[exercise.id] = sets
                } catch {
                    // Don't fail loading if previous performance can't be loaded
                }
            }
        }

        isLoading = false
    }

    func startWorkout() async {
        guard let template, let workoutService, let activeWorkoutManager else { return }
        guard !activeWorkoutManager.hasActiveWorkout else { return }
        errorMessage = nil
        do {
            let workout = try await workoutService.createFromTemplate(template)
            activeWorkoutManager.start(
                workoutId: workout.persistentModelID,
                name: template.name,
                startedAt: workout.startedAt
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func editTemplate() {
        router.presentTemplateForm(templateId: templateId)
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
        // Workout-to-day assignment is now handled inside SplitFormView
    }
}
