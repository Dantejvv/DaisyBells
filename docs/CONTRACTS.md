# View-ViewModel Contracts

This document defines the interface between Views and ViewModels, including state exposed to views, intents views can call, and side effects for navigation/alerts.

---

## Library Tab

### CategoryListViewModel

#### State (ViewModel → View)
- **categories:** [ExerciseCategory] — All categories to display
- **isLoading:** Bool — Whether categories are being fetched
- **errorMessage:** String? — Error message if fetch failed

#### Intents (View → ViewModel)
- **loadCategories()** — Fetch all categories → sets isLoading, updates categories
- **createCategory(name:)** — Create new category → adds to categories
- **deleteCategory(category:)** — Delete category → removes from categories
- **selectCategory(category:)** — User taps category → triggers navigation

#### Side Effects
- **navigateToCategoryDetail** — Navigate to category's exercise list
- **showError** — Display error alert

#### Services
- CategoryService: fetchAll(), create(), delete()

---

### ExerciseListViewModel

#### State (ViewModel → View)
- **exercises:** [Exercise] — Exercises to display (filtered)
- **isLoading:** Bool — Whether exercises are being fetched
- **errorMessage:** String? — Error message if fetch failed
- **searchQuery:** String — Current search text
- **showFavoritesOnly:** Bool — Whether filtering to favorites
- **selectedCategory:** ExerciseCategory? — Category filter (nil = all)

#### Intents (View → ViewModel)
- **loadExercises()** — Fetch exercises for current filters → sets isLoading, updates exercises
- **search(query:)** — Update search filter → updates searchQuery, re-filters exercises
- **toggleFavoritesFilter()** — Toggle favorites-only mode → updates showFavoritesOnly, re-filters
- **selectExercise(exercise:)** — User taps exercise → triggers navigation
- **createExercise()** — User taps add button → triggers navigation

#### Side Effects
- **navigateToExerciseDetail** — Navigate to exercise detail screen
- **navigateToCreateExercise** — Navigate to exercise form (create mode)
- **showError** — Display error alert

#### Services
- ExerciseService: fetchAll(), fetchByCategory(), search()

---

### ExerciseDetailViewModel

#### State (ViewModel → View)
- **exercise:** Exercise — The exercise being viewed
- **isLoading:** Bool — Whether data is being fetched
- **errorMessage:** String? — Error message if operation failed
- **canDelete:** Bool — True if exercise has no history (can be permanently deleted)

#### Intents (View → ViewModel)
- **loadExercise()** — Fetch latest exercise data → updates exercise
- **toggleFavorite()** — Toggle favorite status → updates exercise.isFavorite
- **editExercise()** — User taps edit → triggers navigation
- **deleteExercise()** — Delete or archive exercise → triggers navigation back

#### Side Effects
- **navigateToEditExercise** — Navigate to exercise form (edit mode)
- **navigateBack** — Pop to previous screen after delete
- **showDeleteConfirmation** — Show delete confirmation alert
- **showError** — Display error alert

#### Services
- ExerciseService: fetch(), update(), delete(), archive(), hasHistory()

---

### ExerciseFormViewModel

#### State (ViewModel → View)
- **name:** String — Exercise name input
- **type:** ExerciseType — Selected exercise type
- **notes:** String — Notes/form cues input
- **selectedCategories:** [ExerciseCategory] — Selected categories
- **availableCategories:** [ExerciseCategory] — All categories for picker
- **isEditing:** Bool — True if editing existing, false if creating
- **isSaving:** Bool — Whether save is in progress
- **errorMessage:** String? — Validation or save error

#### Intents (View → ViewModel)
- **loadCategories()** — Fetch available categories → updates availableCategories
- **updateName(name:)** — User types name → updates name
- **updateType(type:)** — User selects type → updates type
- **updateNotes(notes:)** — User types notes → updates notes
- **toggleCategory(category:)** — Toggle category selection → updates selectedCategories
- **save()** — Validate and save exercise → triggers navigation back
- **cancel()** — Discard changes → triggers navigation back

#### Side Effects
- **navigateBack** — Pop to previous screen after save/cancel
- **showValidationError** — Show inline validation feedback
- **showError** — Display error alert

#### Services
- ExerciseService: create(), update()
- CategoryService: fetchAll()

---

### TemplateListViewModel

#### State (ViewModel → View)
- **templates:** [WorkoutTemplate] — All templates to display
- **isLoading:** Bool — Whether templates are being fetched
- **errorMessage:** String? — Error message if fetch failed

#### Intents (View → ViewModel)
- **loadTemplates()** — Fetch all templates → sets isLoading, updates templates
- **selectTemplate(template:)** — User taps template → triggers navigation
- **createTemplate()** — User taps add → triggers navigation
- **deleteTemplate(template:)** — Delete template → removes from templates

#### Side Effects
- **navigateToTemplateDetail** — Navigate to template detail screen
- **navigateToCreateTemplate** — Navigate to template form (create mode)
- **showDeleteConfirmation** — Show delete confirmation alert
- **showError** — Display error alert

#### Services
- TemplateService: fetchAll(), delete()

