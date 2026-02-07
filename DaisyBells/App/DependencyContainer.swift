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
    let workoutService: WorkoutService
    let analyticsService: AnalyticsService
    let seedingService: SeedingService

    // Routers
    let libraryRouter: LibraryRouter
    let routinesRouter: RoutinesRouter
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
        self.workoutService = WorkoutService(modelContext: modelContext)
        self.analyticsService = AnalyticsService(modelContext: modelContext)
        self.seedingService = SeedingService(modelContext: modelContext)

        // Initialize routers
        self.libraryRouter = LibraryRouter()
        self.routinesRouter = RoutinesRouter()
        self.historyRouter = HistoryRouter()
        self.analyticsRouter = AnalyticsRouter()
    }

    func performSetup() async {
        do {
            try await seedingService.seedIfNeeded()
        } catch {
            print("Seeding failed: \(error)")
        }
    }
}
