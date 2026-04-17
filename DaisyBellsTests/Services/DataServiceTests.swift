import Foundation
import Testing
import SwiftData
@testable import DaisyBells

// MARK: - Test Doubles

@MainActor
private final class MockSeedingService: SeedingServiceProtocol {
    var seedIfNeededCalled = false
    var resetSeedingFlagCalled = false

    func seedIfNeeded() async throws {
        seedIfNeededCalled = true
    }

    func resetSeedingFlag() {
        resetSeedingFlagCalled = true
    }
}

// MARK: - Helpers

@MainActor
private func makeTestSettingsService() -> SettingsService {
    SettingsService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
}

@MainActor
private func makeDataService(modelContext: ModelContext) -> (DataService, MockSeedingService) {
    let mockSeeding = MockSeedingService()
    let service = DataService(modelContext: modelContext, seedingService: mockSeeding)
    return (service, mockSeeding)
}

/// Creates a completed workout with one exercise and one set for round-trip tests.
/// Returns (exercise, workout) so callers can assert against originals.
@MainActor
private func createCompletedWorkout(
    container: ModelContainer,
    exerciseName: String = "Bench Press",
    weight: Double = 225,
    reps: Int = 5
) async throws -> (SchemaV1.Exercise, SchemaV1.Workout) {
    let ctx = container.mainContext
    let workoutService = makeWorkoutService(modelContext: ctx)
    let exerciseService = ExerciseService(modelContext: ctx)
    let loggedExerciseService = LoggedExerciseService(modelContext: ctx)
    let loggedSetService = LoggedSetService(modelContext: ctx)

    let exercise = try await exerciseService.create(name: exerciseName, type: .weightAndReps)
    let workout = try await workoutService.createEmpty()
    let logged = try await loggedExerciseService.create(
        exercise: exercise, workout: workout, order: 0,
        weightUnit: .lbs, distanceUnit: nil
    )
    let set = logged.sets[0]
    try await loggedSetService.update(
        set, weight: weight, reps: reps,
        bodyweightModifier: nil, time: nil, distance: nil, notes: nil
    )
    set.isCompleted = true
    try await workoutService.complete(workout)

    return (exercise, workout)
}

// MARK: - Tests

@Suite(.serialized)
struct DataServiceTests {

    // MARK: - Export

    @Test @MainActor
    func exportProducesValidJSON() async throws {
        let container = try makeTestModelContainer()
        let (service, _) = makeDataService(modelContext: container.mainContext)
        let settings = makeTestSettingsService()

        // Seed some data
        let categoryService = CategoryService(modelContext: container.mainContext)
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        _ = try await categoryService.create(name: "Chest")
        _ = try await exerciseService.create(name: "Bench Press", type: .weightAndReps)

        let data = try await service.exportAllData(settings: settings)
        #expect(data.count > 0)

        // Decode back to verify it's valid JSON with correct structure
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exported = try decoder.decode(ExportContainer.self, from: data)

        #expect(exported.categories.count == 1)
        #expect(exported.exercises.count == 1)
        #expect(exported.metadata.schemaVersion == "1.0.0")
    }

    // MARK: - Round-Trip: Categories

    @Test @MainActor
    func roundTripPreservesCategories() async throws {
        let container = try makeTestModelContainer()
        let (service, _) = makeDataService(modelContext: container.mainContext)
        let settings = makeTestSettingsService()

        let categoryService = CategoryService(modelContext: container.mainContext)
        _ = try await categoryService.create(name: "Chest")
        _ = try await categoryService.create(name: "Back")

        // Export
        let data = try await service.exportAllData(settings: settings)

        // Import (clears DB then inserts)
        try await service.importAllData(from: data, settings: settings)

        // Verify
        let categories = try container.mainContext.fetch(FetchDescriptor<SchemaV1.ExerciseCategory>())
        #expect(categories.count == 2)
        let names = Set(categories.map(\.name))
        #expect(names.contains("Chest"))
        #expect(names.contains("Back"))
    }

    // MARK: - Round-Trip: Exercises with Categories

    @Test @MainActor
    func roundTripPreservesExercisesWithCategories() async throws {
        let container = try makeTestModelContainer()
        let (service, _) = makeDataService(modelContext: container.mainContext)
        let settings = makeTestSettingsService()

        let categoryService = CategoryService(modelContext: container.mainContext)
        let exerciseService = ExerciseService(modelContext: container.mainContext)

        let category = try await categoryService.create(name: "Chest")
        let exercise = try await exerciseService.create(name: "Bench Press", type: .weightAndReps)
        exercise.isFavorite = true
        exercise.notes = "Flat bench"
        exercise.categories.append(category)
        try container.mainContext.save()

        let originalId = exercise.id

        // Export → Import
        let data = try await service.exportAllData(settings: settings)
        try await service.importAllData(from: data, settings: settings)

        // Verify
        let exercises = try container.mainContext.fetch(FetchDescriptor<SchemaV1.Exercise>())
        #expect(exercises.count == 1)

        let imported = exercises[0]
        #expect(imported.id == originalId)
        #expect(imported.name == "Bench Press")
        #expect(imported.type == .weightAndReps)
        #expect(imported.isFavorite == true)
        #expect(imported.notes == "Flat bench")
        #expect(imported.categories.count == 1)
        #expect(imported.categories[0].name == "Chest")
    }

    // MARK: - Round-Trip: Workout with Sets

