# View-ViewModel Contracts

This document defines the interface between Views and ViewModels, including state exposed to views, intents views can call, and side effects for navigation/alerts.

---

## Home Tab

### SplitListViewModel

#### State (ViewModel → View)
- **splits:** [Split] — All splits to display
- **isLoading:** Bool — Whether splits are being fetched
- **errorMessage:** String? — Error message if fetch failed

#### Intents (View → ViewModel)
- **loadSplits()** — Fetch all splits → sets isLoading, updates splits
- **selectSplit(split:)** — User taps split → triggers navigation
- **createSplit()** — User taps add → triggers navigation
- **deleteSplit(split:)** — Delete split → removes from splits

#### Side Effects
- **navigateToSplitDetail** — Navigate to split detail screen (via HomeRouter)
- **navigateToCreateSplit** — Navigate to split form (create mode) (via HomeRouter)
- **showDeleteConfirmation** — Show delete confirmation alert
- **showError** — Display error alert

#### Services
- SplitService: fetchAll(), delete()

---

### SplitDetailViewModel

#### State (ViewModel → View)
- **split:** Split — The split being viewed
- **days:** [SplitDay] — Ordered days in split
- **isLoading:** Bool — Whether data is being fetched
- **errorMessage:** String? — Error message if operation failed

#### Intents (View → ViewModel)
- **loadSplit()** — Fetch latest split data → updates split, days
- **editSplit()** — User taps edit → triggers navigation
- **deleteSplit()** — Delete split → triggers navigation back
- **addDay()** — User taps add day → triggers navigation
- **selectDay(day:)** — User taps day → triggers navigation
- **reorderDays(from:to:)** — Drag to reorder → updates days order
- **deleteDay(day:)** — Delete day from split → removes from days

#### Side Effects
- **navigateToEditSplit** — Navigate to split form (edit mode) (via HomeRouter)
- **navigateToSplitDayDetail** — Navigate to split day detail screen (via HomeRouter)
- **navigateToAddDay** — Navigate to split day form (create mode) (via HomeRouter)
- **navigateBack** — Pop to previous screen after delete
- **showDeleteConfirmation** — Show delete confirmation alert
- **showError** — Display error alert

#### Services
- SplitService: fetch(), delete()
- SplitDayService: create(), update(), delete(), reorder()

---

### SplitFormViewModel

#### State (ViewModel → View)
- **name:** String — Split name input
- **isEditing:** Bool — True if editing existing, false if creating
- **isSaving:** Bool — Whether save is in progress
- **errorMessage:** String? — Validation or save error

#### Intents (View → ViewModel)
- **updateName(name:)** — User types name → updates name
- **save()** — Validate and save split → triggers navigation back
- **cancel()** — Discard changes → triggers navigation back

#### Side Effects
- **navigateBack** — Pop to previous screen after save/cancel
- **showValidationError** — Show inline validation feedback
- **showError** — Display error alert

#### Services
- SplitService: create(), update()

---

### SplitDayDetailViewModel

#### State (ViewModel → View)
- **day:** SplitDay — The split day being viewed
- **assignedWorkouts:** [WorkoutTemplate] — Workouts assigned to this day
- **isLoading:** Bool — Whether data is being fetched
- **errorMessage:** String? — Error message if operation failed

#### Intents (View → ViewModel)
- **loadDay()** — Fetch latest day data → updates day, assignedWorkouts
- **editDay()** — User taps edit → triggers navigation
- **deleteDay()** — Delete day → triggers navigation back
- **assignWorkout()** — User taps assign workout → presents workout picker (via HomeRouter)
- **unassignWorkout(workout:)** — Remove workout from day → updates assignedWorkouts
- **startWorkout(workout:)** — Start workout from this day → triggers navigation

#### Side Effects
- **navigateToEditDay** — Navigate to split day form (edit mode) (via HomeRouter)
- **navigateToWorkoutPicker** — Present workout template picker (via HomeRouter)
- **navigateToActiveWorkout** — Navigate to active workout screen (via HomeRouter)
- **navigateBack** — Pop to previous screen after delete
- **showDeleteConfirmation** — Show delete confirmation alert
- **showError** — Display error alert

#### Services
- SplitDayService: fetch(), delete(), assignWorkout(), unassignWorkout()
- WorkoutService: createFromTemplate()

---

### SplitDayFormViewModel

#### State (ViewModel → View)
- **name:** String — Day name input
- **isEditing:** Bool — True if editing existing, false if creating
- **isSaving:** Bool — Whether save is in progress
- **errorMessage:** String? — Validation or save error

#### Intents (View → ViewModel)
- **updateName(name:)** — User types name → updates name
- **save()** — Validate and save day → triggers navigation back
- **cancel()** — Discard changes → triggers navigation back

#### Side Effects
- **navigateBack** — Pop to previous screen after save/cancel
- **showValidationError** — Show inline validation feedback
- **showError** — Display error alert

#### Services
- SplitDayService: create(), update()

---

## Library Tab - Exercise Library

### CategoryListViewModel

