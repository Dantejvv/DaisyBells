# Views Specification

This is the single source of truth for every view in the app. Every SwiftUI view that needs to exist is listed here, along with how views connect to each other via navigation, what each view shows, and which ViewModel drives it.

**Rules:**
- If a view isn't listed here, it shouldn't exist
- If two entries could be the same view, unify them before building
- Shared components are defined once and referenced by name

---

## Navigation Maps

### Home Tab

```
HomeTabRootView
└─ NavigationStack(path: homeRouter.path)
   ├─ root: HomeDashboardView [HomeDashboardViewModel]
   │
   ├─ .splitList
   │   └─ SplitListView [SplitListViewModel]
   │
   ├─ .splitDetail(splitId)
   │   └─ SplitDetailView [SplitDetailViewModel]
   │
   ├─ .splitForm(splitId?)
   │   └─ SplitFormView [SplitFormViewModel]
   │       (nil = create, non-nil = edit)
   │
   ├─ .splitDayDetail(dayId)
   │   └─ SplitDayDetailView [SplitDayDetailViewModel]
   │
   ├─ .splitDayForm(splitId, dayId?)
   │   └─ SplitDayFormView [SplitDayFormViewModel]
   │       (nil = create, non-nil = edit)
   │
   ├─ .templateDetail(templateId)
   │   └─ TemplateDetailView [TemplateDetailViewModel]
   │
   ├─ .templateForm(templateId?)
   │   └─ TemplateFormView [TemplateFormViewModel]
   │       (nil = create, non-nil = edit)
   │
   └─ .activeWorkout(workoutId)
       └─ ActiveWorkoutView [ActiveWorkoutViewModel]

Sheets (homeRouter.presentedSheet):
├─ .exercisePicker → ExercisePickerSheet [ExercisePickerViewModel]
├─ .workoutPicker  → WorkoutPickerSheet [WorkoutPickerViewModel]
├─ .splitDayPicker → SplitDayPickerSheet [SplitDayPickerViewModel]
└─ .settings       → SettingsView [SettingsViewModel]
```

### Library Tab

```
LibraryTabRootView
└─ NavigationStack(path: libraryRouter.path)
   ├─ root: LibraryRootView (segmented: Exercises | Workouts)
   │   ├─ Exercises segment → CategoryListView [CategoryListViewModel]
   │   └─ Workouts segment  → TemplateListView [TemplateListViewModel]
   │
   ├─ .exerciseList(categoryId?)
   │   └─ ExerciseListView [ExerciseListViewModel]
   │
   ├─ .exerciseDetail(exerciseId)
   │   └─ ExerciseDetailView [ExerciseDetailViewModel]
   │
   └─ .exerciseForm(exerciseId?)
       └─ ExerciseFormView [ExerciseFormViewModel]
           (nil = create, non-nil = edit)

Sheets (libraryRouter.presentedSheet):
└─ .settings → SettingsView [SettingsViewModel]
```

### History Tab

```
HistoryTabRootView
└─ NavigationStack(path: historyRouter.path)
   ├─ root: HistoryListView [HistoryListViewModel]
   │
   └─ .workoutDetail(workoutId)
       └─ CompletedWorkoutDetailView [CompletedWorkoutDetailViewModel]

Sheets (historyRouter.presentedSheet):
└─ .settings → SettingsView [SettingsViewModel]
```

### Analytics Tab

```
AnalyticsTabRootView
└─ NavigationStack(path: analyticsRouter.path)
   ├─ root: AnalyticsDashboardView [AnalyticsDashboardViewModel]
   │
   └─ .exerciseAnalytics(exerciseId)
       └─ ExerciseAnalyticsView [ExerciseAnalyticsViewModel]

Sheets (analyticsRouter.presentedSheet):
└─ .settings → SettingsView [SettingsViewModel]
```

---

## View Inventory

### Shared Components

Reusable views used by 2+ screens. Defined once, imported by name.

#### EmptyStateView
Generic empty state placeholder.
- **Props:** `icon: String`, `title: String`, `message: String`
- **Used by:** Any list view when items array is empty

#### LoadingSpinnerView
Centered progress indicator.
- **Props:** none
- **Used by:** Any view during `isLoading` state

#### ErrorAlertModifier
View modifier that presents an error alert bound to a ViewModel's `errorMessage`.
- **Binding:** `errorMessage: Binding<String?>`
- **Used by:** Every view with a ViewModel

