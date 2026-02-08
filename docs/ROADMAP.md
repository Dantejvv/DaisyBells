# DaisyBells Implementation Roadmap

## Current State
- **UI Prototypes:** Complete (19 views, 4 components in ViewTesting/)
- **Mock Data:** Complete (MockTypes.swift with full model hierarchy)
- **Documentation:** Complete (ARCHITECTURE, MODELS, CONTRACTS, FEATURES, USERFLOWS)
- **Production Code:** Empty (Models/, Services/, Features/, Schema/ are empty shells)

---

## Implementation Phases

### Phase 1: Foundation (Schema + Models)
Build the data layer that everything else depends on.

**Files to create:**
- `DaisyBells/Models/Enums.swift` — ExerciseType, WorkoutStatus, Units, Appearance
- `DaisyBells/Schema/SchemaV1.swift` — VersionedSchema with all @Model classes
- `DaisyBells/Schema/MigrationPlan.swift` — SchemaMigrationPlan

**Models (inside SchemaV1):**
- ExerciseCategory
- Exercise
- WorkoutTemplate
- TemplateExercise
- Split
- SplitDay
- Workout
- LoggedExercise
- LoggedSet

**Note:** Models are shared across all features, not organized per-feature.

**Verification:**
- Build succeeds
- ModelContainer can be instantiated

---

### Phase 2: Services Layer
Build business logic + SwiftData access.

**Files to create:**
- `DaisyBells/Services/Protocols/` — Service protocols for DI/testing
  - CategoryServiceProtocol
  - ExerciseServiceProtocol
  - TemplateServiceProtocol
  - SplitServiceProtocol
  - SplitDayServiceProtocol
  - WorkoutServiceProtocol
  - LoggedExerciseServiceProtocol
  - LoggedSetServiceProtocol
  - AnalyticsServiceProtocol
  - SettingsServiceProtocol
- `DaisyBells/Services/CategoryService.swift`
- `DaisyBells/Services/ExerciseService.swift`
- `DaisyBells/Services/TemplateService.swift`
- `DaisyBells/Services/SplitService.swift`
- `DaisyBells/Services/SplitDayService.swift`
- `DaisyBells/Services/WorkoutService.swift`
- `DaisyBells/Services/LoggedExerciseService.swift`
- `DaisyBells/Services/LoggedSetService.swift`
- `DaisyBells/Services/AnalyticsService.swift`
- `DaisyBells/Services/SettingsService.swift`
- `DaisyBells/Services/SeedingService.swift`

**Note:** Services are shared across all features and own all SwiftData access.

**Verification:**
- Unit tests pass for service operations
- CRUD operations work with in-memory ModelContainer

---

### Phase 3: Infrastructure
Build DI container, routers, extensions.

**Files to create:**
- `DaisyBells/App/DependencyContainer.swift` — Composition root, creates ModelContainer and all services
- `DaisyBells/Features/Home/HomeRouter.swift` — Navigation enum + router for Split features
- `DaisyBells/Features/Library/LibraryRouter.swift` — Navigation enum + router for Exercise/Template features
- `DaisyBells/Features/History/HistoryRouter.swift` — Navigation enum + router for History features
- `DaisyBells/Features/Analytics/AnalyticsRouter.swift` — Navigation enum + router for Analytics features
- `DaisyBells/Extensions/Date+Formatting.swift` — Date formatting helpers
- `DaisyBells/Extensions/Double+Units.swift` — Unit conversion helpers

**Router Pattern:**
- Each router is `@Observable` with `path: [Route]` array
- Routes are `Hashable` enums with associated values
- Routers expose `push(_:)`, `pop()`, `popToRoot()` methods
- ViewModels receive router via initializer and call router methods to navigate

**Verification:**
- App launches with DependencyContainer
- Seed data loads on first launch
- All four routers can be instantiated

---

### Phase 4: ViewModels
Build @MainActor, @Observable ViewModels per CONTRACTS.md.

**Files to create (Home feature - Splits):**
- `DaisyBells/Features/Home/SplitListViewModel.swift`
- `DaisyBells/Features/Home/SplitDetailViewModel.swift`
- `DaisyBells/Features/Home/SplitFormViewModel.swift`
- `DaisyBells/Features/Home/SplitDayDetailViewModel.swift`
- `DaisyBells/Features/Home/SplitDayFormViewModel.swift`

**Files to create (Library feature - Exercises):**
- `DaisyBells/Features/Library/Exercises/CategoryListViewModel.swift`
- `DaisyBells/Features/Library/Exercises/ExerciseListViewModel.swift`
- `DaisyBells/Features/Library/Exercises/ExerciseDetailViewModel.swift`
- `DaisyBells/Features/Library/Exercises/ExerciseFormViewModel.swift`

**Files to create (Library feature - Templates):**
- `DaisyBells/Features/Library/Templates/TemplateListViewModel.swift`
- `DaisyBells/Features/Library/Templates/TemplateDetailViewModel.swift`
- `DaisyBells/Features/Library/Templates/TemplateFormViewModel.swift`

