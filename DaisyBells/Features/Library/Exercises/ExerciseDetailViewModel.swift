import Foundation
import SwiftData

struct ExerciseStats {
    let lastPerformed: Date?
    let personalRecord: PersonalRecord?
    let totalVolume: Double
}

@MainActor @Observable
final class ExerciseDetailViewModel {
    // MARK: - State

    private(set) var exercise: SchemaV1.Exercise?
    private(set) var isLoading = false
    var errorMessage: String?
    private(set) var canDelete = true
    private(set) var performanceStats: ExerciseStats?

    // MARK: - Dependencies

    private let exerciseService: ExerciseServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let router: LibraryRouter
    private let exerciseId: PersistentIdentifier

    // MARK: - Init

    init(
        exerciseService: ExerciseServiceProtocol,
        analyticsService: AnalyticsServiceProtocol,
        router: LibraryRouter,
        exerciseId: PersistentIdentifier
    ) {
        self.exerciseService = exerciseService
        self.analyticsService = analyticsService
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

            // Load performance stats
            let lastPerformed = try await analyticsService.lastPerformedDate(exerciseModel)
            let personalRecord = try await analyticsService.personalBestForExercise(exerciseModel)
            let totalVolume = try await analyticsService.volumeForExercise(exerciseModel)

            performanceStats = ExerciseStats(
                lastPerformed: lastPerformed,
                personalRecord: personalRecord,
                totalVolume: totalVolume
            )
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
