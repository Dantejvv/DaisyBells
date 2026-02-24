import Foundation
import SwiftData
import SwiftUI  // Required for IndexSet

@MainActor @Observable
final class SplitFormViewModel {
    // MARK: - Local Types

    struct DayEditState: Identifiable {
        let id: UUID
        var name: String
        var order: Int
        var assignedWorkouts: [WorkoutInfo]
        var persistentId: PersistentIdentifier?  // nil = new day

        struct WorkoutInfo: Identifiable {
            let id: UUID
            let name: String
            let exerciseCount: Int
            let persistentId: PersistentIdentifier
        }
    }

    // MARK: - State

    var name: String = ""
    var notes: String = ""
    var days: [DayEditState] = []
    private(set) var isEditing = false
    private(set) var isSaving = false
    private(set) var shouldDismiss = false
    var errorMessage: String?

    // Workout picker state
    var showWorkoutPicker = false
    private(set) var dayIndexForWorkoutPicker: Int?

    // Add day prompt state
    var showAddDayPrompt = false
    var newDayName = ""

    // MARK: - Dependencies

    private let splitService: SplitServiceProtocol
    private let splitDayService: SplitDayServiceProtocol
    private let templateService: TemplateServiceProtocol
    private let splitId: PersistentIdentifier?

    // Edit-mode diff tracking
    private var originalDayIds: Set<PersistentIdentifier> = []
    private var originalWorkoutIds: [PersistentIdentifier: Set<PersistentIdentifier>] = [:]

    // MARK: - Init

    init(
        splitService: SplitServiceProtocol,
        splitDayService: SplitDayServiceProtocol,
        templateService: TemplateServiceProtocol,
        splitId: PersistentIdentifier?
    ) {
        self.splitService = splitService
        self.splitDayService = splitDayService
        self.templateService = templateService
        self.splitId = splitId
    }

    // MARK: - Intents

    func load() async {
        guard let splitId else { return }

        isEditing = true
        errorMessage = nil

        guard let split = splitService.fetch(by: splitId) else {
            errorMessage = "Split not found"
            return
        }

        name = split.name
        notes = split.notes ?? ""

        let sortedDays = split.days.sorted { $0.order < $1.order }
        days = sortedDays.map { day in
            let workoutInfos = day.assignedWorkouts.map { template in
                DayEditState.WorkoutInfo(
                    id: template.id,
                    name: template.name,
                    exerciseCount: template.templateExercises.count,
                    persistentId: template.persistentModelID
                )
            }
            return DayEditState(
                id: day.id,
                name: day.name,
                order: day.order,
                assignedWorkouts: workoutInfos,
                persistentId: day.persistentModelID
            )
        }

        // Snapshot for diff on save
        originalDayIds = Set(sortedDays.map { $0.persistentModelID })
        originalWorkoutIds = [:]
        for day in sortedDays {
            originalWorkoutIds[day.persistentModelID] = Set(day.assignedWorkouts.map { $0.persistentModelID })
        }
    }

    // MARK: - Day Management

    func addDay(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let newDay = DayEditState(
            id: UUID(),
            name: trimmed,
            order: days.count,
            assignedWorkouts: [],
            persistentId: nil
        )
        days.append(newDay)
    }

    func removeDay(at offsets: IndexSet) {
        days.remove(atOffsets: offsets)
        reindexDays()
    }

    func reorderDays(from source: IndexSet, to destination: Int) {
        days.move(fromOffsets: source, toOffset: destination)
        reindexDays()
    }

    func updateDayName(_ newName: String, at index: Int) {
        guard days.indices.contains(index) else { return }
        days[index].name = newName
    }

    // MARK: - Workout Assignment

    func presentWorkoutPicker(forDayAt index: Int) {
        dayIndexForWorkoutPicker = index
        showWorkoutPicker = true
    }