#### ConfirmationDialogModifier
Reusable confirmation dialog for destructive actions.
- **Props:** `title: String`, `message: String`, `isPresented: Binding<Bool>`, `onConfirm: () -> Void`
- **Used by:** Delete actions across all list and detail views

---

### Home Tab Views

#### HomeDashboardView
**File:** `Features/Home/HomeDashboardView.swift`
**ViewModel:** `HomeDashboardViewModel`
**Purpose:** Home tab root content. Shows active split overview and recent templates.

**Layout:**
- Active split section (inline, shows split name + day cards)
  - When a split is active: expandable day cards showing assigned workouts
  - When no split is active: prompt with "Set Up Split" button
  - Gear icon in section header → navigates to SplitListView
- Recent templates section (derived from completed workout history)
- "Start Empty Workout" button (navigates to ActiveWorkoutView)
- Toolbar "+" button → presents WorkoutPickerSheet

**ViewModel state:** `activeSplit`, `splitDays`, `recentTemplates`, `hasActiveWorkout`, `isLoading`, `errorMessage`
**ViewModel intents:** `loadDashboard()`, `reloadSplit()`
**Services:** WorkoutService, TemplateService, SplitService, SettingsService

---

#### SplitListView
**File:** `Features/Home/SplitListView.swift`
**ViewModel:** `SplitListViewModel`
**Purpose:** Manage all splits. Set active split, create/edit/delete.

**Layout:**
- List of all splits
  - Active split indicated with checkmark
  - Tap → set as active split
  - Swipe actions: edit (navigates to SplitDetailView), delete
- Toolbar "+" → navigates to SplitFormView (create)
- Empty state when no splits exist

**ViewModel state:** `splits`, `activeSplitId`, `isLoading`, `errorMessage`
**ViewModel intents:** `loadSplits()`, `setActiveSplit(split:)`, `selectSplit(split:)`, `createSplit()`, `deleteSplit(split:)`
**Navigation:** pushes `.splitDetail`, `.splitForm`
**Services:** SplitService, SettingsService

---

#### SplitDetailView
**File:** `Features/Home/SplitDetailView.swift`
**ViewModel:** `SplitDetailViewModel`
**Purpose:** View and manage a single split's days and workout assignments.

**Layout:**
- Split name as title
- Ordered list of days
  - Each day shows name and assigned workout count
  - Tap day → navigates to SplitDayDetailView
  - Drag to reorder
  - Swipe to delete
- Toolbar: edit button → navigates to SplitFormView (edit), add day button → navigates to SplitDayFormView (create), delete split

**ViewModel state:** `split`, `days`, `isLoading`, `errorMessage`
**ViewModel intents:** `loadSplit()`, `editSplit()`, `deleteSplit()`, `addDay()`, `selectDay(day:)`, `reorderDays(from:to:)`, `deleteDay(day:)`
**Navigation:** pushes `.splitForm`, `.splitDayDetail`, `.splitDayForm`
**Services:** SplitService, SplitDayService

---

#### SplitFormView
**File:** `Features/Home/SplitFormView.swift`
**ViewModel:** `SplitFormViewModel`
**Purpose:** Create or edit a split (name only).

**Layout:**
- Name text field
- Save / Cancel buttons
- Inline validation error for empty name

**ViewModel state:** `name`, `isEditing`, `isSaving`, `errorMessage`
**ViewModel intents:** `updateName(name:)`, `save()`, `cancel()`
**Navigation:** pops on save/cancel
**Services:** SplitService

---

#### SplitDayDetailView
**File:** `Features/Home/SplitDayDetailView.swift`
**ViewModel:** `SplitDayDetailViewModel`
**Purpose:** View a split day's assigned workouts. Assign/unassign workouts, start a workout.

**Layout:**
- Day name as title
- List of assigned workout templates
  - Tap workout → start workout (navigates to ActiveWorkoutView)
  - Swipe to unassign
- Toolbar: edit day name, assign workout (presents WorkoutPickerSheet), delete day

**ViewModel state:** `day`, `assignedWorkouts`, `isLoading`, `errorMessage`
**ViewModel intents:** `loadDay()`, `editDay()`, `deleteDay()`, `assignWorkout()`, `unassignWorkout(workout:)`, `startWorkout(workout:)`
**Navigation:** pushes `.activeWorkout`, `.splitDayForm`; presents `.workoutPicker`
**Services:** SplitDayService, WorkoutService

