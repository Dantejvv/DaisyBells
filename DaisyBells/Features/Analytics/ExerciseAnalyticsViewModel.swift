import Foundation
import SwiftData

@MainActor @Observable
final class ExerciseAnalyticsViewModel {
    // MARK: - State

    private(set) var exercise: SchemaV1.Exercise?
    private(set) var totalVolume: Double = 0
    private(set) var personalBest: PersonalRecord?
    private(set) var lastPerformed: Date?
    private(set) var recentSets: [SchemaV1.LoggedSet] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let analyticsService: AnalyticsServiceProtocol
    private let exerciseService: ExerciseServiceProtocol
    private let exerciseId: PersistentIdentifier

    // MARK: - Init

    init(
        analyticsService: AnalyticsServiceProtocol,
        exerciseService: ExerciseServiceProtocol,
        exerciseId: PersistentIdentifier
    ) {
        self.analyticsService = analyticsService
        self.exerciseService = exerciseService
        self.exerciseId = exerciseId
    }

    // MARK: - Intents

    func loadAnalytics() async {
        isLoading = true
        errorMessage = nil
        do {
            guard let exerciseModel = exerciseService.fetch(by: exerciseId) else {
                errorMessage = "Exercise not found"
                isLoading = false
                return
            }

            exercise = exerciseModel

            async let volume = analyticsService.volumeForExercise(exerciseModel)
            async let best = analyticsService.personalBestForExercise(exerciseModel)
            async let lastDate = analyticsService.lastPerformedDate(exerciseModel)
            async let sets = analyticsService.recentSetsForExercise(exerciseModel, limit: 10)

            totalVolume = try await volume
            personalBest = try await best
            lastPerformed = try await lastDate
            recentSets = try await sets
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func refresh() async {
        await loadAnalytics()
    }
}