**Files to create (Shared Pickers):**
- `DaisyBells/Features/Shared/ExercisePickerViewModel.swift`
- `DaisyBells/Features/Shared/WorkoutPickerViewModel.swift`
- `DaisyBells/Features/Shared/SplitDayPickerViewModel.swift`

**Files to create (ActiveWorkout feature):**
- `DaisyBells/Features/ActiveWorkout/ActiveWorkoutViewModel.swift`

**Files to create (History feature):**
- `DaisyBells/Features/History/HistoryListViewModel.swift`
- `DaisyBells/Features/History/CompletedWorkoutDetailViewModel.swift`

**Files to create (Analytics feature):**
- `DaisyBells/Features/Analytics/AnalyticsDashboardViewModel.swift`
- `DaisyBells/Features/Analytics/ExerciseAnalyticsViewModel.swift`

**Files to create (Settings feature):**
- `DaisyBells/Features/Settings/SettingsViewModel.swift`

**ViewModel Pattern:**
- All ViewModels are `@MainActor` and `@Observable`
- Receive services and router via initializer (not @Environment)
- Expose state (read-only computed properties preferred)
- Expose intents (async methods that call services)
- `errorMessage: String?` is `var` (not `private(set)`) for view binding

**Verification:**
- ViewModel unit tests pass
- State transitions match CONTRACTS.md
- All ViewModels follow MVVM rules from ARCHITECTURE.md

---

### Phase 5: Production Views
Migrate ViewTesting prototypes to production with real ViewModels.

**Process per view:**
1. Copy from ViewTesting/ to Features/
2. Replace MockTypes with real SchemaV1 models
3. Replace inline mock data with ViewModel bindings via `@State`
4. Wire navigation through Router (use `NavigationLink(value:)`, not inline destinations)
5. Remove `@EnvironmentObject` - ViewModels passed as `@State` init parameters
6. Use `.environment()` modifier to inject dependencies from DependencyContainer

**View Pattern:**
- Views receive ViewModels as `@State` init parameters
- ViewModels created in `navigationDestination(for:)` closures with injected dependencies
- Navigation: `NavigationStack(path: $router.path)` + `.navigationDestination(for: Route.self)`
- Sheets: `router.presentedSheet` drives `.sheet(item:)`
- No `@Query` - all data flows through ViewModels

**Order (dependencies first):**
1. Components (EmptyStateView, LoadingSpinnerView, ConfirmationDialogModifier, ErrorAlertModifier)
2. Home/Splits (SplitList → SplitDetail → SplitForm → SplitDayDetail → SplitDayForm)
3. Library/Exercises (CategoryList → ExerciseList → ExerciseDetail → ExerciseForm)
4. Library/Templates (TemplateList → TemplateDetail → TemplateForm)
5. Shared Pickers (ExercisePicker, WorkoutPicker, SplitDayPicker)
6. ActiveWorkout (depends on ExercisePicker)
7. History (HistoryList → CompletedWorkoutDetail)
8. Analytics (Dashboard → ExerciseAnalyticsDetail)
9. Settings (modal)
10. MainTabView (orchestrates all 4 tabs: Home, Library, History, Analytics)

**Verification:**
- All navigation flows work end-to-end per USERFLOWS.md
- Data persists across app launches
- No @EnvironmentObject or @Query usage
- All dependencies flow through DependencyContainer

---

### Phase 6: Polish + Testing
Final integration and quality assurance.

**Tasks:**
- Comprehensive service tests (SwiftTesting)
- ViewModel state transition tests
- Manual end-to-end testing of all user flows
- Edge cases: empty states, error handling, data validation
- Analytics derivation accuracy

**Verification:**
- All tests pass
- All USERFLOWS.md scenarios work

---

## Recommended Build Order (Granular)

