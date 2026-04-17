import Foundation
import SwiftData
import SwiftUI  // Required for IndexSet

@MainActor @Observable
final class TemplateFormViewModel {
    // MARK: - State

    var name: String = ""
    var notes: String = ""
    private(set) var exercises: [DraftTemplateExercise] = []
    private(set) var isEditing = false
    private(set) var isSaving = false
    private(set) var previousPerformance: [UUID: [SchemaV1.LoggedSet]] = [:]
    var errorMessage: String?

    // Exercise picker sheet state (managed locally, not via router)
    var showExercisePicker = false

    // MARK: - Dependencies

    private let templateService: TemplateServiceProtocol
    private let exerciseService: ExerciseServiceProtocol
    private let workoutService: WorkoutServiceProtocol
    private let router: TemplateRouting
    private let templateId: PersistentIdentifier?

    // MARK: - Init

    init(
        templateService: TemplateServiceProtocol,
        exerciseService: ExerciseServiceProtocol,
        workoutService: WorkoutServiceProtocol,
        router: TemplateRouting,
        templateId: PersistentIdentifier? = nil
    ) {
        self.templateService = templateService
        self.exerciseService = exerciseService
        self.workoutService = workoutService
        self.router = router
        self.templateId = templateId
        self.isEditing = templateId != nil
    }

    // MARK: - Intents

    func load() async {
        errorMessage = nil

        if let templateId,
           let templateModel = templateService.fetch(by: templateId) {
            name = templateModel.name
            notes = templateModel.notes ?? ""

            let sortedExercises = templateModel.templateExercises.sorted { $0.order < $1.order }
            exercises = sortedExercises.map { te in
                let sortedSets = te.sets.sorted { $0.order < $1.order }
                return DraftTemplateExercise(
                    exerciseId: te.exercise?.id ?? UUID(),
                    exerciseName: te.exercise?.name ?? "Unknown Exercise",
                    exerciseType: te.exercise?.type ?? .weightAndReps,
                    exerciseNotes: te.exercise?.notes,
                    notes: te.notes,
                    order: te.order,
                    sets: sortedSets.map { s in
                        DraftTemplateSet(
                            order: s.order,
                            weight: s.weight,
                            reps: s.reps,
                            bodyweightModifier: s.bodyweightModifier,
                            time: s.time,
                            distance: s.distance,
                            notes: s.notes
                        )
                    }
                )
            }

            for draftExercise in exercises {
                await loadPreviousPerformance(for: draftExercise.exerciseId)
            }
        }
    }

    func updateName(_ newName: String) {
        name = newName
    }

    func updateNotes(_ newNotes: String) {
        notes = newNotes
    }

    func addExercise() {
        showExercisePicker = true
    }

    func onExercisesSelected(_ exerciseIds: [PersistentIdentifier]) async {
        let maxOrder = exercises.map(\.order).max() ?? -1

        for (offset, exerciseId) in exerciseIds.enumerated() {
            guard let exercise = exerciseService.fetch(by: exerciseId) else { continue }

            await loadPreviousPerformance(for: exercise.id)
            let previousSets = previousPerformance[exercise.id] ?? []
            let setCount = max(previousSets.count, 1)

            let draftSets = (0..<setCount).map { i in
                DraftTemplateSet(order: i)
            }

            let draft = DraftTemplateExercise(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                exerciseType: exercise.type,
                exerciseNotes: exercise.notes,
                order: maxOrder + 1 + offset,
                sets: draftSets
            )
            exercises.append(draft)
        }
        showExercisePicker = false
    }

    func removeExercise(_ exercise: DraftTemplateExercise) {
        exercises.removeAll { $0.id == exercise.id }
        reindexExercises()
    }

    func reorderExercises(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        reindexExercises()
    }

    func addSet(to exercise: DraftTemplateExercise) {
        guard let index = exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        let maxOrder = exercises[index].sets.map(\.order).max() ?? -1
        let newSet = DraftTemplateSet(order: maxOrder + 1)
        exercises[index].sets.append(newSet)
    }

    func removeSet(_ set: DraftTemplateSet, from exercise: DraftTemplateExercise) {
        guard let exIndex = exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        exercises[exIndex].sets.removeAll { $0.id == set.id }
        reindexSets(for: exIndex)
    }

    func updateSet(
        _ set: DraftTemplateSet,
        in exercise: DraftTemplateExercise,
        weight: Double?,
        reps: Int?,
        bodyweightModifier: Double?,
        time: TimeInterval?,
        distance: Double?,
        notes: String?
    ) {
        guard let exIndex = exercises.firstIndex(where: { $0.id == exercise.id }),
              let setIndex = exercises[exIndex].sets.firstIndex(where: { $0.id == set.id }) else { return }
        exercises[exIndex].sets[setIndex].weight = weight
        exercises[exIndex].sets[setIndex].reps = reps
        exercises[exIndex].sets[setIndex].bodyweightModifier = bodyweightModifier
        exercises[exIndex].sets[setIndex].time = time
        exercises[exIndex].sets[setIndex].distance = distance
        exercises[exIndex].sets[setIndex].notes = notes
    }

    func updateTemplateExerciseNotes(_ exercise: DraftTemplateExercise, notes: String?) {
        guard let index = exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        exercises[index].notes = notes
    }

    func updateExerciseNotes(_ draft: DraftTemplateExercise, notes: String?) async {
        guard let index = exercises.firstIndex(where: { $0.id == draft.id }) else { return }
        exercises[index].exerciseNotes = notes
        do {
            let exercise = try await exerciseService.fetch(id: draft.exerciseId)
            exercise.notes = notes
            try await exerciseService.update(exercise)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        guard validate() else { return }

        isSaving = true
        errorMessage = nil
        do {
            try await templateService.saveTemplate(
                existingId: templateId,
                name: name,
                notes: notes.isEmpty ? nil : notes,
                exercises: exercises
            )
            router.dismissSheet()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func cancel() {
        router.dismissSheet()
    }

    // MARK: - Private

    private func validate() -> Bool {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Name is required"
            return false
        }
        return true
    }

    private func loadPreviousPerformance(for exerciseId: UUID) async {
        do {
            let exercise = try await exerciseService.fetch(id: exerciseId)
            let sets = try await workoutService.lastPerformedSets(for: exercise)
            previousPerformance[exerciseId] = sets
        } catch {
            // Non-critical — just means no placeholders
        }
    }

    private func reindexExercises() {
        for i in exercises.indices {
            exercises[i].order = i
        }
    }

    private func reindexSets(for exerciseIndex: Int) {
        for i in exercises[exerciseIndex].sets.indices {
            exercises[exerciseIndex].sets[i].order = i
        }
    }
}
