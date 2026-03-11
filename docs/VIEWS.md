# Views Inventory

Every view in DaisyBells, organized by section. Views marked `[planned]` have a ViewModel but no view file yet.

## Home

- **HomeDashboardView** — Main home screen. Shows active split with vertical day list (cycle tracking, swipe for set-next/skip actions, tap to expand workout list), NewWorkoutCard for blank workouts, and template cards.
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
- **TemplateFormView** — Card-based form to create or edit a template. Header card with name and notes fields, then exercise cards with editable set rows (matching ActiveWorkoutView's layout), add/remove sets, add/remove/reorder exercises. Auto-creates sets from previous workout history (falls back to 1 empty set).
- **WorkoutPickerSheet** — Searchable list to pick a workout template (used when assigning workouts to split days).

## History

- **HistoryListView** — Chronological list of completed workouts. Each row shows template name, date, duration, and exercise/set counts.
- **CompletedWorkoutDetailView** — Read-only view of a finished workout: date, duration, volume summary, then exercise cards with logged set values shown as read-only pills.
- **HistoryCalendarSheet** — Monthly calendar sheet showing workout activity. Accent-colored dots indicate days with completed workouts. Supports month navigation via arrows, a "Today" button, and collapsing to a single-week strip.

## Analytics

- **AnalyticsDashboardView** — Overview of workout stats and trends.
- **ExerciseAnalyticsView** — Per-exercise analytics: history, PRs, volume over time.

## Profile

- **ProfileView** — App settings: units, distance units, appearance, and active split selection.

## Active Workout

- **ActiveWorkoutSheet** — Modal sheet wrapping ActiveWorkoutView. Shown globally from any tab.
- **ActiveWorkoutView** — Full workout logging screen inside the sheet: exercise cards with editable set rows, add exercises, finish/discard workout.
- **ActiveWorkoutFloatingButton** — Small floating pill at bottom of screen showing workout name and elapsed timer. Tap to reopen the sheet.

## Shared Components

- **NewWorkoutCard** — Card with plus icon, "New Workout" title, subtitle, and Start button. Used at top of template list on HomeDashboardView. Props: `isDisabled`, `onStart`.
- **EmptyStateView** — Generic empty state with icon, title, message, and optional action button.
- **LoadingSpinnerView** — Centered spinner for loading states.
- **TemplateCard** — Expandable card for workout templates. Shows name, exercise count, start button, expand to see exercise list and "View Details" link.
- **ExerciseCardContainer** — Card chrome wrapper: VStack with bgCard background, rounded corners, subtle border. Used by ActiveWorkoutView, CompletedWorkoutDetailView, and TemplateDetailView.
- **ExerciseCardHeader** — Header row with exercise name and @ViewBuilder trailing content (menu, type label, etc.).
- **SetColumnHeaders** — Column label row (SET / LB / REPS / NOTES) that switches on ExerciseType. Optional check column for active workouts.
- **SetNumberBadge** — Colored circle badge with set number. Styles: completed (green), active (accent), pending (gray), neutral (gray).
- **ReadOnlyDualPill / ReadOnlySinglePill** — Static text in capsule shape for read-only set values.
- **ReadOnlySetRow** — Composes SetNumberBadge + ReadOnlyPills + notes for a single read-only set row. Used by CompletedWorkoutDetailView and TemplateDetailView.
- **PillTextField** — Single TextField building block for numeric input pills. Decimal pad keyboard, centered text.
- **EditableDualPill** — Two-field fused capsule (width 94) composing two PillTextFields with a divider. Used for weight/reps, distance/time, etc.
- **EditableSinglePill** — Single-field capsule (width 46) wrapping one PillTextField. Used for reps-only or time-only exercises.
- **EditableNotesField** — Editable text field for per-set notes with placeholder support. Data-agnostic via onChange callback.
- **EditableSetRow** — Composes SetNumberBadge + EditablePills (6-way ExerciseType switch) + EditableNotesField. Used by ActiveWorkoutView and TemplateFormView.
- **ErrorAlertModifier** — `.errorAlert(errorMessage:)` modifier that shows an alert from ViewModel error state.
- **ConfirmationDialogModifier** — `.destructiveConfirmation(...)` modifier for delete/archive confirmations.
