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
    private(set) var didSaveAsTemplate = false
    var errorMessage: String?
    var workoutNotes: String = ""
    var showSaveAsTemplatePrompt = false
    var showCancelConfirmation = false
    var showCompleteConfirmation = false
    var templateName: String = ""

    // MARK: - Dependencies

    private let workoutService: WorkoutServiceProtocol
    private let exerciseService: ExerciseServiceProtocol
    private let loggedExerciseService: LoggedExerciseServiceProtocol
    private let loggedSetService: LoggedSetServiceProtocol
    private let templateService: TemplateServiceProtocol
    private let settingsService: SettingsServiceProtocol
    private let workoutId: PersistentIdentifier
    private var timerTask: Task<Void, Never>? {
        willSet {
            timerTask?.cancel()
        }
    }

    // Closure-based navigation (decoupled from HomeRouter)
    var onDismiss: () -> Void = {}
    var onComplete: () async -> Void = {}
    var onTimerReset: ((Date) -> Void)?
    var onPresentExercisePicker: (@escaping ([PersistentIdentifier]) -> Void) -> Void = { _ in }
    var onDismissExercisePicker: () -> Void = {}

    // MARK: - Init

    init(
        workoutService: WorkoutServiceProtocol,
        exerciseService: ExerciseServiceProtocol,
        loggedExerciseService: LoggedExerciseServiceProtocol,
        loggedSetService: LoggedSetServiceProtocol,
        templateService: TemplateServiceProtocol,
        settingsService: SettingsServiceProtocol,
        workoutId: PersistentIdentifier
    ) {
        self.workoutService = workoutService
        self.exerciseService = exerciseService
        self.loggedExerciseService = loggedExerciseService
        self.loggedSetService = loggedSetService
        self.templateService = templateService
        self.settingsService = settingsService
        self.workoutId = workoutId
    }

    var defaultWeightUnit: Units { settingsService.units }
    var defaultDistanceUnit: DistanceUnits { settingsService.distanceUnits }

    // MARK: - Computed Properties

    var totalExercises: Int { exercises.count }

    var completedExercises: Int {
        exercises.filter { exercise in
            let sets = exercise.sets
            return !sets.isEmpty && sets.allSatisfy(\.isCompleted)
        }.count
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var completedSets: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.isCompleted).count }
    }

    var startedAtFormatted: String {
        guard let workout else { return "" }
        return workout.startedAt.formatted(.dateTime.month().day().year().hour().minute())
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
        workoutNotes = workoutModel.fromTemplate?.notes ?? workoutModel.notes ?? ""
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
        onPresentExercisePicker { [weak self] exerciseIds in
            Task { @MainActor in
                await self?.onExercisesSelected(exerciseIds)
            }
        }
    }

    func onExercisesSelected(_ exerciseIds: [PersistentIdentifier]) async {
        guard let workout else { return }
        errorMessage = nil

        for exerciseId in exerciseIds {
            guard let exercise = exerciseService.fetch(by: exerciseId) else { continue }
            do {
                // Load previous performance first to determine set count
                await loadPreviousPerformance(for: exercise)
                let previousCount = previousPerformance[exercise.id]?.count ?? 0

                let maxOrder = workout.loggedExercises.map(\.order).max() ?? -1
                let weightUnit = exercise.resolvedWeightUnit(default: defaultWeightUnit)
                let distanceUnit = exercise.resolvedDistanceUnit(default: defaultDistanceUnit)
                _ = try await loggedExerciseService.createWithSets(
                    exercise: exercise,
                    workout: workout,
                    order: maxOrder + 1,
                    setCount: max(previousCount, 1),
                    weightUnit: weightUnit,
                    distanceUnit: distanceUnit
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        refreshExercises()
        onDismissExercisePicker()
    }

    func removeExercise(_ loggedExercise: SchemaV1.LoggedExercise) async {
        guard let workout else { return }
        errorMessage = nil
        do {
            try await loggedExerciseService.delete(loggedExercise)
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
            let maxOrder = loggedExercise.sets.map(\.order).max() ?? -1
            let exercise = loggedExercise.exercise
            let weightUnit = exercise?.resolvedWeightUnit(default: defaultWeightUnit)
            let distanceUnit = exercise?.resolvedDistanceUnit(default: defaultDistanceUnit)
            _ = try await loggedSetService.create(loggedExercise: loggedExercise, order: maxOrder + 1, weightUnit: weightUnit, distanceUnit: distanceUnit)
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
        bodyweightModifier: Double?,
        notes: String? = nil
    ) async {
        errorMessage = nil
        do {
            try await loggedSetService.update(
                set,
                weight: weight,
                reps: reps,
                bodyweightModifier: bodyweightModifier,
                time: time,
                distance: distance,
                notes: notes
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func canDeleteSet(_ set: SchemaV1.LoggedSet, from loggedExercise: SchemaV1.LoggedExercise) -> Bool {
        !set.isCompleted && loggedExercise.sets.count > 1
    }

    func deleteSet(_ set: SchemaV1.LoggedSet, from loggedExercise: SchemaV1.LoggedExercise) async {
        errorMessage = nil
        do {
            try await loggedSetService.delete(set)
            refreshExercises()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSetCompletion(_ set: SchemaV1.LoggedSet) async {
        errorMessage = nil
        do {
            if !set.isCompleted {
                applyPlaceholderValues(to: set)
            }
            try await loggedSetService.toggleCompletion(set)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyPlaceholderValues(to set: SchemaV1.LoggedSet) {
        guard let loggedExercise = set.loggedExercise,
              let exercise = loggedExercise.exercise,
              let previousSets = previousPerformance[exercise.id] else { return }

        let sortedSets = loggedExercise.sets.sorted { $0.order < $1.order }
        guard let index = sortedSets.firstIndex(where: { $0.id == set.id }),
              index < previousSets.count else { return }

        let prev = previousSets[index]
        let weightUnit = exercise.resolvedWeightUnit(default: defaultWeightUnit)
        let distanceUnit = exercise.resolvedDistanceUnit(default: defaultDistanceUnit)
        let prevWeightUnit = prev.resolvedWeightUnit ?? weightUnit
        let prevDistanceUnit = prev.resolvedDistanceUnit ?? distanceUnit

        if set.weight == nil, let w = prev.weight {
            set.weight = w.convert(from: prevWeightUnit, to: weightUnit)
        }
        if set.reps == nil, let r = prev.reps {
            set.reps = r
        }
        if set.bodyweightModifier == nil, let bw = prev.bodyweightModifier {
            set.bodyweightModifier = bw.convert(from: prevWeightUnit, to: weightUnit)
        }
        if set.time == nil, let t = prev.time {
            set.time = t
        }
        if set.distance == nil, let d = prev.distance {
            set.distance = d.convertDistance(from: prevDistanceUnit, to: distanceUnit)
        }
        if set.notes == nil || set.notes?.isEmpty == true, let n = prev.notes, !n.isEmpty {
            set.notes = n
        }
    }

    func updateWeightUnit(_ exercise: SchemaV1.Exercise, unit: Units?) async {
        let oldUnit = exercise.resolvedWeightUnit(default: defaultWeightUnit)
        exercise.preferredWeightUnit = unit
        let newUnit = exercise.resolvedWeightUnit(default: defaultWeightUnit)
        errorMessage = nil

        // Convert in-progress set values to the new unit
        if oldUnit != newUnit {
            for loggedExercise in exercises where loggedExercise.exercise?.id == exercise.id {
                for set in loggedExercise.sets {
                    if let weight = set.weight {
                        set.weight = weight.convert(from: oldUnit, to: newUnit)
                    }
                    if let bw = set.bodyweightModifier {
                        set.bodyweightModifier = bw.convert(from: oldUnit, to: newUnit)
                    }
                    set.weightUnit = newUnit.rawValue
                }
            }
        }

        do {
            try await exerciseService.update(exercise)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateDistanceUnit(_ exercise: SchemaV1.Exercise, unit: DistanceUnits?) async {
        let oldUnit = exercise.resolvedDistanceUnit(default: defaultDistanceUnit)
        exercise.preferredDistanceUnit = unit
        let newUnit = exercise.resolvedDistanceUnit(default: defaultDistanceUnit)
        errorMessage = nil

        // Convert in-progress set values to the new unit
        if oldUnit != newUnit {
            for loggedExercise in exercises where loggedExercise.exercise?.id == exercise.id {
                for set in loggedExercise.sets {
                    if let distance = set.distance {
                        set.distance = distance.convertDistance(from: oldUnit, to: newUnit)
                    }
                    set.distanceUnit = newUnit.rawValue
                }
            }
        }

        do {
            try await exerciseService.update(exercise)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateExerciseNotes(_ exercise: SchemaV1.Exercise, notes: String?) async {
        exercise.notes = notes
        do {
            try await exerciseService.update(exercise)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var hasTemplate: Bool { workout?.fromTemplate != nil }

    func updateWorkoutNotes(_ notes: String) async {
        let trimmed = notes.isEmpty ? nil : notes
        workoutNotes = notes
        errorMessage = nil
        do {
            if let template = workout?.fromTemplate {
                template.notes = trimmed
                try await templateService.update(template)
            } else if let workout {
                workout.notes = trimmed
                try await workoutService.update(workout)
            }
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
            if workout.fromTemplate == nil && !exercises.isEmpty {
                showSaveAsTemplatePrompt = true
            } else {
                await onComplete()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveAsTemplate() async {
        guard workout != nil else { return }
        let name = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            errorMessage = "Template name is required"
            return
        }

        errorMessage = nil
        do {
            let template = try await templateService.create(name: name)
            for loggedExercise in exercises {
                guard let exercise = loggedExercise.exercise else { continue }
                try await templateService.addExercise(
                    exercise,
                    to: template
                )
            }
            didSaveAsTemplate = true
            showSaveAsTemplatePrompt = false
            await onComplete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func skipSaveAsTemplate() async {
        showSaveAsTemplatePrompt = false
        await onComplete()
    }

    func cancelWorkout() async {
        guard let workout else { return }
        errorMessage = nil
        do {
            try await workoutService.cancel(workout)
            stopTimer()
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    private func refreshExercises() {
        guard let workout else { return }
        exercises = workout.loggedExercises.sorted { $0.order < $1.order }
    }

    func resetTimer() async {
        guard let workout else { return }
        let now = Date()
        workout.startedAt = now
        do {
            try await workoutService.update(workout)
        } catch {
            errorMessage = error.localizedDescription
        }
        elapsedTime = 0
        stopTimer()
        startTimer()
        onTimerReset?(now)
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