    func onWorkoutSelected(_ templateId: PersistentIdentifier) {
        guard let index = dayIndexForWorkoutPicker,
              days.indices.contains(index) else {
            showWorkoutPicker = false
            dayIndexForWorkoutPicker = nil
            return
        }

        guard let template = templateService.fetch(by: templateId) else {
            errorMessage = "Workout template not found"
            showWorkoutPicker = false
            dayIndexForWorkoutPicker = nil
            return
        }

        // Prevent duplicate assignment
        let alreadyAssigned = days[index].assignedWorkouts.contains { $0.persistentId == templateId }
        if !alreadyAssigned {
            let info = DayEditState.WorkoutInfo(
                id: template.id,
                name: template.name,
                exerciseCount: template.templateExercises.count,
                persistentId: template.persistentModelID
            )
            days[index].assignedWorkouts.append(info)
        }

        showWorkoutPicker = false
        dayIndexForWorkoutPicker = nil
    }

    func removeWorkout(at workoutOffsets: IndexSet, fromDayAt dayIndex: Int) {
        guard days.indices.contains(dayIndex) else { return }
        days[dayIndex].assignedWorkouts.remove(atOffsets: workoutOffsets)
    }

    // MARK: - Save

    func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Name cannot be empty"
            return
        }

        // Validate day names
        for day in days {
            if day.name.trimmingCharacters(in: .whitespaces).isEmpty {
                errorMessage = "All days must have a name"
                return
            }
        }

        isSaving = true
        errorMessage = nil

        do {
            if isEditing {
                try await saveEdit(trimmedName: trimmedName)
            } else {
                try await saveCreate(trimmedName: trimmedName)
            }
            shouldDismiss = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    // MARK: - Private

    private func saveCreate(trimmedName: String) async throws {
        let split = try await splitService.create(
            name: trimmedName,
            notes: notes.isEmpty ? nil : notes
        )

        for day in days {
            let newDay = try await splitDayService.create(name: day.name, split: split)
            for workout in day.assignedWorkouts {
                if let template = templateService.fetch(by: workout.persistentId) {
                    try await splitDayService.assignWorkout(template, to: newDay)
                }
            }
        }
    }

    private func saveEdit(trimmedName: String) async throws {
        guard let splitId, let split = splitService.fetch(by: splitId) else {
            errorMessage = "Split not found"
            return
        }

        // Update split name/notes
        split.name = trimmedName
        split.notes = notes.isEmpty ? nil : notes
        try await splitService.update(split)

        let currentDayPersistentIds = Set(days.compactMap { $0.persistentId })

        // Delete removed days
        let removedDayIds = originalDayIds.subtracting(currentDayPersistentIds)
        for removedId in removedDayIds {
            if let dayModel = splitDayService.fetch(by: removedId) {
                try await splitDayService.delete(dayModel, from: split)
            }
        }

        // Create new days and update existing days
        var orderedDayModels: [SchemaV1.SplitDay] = []
        for day in days {
            if let persistentId = day.persistentId, originalDayIds.contains(persistentId) {
                // Existing day — update name
                if let dayModel = splitDayService.fetch(by: persistentId) {
                    dayModel.name = day.name
                    try await splitDayService.update(dayModel)
                    orderedDayModels.append(dayModel)

                    // Diff workout assignments
                    let originalWorkouts = originalWorkoutIds[persistentId] ?? []
                    let currentWorkouts = Set(day.assignedWorkouts.map { $0.persistentId })

                    // Unassign removed workouts
                    for removedWorkoutId in originalWorkouts.subtracting(currentWorkouts) {
                        if let template = templateService.fetch(by: removedWorkoutId) {
                            try await splitDayService.unassignWorkout(template, from: dayModel)
                        }
                    }

                    // Assign new workouts
                    for addedWorkoutId in currentWorkouts.subtracting(originalWorkouts) {
                        if let template = templateService.fetch(by: addedWorkoutId) {
                            try await splitDayService.assignWorkout(template, to: dayModel)
                        }
                    }
                }
            } else {
                // New day — create
                let newDay = try await splitDayService.create(name: day.name, split: split)
                for workout in day.assignedWorkouts {
                    if let template = templateService.fetch(by: workout.persistentId) {
                        try await splitDayService.assignWorkout(template, to: newDay)
                    }
                }
                orderedDayModels.append(newDay)
            }
        }

        // Reorder all days
        if !orderedDayModels.isEmpty {
            try await splitDayService.reorder(days: orderedDayModels, in: split)
        }
    }

    private func reindexDays() {
        for i in days.indices {
            days[i].order = i
        }
    }
}
