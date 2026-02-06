import Foundation
import SwiftData
import SwiftUI  // Required for IndexSet

@MainActor @Observable
final class ActiveWorkoutViewModel {
    // MARK: - State

    private(set) var workout: SchemaV1.Workout?
    private(set) var exercises: [SchemaV1.LoggedExercise] = []
    private(set) var previousPerformance: [UUID: [SchemaV1.LoggedSet]] = [:]
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var fromTemplateName: String?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var workoutNotes: String = ""

    // MARK: - Dependencies

    private let workoutService: WorkoutServiceProtocol
    private let exerciseService: ExerciseServiceProtocol
    private let router: LibraryRouter
    private let workoutId: PersistentIdentifier
    private var timerTask: Task<Void, Never>? {
        willSet {
            timerTask?.cancel()
        }
    }

    // MARK: - Init

    init(
        workoutService: WorkoutServiceProtocol,
        exerciseService: ExerciseServiceProtocol,
        router: LibraryRouter,
        workoutId: PersistentIdentifier
    ) {
        self.workoutService = workoutService
        self.exerciseService = exerciseService
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
        workoutNotes = workoutModel.notes ?? ""
        fromTemplateName = workoutModel.fromTemplate?.name

        // Load previous performance for each exercise
        for loggedExercise in exercises {
            if let exercise = loggedExercise.exercise {
                await loadPreviousPerformance(for: exercise)
            }
        }

        startTimer()
        isLoading = false
    }

    func loadPreviousPerformance(for exercise: SchemaV1.Exercise) async {
        do {
            let previousSets = try await workoutService.lastPerformedSets(for: exercise)
            previousPerformance[exercise.id] = previousSets
        } catch {
            // Silently fail - previous performance is optional
        }
    }

    func addExercise() {
        router.presentExercisePicker { [weak self] exerciseId in
            Task { @MainActor in
                await self?.onExerciseSelected(exerciseId)
            }
        }
    }

    func onExerciseSelected(_ exerciseId: PersistentIdentifier) async {
        guard let workout,
              let exercise = exerciseService.fetch(by: exerciseId) else { return }

        errorMessage = nil
        do {
            let loggedExercise = try await workoutService.addExercise(exercise, to: workout)
            exercises = workout.loggedExercises.sorted { $0.order < $1.order }

            await loadPreviousPerformance(for: exercise)

            // Add initial set
            _ = try await workoutService.addSet(to: loggedExercise)
            refreshExercises()
        } catch {
            errorMessage = error.localizedDescription
        }

        router.dismissSheet()
    }

    func removeExercise(_ loggedExercise: SchemaV1.LoggedExercise) async {
        guard let workout else { return }
        errorMessage = nil
        do {
            try await workoutService.removeExercise(loggedExercise, from: workout)
            exercises = workout.loggedExercises.sorted { $0.order < $1.order }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reorderExercises(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        // Update order values
        for (index, exercise) in exercises.enumerated() {
            exercise.order = index
        }
    }

    func addSet(to loggedExercise: SchemaV1.LoggedExercise) async {
        errorMessage = nil
        do {
            _ = try await workoutService.addSet(to: loggedExercise)
            refreshExercises()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateSet(
        _ set: SchemaV1.LoggedSet,
        weight: Double?,
        reps: Int?,
        time: TimeInterval?,
        distance: Double?,
        bodyweightModifier: Double?
    ) async {
        set.weight = weight
        set.reps = reps
        set.time = time
        set.distance = distance
        set.bodyweightModifier = bodyweightModifier

        errorMessage = nil
        do {
            try await workoutService.updateSet(set)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteSet(_ set: SchemaV1.LoggedSet, from loggedExercise: SchemaV1.LoggedExercise) async {
        errorMessage = nil
        do {
            try await workoutService.removeSet(set, from: loggedExercise)
            refreshExercises()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateExerciseNotes(_ loggedExercise: SchemaV1.LoggedExercise, notes: String) {
        loggedExercise.notes = notes.isEmpty ? nil : notes
    }

    func updateWorkoutNotes(_ notes: String) async {
        guard let workout else { return }
        workoutNotes = notes
        errorMessage = nil
        do {
            try await workoutService.updateNotes(workout, notes: notes.isEmpty ? nil : notes)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeWorkout() async {
        guard let workout else { return }
        errorMessage = nil
        do {
            try await workoutService.complete(workout)
            stopTimer()
            router.popToRoot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelWorkout() async {
        guard let workout else { return }
        errorMessage = nil
        do {
            try await workoutService.cancel(workout)
            stopTimer()
            router.popToRoot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    private func refreshExercises() {
        guard let workout else { return }
        exercises = workout.loggedExercises.sorted { $0.order < $1.order }
    }

    private func startTimer() {
        guard let workout else { return }

        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.elapsedTime = Date().timeIntervalSince(workout.startedAt)
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func stopTimer() {
        timerTask = nil
    }
}