#### State (ViewModel → View)
- **categories:** [ExerciseCategory] — All categories to display (ordered)
- **isLoading:** Bool — Whether categories are being fetched
- **errorMessage:** String? — Error message if fetch failed

#### Intents (View → ViewModel)
- **loadCategories()** — Fetch all categories → sets isLoading, updates categories
- **createCategory(name:)** — Create new category → adds to categories
- **updateCategory(category:name:)** — Rename category → updates category
- **reorderCategories(from:to:)** — Drag to reorder → updates categories order
- **deleteCategory(category:)** — Delete category → removes from categories
- **selectCategory(category:)** — User taps category → triggers navigation

#### Side Effects
- **navigateToCategoryDetail** — Navigate to category's exercise list
- **showDeleteConfirmation** — Show delete confirmation (only if no exercises)
- **showError** — Display error alert

#### Services
- CategoryService: fetchAll(), create(), update(), delete(), reorder()

---

### ExerciseListViewModel

#### State (ViewModel → View)
- **exercises:** [Exercise] — Exercises to display (filtered)
- **isLoading:** Bool — Whether exercises are being fetched
- **errorMessage:** String? — Error message if fetch failed
- **searchQuery:** String — Current search text
- **showFavoritesOnly:** Bool — Whether filtering to favorites
- **showArchived:** Bool — Whether showing archived exercises
- **selectedCategory:** ExerciseCategory? — Category filter (nil = all)

#### Intents (View → ViewModel)
- **loadExercises()** — Fetch exercises for current filters → sets isLoading, updates exercises
- **search(query:)** — Update search filter → updates searchQuery, re-filters exercises
- **toggleFavoritesFilter()** — Toggle favorites-only mode → updates showFavoritesOnly, re-filters
- **toggleArchivedFilter()** — Toggle archived visibility → updates showArchived, re-filters
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
- **performanceStats:** ExerciseStats? — Read-only stats (last performed, PR, volume)
- **isLoading:** Bool — Whether data is being fetched
- **errorMessage:** String? — Error message if operation failed
- **canDelete:** Bool — True if exercise has no history (can be permanently deleted)

#### Intents (View → ViewModel)
- **loadExercise()** — Fetch latest exercise data and stats → updates exercise, performanceStats
- **toggleFavorite()** — Toggle favorite status → updates exercise.isFavorite
- **editExercise()** — User taps edit → triggers navigation
- **deleteExercise()** — Delete or archive exercise → triggers navigation back

#### Side Effects
- **navigateToEditExercise** — Navigate to exercise form (edit mode)
- **navigateBack** — Pop to previous screen after delete
- **showDeleteConfirmation** — Show delete/archive confirmation alert
- **showError** — Display error alert

#### Services
- ExerciseService: fetch(), update(), delete(), archive(), hasHistory()
- AnalyticsService: statsForExercise()

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

## Library Tab - Workout Library

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
- **navigateToTemplateDetail** — Navigate to template detail screen (via LibraryRouter)
- **navigateToCreateTemplate** — Navigate to template form (create mode) (via LibraryRouter)
- **showDeleteConfirmation** — Show delete confirmation alert
- **showError** — Display error alert

#### Services
- TemplateService: fetchAll(), delete()

---

### TemplateDetailViewModel

#### State (ViewModel → View)
- **template:** WorkoutTemplate — The template being viewed
- **exercises:** [TemplateExercise] — Ordered exercises in template
- **assignedSplitDays:** [SplitDay] — Split days this template is assigned to
- **isLoading:** Bool — Whether data is being fetched
- **errorMessage:** String? — Error message if operation failed

#### Intents (View → ViewModel)
- **loadTemplate()** — Fetch latest template data → updates template, exercises, assignedSplitDays
- **startWorkout()** — Start workout from this template → triggers navigation
- **editTemplate()** — User taps edit → triggers navigation
- **duplicateTemplate()** — Create copy of template → triggers navigation to copy
- **assignToSplit()** — User taps assign → presents split day picker (via LibraryRouter)
- **deleteTemplate()** — Delete template → triggers navigation back

#### Side Effects
- **navigateToActiveWorkout** — Navigate to active workout screen (via LibraryRouter)
- **navigateToEditTemplate** — Navigate to template form (edit mode) (via LibraryRouter)
- **navigateToSplitDayPicker** — Present split day picker (via LibraryRouter)
- **navigateToTemplateCopy** — Navigate to duplicated template
- **navigateBack** — Pop to previous screen after delete
- **showDeleteConfirmation** — Show delete confirmation alert
- **showError** — Display error alert

#### Services
- TemplateService: fetch(), duplicate(), delete()
- SplitDayService: fetchBySplitTemplate()
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
- **addExercise()** — User taps add exercise → presents exercise picker (via LibraryRouter)
- **removeExercise(exercise:)** — Remove exercise from template → updates exercises
- **reorderExercises(from:to:)** — Drag to reorder → updates exercises order
- **updateTargets(exercise:sets:reps:)** — Update target sets/reps → updates exercise
- **save()** — Validate and save template → triggers navigation back
- **cancel()** — Discard changes → triggers navigation back