| Step | Component | Depends On | Estimate |
|------|-----------|------------|----------|
| **Phase 1: Foundation** |
| 1 | Enums.swift | — | Small |
| 2 | SchemaV1.swift | Enums | Medium |
| 3 | MigrationPlan.swift | SchemaV1 | Small |
| **Phase 2: Services** |
| 4 | Service Protocols | Models | Small |
| 5 | SettingsService | — | Small |
| 6 | CategoryService | Models | Small |
| 7 | ExerciseService | Models, CategoryService | Medium |
| 8 | TemplateService | Models, ExerciseService | Medium |
| 9 | SplitService | Models | Small |
| 10 | SplitDayService | Models, SplitService | Small |
| 11 | LoggedExerciseService | Models, ExerciseService | Small |
| 12 | LoggedSetService | Models | Small |
| 13 | WorkoutService | Models, ExerciseService, LoggedExerciseService, LoggedSetService | Large |
| 14 | AnalyticsService | Models, WorkoutService | Medium |
| 15 | SeedingService | CategoryService, ExerciseService | Small |
| **Phase 3: Infrastructure** |
| 16 | DependencyContainer | All Services | Medium |
| 17 | HomeRouter | — | Small |
| 18 | LibraryRouter | — | Small |
| 19 | HistoryRouter | — | Small |
| 20 | AnalyticsRouter | — | Small |
| 21 | Date+Formatting | — | Small |
| 22 | Double+Units | — | Small |
| 23 | Seed JSON files | — | Small |
| **Phase 4: ViewModels** |
| 24 | SplitListViewModel | SplitService, HomeRouter | Small |
| 25 | SplitDetailViewModel | SplitService, SplitDayService, HomeRouter | Medium |
| 26 | SplitFormViewModel | SplitService, HomeRouter | Small |
| 27 | SplitDayDetailViewModel | SplitDayService, WorkoutService, HomeRouter | Medium |
| 28 | SplitDayFormViewModel | SplitDayService, HomeRouter | Small |
| 29 | CategoryListViewModel | CategoryService, LibraryRouter | Small |
| 30 | ExerciseListViewModel | ExerciseService, LibraryRouter | Medium |
| 31 | ExerciseDetailViewModel | ExerciseService, AnalyticsService, LibraryRouter | Small |
| 32 | ExerciseFormViewModel | ExerciseService, CategoryService, LibraryRouter | Medium |
| 33 | TemplateListViewModel | TemplateService, LibraryRouter | Small |
| 34 | TemplateDetailViewModel | TemplateService, SplitDayService, WorkoutService, LibraryRouter | Medium |
| 35 | TemplateFormViewModel | TemplateService, LibraryRouter | Medium |
| 36 | ExercisePickerViewModel | ExerciseService, CategoryService | Small |
| 37 | WorkoutPickerViewModel | TemplateService | Small |
| 38 | SplitDayPickerViewModel | SplitService | Small |
| 39 | ActiveWorkoutViewModel | WorkoutService, TemplateService, LoggedExerciseService, LoggedSetService | Large |
| 40 | HistoryListViewModel | WorkoutService, HistoryRouter | Small |
| 41 | CompletedWorkoutDetailViewModel | WorkoutService, HistoryRouter | Small |
| 42 | AnalyticsDashboardViewModel | AnalyticsService, AnalyticsRouter | Medium |
| 43 | ExerciseAnalyticsViewModel | AnalyticsService, AnalyticsRouter | Small |
| 44 | SettingsViewModel | SettingsService | Small |
| **Phase 5: Views** |
| 45 | Migrate Components (4) | — | Small |
| 46 | Migrate Home Views (Splits) | Split ViewModels, HomeRouter | Large |
| 47 | Migrate Library/Exercise Views | Exercise ViewModels, LibraryRouter | Large |
| 48 | Migrate Library/Template Views | Template ViewModels, LibraryRouter | Large |
| 49 | Migrate Shared Pickers | Picker ViewModels | Medium |
| 50 | Migrate ActiveWorkout View | ActiveWorkoutViewModel, ExercisePicker | Large |
| 51 | Migrate History Views | History ViewModels, HistoryRouter | Medium |
| 52 | Migrate Analytics Views | Analytics ViewModels, AnalyticsRouter | Medium |
| 53 | Migrate Settings View | SettingsViewModel | Small |
| 54 | Migrate MainTabView | All Tabs | Medium |
| **Phase 6: Testing** |
| 55 | Service Tests | Services | Medium |
| 56 | ViewModel Tests | ViewModels | Medium |
| 57 | End-to-End Testing | All | Large |

---

## Key Files Reference

**Contracts:** `docs/CONTRACTS.md` — State, intents, side effects per ViewModel
**Models:** `docs/MODELS.md` — SwiftData model definitions
**Architecture:** `docs/ARCHITECTURE.md` — Rules, patterns, concurrency
**Features:** `docs/FEATURES.md` — Feature specifications
**User Flows:** `docs/USERFLOWS.md` — End-to-end user scenarios
**UI Prototypes:** `DaisyBells/ViewTesting/` — Visual reference for all views

---

## Notes

### Architecture Constraints
- **No UIKit, CoreData, Combine, or third-party packages**
- **No @Query in views** — all data flows through ViewModels and Services
- **No @EnvironmentObject** — ViewModels receive dependencies via initializer
- **Use VersionedSchema from day one** — SchemaV1 even for initial release
- **Services own all SwiftData access** — ViewModels never access ModelContext

### Tab Structure (4 tabs)
1. **Home** — Split dashboard, start workout options, resume active workout
2. **Library** — Exercise Library + Workout Library (templates)
3. **History** — Completed workouts (read-only, chronological)
4. **Analytics** — Insights, metrics, personal records

### Domain Rules
- **Exercises are archived, not deleted** when they have workout history
- **Analytics are derived, not persisted** — cached fields updated on workout completion
- **Completed workouts are immutable** — read-only, only deletable
- **Settings via SettingsService only** — no @AppStorage in Views

### File Organization
- **Models/** — Shared SwiftData @Model classes across all features
- **Services/** — Shared business logic and persistence across all features
- **Features/{Feature}/** — Views, ViewModels, Routers per feature
- **Components/** — Reusable UI used by 2+ features
- **Extensions/** — Swift type extensions (Date, Double, etc.)