---

#### SplitDayFormView
**File:** `Features/Home/SplitDayFormView.swift`
**ViewModel:** `SplitDayFormViewModel`
**Purpose:** Create or edit a split day (name only).

**Layout:**
- Name text field
- Save / Cancel buttons
- Inline validation error for empty name

**ViewModel state:** `name`, `isEditing`, `isSaving`, `errorMessage`
**ViewModel intents:** `updateName(name:)`, `save()`, `cancel()`
**Navigation:** pops on save/cancel
**Services:** SplitDayService

---

#### TemplateDetailView
**File:** `Features/Home/TemplateDetailView.swift`
**ViewModel:** `TemplateDetailViewModel`
**Purpose:** View a workout template's exercises and metadata. Start workout, edit, duplicate, delete.

**Layout:**
- Template name as title
- Template notes (if any)
- Ordered list of exercises with their template sets
- Actions: start workout, edit, duplicate, delete
- Assigned split days info

**ViewModel state:** `template`, `exercises`, `assignedSplitDays`, `isLoading`, `errorMessage`
**ViewModel intents:** `loadTemplate()`, `startWorkout()`, `editTemplate()`, `duplicateTemplate()`, `deleteTemplate()`
**Navigation:** pushes `.activeWorkout`, `.templateForm`
**Services:** TemplateService, SplitDayService, WorkoutService

---

#### TemplateFormView
**File:** `Features/Home/TemplateFormView.swift`
**ViewModel:** `TemplateFormViewModel`
**Purpose:** Create or edit a workout template. Manage name, notes, and exercise list.

**Layout:**
- Name text field
- Notes text field
- Exercise list (ordered)
  - Each row shows exercise name
  - Drag to reorder
  - Swipe to remove
- Add exercise button → presents ExercisePickerSheet
- Save / Cancel buttons

**ViewModel state:** `name`, `notes`, `exercises`, `isEditing`, `isSaving`, `errorMessage`
**ViewModel intents:** `load()`, `updateName(_:)`, `updateNotes(_:)`, `addExercise()`, `removeExercise(_:)`, `reorderExercises(from:to:)`, `save()`, `cancel()`
**Navigation:** presents `.exercisePicker`; pops on save/cancel
**Services:** TemplateService, ExerciseService

---

#### ActiveWorkoutView
**File:** `Features/Home/ActiveWorkoutView.swift`
**ViewModel:** `ActiveWorkoutViewModel`
**Purpose:** Real-time workout logging. Add exercises, log sets, complete or cancel.

**Layout:**
- Workout name / elapsed time header
- Workout notes field (editable)
- Exercise sections (ordered)
  - Exercise name + type indicator
  - Exercise-level notes (editable)
  - Set rows with dynamic fields based on ExerciseType:
    - Weight + Reps, Bodyweight (+/- modifier), Time, Distance + Time, Weight + Time, Reps only
  - Previous performance shown as placeholders
  - Add set / remove set
  - Swipe to remove exercise
- Toolbar: add exercise (presents ExercisePickerSheet), complete, cancel
- Completion flow: optional "save as template" prompt

**ViewModel state:** `workout`, `exercises`, `previousPerformance`, `elapsedTime`, `isLoading`, `errorMessage`, `showSaveAsTemplatePrompt`, `templateName`, `didSaveAsTemplate`
**ViewModel intents:** `loadWorkout()`, `loadPreviousPerformance(for:)`, `addExercise()`, `removeExercise(_:)`, `reorderExercises(from:to:)`, `addSet(exercise:)`, `updateSet(...)`, `deleteSet(_:)`, `updateExerciseNotes(...)`, `updateWorkoutNotes(_:)`, `completeWorkout()`, `saveAsTemplate(name:)`, `skipSaveAsTemplate()`, `cancelWorkout()`
**Navigation:** presents `.exercisePicker`; pops to root on complete/cancel
**Services:** WorkoutService, TemplateService, LoggedExerciseService, LoggedSetService

---

### Library Tab Views

#### LibraryRootView
**File:** `Features/Library/LibraryRootView.swift`
**ViewModel:** None (pure layout container)
**Purpose:** Library tab root with segmented control switching between Exercises and Workouts sections.