#### Side Effects
- **navigateToExercisePicker** — Present exercise picker (via LibraryRouter)
- **navigateBack** — Pop to previous screen after save/cancel
- **showValidationError** — Show inline validation feedback
- **showError** — Display error alert

#### Services
- TemplateService: create(), update()

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

### WorkoutPickerViewModel

#### State (ViewModel → View)
- **templates:** [WorkoutTemplate] — Available workout templates to pick
- **searchQuery:** String — Current search text
- **isLoading:** Bool — Whether data is being fetched

#### Intents (View → ViewModel)
- **loadTemplates()** — Fetch available templates → updates templates
- **search(query:)** — Filter by search text → updates searchQuery, templates
- **selectTemplate(template:)** — User picks template → triggers callback and navigation

#### Side Effects
- **dismissWithSelection** — Dismiss picker and return selected template
- **dismissWithoutSelection** — Dismiss picker (cancel)

#### Services
- TemplateService: fetchAll(), search()

---

### SplitDayPickerViewModel

#### State (ViewModel → View)
- **splits:** [Split] — All splits with their days
- **isLoading:** Bool — Whether data is being fetched

#### Intents (View → ViewModel)
- **loadSplits()** — Fetch all splits and days → updates splits
- **selectDay(day:)** — User picks split day → triggers callback and navigation

#### Side Effects
- **dismissWithSelection** — Dismiss picker and return selected split day
- **dismissWithoutSelection** — Dismiss picker (cancel)

#### Services
- SplitService: fetchAll()

---

## Active Workout

### ActiveWorkoutViewModel

#### State (ViewModel → View)
- **workout:** Workout — The active workout session
- **exercises:** [LoggedExercise] — Exercises being logged
- **previousPerformance:** [Exercise.ID: [LoggedSet]] — Last completed sets per exercise, used as placeholder values
- **elapsedTime:** TimeInterval — Time since workout started
- **fromTemplate:** WorkoutTemplate? — Source template (if any)
- **isLoading:** Bool — Whether data is being saved
- **errorMessage:** String? — Error message if operation failed
- **showSaveAsTemplatePrompt:** Bool — Whether save-as-template prompt is showing
- **templateName:** String — Name for the new template
- **didSaveAsTemplate:** Bool — Whether template was saved successfully

#### Intents (View → ViewModel)
- **loadWorkout()** — Load active workout data → updates workout, exercises
- **loadPreviousPerformance(for exercise:)** — Fetch last completed sets for exercise → updates previousPerformance
- **addExercise()** — User taps add exercise → presents exercise picker
- **removeExercise(exercise:)** — Remove exercise from workout → updates exercises
- **reorderExercises(from:to:)** — Drag to reorder → updates exercises order
- **addSet(exercise:)** — Add new set to exercise → updates exercise.sets
- **updateSet(set:weight:reps:time:distance:notes:)** — Update set values → updates set
- **deleteSet(set:)** — Remove set → updates exercise.sets
- **updateExerciseNotes(exercise:notes:)** — Update exercise notes → updates exercise
- **updateWorkoutNotes(notes:)** — Update workout notes → updates workout
- **completeWorkout()** — Finish and save workout → shows save-as-template prompt
- **saveAsTemplate(name:)** — Save current workout exercises as a new template → completes workout
- **skipSaveAsTemplate()** — Skip saving as template → completes workout
- **cancelWorkout()** — Discard workout → triggers navigation

#### Side Effects
- **navigateToExercisePicker** — Present exercise picker
- **navigateToHome** — Pop to home tab after completion/cancel
- **showCompleteConfirmation** — Show completion confirmation
- **showSaveAsTemplatePrompt** — Show prompt to save workout as template
- **showCancelConfirmation** — Show discard confirmation alert
- **showError** — Display error alert

#### Services
- WorkoutService: fetch(), update(), complete(), cancel(), lastPerformedSets(for:)
- TemplateService: create(), addExercise()
- LoggedExerciseService: create(), update(), delete(), reorder()
- LoggedSetService: create(), update(), delete()

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
- **workout:** Workout — The completed workout (read-only)
- **exercises:** [LoggedExercise] — Exercises performed with sets (read-only)
- **duration:** TimeInterval — Total workout duration
- **isLoading:** Bool — Whether data is being fetched
- **errorMessage:** String? — Error message if operation failed

#### Intents (View → ViewModel)
- **loadWorkout()** — Fetch workout details → updates workout, exercises
- **deleteWorkout()** — Delete workout → triggers navigation back

#### Side Effects
- **navigateBack** — Pop to previous screen after delete
- **showDeleteConfirmation** — Show delete confirmation alert
- **showError** — Display error alert

#### Services
- WorkoutService: fetch(), delete()

---

## Analytics Tab

### AnalyticsDashboardViewModel

#### State (ViewModel → View)
- **workoutsThisWeek:** Int — Count of workouts this week
- **workoutsThisMonth:** Int — Count of workouts this month
- **totalVolume:** Double — Total training volume
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
- AnalyticsService: workoutsThisWeek(), workoutsThisMonth(), totalVolume(), recentExercises(), personalRecords()

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
