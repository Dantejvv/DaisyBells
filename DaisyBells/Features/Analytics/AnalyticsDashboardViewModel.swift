import Foundation
import SwiftData

@MainActor @Observable
final class AnalyticsDashboardViewModel {
    // MARK: - State

    private(set) var workoutsThisWeek: Int = 0
    private(set) var workoutsThisMonth: Int = 0
    private(set) var recentExercises: [SchemaV1.Exercise] = []
    private(set) var personalRecords: [PersonalRecord] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let analyticsService: AnalyticsServiceProtocol
    private let router: AnalyticsRouter

    // MARK: - Init

    init(analyticsService: AnalyticsServiceProtocol, router: AnalyticsRouter) {
        self.analyticsService = analyticsService
        self.router = router
    }

    // MARK: - Intents

    func loadAnalytics() async {
        isLoading = true
        errorMessage = nil
        do {
            async let weekCount = analyticsService.workoutsThisWeek()
            async let monthCount = analyticsService.workoutsThisMonth()
            async let exercises = analyticsService.recentExercises(limit: 5)
            async let records = analyticsService.personalRecords(limit: 5)

            workoutsThisWeek = try await weekCount
            workoutsThisMonth = try await monthCount
            recentExercises = try await exercises
            personalRecords = try await records
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func selectExercise(_ exercise: SchemaV1.Exercise) {
        router.navigateToExerciseAnalytics(exerciseId: exercise.persistentModelID)
    }

    func refresh() async {
        await loadAnalytics()
    }
}