**Layout:**
- Segmented picker: "Exercises" | "Workouts"
- Exercises segment → inline CategoryListView
- Workouts segment → inline TemplateListView
- Both share the same NavigationStack from LibraryTabRootView

**Note:** This is a thin layout wrapper. The real logic lives in CategoryListView and TemplateListView, which each have their own ViewModels.

---

#### CategoryListView
**File:** `Features/Library/Exercises/CategoryListView.swift`
**ViewModel:** `CategoryListViewModel`
**Purpose:** Browse exercise categories. Tap to see exercises in category.

**Layout:**
- List of categories (ordered)
  - Tap category → navigates to ExerciseListView filtered by category
  - Swipe to rename or delete
  - Drag to reorder
- "All Exercises" row at top → navigates to ExerciseListView (no category filter)
- Toolbar: add category (inline alert with text field), create exercise button
- Category name max length: 20 characters (enforced by CategoryService)

**ViewModel state:** `categories`, `isLoading`, `errorMessage`
**ViewModel intents:** `loadCategories()`, `createCategory(name:)`, `updateCategory(category:name:)`, `reorderCategories(from:to:)`, `deleteCategory(category:)`, `selectCategory(category:)`
**Navigation:** pushes `.exerciseList(categoryId:)`
**Services:** CategoryService

---

#### ExerciseListView
**File:** `Features/Library/Exercises/ExerciseListView.swift`
**ViewModel:** `ExerciseListViewModel`
**Purpose:** Browse exercises, optionally filtered by category. Search, filter, navigate to detail.

**Layout:**
- Search bar
- Filter options: favorites only, show archived
- List of exercises
  - Each row: name, type badge, favorite indicator
  - Tap → navigates to ExerciseDetailView
- Toolbar: create exercise button
- Empty state when no matches

**ViewModel state:** `exercises`, `isLoading`, `errorMessage`, `searchQuery`, `showFavoritesOnly`, `showArchived`, `selectedCategory`
**ViewModel intents:** `loadExercises()`, `search(query:)`, `toggleFavoritesFilter()`, `toggleArchivedFilter()`, `selectExercise(exercise:)`, `createExercise()`
**Navigation:** pushes `.exerciseDetail`, `.exerciseForm`
**Services:** ExerciseService

---

#### ExerciseDetailView
**File:** `Features/Library/Exercises/ExerciseDetailView.swift`
**ViewModel:** `ExerciseDetailViewModel`
**Purpose:** View exercise metadata and performance stats. Edit, favorite, delete/archive.

**Layout:**
- Exercise name, type, categories
- Notes / form cues
- Read-only performance stats (last performed, PR, volume)
- Actions: toggle favorite, edit, delete (or archive if has history)

**ViewModel state:** `exercise`, `performanceStats`, `isLoading`, `errorMessage`, `canDelete`
**ViewModel intents:** `loadExercise()`, `toggleFavorite()`, `editExercise()`, `deleteExercise()`
**Navigation:** pushes `.exerciseForm`; pops on delete
**Services:** ExerciseService, AnalyticsService

---

#### ExerciseFormView
**File:** `Features/Library/Exercises/ExerciseFormView.swift`
**ViewModel:** `ExerciseFormViewModel`
**Purpose:** Create or edit an exercise.

**Layout:**
- Name text field
- Exercise type picker (segmented or menu)
- Notes / form cues text editor
- Category multi-select list
- Save / Cancel buttons

**ViewModel state:** `name`, `type`, `notes`, `selectedCategories`, `availableCategories`, `isEditing`, `isSaving`, `errorMessage`
**ViewModel intents:** `loadCategories()`, `updateName(name:)`, `updateType(type:)`, `updateNotes(notes:)`, `toggleCategory(category:)`, `save()`, `cancel()`
**Navigation:** pops on save/cancel
**Services:** ExerciseService, CategoryService

---

#### TemplateListView (Library context)
**File:** `Features/Library/Templates/TemplateListView.swift`
**ViewModel:** `TemplateListViewModel`
**Purpose:** Browse workout templates in the Library tab's "Workouts" segment.

**Layout:**
- List of templates
  - Each row: name, exercise count
  - Tap → navigates to TemplateDetailView
  - Swipe to delete
