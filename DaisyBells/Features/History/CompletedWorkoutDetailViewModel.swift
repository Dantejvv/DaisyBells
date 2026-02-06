import Foundation
import SwiftData

@MainActor @Observable
final class CompletedWorkoutDetailViewModel {
    // MARK: - State

    private(set) var workout: SchemaV1.Workout?
    private(set) var exercises: [SchemaV1.LoggedExercise] = []
    private(set) var duration: TimeInterval = 0
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let workoutService: WorkoutServiceProtocol
    private let router: HistoryRouter
    private let workoutId: PersistentIdentifier

    // MARK: - Init

    init(
        workoutService: WorkoutServiceProtocol,
        router: HistoryRouter,
        workoutId: PersistentIdentifier
    ) {
        self.workoutService = workoutService
        self.router = router
        self.workoutId = workoutId
    }

    // MARK: - Intents

    func loadWorkout() async {
        isLoading = true
        errorMessage = nil

        guard let workoutModel = workoutService.fetch(by: workoutId) else {
            errorMessage = "Workout not found"
            isLoading = false
            return
        }

        workout = workoutModel
        exercises = workoutModel.loggedExercises.sorted { $0.order < $1.order }

        if let completedAt = workoutModel.completedAt {
            duration = completedAt.timeIntervalSince(workoutModel.startedAt)
        }
        isLoading = false
    }

    func updateNotes(_ notes: String) async {
        guard let workout else { return }
        errorMessage = nil
        do {
            try await workoutService.updateNotes(workout, notes: notes.isEmpty ? nil : notes)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteWorkout() async {
        guard let workout else { return }
        errorMessage = nil
        do {
            try await workoutService.delete(workout)
            router.pop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
