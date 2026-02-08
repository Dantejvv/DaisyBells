# DaisyBells Implementation Roadmap

## Current State (Updated 2026-02-08)
- ✅ **Phase 1: Foundation** — COMPLETE (Enums, SchemaV1, MigrationPlan)
- ✅ **Phase 2: Services** — COMPLETE (11 services + protocols, all tested)
- ✅ **Phase 3: Infrastructure** — COMPLETE (DependencyContainer, 4 Routers, tab root views, extensions)
- ✅ **Phase 4: ViewModels** — COMPLETE (24+ ViewModels across all features)
- ❌ **Phase 5: Production Views** — NOT STARTED (ViewTesting/ deleted, no views implemented)
- ❌ **Phase 6: Polish + Testing** — NOT STARTED

**Documentation:** Complete (ARCHITECTURE, MODELS, CONTRACTS, FEATURES, USERFLOWS, ROADMAP)

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
Build production SwiftUI views from scratch (ViewTesting prototypes were deleted).

**Implementation Strategy:**
Since ViewTesting prototypes no longer exist, views will be built fresh using:
1. CONTRACTS.md for state/intent specifications
2. FEATURES.md for UI requirements
3. USERFLOWS.md for interaction patterns
4. Existing ViewModels for data binding

**View Pattern (Critical Architecture Rules):**
- Views receive ViewModels as `@State` init parameters (NOT @EnvironmentObject)
- ViewModels created in `navigationDestination(for:)` closures with injected dependencies
- Navigation: `NavigationStack(path: $router.path)` + `.navigationDestination(for: Route.self)`
- Sheets: `router.presentedSheet` drives `.sheet(item:)`
- Use `NavigationLink(value:)`, NEVER `NavigationLink(destination:)` with inline views
- No `@Query` - all data flows through ViewModels
- Services/Routers accessed from DependencyContainer via `.environment()`

**Implementation Order (dependencies first):**
1. **Components** (shared across features)
   - `EmptyStateView` — Shows icon, title, message for empty states
   - `LoadingSpinnerView` — Centered spinner for loading states
   - `ErrorAlertModifier` — View modifier for error alerts bound to ViewModel.errorMessage
   - `ConfirmationDialogModifier` — Reusable confirmation dialogs

2. **Home/Splits** (split dashboard and management)
   - `SplitListView` → `SplitDetailView` → `SplitFormView`
   - `SplitDayDetailView` → `SplitDayFormView`

3. **Library/Exercises** (exercise library management)
   - `CategoryListView` → `ExerciseListView` → `ExerciseDetailView` → `ExerciseFormView`

4. **Library/Templates** (workout template management)
   - `TemplateListView` → `TemplateDetailView` → `TemplateFormView`

5. **Shared Pickers** (presented as sheets)
   - `ExercisePickerView`
   - `WorkoutPickerView`
   - `SplitDayPickerView`

6. **ActiveWorkout** (workout logging, depends on ExercisePicker)
   - `ActiveWorkoutView`

7. **History** (completed workout viewing)
   - `HistoryListView` → `CompletedWorkoutDetailView`

8. **Analytics** (read-only dashboards)
   - `AnalyticsDashboardView` → `ExerciseAnalyticsView`

9. **Settings** (presented as sheet)
   - `SettingsView`