    @Test @MainActor
    func roundTripPreservesWorkoutWithSets() async throws {
        let container = try makeTestModelContainer()
        let (service, _) = makeDataService(modelContext: container.mainContext)
        let settings = makeTestSettingsService()

        let (exercise, workout) = try await createCompletedWorkout(container: container)
        let originalWorkoutId = workout.id
        let originalExerciseId = exercise.id

        // Export → Import
        let data = try await service.exportAllData(settings: settings)
        try await service.importAllData(from: data, settings: settings)

        // Verify workout
        let workouts = try container.mainContext.fetch(FetchDescriptor<SchemaV1.Workout>())
        #expect(workouts.count == 1)

        let imported = workouts[0]
        #expect(imported.id == originalWorkoutId)
        #expect(imported.status == .completed)
        #expect(imported.completedAt != nil)
        #expect(imported.loggedExercises.count == 1)

        // Verify logged exercise → set chain
        let loggedEx = imported.loggedExercises[0]
        #expect(loggedEx.exercise?.id == originalExerciseId)
        #expect(loggedEx.sets.count == 1)

        let set = loggedEx.sets[0]
        #expect(set.weight == 225)
        #expect(set.reps == 5)
        #expect(set.isCompleted == true)
        #expect(set.weightUnit == Units.lbs.rawValue)
    }

    // MARK: - Round-Trip: PR Cache Recalculation

    @Test @MainActor
    func roundTripRecalculatesPRCache() async throws {
        let container = try makeTestModelContainer()
        let (service, _) = makeDataService(modelContext: container.mainContext)
        let settings = makeTestSettingsService()

        let (exercise, _) = try await createCompletedWorkout(
            container: container, weight: 315, reps: 3
        )

        // Confirm PRs are set before export
        #expect(exercise.prWeight == 315)
        #expect(exercise.prReps == 3)

        // Export → Import (import clears DB, then recalculates stats)
        let data = try await service.exportAllData(settings: settings)
        try await service.importAllData(from: data, settings: settings)

        // Verify PRs were recalculated from workout history
        let exercises = try container.mainContext.fetch(FetchDescriptor<SchemaV1.Exercise>())
        let imported = exercises[0]

        #expect(imported.prWeight == 315)
        #expect(imported.prReps == 3)
        #expect(imported.prEstimated1RM != nil)
        #expect(imported.prAchievedAt != nil)
        #expect(imported.hasCompletedWorkout == true)
        #expect(imported.lastPerformedAt != nil)
    }

    // MARK: - Round-Trip: Settings

    @Test @MainActor
    func roundTripPreservesSettings() async throws {
        let container = try makeTestModelContainer()
        let (service, _) = makeDataService(modelContext: container.mainContext)

        // Export with kg/km/dark
        let exportSettings = makeTestSettingsService()
        exportSettings.units = .kg
        exportSettings.distanceUnits = .km
        exportSettings.appearance = .dark

        let data = try await service.exportAllData(settings: exportSettings)

        // Import into fresh settings (defaults: lbs/mi/system)
        let importSettings = makeTestSettingsService()
        #expect(importSettings.units == .lbs) // confirm defaults
        #expect(importSettings.appearance == .system)

        try await service.importAllData(from: data, settings: importSettings)

        // Settings should now match the exported values
        #expect(importSettings.units == .kg)
        #expect(importSettings.distanceUnits == .km)
        #expect(importSettings.appearance == .dark)
    }

    // MARK: - Reset

    @Test @MainActor
    func resetDeletesAllDataAndReseeds() async throws {
        let container = try makeTestModelContainer()
        let (service, mockSeeding) = makeDataService(modelContext: container.mainContext)
        let settings = makeTestSettingsService()

        // Create some data
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        let categoryService = CategoryService(modelContext: container.mainContext)
        _ = try await exerciseService.create(name: "Squat", type: .weightAndReps)
        _ = try await categoryService.create(name: "Legs")

        // Change settings from defaults
        settings.units = .kg
        settings.appearance = .dark

        // Reset
        try await service.resetAllData(settings: settings)

        // All data should be deleted
        let exercises = try container.mainContext.fetch(FetchDescriptor<SchemaV1.Exercise>())
        let categories = try container.mainContext.fetch(FetchDescriptor<SchemaV1.ExerciseCategory>())
        let workouts = try container.mainContext.fetch(FetchDescriptor<SchemaV1.Workout>())
        #expect(exercises.isEmpty)
        #expect(categories.isEmpty)
        #expect(workouts.isEmpty)

        // Settings should be reset to defaults
        #expect(settings.units == .lbs)
        #expect(settings.distanceUnits == .mi)
        #expect(settings.appearance == .system)
        #expect(settings.activeSplitId == nil)

        // Seeding should have been triggered
        #expect(mockSeeding.resetSeedingFlagCalled == true)
        #expect(mockSeeding.seedIfNeededCalled == true)
    }

    // MARK: - Error Handling

    @Test @MainActor
    func importInvalidJSONThrows() async throws {
        let container = try makeTestModelContainer()
        let (service, _) = makeDataService(modelContext: container.mainContext)
        let settings = makeTestSettingsService()

        // Create data that should survive the failed import
        let exerciseService = ExerciseService(modelContext: container.mainContext)
        _ = try await exerciseService.create(name: "Survivor", type: .reps)

        let garbage = Data("not valid json".utf8)

        await #expect(throws: ServiceError.self) {
            try await service.importAllData(from: garbage, settings: settings)
        }

        // Existing data should still be intact (decode fails before deleteAllModels)
        let exercises = try container.mainContext.fetch(FetchDescriptor<SchemaV1.Exercise>())
        #expect(exercises.count == 1)
        #expect(exercises[0].name == "Survivor")
    }
}
