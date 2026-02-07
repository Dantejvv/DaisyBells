import Foundation
import SwiftData

@MainActor @Observable
final class HistoryListViewModel {
    // MARK: - State

    private(set) var workouts: [SchemaV1.Workout] = []
    private(set) var isLoading = false
    var errorMessage: String?

    var isEmpty: Bool {
        workouts.isEmpty
    }

    // MARK: - Dependencies

    private let workoutService: WorkoutServiceProtocol
    private let router: HistoryRouter

    // MARK: - Init

    init(workoutService: WorkoutServiceProtocol, router: HistoryRouter) {
        self.workoutService = workoutService
        self.router = router
    }

    // MARK: - Intents

    func loadWorkouts() async {
        isLoading = true
        errorMessage = nil
        do {
            let completed = try await workoutService.fetchCompleted()
            workouts = completed.sorted { ($0.completedAt ?? $0.startedAt) > ($1.completedAt ?? $1.startedAt) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func selectWorkout(_ workout: SchemaV1.Workout) {
        router.navigateToWorkoutDetail(workoutId: workout.persistentModelID)
    }

    func deleteWorkout(_ workout: SchemaV1.Workout) async {
        errorMessage = nil
        do {
            try await workoutService.delete(workout)
            await loadWorkouts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearAllHistory() async {
        errorMessage = nil
        do {
            try await workoutService.deleteAll()
            await loadWorkouts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