10. **Tab Root Views** (update from placeholders to real content)
    - Update `HomeTabRootView` with SplitListView
    - Update `LibraryTabRootView` with segmented control for Exercises/Templates
    - Update `HistoryTabRootView` with HistoryListView
    - Update `AnalyticsTabRootView` with AnalyticsDashboardView

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
| **Phase 4: ViewModels** | ✅ COMPLETE |
| 24 | SplitListViewModel | SplitService, HomeRouter | ✅ Done |
| 25 | SplitDetailViewModel | SplitService, SplitDayService, HomeRouter | ✅ Done |
| 26 | SplitFormViewModel | SplitService, HomeRouter | ✅ Done |
| 27 | SplitDayDetailViewModel | SplitDayService, WorkoutService, HomeRouter | ✅ Done |
| 28 | SplitDayFormViewModel | SplitDayService, HomeRouter | ✅ Done |
| 29 | CategoryListViewModel | CategoryService, LibraryRouter | ✅ Done |
| 30 | ExerciseListViewModel | ExerciseService, LibraryRouter | ✅ Done |
| 31 | ExerciseDetailViewModel | ExerciseService, AnalyticsService, LibraryRouter | ✅ Done |
| 32 | ExerciseFormViewModel | ExerciseService, CategoryService, LibraryRouter | ✅ Done |
| 33 | TemplateListViewModel | TemplateService, LibraryRouter | ✅ Done |
| 34 | TemplateDetailViewModel | TemplateService, SplitDayService, WorkoutService, LibraryRouter | ✅ Done |
| 35 | TemplateFormViewModel | TemplateService, LibraryRouter | ✅ Done |
| 36 | ExercisePickerViewModel | ExerciseService, CategoryService | ✅ Done |
| 37 | WorkoutPickerViewModel | TemplateService | ✅ Done |
| 38 | SplitDayPickerViewModel | SplitService | ✅ Done |
| 39 | ActiveWorkoutViewModel | WorkoutService, TemplateService, LoggedExerciseService, LoggedSetService | ✅ Done |
| 40 | HistoryListViewModel | WorkoutService, HistoryRouter | ✅ Done |
| 41 | CompletedWorkoutDetailViewModel | WorkoutService, HistoryRouter | ✅ Done |
| 42 | AnalyticsDashboardViewModel | AnalyticsService, AnalyticsRouter | ✅ Done |
| 43 | ExerciseAnalyticsViewModel | AnalyticsService, AnalyticsRouter | ✅ Done |
| 44 | SettingsViewModel | SettingsService | ✅ Done |
| **Phase 5: Views** | ❌ NOT STARTED |
| 45 | Build Components (4) | — | Small |
| 46 | Build Home/Split Views (5 views) | Split ViewModels, HomeRouter | Large |
| 47 | Build Library/Exercise Views (4 views) | Exercise ViewModels, LibraryRouter | Large |
| 48 | Build Library/Template Views (3 views) | Template ViewModels, LibraryRouter | Large |
| 49 | Build Shared Pickers (3 views) | Picker ViewModels | Medium |
| 50 | Build ActiveWorkout View | ActiveWorkoutViewModel, ExercisePicker | Large |
| 51 | Build History Views (2 views) | History ViewModels, HistoryRouter | Medium |
| 52 | Build Analytics Views (2 views) | Analytics ViewModels, AnalyticsRouter | Medium |
| 53 | Build Settings View | SettingsViewModel | Small |
| 54 | Update Tab Root Views (4 views) | Replace placeholders with real content | Medium |
| **Phase 6: Testing** |
| 55 | Service Tests | Services | Medium |
| 56 | ViewModel Tests | ViewModels | Medium |
| 57 | End-to-End Testing | All | Large |

---

## Phase 5 Implementation Guide

### Critical Architecture Patterns (Reference Before Building Each View)

**1. ViewModel Injection Pattern**
```swift
struct SplitListView: View {
    @State private var viewModel: SplitListViewModel

    init(viewModel: SplitListViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        // Use viewModel.state and call viewModel.intent()
    }
}
```

**2. Navigation Destination Pattern**
```swift
// In tab root view
NavigationStack(path: $router.path) {
    SplitListView(viewModel: SplitListViewModel(
        splitService: container.splitService,
        router: container.homeRouter
    ))
    .navigationDestination(for: HomeRoute.self) { route in
        switch route {
        case .splitDetail(let splitId):
            SplitDetailView(viewModel: SplitDetailViewModel(
                splitId: splitId,
                splitService: container.splitService,
                splitDayService: container.splitDayService,
                router: container.homeRouter
            ))
        // ... other routes
        }
    }
}
```

**3. Sheet Presentation Pattern**
```swift
.sheet(item: $router.presentedSheet) { sheet in
    switch sheet {
    case .exercisePicker(let callback):
        ExercisePickerView(viewModel: ExercisePickerViewModel(
            exerciseService: container.exerciseService,
            categoryService: container.categoryService,
            onSelect: callback
        ))
    }
}
```

**4. Error Handling Pattern**
```swift
// In View
.alert("Error", isPresented: Binding(
    get: { viewModel.errorMessage != nil },
    set: { if !$0 { viewModel.errorMessage = nil } }
)) {
    Button("OK") { viewModel.errorMessage = nil }
} message: {
    Text(viewModel.errorMessage ?? "")
}
```

**5. Empty State Pattern**
```swift
if viewModel.items.isEmpty {
    EmptyStateView(
        icon: "tray",
        title: "No Items",
        message: "Tap + to create your first item"
    )
} else {
    List { /* content */ }
}
```

### View File Checklist (Use for Each View)
- [ ] ViewModel injected as `@State` init parameter (NOT @EnvironmentObject)
- [ ] Uses `NavigationLink(value:)` for navigation (NOT destination:)
- [ ] Calls ViewModel intent methods for all actions
- [ ] No direct SwiftData access (@Query forbidden)
- [ ] Error handling via `viewModel.errorMessage` binding
- [ ] Loading states via `viewModel.isLoading`
- [ ] Empty states via `EmptyStateView` component
- [ ] No business logic in View (only presentation)
- [ ] Task { await viewModel.load() } in .task modifier for data loading
- [ ] Destructive actions have confirmation dialogs

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
