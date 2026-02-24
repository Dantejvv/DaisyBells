# Views Inventory

Every view in DaisyBells, organized by section. Views marked `[planned]` have a ViewModel but no view file yet.

## Home

- **HomeDashboardView** — Main home screen. Shows active split, quick-start workout options, and recent activity.
- **SplitListView** — List of all training splits. Each row shows split name and day count.
- **SplitFormView** — Form to create or edit a split. Name, notes, and day management.

## Library

- **LibraryRootView** — Segmented control switching between Exercises and Workouts tabs.
- **CategoryListView** — Grid/list of exercise categories. Tap a category to see its exercises.
- **ExerciseListView** — List of exercises filtered by category. Shows name, type, and favorite star.
- **ExerciseDetailView** — Single exercise info: type, favorite toggle, categories as tags, notes, and performance stats (last performed, PR, total volume). Archive/delete action at bottom.
- **ExerciseFormView** — Form to create or edit an exercise. Name, type picker, notes, category selection.
- **ExercisePickerSheet** — Searchable list to pick an exercise (used when adding exercises to a template).
- **TemplateListView** — List of workout templates. Each row is a TemplateCard showing name, exercise count, expand/collapse, and start button.
- **TemplateDetailView** — Single template info: notes, then exercise cards with set rows displayed as read-only pills (matching CompletedWorkoutDetailView layout). Set values sourced from template sets or previous performance data, with neutral badge style. Actions: start workout, duplicate, delete.
- **TemplateFormView** — Form to create or edit a template. Name, notes, and exercise list with add/remove/reorder.
- **WorkoutPickerSheet** — Searchable list to pick a workout template (used when assigning workouts to split days).

## History

- **HistoryListView** — Chronological list of completed workouts. Each row shows template name, date, duration, and exercise/set counts.
- **CompletedWorkoutDetailView** — Read-only view of a finished workout: date, duration, volume summary, then exercise cards with logged set values shown as read-only pills.

## Analytics

- **AnalyticsDashboardView** — Overview of workout stats and trends. `[planned]`
- **ExerciseAnalyticsView** — Per-exercise analytics: history, PRs, volume over time. `[planned]`

## Profile

- **ProfileView** — App settings: units, distance units, appearance, and active split selection.

## Active Workout

- **ActiveWorkoutSheet** — Modal sheet wrapping ActiveWorkoutView. Shown globally from any tab.
- **ActiveWorkoutView** — Full workout logging screen inside the sheet: exercise cards with editable set rows, add exercises, finish/discard workout.
- **ActiveWorkoutFloatingButton** — Small floating pill at bottom of screen showing workout name and elapsed timer. Tap to reopen the sheet.

## Shared Components

- **EmptyStateView** — Generic empty state with icon, title, message, and optional action button.
- **LoadingSpinnerView** — Centered spinner for loading states.
- **TemplateCard** — Expandable card for workout templates. Shows name, exercise count, start button, expand to see exercise list and "View Details" link.
- **ExerciseCardContainer** — Card chrome wrapper: VStack with bgCard background, rounded corners, subtle border. Used by ActiveWorkoutView, CompletedWorkoutDetailView, and TemplateDetailView.
- **ExerciseCardHeader** — Header row with exercise name and @ViewBuilder trailing content (menu, type label, etc.).
- **SetColumnHeaders** — Column label row (SET / LB / REPS / NOTES) that switches on ExerciseType. Optional check column for active workouts.
- **SetNumberBadge** — Colored circle badge with set number. Styles: completed (green), active (accent), pending (gray), neutral (gray).
- **ReadOnlyDualPill / ReadOnlySinglePill** — Static text in capsule shape for read-only set values.
- **ReadOnlySetRow** — Composes SetNumberBadge + ReadOnlyPills + notes for a single read-only set row. Used by CompletedWorkoutDetailView and TemplateDetailView.
- **ErrorAlertModifier** — `.errorAlert(errorMessage:)` modifier that shows an alert from ViewModel error state.
- **ConfirmationDialogModifier** — `.destructiveConfirmation(...)` modifier for delete/archive confirmations.
