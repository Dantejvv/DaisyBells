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
    var showDeleteConfirmation = false
    private(set) var templatePendingDelete: SchemaV1.WorkoutTemplate?

    // MARK: - Dependencies

    private let templateService: TemplateServiceProtocol
    private let splitService: SplitServiceProtocol
    private let workoutService: WorkoutServiceProtocol
    private let settingsService: SettingsServiceProtocol
    private let activeWorkoutManager: ActiveWorkoutManager
    private let router: HomeRouter

    var hasActiveWorkout: Bool { activeWorkoutManager.hasActiveWorkout }
    var completedDayCount: Int { splitDays.filter(\.isCompletedInCycle).count }
    var isCycleComplete: Bool { activeSplit != nil && !splitDays.isEmpty && splitDays.allSatisfy(\.isCompletedInCycle) }
    var suggestedDayIndex: Int? {
        splitDays.firstIndex(where: { !$0.isCompletedInCycle })
    }

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
        showDeleteConfirmation = true
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

    func startSplitDayWorkout(_ template: SchemaV1.WorkoutTemplate, dayIndex: Int) async {
        guard !hasActiveWorkout else { return }
        errorMessage = nil
        do {
            let workout = try await workoutService.createFromTemplate(template)
            activeWorkoutManager.onWorkoutCompleted = { [weak self] in
                await self?.completeSplitDay()
            }
            activeWorkoutManager.start(
                workoutId: workout.persistentModelID,
                name: template.name,
                startedAt: workout.startedAt,
                splitDayIndex: dayIndex
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resumeActiveWorkout() {
        activeWorkoutManager.showSheet()
    }

    // MARK: - Cycle Tracking

    private func completeSplitDay() async {
        guard let split = activeSplit,
              let dayIndex = activeWorkoutManager.activeSplitDayIndex else { return }
        do {
            try await splitService.skipDay(at: dayIndex, in: split)
            await loadDashboard()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetCycle() async {
        guard let split = activeSplit else { return }
        errorMessage = nil
        do {
            try await splitService.resetCycle(split)
            await loadDashboard()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uncompleteDay(at index: Int) async {
        errorMessage = nil
        do {
            guard let split = activeSplit else { return }
            try await splitService.uncompleteDay(at: index, in: split)
            await loadDashboard()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func skipDay(at index: Int) async {
        errorMessage = nil
        do {
            guard let split = activeSplit else { return }
            try await splitService.skipDay(at: index, in: split)
            await loadDashboard()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
