import Foundation
import SwiftData

@MainActor @Observable
final class ExerciseDetailViewModel {
    // MARK: - State

    private(set) var exercise: SchemaV1.Exercise?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var canDelete = true

    // MARK: - Dependencies

    private let exerciseService: ExerciseServiceProtocol
    private let router: LibraryRouter
    private let exerciseId: PersistentIdentifier

    // MARK: - Init

    init(
        exerciseService: ExerciseServiceProtocol,
        router: LibraryRouter,
        exerciseId: PersistentIdentifier
    ) {
        self.exerciseService = exerciseService
        self.router = router
        self.exerciseId = exerciseId
    }

    // MARK: - Intents

    func loadExercise() async {
        isLoading = true
        errorMessage = nil
        do {
            guard let exerciseModel = exerciseService.fetch(by: exerciseId) else {
                errorMessage = "Exercise not found"
                isLoading = false
                return
            }

            exercise = exerciseModel
            let hasHistory = try await exerciseService.hasHistory(exerciseModel)
            canDelete = !hasHistory
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func toggleFavorite() async {
        guard let exercise else { return }
        errorMessage = nil
        do {
            exercise.isFavorite.toggle()
            try await exerciseService.update(exercise)
        } catch {
            errorMessage = error.localizedDescription
            exercise.isFavorite.toggle() // Revert on error
        }
    }

    func editExercise() {
        router.navigateToEditExercise(exerciseId: exerciseId)
    }

    func deleteExercise() async {
        guard let exercise else { return }
        errorMessage = nil
        do {
            if canDelete {
                try await exerciseService.delete(exercise)
            } else {
                try await exerciseService.archive(exercise)
            }
            router.pop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
