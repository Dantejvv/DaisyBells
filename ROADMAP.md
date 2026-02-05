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
- Workout
- LoggedExercise
- LoggedSet

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
  - WorkoutServiceProtocol
  - AnalyticsServiceProtocol
  - SettingsServiceProtocol
- `DaisyBells/Services/CategoryService.swift`
- `DaisyBells/Services/ExerciseService.swift`
- `DaisyBells/Services/TemplateService.swift`
- `DaisyBells/Services/WorkoutService.swift`
- `DaisyBells/Services/AnalyticsService.swift`
- `DaisyBells/Services/SettingsService.swift`
- `DaisyBells/Services/SeedingService.swift`

**Verification:**
- Unit tests pass for service operations
- CRUD operations work with in-memory ModelContainer

---

### Phase 3: Infrastructure
Build DI container, routers, extensions.

**Files to create:**
- `DaisyBells/App/DependencyContainer.swift` — Composition root
- `DaisyBells/Features/Library/LibraryRouter.swift` — Navigation enum + router
- `DaisyBells/Features/History/HistoryRouter.swift`
- `DaisyBells/Features/Analytics/AnalyticsRouter.swift`
- `DaisyBells/Extensions/Date+Formatting.swift`
- `DaisyBells/Extensions/Double+Units.swift`

**Verification:**
- App launches with DependencyContainer
- Seed data loads on first launch

---

### Phase 4: ViewModels
Build @MainActor, @Observable ViewModels per CONTRACTS.md.

**Files to create (Library feature):**
- `DaisyBells/Features/Library/Exercises/CategoryListViewModel.swift`
- `DaisyBells/Features/Library/Exercises/ExerciseListViewModel.swift`
- `DaisyBells/Features/Library/Exercises/ExerciseDetailViewModel.swift`
- `DaisyBells/Features/Library/Exercises/ExerciseFormViewModel.swift`
- `DaisyBells/Features/Library/Exercises/ExercisePickerViewModel.swift`
- `DaisyBells/Features/Library/Templates/TemplateListViewModel.swift`
- `DaisyBells/Features/Library/Templates/TemplateDetailViewModel.swift`
- `DaisyBells/Features/Library/Templates/TemplateFormViewModel.swift`

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

**Verification:**
- ViewModel unit tests pass
- State transitions match CONTRACTS.md

---

### Phase 5: Production Views
Migrate ViewTesting prototypes to production with real ViewModels.

**Process per view:**
1. Copy from ViewTesting/ to Features/
2. Replace MockTypes with real SwiftData models
3. Replace inline mock data with ViewModel bindings
4. Wire navigation through Router

**Order (dependencies first):**
1. Components (EmptyStateView, LoadingSpinnerView, ConfirmationDialogModifier, ErrorAlertModifier)
2. Library/Exercises (CategoryList → ExerciseList → ExerciseDetail → ExerciseForm)
3. Library/Templates (TemplateList → TemplateDetail → TemplateForm)
4. ExercisePicker (shared modal)
5. ActiveWorkout (depends on ExercisePicker)
6. History (HistoryList → CompletedWorkoutDetail)
7. Analytics (Dashboard → ExerciseAnalyticsDetail)
8. Settings (modal)
9. MainTabView (orchestrates all)

**Verification:**
- All navigation flows work end-to-end
- Data persists across app launches

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
| 1 | Enums.swift | — | Small |
| 2 | SchemaV1.swift | Enums | Medium |
| 3 | MigrationPlan.swift | SchemaV1 | Small |
| 4 | Service Protocols | Models | Small |
| 5 | SettingsService | — | Small |
| 6 | CategoryService | Models | Small |
| 7 | ExerciseService | Models, CategoryService | Medium |
| 8 | TemplateService | Models, ExerciseService | Medium |
| 9 | WorkoutService | Models, ExerciseService | Large |
| 10 | AnalyticsService | Models, WorkoutService | Medium |
| 11 | SeedingService | CategoryService, ExerciseService | Small |
| 12 | DependencyContainer | All Services | Medium |
| 13 | Routers (3) | — | Small |
| 14 | Extensions | — | Small |
| 15 | Seed JSON files | — | Small |
| 16 | CategoryListViewModel | CategoryService, Router | Small |
| 17 | ExerciseListViewModel | ExerciseService, Router | Medium |
| 18 | ExerciseDetailViewModel | ExerciseService, Router | Small |
| 19 | ExerciseFormViewModel | ExerciseService, CategoryService | Medium |
| 20 | TemplateListViewModel | TemplateService, Router | Small |
| 21 | TemplateDetailViewModel | TemplateService, WorkoutService, Router | Medium |
| 22 | TemplateFormViewModel | TemplateService | Medium |
| 23 | ExercisePickerViewModel | ExerciseService, CategoryService | Small |
| 24 | ActiveWorkoutViewModel | WorkoutService | Large |
| 25 | HistoryListViewModel | WorkoutService, Router | Small |
| 26 | CompletedWorkoutDetailViewModel | WorkoutService | Small |
| 27 | AnalyticsDashboardViewModel | AnalyticsService, Router | Medium |
| 28 | ExerciseAnalyticsViewModel | AnalyticsService | Small |
| 29 | SettingsViewModel | SettingsService | Small |
| 30 | Migrate Components (4) | — | Small |
| 31 | Migrate Library Views | ViewModels, Router | Large |
| 32 | Migrate ActiveWorkout View | ViewModel, ExercisePicker | Large |
| 33 | Migrate History Views | ViewModels, Router | Medium |
| 34 | Migrate Analytics Views | ViewModels, Router | Medium |
| 35 | Migrate Settings + MainTabView | All | Medium |
| 36 | Service Tests | Services | Medium |
| 37 | ViewModel Tests | ViewModels | Medium |

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

- **No UIKit, CoreData, Combine, or third-party packages**
- **No @Query in views** — all data flows through ViewModels
- **No @EnvironmentObject** — manual DI only
- **Use VersionedSchema from day one** — SchemaV1 even for initial release
- **Exercises are archived, not deleted** when they have workout history
- **Analytics are derived, not persisted** — calculated on demand
- **Settings via SettingsService only** — no @AppStorage in Views
