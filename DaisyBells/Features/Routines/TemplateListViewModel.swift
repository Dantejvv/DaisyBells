import Foundation
import SwiftData

@MainActor @Observable
final class TemplateListViewModel {
    // MARK: - State

    private(set) var templates: [SchemaV1.WorkoutTemplate] = []
    private(set) var recentWorkouts: [RecentWorkout] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let templateService: TemplateServiceProtocol
    private let workoutService: WorkoutServiceProtocol
    private let router: RoutinesRouter
    
    // MARK - RecentWorkout Projection
    struct RecentWorkout: Identifiable {
        let id: PersistentIdentifier
        let name: String
        let date: Date
        let templateId: PersistentIdentifier?
    }
    
    // MARK: - Init

    init(templateService: TemplateServiceProtocol, workoutService: WorkoutServiceProtocol, router: RoutinesRouter) {
        self.templateService = templateService
        self.workoutService = workoutService
        self.router = router
    }

    // MARK: - Intents

    func loadTemplates() async {
        isLoading = true
        errorMessage = nil
        do {
            templates = try await templateService.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func loadRecentWorkouts(limit: Int = 7) async {
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

    func selectTemplate(_ template: SchemaV1.WorkoutTemplate) {
        router.navigateToTemplateDetail(templateId: template.persistentModelID)
    }

    func createTemplate() {
        router.navigateToCreateTemplate()
    }

    func deleteTemplate(_ template: SchemaV1.WorkoutTemplate) async {
        errorMessage = nil
        do {
            try await templateService.delete(template)
            await loadTemplates()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func startWorkout(_ workout: RecentWorkout) {
        router.navigateToActiveWorkout(workoutId: workout.id)
    }
}