- Toolbar: create template button
- Empty state when no templates

**Note on ViewModel location:** `TemplateListViewModel` currently lives in `Features/Home/` and uses `HomeRouter`. For the Library tab context, this ViewModel either needs to also accept a `LibraryRouter`, or the Library's "Workouts" segment navigates using `HomeRouter`. This is a known architectural decision to resolve — see "Open Questions" below.

**ViewModel state:** `templates`, `isLoading`, `errorMessage`
**ViewModel intents:** `loadTemplates()`, `selectTemplate(template:)`, `createTemplate()`, `deleteTemplate(template:)`
**Services:** TemplateService

---

### Sheet Views

Sheets are presented modally by routers. Each sheet wraps a view in a `NavigationStack` for its own title bar and toolbar.

#### ExercisePickerSheet
**File:** `Features/Library/Exercises/ExercisePickerSheet.swift`
**ViewModel:** `ExercisePickerViewModel`
**Purpose:** Modal picker to select an exercise. Used when adding exercises to templates or active workouts.

**Layout:**
- NavigationStack wrapper with "Select Exercise" title
- Search bar
- Category filter (segmented or horizontal scroll)
- Exercise list (filtered)
  - Tap → calls `onSelect` callback with exercise ID, dismisses
- Cancel button in toolbar

**Presented by:** HomeRouter `.exercisePicker`
**Callback:** `onSelect: (PersistentIdentifier) -> Void`

**ViewModel state:** `exercises`, `categories`, `searchQuery`, `selectedCategory`, `isLoading`
**ViewModel intents:** `loadExercises()`, `search(query:)`, `filterByCategory(category:)`, `selectExercise(exercise:)`
**Services:** ExerciseService, CategoryService

---

#### WorkoutPickerSheet
**File:** `Features/Library/WorkoutPickerSheet.swift`
**ViewModel:** `WorkoutPickerViewModel`
**Purpose:** Modal picker to select a workout template. Used when assigning workouts to split days.

**Layout:**
- NavigationStack wrapper with "Select Workout" title
- Search bar
- Template list (filtered)
  - Tap → calls `onSelect` callback with template ID, dismisses
- Cancel button in toolbar

**Presented by:** HomeRouter `.workoutPicker`
**Callback:** `onSelect: (PersistentIdentifier) -> Void`

**ViewModel state:** `templates`, `searchQuery`, `isLoading`
**ViewModel intents:** `loadTemplates()`, `search(query:)`, `selectTemplate(template:)`
**Services:** TemplateService

---

#### SplitDayPickerSheet
**File:** `Features/Home/SplitDayPickerSheet.swift`
**ViewModel:** `SplitDayPickerViewModel`
**Purpose:** Modal picker to select a split day. Used when assigning a template to a split day.

**Layout:**
- NavigationStack wrapper with "Select Day" title
- List of splits, each showing its days
  - Tap day → calls `onSelect` callback with day ID, dismisses
- Cancel button in toolbar

**Presented by:** HomeRouter `.splitDayPicker`
**Callback:** `onSelect: (PersistentIdentifier) -> Void`

**ViewModel state:** `splits`, `isLoading`
**ViewModel intents:** `loadSplits()`, `selectDay(day:)`
**Services:** SplitService

---

#### SettingsView
**File:** `Features/Settings/SettingsView.swift`
**ViewModel:** `SettingsViewModel`
**Purpose:** App settings presented as a sheet from any tab.

**Layout:**
- NavigationStack wrapper with "Settings" title
- Units picker (lbs / kg)
- Appearance picker (light / dark / system)
- Export data button
- Import data button
- Reset all data button (destructive, with confirmation)
- About / version info

**Presented by:** All routers via `.settings` sheet

**ViewModel state:** `units`, `appearance`, `appVersion`, `isExporting`, `isImporting`, `errorMessage`
**ViewModel intents:** `loadSettings()`, `updateUnits(units:)`, `updateAppearance(appearance:)`, `exportData()`, `importData(url:)`, `resetData()`
**Services:** SettingsService

---

### History Tab Views

#### HistoryListView
**File:** `Features/History/HistoryListView.swift`
**ViewModel:** `HistoryListViewModel`
**Purpose:** Chronological list of completed workouts.

**Layout:**
- List of completed workouts (newest first)
  - Each row: workout name, date, exercise count, duration
  - Tap → navigates to CompletedWorkoutDetailView
  - Swipe to delete
