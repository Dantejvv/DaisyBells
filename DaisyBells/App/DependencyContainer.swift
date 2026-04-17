import Foundation
import SwiftData

@MainActor @Observable
final class DependencyContainer {
    let modelContainer: ModelContainer

    // Services
    let settingsService: SettingsService
    let categoryService: CategoryService
    let exerciseService: ExerciseService
    let templateService: TemplateService
    let splitService: SplitService
    let splitDayService: SplitDayService
    let loggedExerciseService: LoggedExerciseService
    let loggedSetService: LoggedSetService
    let workoutService: WorkoutService
    let analyticsService: AnalyticsService
    let seedingService: SeedingService
    let dataService: DataService

    // Appearance
    private(set) var currentAppearance: Appearance = .system

    // Active Workout
    let activeWorkoutManager: ActiveWorkoutManager

    // Routers
    let homeRouter: HomeRouter
    let libraryRouter: LibraryRouter
    let historyRouter: HistoryRouter
    let analyticsRouter: AnalyticsRouter

    init() throws {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(schema: schema)
        self.modelContainer = try ModelContainer(
            for: schema,
            migrationPlan: DaisyBellsMigrationPlan.self,
            configurations: config
        )

        let modelContext = modelContainer.mainContext

        self.settingsService = SettingsService()
        self.categoryService = CategoryService(modelContext: modelContext)
        self.exerciseService = ExerciseService(modelContext: modelContext)
        self.templateService = TemplateService(modelContext: modelContext)
        self.splitService = SplitService(modelContext: modelContext)
        self.splitDayService = SplitDayService(modelContext: modelContext)
        self.loggedExerciseService = LoggedExerciseService(modelContext: modelContext)
        self.loggedSetService = LoggedSetService(modelContext: modelContext)
        self.workoutService = WorkoutService(
            modelContext: modelContext,
            exerciseService: exerciseService,
            loggedExerciseService: loggedExerciseService,
            loggedSetService: loggedSetService
        )
        self.analyticsService = AnalyticsService(modelContext: modelContext)
        self.seedingService = SeedingService(modelContext: modelContext)
        self.dataService = DataService(modelContext: modelContext, seedingService: seedingService)

        // Initialize active workout manager
        self.activeWorkoutManager = ActiveWorkoutManager(workoutService: workoutService)

        // Initialize routers
        self.homeRouter = HomeRouter()
        self.libraryRouter = LibraryRouter()
        self.historyRouter = HistoryRouter()
        self.analyticsRouter = AnalyticsRouter()

        self.currentAppearance = settingsService.appearance
    }

    func updateAppearance(_ newAppearance: Appearance) {
        settingsService.appearance = newAppearance
        currentAppearance = newAppearance
    }

    func performSetup() async {
        do {
            try await seedingService.seedIfNeeded()
        } catch {
            print("Seeding failed: \(error)")
        }

        await activeWorkoutManager.checkForActiveWorkout()
    }
}
