# DaisyBells

A workout tracking iOS app for logging exercises, creating workout templates, and viewing analytics.

## Tech Stack
- Swift, SwiftUI, SwiftData, SwiftTesting
- iOS 17+
- MVVM + Services architecture

## Do Not Use
- UIKit
- CoreData
- Combine
- Third-party dependencies
- @EnvironmentObject for dependency injection

## App Structure
### Tab Structure (4 tabs)
- **Home** — Split dashboard, start workouts, quick access to active workout
- **Library** — Exercise Library + Workout Library (templates)
- **History** — Completed workouts (read-only, chronological)
- **Analytics** — Insights, metrics, personal records

### Core Domain Models
- **Exercise Library:** `Exercise`, `ExerciseCategory`
- **Workout Planning:** `WorkoutTemplate`, `TemplateExercise`
- **Splits:** `Split`, `SplitDay`
- **Workout Logging:** `Workout`, `LoggedExercise`, `LoggedSet`
- **Enums:** `ExerciseType`, `WorkoutStatus`, `Units`, `Appearance`

## Documentation
- `docs/ARCHITECTURE.md` — Architecture decisions, MVVM rules, concurrency model
- `docs/MODELS.md` — Data model definitions and relationships
- `docs/FEATURES.md` — Feature specifications
- `docs/CONTRACTS.md` — View-ViewModel contracts (state, intents, side effects)
- `docs/USERFLOWS.md` — User flows and model lifecycle mappings

## Architecture Rules
- **Views:** No business logic, no SwiftData access, call ViewModel intents only
- **ViewModels:** @MainActor, @Observable, call services for all data operations
- **Services:** Own all business logic and SwiftData access, injected via protocols
- **Navigation:** Enum-based routing with per-tab Routers (HomeRouter, LibraryRouter, HistoryRouter, AnalyticsRouter)
  - Route enums are Hashable with associated values for passing data
  - Use `NavigationLink(value:)`, not `NavigationLink(destination:)` with inline views
  - ViewModels call router methods to navigate (push, pop, popToRoot)
- **Models:** Use VersionedSchema from day one
- **Settings:** Access UserDefaults only through SettingsService, never use @AppStorage in Views
- **Error Handling:** Services use `async throws`, ViewModels catch and translate to `errorMessage: String?`

## Service Protocols
- `ExerciseService` — Exercise CRUD, archiving, history checks
- `CategoryService` — Category management, reordering
- `TemplateService` — WorkoutTemplate CRUD, duplication
- `WorkoutService` — Active and completed workout management
- `SplitService` — Split CRUD
- `SplitDayService` — Split day management, workout assignments
- `LoggedExerciseService` — Exercise logging during workouts
- `LoggedSetService` — Set logging and editing
- `AnalyticsService` — Aggregations and derived analytics (combines cached data with on-demand calculations)
- `SettingsService` — UserDefaults access for app preferences

## File Structure
- `DaisyBells/App/` — App entry point and DependencyContainer
- `DaisyBells/Models/` — SwiftData @Model classes, shared across features
- `DaisyBells/Schema/` — VersionedSchema and MigrationPlan
- `DaisyBells/Services/` — Business logic and persistence, shared across features
- `DaisyBells/Features/{Feature}/` — Views, ViewModels, Routers per feature
- `DaisyBells/Components/` — Reusable UI components used by 2+ features
- `DaisyBells/Extensions/` — Swift type extensions (e.g., Date+Formatting, Double+Units)
- `DaisyBells/Resources/` — Assets.xcassets and SeedData/ JSON files
- `DaisyBellsTests/` — Tests for Services and ViewModels

## SwiftData Concurrency
- ModelContext and @Model types are NOT Sendable
- Use @MainActor for ViewModels
- Use @ModelActor for background SwiftData work
- Transfer models between contexts via PersistentIdentifier
- Enable **Strict Concurrency Checking: Complete** in build settings

## Data Seeding
- Default categories (~7) and exercises (~20-50) seeded from JSON on first launch
- Seeding runs once via DependencyContainer before UI initialization
- Users can delete defaults; they will not be re-created
- Tests can choose whether to seed or start with empty database

## Exercise Lifecycle Rules
- Exercises referenced by workout history are **archived**, not deleted
- Archived exercises are hidden from library by default but preserved in workout history
- Exercises with no history can be permanently deleted
- Show archived exercises via optional toggle filter

## Avoid
- Do not use @Query in views—fetch through services
- Do not use singletons or global state
- Do not add third-party packages
- Do not create new features without updating docs/FEATURES.md
