import Foundation
import SwiftData

@MainActor @Observable
final class CompletedWorkoutDetailViewModel {
    // MARK: - State

    private(set) var workout: SchemaV1.Workout?
    private(set) var exercises: [SchemaV1.LoggedExercise] = []
    private(set) var duration: TimeInterval = 0
    private(set) var isLoading = false
    var errorMessage: String?

    var showDeleteConfirmation = false

    // MARK: - Dependencies

    private let workoutService: WorkoutServiceProtocol
    private let templateService: TemplateServiceProtocol
    private let settingsService: SettingsServiceProtocol
    private let router: HistoryRouter
    private let workoutId: PersistentIdentifier

    var units: Units {
        settingsService.units
    }

    var distanceUnits: DistanceUnits {
        settingsService.distanceUnits
    }

    // MARK: - Init

    init(
        workoutService: WorkoutServiceProtocol,
        templateService: TemplateServiceProtocol,
        settingsService: SettingsServiceProtocol,
        router: HistoryRouter,
        workoutId: PersistentIdentifier
    ) {
        self.workoutService = workoutService
        self.templateService = templateService
        self.settingsService = settingsService
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

    var hasTemplate: Bool { workout?.fromTemplate != nil }

    func updateNotes(_ notes: String) async {
        guard let workout else { return }
        workout.notes = notes.isEmpty ? nil : notes
        errorMessage = nil
        do {
            try await workoutService.update(workout)
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

    // MARK: - Computed

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var totalVolume: Double {
        let displayUnit = units
        var volume: Double = 0
        for loggedExercise in exercises {
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
}