- Toolbar: clear all history button (destructive, with confirmation)
- Empty state when no history

**ViewModel state:** `workouts`, `isLoading`, `errorMessage`, `isEmpty`
**ViewModel intents:** `loadWorkouts()`, `selectWorkout(workout:)`, `deleteWorkout(workout:)`, `clearAllHistory()`
**Navigation:** pushes `.workoutDetail`
**Services:** WorkoutService

---

#### CompletedWorkoutDetailView
**File:** `Features/History/CompletedWorkoutDetailView.swift`
**ViewModel:** `CompletedWorkoutDetailViewModel`
**Purpose:** Read-only view of a completed workout's exercises and sets.

**Layout:**
- Workout name, date, duration
- Workout notes (read-only)
- Exercise sections (ordered)
  - Exercise name
  - Exercise notes (read-only)
  - Set rows showing all recorded data (weight, reps, time, distance, notes)
- Toolbar: delete workout (destructive, with confirmation)

**ViewModel state:** `workout`, `exercises`, `duration`, `isLoading`, `errorMessage`
**ViewModel intents:** `loadWorkout()`, `deleteWorkout()`
**Navigation:** pops on delete
**Services:** WorkoutService

---

### Analytics Tab Views

#### AnalyticsDashboardView
**File:** `Features/Analytics/AnalyticsDashboardView.swift`
**ViewModel:** `AnalyticsDashboardViewModel`
**Purpose:** Overview of training metrics and personal records.

**Layout:**
- Summary cards: workouts this week, workouts this month, total volume
- Recent exercises list
  - Tap exercise → navigates to ExerciseAnalyticsView
- Personal records section
- Empty state when no workout history

**ViewModel state:** `workoutsThisWeek`, `workoutsThisMonth`, `totalVolume`, `recentExercises`, `personalRecords`, `isLoading`, `errorMessage`
**ViewModel intents:** `loadAnalytics()`, `selectExercise(exercise:)`, `refresh()`
**Navigation:** pushes `.exerciseAnalytics`
**Services:** AnalyticsService

---

#### ExerciseAnalyticsView
**File:** `Features/Analytics/ExerciseAnalyticsView.swift`
**ViewModel:** `ExerciseAnalyticsViewModel`
**Purpose:** Detailed analytics for a single exercise.

**Layout:**
- Exercise name as title
- Stats: total volume, personal best, last performed date
- Recent sets list (trend display)

**ViewModel state:** `exercise`, `totalVolume`, `personalBest`, `lastPerformed`, `recentSets`, `isLoading`, `errorMessage`
**ViewModel intents:** `loadAnalytics()`, `refresh()`
**Services:** AnalyticsService

---

## View Count Summary

| Area | Views | Sheets |
|------|-------|--------|
| Components | 4 shared | — |
| Home tab | 9 (dashboard + 6 split/day + 2 template) | — |
| Home sheets | — | 3 (exercise picker, workout picker, split day picker) |
| Library tab | 6 (root + categories + 3 exercise + template list) | — |
| History tab | 2 | — |
| Analytics tab | 2 | — |
| Settings | — | 1 |
| **Total** | **23 views** | **4 sheets** |

---

## Open Questions

### 1. Template views shared between Home and Library
Template CRUD currently routes through `HomeRouter` (ViewModels in `Features/Home/`). The Library tab's "Workouts" segment also needs to show template list/detail/form. Options:
- **A) Templates only navigate from Home tab** — Library "Workouts" segment shows a simple list that deep-links into the Home tab's navigation
- **B) Duplicate route enums in LibraryRouter** — Add template routes to LibraryRouter, make ViewModels accept either router via protocol
- **C) Move template ViewModels to shared location** — Extract router dependency into a protocol so the same ViewModel works with any router

This must be resolved before building the Library tab's Workouts segment.

### 2. HomeDashboardViewModel
This ViewModel doesn't exist yet in the codebase. It was created during the Phase 5 iteration that was reset. It needs to be (re)created before building HomeDashboardView.

### 3. HomeRouter missing `.splitList` route
The current `HomeRoute` enum doesn't include a `.splitList` case. The dashboard's gear icon needs to navigate to `SplitListView`. Either add this route to `HomeRoute`, or present it as a sheet.
