import Foundation
import SwiftData

@MainActor @Observable
final class TemplateListViewModel {
    // MARK: - State

    private(set) var templates: [SchemaV1.WorkoutTemplate] = []
    private(set) var recentWorkouts: [RecentWorkout] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var searchQuery: String = ""

    // Delete confirmation state
    var templatePendingDelete: SchemaV1.WorkoutTemplate?

    // MARK: - Dependencies

    private let templateService: TemplateServiceProtocol
    private let workoutService: WorkoutServiceProtocol?
    private let activeWorkoutManager: ActiveWorkoutManager?
    private let router: TemplateRouting

    // MARK - RecentWorkout Projection
    struct RecentWorkout: Identifiable {
        let id: PersistentIdentifier
        let name: String
        let date: Date
        let templateId: PersistentIdentifier?
    }

    // MARK: - Init

    init(
        templateService: TemplateServiceProtocol,
        workoutService: WorkoutServiceProtocol? = nil,
        activeWorkoutManager: ActiveWorkoutManager? = nil,
        router: TemplateRouting
    ) {
        self.templateService = templateService
        self.workoutService = workoutService
        self.activeWorkoutManager = activeWorkoutManager
        self.router = router
    }

    // MARK: - Intents

    func loadTemplates() async {
        isLoading = true
        errorMessage = nil
        do {
            if searchQuery.isEmpty {
                templates = try await templateService.fetchAll()
            } else {
                templates = try await templateService.search(query: searchQuery)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadRecentWorkouts(limit: Int = 7) async {
        guard let workoutService else { return }
        errorMessage = nil
        do {
            let workouts = try await workoutService.fetchRecent(limit: limit)

            recentWorkouts = workouts.map {
                RecentWorkout(
                    id: $0.persistentModelID,
                    name: $0.fromTemplate?.name ?? "Workout",
                    date: $0.completedAt ?? $0.startedAt,
                    templateId: $0.fromTemplate?.persistentModelID
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func search(query: String) async {
        searchQuery = query
        await loadTemplates()
    }

    func selectTemplate(_ template: SchemaV1.WorkoutTemplate) {
        router.navigateToTemplateDetail(templateId: template.persistentModelID)
    }

    func createTemplate() {
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
            await loadTemplates()
        } catch {
            errorMessage = error.localizedDescription
            templatePendingDelete = nil
        }
    }

    func startWorkout(_ workout: RecentWorkout) {
        activeWorkoutManager?.showSheet()
    }
}
