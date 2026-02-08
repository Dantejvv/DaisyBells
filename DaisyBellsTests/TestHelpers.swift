import Foundation
import SwiftData
@testable import DaisyBells

/// Creates an isolated in-memory ModelContainer for testing
@MainActor
func makeTestModelContainer() throws -> ModelContainer {
    let schema = Schema(versionedSchema: SchemaV1.self)
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: config)
}

/// Creates a properly configured WorkoutService with all dependencies for testing
@MainActor
func makeWorkoutService(modelContext: ModelContext) -> WorkoutService {
    let exerciseService = ExerciseService(modelContext: modelContext)
    let loggedExerciseService = LoggedExerciseService(modelContext: modelContext)
    let loggedSetService = LoggedSetService(modelContext: modelContext)
    return WorkoutService(
        modelContext: modelContext,
        exerciseService: exerciseService,
        loggedExerciseService: loggedExerciseService,
        loggedSetService: loggedSetService
    )
}