---

### TemplateDetailViewModel

#### State (ViewModel → View)
- **template:** WorkoutTemplate — The template being viewed
- **exercises:** [TemplateExercise] — Ordered exercises in template
- **isLoading:** Bool — Whether data is being fetched
- **errorMessage:** String? — Error message if operation failed

#### Intents (View → ViewModel)
- **loadTemplate()** — Fetch latest template data → updates template, exercises
- **startWorkout()** — Start workout from this template → triggers navigation
- **editTemplate()** — User taps edit → triggers navigation
- **duplicateTemplate()** — Create copy of template → triggers navigation to copy
- **deleteTemplate()** — Delete template → triggers navigation back

#### Side Effects
- **navigateToActiveWorkout** — Navigate to active workout screen
- **navigateToEditTemplate** — Navigate to template form (edit mode)
- **navigateToTemplateCopy** — Navigate to duplicated template
- **navigateBack** — Pop to previous screen after delete
- **showDeleteConfirmation** — Show delete confirmation alert
- **showError** — Display error alert

#### Services
- TemplateService: fetch(), duplicate(), delete()
- WorkoutService: createFromTemplate()

---

### TemplateFormViewModel

#### State (ViewModel → View)
- **name:** String — Template name input
- **notes:** String — Template notes input
- **exercises:** [TemplateExercise] — Ordered exercises in template
- **isEditing:** Bool — True if editing existing, false if creating
- **isSaving:** Bool — Whether save is in progress
- **errorMessage:** String? — Validation or save error

#### Intents (View → ViewModel)
- **updateName(name:)** — User types name → updates name
- **updateNotes(notes:)** — User types notes → updates notes
- **addExercise()** — User taps add exercise → triggers navigation to picker
- **removeExercise(exercise:)** — Remove exercise from template → updates exercises
- **reorderExercises(from:to:)** — Drag to reorder → updates exercises order
- **updateTargets(exercise:sets:reps:)** — Update target sets/reps → updates exercise
- **save()** — Validate and save template → triggers navigation back
- **cancel()** — Discard changes → triggers navigation back

#### Side Effects
- **navigateToExercisePicker** — Navigate to exercise picker
- **navigateBack** — Pop to previous screen after save/cancel
- **showValidationError** — Show inline validation feedback
- **showError** — Display error alert

#### Services
- TemplateService: create(), update()

---

## Active Workout

### ActiveWorkoutViewModel

#### State (ViewModel → View)
- **workout:** Workout — The active workout session
- **exercises:** [LoggedExercise] — Exercises being logged
- **elapsedTime:** TimeInterval — Time since workout started
- **fromTemplate:** WorkoutTemplate? — Source template (if any)
- **isLoading:** Bool — Whether data is being saved
- **errorMessage:** String? — Error message if operation failed

#### Intents (View → ViewModel)
- **loadWorkout()** — Load active workout data → updates workout, exercises
- **addExercise()** — User taps add exercise → triggers navigation to picker
- **removeExercise(exercise:)** — Remove exercise from workout → updates exercises
- **reorderExercises(from:to:)** — Drag to reorder → updates exercises order
- **addSet(exercise:)** — Add new set to exercise → updates exercise.sets
- **updateSet(set:weight:reps:time:distance:)** — Update set values → updates set
- **deleteSet(set:)** — Remove set → updates exercise.sets
- **updateExerciseNotes(exercise:notes:)** — Update exercise notes → updates exercise
- **updateWorkoutNotes(notes:)** — Update workout notes → updates workout
- **completeWorkout()** — Finish and save workout → triggers navigation
- **cancelWorkout()** — Discard workout → triggers navigation

#### Side Effects
- **navigateToExercisePicker** — Navigate to exercise picker
- **navigateToHistory** — Navigate to history tab after completion
- **navigateToLibrary** — Navigate to library tab after cancel
- **showCompleteConfirmation** — Show completion confirmation
- **showCancelConfirmation** — Show discard confirmation alert
- **showError** — Display error alert

#### Services
- WorkoutService: fetch(), update(), complete(), cancel()
- LoggedExerciseService: create(), update(), delete(), reorder()
- LoggedSetService: create(), update(), delete()

---

### ExercisePickerViewModel

#### State (ViewModel → View)
- **exercises:** [Exercise] — Available exercises to pick
- **categories:** [ExerciseCategory] — Categories for filtering
- **searchQuery:** String — Current search text
- **selectedCategory:** ExerciseCategory? — Category filter (nil = all)
- **isLoading:** Bool — Whether data is being fetched

#### Intents (View → ViewModel)
- **loadExercises()** — Fetch available exercises → updates exercises, categories
- **search(query:)** — Filter by search text → updates searchQuery, exercises
- **filterByCategory(category:)** — Filter by category → updates selectedCategory, exercises
- **selectExercise(exercise:)** — User picks exercise → triggers callback and navigation

#### Side Effects
- **dismissWithSelection** — Dismiss picker and return selected exercise
- **dismissWithoutSelection** — Dismiss picker (cancel)

