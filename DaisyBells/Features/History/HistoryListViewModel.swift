import Foundation
import SwiftData

@MainActor @Observable
final class HistoryListViewModel {
    // MARK: - State

    private(set) var workouts: [SchemaV1.Workout] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var searchQuery: String = ""
    var showClearAllConfirmation = false

    var isEmpty: Bool {
        workouts.isEmpty && searchQuery.isEmpty
    }

    var filteredWorkouts: [SchemaV1.Workout] {
        guard !searchQuery.isEmpty else { return workouts }
        let query = searchQuery.lowercased()
        return workouts.filter { workout in
            let templateName = workout.fromTemplate?.name ?? ""
            return templateName.lowercased().contains(query)
        }
    }

    var groupedWorkouts: [(String, [SchemaV1.Workout])] {
        let grouped = Dictionary(grouping: filteredWorkouts) { workout -> Date in
            (workout.completedAt ?? workout.startedAt).startOfDay
        }
        return grouped.keys.sorted(by: >).map { date in
            (date.dayHeaderFormat, grouped[date]!)
        }
    }

    var units: Units {
        settingsService.units
    }

    // MARK: - Dependencies

    private let workoutService: WorkoutServiceProtocol
    private let settingsService: SettingsServiceProtocol
    private let router: HistoryRouter

    // MARK: - Init

    init(
        workoutService: WorkoutServiceProtocol,
        settingsService: SettingsServiceProtocol,
        router: HistoryRouter
    ) {
        self.workoutService = workoutService
        self.settingsService = settingsService
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

    func showCalendar() {
        router.presentCalendar()
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

    // MARK: - Helpers

    func totalVolume(for workout: SchemaV1.Workout) -> Double {
        let displayUnit = units
        var volume: Double = 0
        for loggedExercise in workout.loggedExercises {
            for set in loggedExercise.sets {
                if let weight = set.weight, let reps = set.reps {
                    let storedUnit = set.resolvedWeightUnit ?? displayUnit
                    let converted = weight.convert(from: storedUnit, to: displayUnit)
                    volume += converted * Double(reps)
                }
            }
        }
        return volume
    }

    func duration(for workout: SchemaV1.Workout) -> TimeInterval {
        guard let completedAt = workout.completedAt else { return 0 }
        return completedAt.timeIntervalSince(workout.startedAt)
    }
}
