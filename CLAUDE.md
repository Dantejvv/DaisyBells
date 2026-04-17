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
### Tab Structure (5 tabs)
- **Home** — Split dashboard, start workouts, quick access to active workout
- **Library** — Exercise Library + Workout Library (templates)
- **History** — Completed workouts (read-only, chronological)
- **Analytics** — Insights, metrics, personal records
- **Profile** — Settings (units, distance units, appearance), data export/import/reset

### Core Domain Models
- **Exercise Library:** `Exercise`, `ExerciseCategory`
- **Workout Planning:** `WorkoutTemplate`, `TemplateExercise`, `TemplateSet`
- **Splits:** `Split`, `SplitDay`
- **Workout Logging:** `Workout`, `LoggedExercise`, `LoggedSet`
- **Enums:** `ExerciseType`, `WorkoutStatus`, `Units`, `DistanceUnits`, `Appearance`, `ExerciseSortOption`

## Current Implementation Status
**Completed Phases:**
- ✅ Phase 1: Foundation (Enums, SchemaV1, MigrationPlan)
- ✅ Phase 2: Services (12 services + protocols, tested — SeedingService lacks test coverage)
- ✅ Phase 3: Infrastructure (DependencyContainer, 4 Routers, extensions)
- ✅ Phase 4: ViewModels (24+ ViewModels across all features)

**Remaining Work:**
- 🔨 Phase 5: Production Views (in progress — Home and Library views being built)
- ❌ Phase 6: Polish + Testing

## Documentation
- `docs/ARCHITECTURE.md` — Architecture decisions, MVVM rules, concurrency model
- `docs/MODELS.md` — Data model definitions and relationships

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
- `SeedingService` — First-launch data seeding from bundled JSON
- `DataService` — Data export, import, and reset (backup/restore)

## File Structure
- `DaisyBells/App/` — App entry point and DependencyContainer
- `DaisyBells/Models/` — SwiftData @Model classes, shared across features
- `DaisyBells/Schema/` — VersionedSchema and MigrationPlan
- `DaisyBells/Services/` — Business logic and persistence, shared across features
- `DaisyBells/Services/DTOs/` — Export/import data transfer objects (ExportContainer, JSONDocument)
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

## View Coupling
- **ActiveWorkoutView ↔ TemplateDetailView**: TemplateDetailView mirrors ActiveWorkoutView's layout as a read-only preview. When changing ActiveWorkoutView's exercise card or set row layout, update TemplateDetailView to match.

## Building
- Build command: `xcodebuild build -project /Users/dante/Dev/DaisyBells/DaisyBells.xcodeproj -scheme DaisyBells -destination 'generic/platform=iOS Simulator'`
- Do NOT use `-quiet` — it hides `BUILD SUCCEEDED`/`BUILD FAILED` and only shows a harmless Xcode IDE warning, making it look like the build failed
- Check for `BUILD SUCCEEDED` or `error:` in output using `grep -E "(BUILD|error:)"` when piping

## Testing
- Do NOT run simulator tests (xcodebuild test). Just build the app to verify compilation.

## Avoid
- Do not use @Query in views—fetch through services
- Do not use singletons or global state
- Do not add third-party packages