#### Services
- ExerciseService: fetchAll(), fetchByCategory(), search()
- CategoryService: fetchAll()

---

## History Tab

### HistoryListViewModel

#### State (ViewModel → View)
- **workouts:** [Workout] — Completed workouts (chronological, newest first)
- **isLoading:** Bool — Whether workouts are being fetched
- **errorMessage:** String? — Error message if fetch failed
- **isEmpty:** Bool — True if no workout history exists

#### Intents (View → ViewModel)
- **loadWorkouts()** — Fetch completed workouts → sets isLoading, updates workouts
- **selectWorkout(workout:)** — User taps workout → triggers navigation
- **deleteWorkout(workout:)** — Delete workout → removes from workouts
- **clearAllHistory()** — Delete all workouts → clears workouts

#### Side Effects
- **navigateToWorkoutDetail** — Navigate to completed workout detail
- **showDeleteConfirmation** — Show delete confirmation alert
- **showClearAllConfirmation** — Show clear all confirmation alert
- **showError** — Display error alert

#### Services
- WorkoutService: fetchCompleted(), delete(), deleteAll()

---

### CompletedWorkoutDetailViewModel

#### State (ViewModel → View)
- **workout:** Workout — The completed workout
- **exercises:** [LoggedExercise] — Exercises performed with sets
- **duration:** TimeInterval — Total workout duration
- **isLoading:** Bool — Whether data is being fetched
- **errorMessage:** String? — Error message if operation failed

#### Intents (View → ViewModel)
- **loadWorkout()** — Fetch workout details → updates workout, exercises
- **updateNotes(notes:)** — Edit workout notes → updates workout.notes
- **deleteWorkout()** — Delete workout → triggers navigation back

#### Side Effects
- **navigateBack** — Pop to previous screen after delete
- **showDeleteConfirmation** — Show delete confirmation alert
- **showError** — Display error alert

#### Services
- WorkoutService: fetch(), updateNotes(), delete()

---

## Analytics Tab

### AnalyticsDashboardViewModel

#### State (ViewModel → View)
- **workoutsThisWeek:** Int — Count of workouts this week
- **workoutsThisMonth:** Int — Count of workouts this month
- **recentExercises:** [Exercise] — Recently performed exercises
- **personalRecords:** [PersonalRecord] — Recent PRs achieved
- **isLoading:** Bool — Whether analytics are being calculated
- **errorMessage:** String? — Error message if calculation failed

#### Intents (View → ViewModel)
- **loadAnalytics()** — Calculate all analytics → updates all state
- **selectExercise(exercise:)** — User taps exercise → triggers navigation
- **refresh()** — Recalculate analytics → updates all state

#### Side Effects
- **navigateToExerciseAnalytics** — Navigate to exercise-specific analytics
- **showError** — Display error alert

#### Services
- AnalyticsService: workoutsThisWeek(), workoutsThisMonth(), recentExercises(), personalRecords()

---

### ExerciseAnalyticsViewModel

#### State (ViewModel → View)
- **exercise:** Exercise — The exercise being analyzed
- **totalVolume:** Double — Total weight lifted all time
- **personalBest:** PersonalRecord? — Best performance
- **lastPerformed:** Date? — Date of last workout with this exercise
- **recentSets:** [LoggedSet] — Recent sets for trend display
- **isLoading:** Bool — Whether analytics are being calculated
- **errorMessage:** String? — Error message if calculation failed

#### Intents (View → ViewModel)
- **loadAnalytics()** — Calculate exercise analytics → updates all state
- **refresh()** — Recalculate analytics → updates all state

#### Side Effects
- **showError** — Display error alert

#### Services
- AnalyticsService: volumeForExercise(), personalBestForExercise(), lastPerformedDate(), recentSetsForExercise()

---

## Settings Modal

### SettingsViewModel

#### State (ViewModel → View)
- **units:** Units — Current unit preference (lbs/kg)
- **appearance:** Appearance — Current appearance (light/dark/system)
- **appVersion:** String — Current app version
- **isExporting:** Bool — Whether export is in progress
- **isImporting:** Bool — Whether import is in progress
- **errorMessage:** String? — Error message if operation failed

#### Intents (View → ViewModel)
- **loadSettings()** — Load current settings → updates units, appearance
- **updateUnits(units:)** — Change unit preference → updates units
- **updateAppearance(appearance:)** — Change appearance → updates appearance
- **exportData()** — Export all data to JSON → triggers share sheet
- **importData(url:)** — Import data from JSON file → shows confirmation
- **resetData()** — Delete all user data → clears data
- **openAbout()** — User taps about → triggers navigation

#### Side Effects
- **showShareSheet** — Present share sheet with exported JSON
- **showFilePicker** — Present file picker for import
- **showImportConfirmation** — Confirm before importing (will overwrite)
- **showResetConfirmation** — Confirm before reset (destructive)
- **navigateToAbout** — Navigate to about screen
- **showError** — Display error alert
- **showSuccess** — Display success message

#### Services
- SettingsService: getUnits(), setUnits(), getAppearance(), setAppearance()
- DataService: exportAll(), importAll(), resetAll()
