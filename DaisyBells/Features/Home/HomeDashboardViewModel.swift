import Foundation
import SwiftData

@MainActor @Observable
final class HomeDashboardViewModel {
    // MARK: - State

    private(set) var activeSplit: SchemaV1.Split?
    private(set) var splitDays: [SchemaV1.SplitDay] = []
    private(set) var templates: [SchemaV1.WorkoutTemplate] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // Delete confirmation state
    var templatePendingDelete: SchemaV1.WorkoutTemplate?

    // MARK: - Dependencies

    private let templateService: TemplateServiceProtocol
    private let splitService: SplitServiceProtocol
    private let workoutService: WorkoutServiceProtocol
    private let settingsService: SettingsServiceProtocol
    private let activeWorkoutManager: ActiveWorkoutManager
    private let router: HomeRouter

    var hasActiveWorkout: Bool { activeWorkoutManager.hasActiveWorkout }

    // MARK: - Init

    init(
        templateService: TemplateServiceProtocol,
        splitService: SplitServiceProtocol,
        workoutService: WorkoutServiceProtocol,
        settingsService: SettingsServiceProtocol,
        activeWorkoutManager: ActiveWorkoutManager,
        router: HomeRouter
    ) {
        self.templateService = templateService
        self.splitService = splitService
        self.workoutService = workoutService
        self.settingsService = settingsService
        self.activeWorkoutManager = activeWorkoutManager
        self.router = router
    }

    // MARK: - Intents

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        do {
            templates = try await templateService.fetchAll()

            // Load active split
            if let activeSplitId = settingsService.activeSplitId {
                let split = try await splitService.fetch(id: activeSplitId)
                activeSplit = split
                splitDays = split.days.sorted { $0.order < $1.order }
            } else {
                activeSplit = nil
                splitDays = []
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func presentNewTemplate() {
        router.presentTemplateForm(templateId: nil)
    }

    func editTemplate(_ template: SchemaV1.WorkoutTemplate) {
        router.presentTemplateForm(templateId: template.persistentModelID)
    }

    // MARK: - Delete Flow

    func requestDelete(_ template: SchemaV1.WorkoutTemplate) {
        templatePendingDelete = template
    }

    func cancelDelete() {
        templatePendingDelete = nil
    }

    func confirmDelete() async {
        guard let template = templatePendingDelete else { return }
        errorMessage = nil
        do {
            try await templateService.delete(template)
            templatePendingDelete = nil
            await loadDashboard()
        } catch {
            errorMessage = error.localizedDescription
            templatePendingDelete = nil
        }
    }

    // MARK: - Workout Actions

    func startEmptyWorkout() async {
        guard !hasActiveWorkout else { return }
        errorMessage = nil
        do {
            let workout = try await workoutService.createEmpty()
            activeWorkoutManager.start(
                workoutId: workout.persistentModelID,
                name: nil,
                startedAt: workout.startedAt
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startWorkoutFromTemplate(_ template: SchemaV1.WorkoutTemplate) async {
        guard !hasActiveWorkout else { return }
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

    func resumeActiveWorkout() {
        activeWorkoutManager.showSheet()
    }
}
