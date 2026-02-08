# User Flows

## Model to User Flow Mapping

This section maps data models to the user flows that create, read, update, or delete them.

### ExerciseCategory
- **Create:** Create Category
- **Read:** Browse Categories, Browse Exercises
- **Update:** Edit Category, Reorder Categories
- **Delete:** Delete Category

### Exercise
- **Create:** Create Exercise
- **Read:** Browse Exercises, Search Exercises, Exercise Detail, Exercise Picker
- **Update:** Edit Exercise, Favorite Exercise
- **Delete:** Delete Exercise (no history) or Archive Exercise (has history)

### WorkoutTemplate
- **Create:** Create Template
- **Read:** Browse Templates, Template Detail
- **Update:** Edit Template, Reorder Exercises, Assign to Split Day
- **Delete:** Delete Template

### TemplateExercise
- **Create:** Add Exercise to Template
- **Read:** Template Detail
- **Update:** Reorder Exercises, Edit Template
- **Delete:** Remove Exercise from Template

### Split
- **Create:** Create Split
- **Read:** Browse Splits, Split Dashboard, View Split Detail
- **Update:** Edit Split, Add/Remove Days, Reorder Days, Assign Workouts
- **Delete:** Delete Split

### SplitDay
- **Create:** Add Day to Split
- **Read:** Split Dashboard, Split Detail
- **Update:** Edit Day Name, Reorder Days, Assign/Unassign Workouts
- **Delete:** Remove Day from Split

### Workout
- **Create:** Start Workout from Template, Start Empty Workout
- **Read:** View History, View Workout Details, Active Workout
- **Update:** Complete Workout, Add Workout Notes
- **Delete:** Cancel Workout, Delete Completed Workout

### LoggedExercise
- **Create:** Add Exercise During Workout, Start Workout from Template
- **Read:** Active Workout, Completed Workout Detail
- **Update:** Add Exercise Notes
- **Delete:** Remove Exercise from Workout

### LoggedSet
- **Create:** Log a Set
- **Read:** Active Workout, Completed Workout Detail
- **Update:** Edit a Set
- **Delete:** Delete a Set

### Model Lifecycle Through User Flows

**Exercise Lifecycle**
```
Create Exercise → Edit Exercise → Favorite Exercise → Delete/Archive Exercise
                                                            │
                                    ┌───────────────────────┴───────────────────────┐
                                    ▼                                               ▼
                            [No History]                                    [Has History]
                            Exercise Removed                                Exercise Archived
```

**Split Lifecycle**
```
Create Split → Add Days → Assign Workouts to Days → View Split Dashboard
                   │                                         │
                   ▼                                         ▼
            Reorder Days                            Start Workout from Split
            Edit Day Names                          (via Home Tab)
            Delete Days
```

**Template to Workout Flow**
```
Create Template → Add Exercises → Assign to Split Day (optional)
                                          │
                    ┌─────────────────────┴────────────────────────┐
                    │                                              │
                    ▼                                              ▼
        Start from Split Dashboard               Start from Workout Library
                    │                                              │
                    └──────────────────┬───────────────────────────┘
                                       ▼
                              Workout created (status: active)
                              LoggedExercises created from TemplateExercises
                                       │
                     ┌─────────────────┴─────────────────┐
                     ▼                                   ▼
             Complete Workout                     Cancel Workout
             (status: completed)                  (status: cancelled)
             Saved to History                     Discarded
                     │
       ┌─────────────┴─────────────┐
       ▼                           ▼
Save as Template          History Record Only
(optional)
```

**Analytics Data Sources**
```
Workout (completed) ──► LoggedExercise ──► LoggedSet
        │                     │                │
        ▼                     ▼                ▼
  Workouts/week        Volume/exercise    Personal Records
  Workouts/month       Last performed     Performance trends
```

---

## Home Tab

### View Split Dashboard
Home Tab → Split Dashboard → View All Splits → Days and Assigned Workouts

### Start Workout from Split
Home Tab → Split Dashboard → Select Split → Select Day → Select Workout → Start Workout → Active Workout Screen

### Start Workout from Recent/Pinned
Home Tab → Recent/Pinned Workouts → Select Workout → Start Workout → Active Workout Screen

### Start Empty Workout
Home Tab → Start Empty Workout Button → Active Workout Screen

### Resume Active Workout
Home Tab → Active Workout Banner (if workout in progress) → Active Workout Screen

---

## Exercise Library

### Browse Exercises
Library Tab → Exercise Library → Categories List → Select Category → Exercise List → Exercise Detail

### Search Exercises
Library Tab → Exercise Library → Search Bar → Type Query → Filtered Results → Exercise Detail

### Create Exercise
Library Tab → Exercise Library → "+" Button → Exercise Form → Fill Details → Select Categories → Save → Exercise List

### Edit Exercise
Library Tab → Exercise Library → Exercise Detail → Edit Button → Exercise Form → Modify Details → Save → Exercise Detail

### Delete Exercise (No History)
Library Tab → Exercise Library → Exercise Detail → Delete → Confirm → Exercise Removed

### Archive Exercise (Has History)
Library Tab → Exercise Library → Exercise Detail → Delete → Confirm → Exercise Archived (hidden from library, preserved in history)

### Favorite Exercise
Library Tab → Exercise Library → Exercise Detail → Tap Favorite → Exercise Marked as Favorite

### Filter by Favorites
Library Tab → Exercise Library → Favorites Filter → Favorite Exercises List

### Toggle Archived Exercises
Library Tab → Exercise Library → Show Archived Filter → Archived Exercises Visible

---

## Exercise Categories

### Browse Categories
Library Tab → Exercise Library → Categories List → View All Categories

### Create Category
Library Tab → Exercise Library → Categories List → "+" Button → Enter Name → Save → Categories List

### Edit Category
Library Tab → Exercise Library → Categories List → Category → Edit → Modify Name → Save

### Reorder Categories
Library Tab → Exercise Library → Categories List → Edit Mode → Drag Category → Drop in New Position → Order Updated

### Delete Category
Library Tab → Exercise Library → Categories List → Category → Delete → Confirm → Category Removed (only if no exercises assigned)

---

## Workout Library

### Browse Templates
Library Tab → Workout Library → Template List

### Create Template
Library Tab → Workout Library → "+" Button → Template Form → Add Name → Add Exercises → Set Order → Save → Template List

### Edit Template
Library Tab → Workout Library → Select Template → Template Detail → Edit → Modify Template → Save → Template Detail

### Add Exercise to Template
Template Edit → Add Exercise → Exercise Picker → Select Exercise → Set Target Sets/Reps → Exercise Added

### Reorder Exercises in Template
Template Edit → Drag Exercise → Drop in New Position → Order Updated

### Remove Exercise from Template
Template Edit → Exercise Row → Delete → Exercise Removed

### Duplicate Template
Template Detail → Duplicate → New Template Created → Template List

### Delete Template
Template Detail → Delete → Confirm → Template Removed

### Assign Template to Split Day
Template Detail → Assign to Split → Select Split → Select Day → Template Assigned

### Start Workout from Template
Library Tab → Workout Library → Select Template → Template Detail → Start Workout → Active Workout Screen

---

## Splits

### Browse Splits
Home Tab → Split Dashboard → View All Splits

### Create Split
Home Tab → Split Dashboard → "+" Button → Enter Split Name → Save → Split Created → Add Days

### Edit Split
Home Tab → Split Dashboard → Select Split → Split Detail → Edit → Modify Name → Save

### Delete Split
Home Tab → Split Dashboard → Select Split → Split Detail → Delete → Confirm → Split Removed

### Add Day to Split
Split Detail → Add Day → Enter Day Name → Save → Day Added to Split

### Edit Day Name
Split Detail → Select Day → Edit → Modify Name → Save

### Reorder Days
Split Detail → Edit Mode → Drag Day → Drop in New Position → Order Updated

### Remove Day from Split
Split Detail → Select Day → Delete → Confirm → Day Removed

### Assign Workout to Day
Split Detail → Select Day → Assign Workout → Select from Template List → Workout Assigned

### Unassign Workout from Day
Split Detail → Select Day → Assigned Workouts List → Select Workout → Unassign → Workout Removed from Day

### View Split Day Workouts
Split Detail → Select Day → View Assigned Workouts → Workout List

---

## Active Workout

### Start Workout from Template
Library Tab → Workout Library → Select Template → Template Detail → Start Workout → Active Workout Screen

### Start Workout from Split
Home Tab → Split Dashboard → Select Split → Select Day → Select Workout → Start Workout → Active Workout Screen

### Start Empty Workout
Home Tab → Start Empty Workout → Active Workout Screen

### Add Exercise During Workout
Active Workout → Add Exercise → Exercise Picker → Select Exercise → Exercise Added to Workout

### Log a Set
Active Workout → Select Exercise → Add Set → Enter Weight/Reps/Time → Enter Notes (optional) → Set Logged

### Edit a Set
Active Workout → Select Exercise → Tap Set → Modify Values → Set Updated

### Delete a Set
Active Workout → Select Exercise → Set Row → Delete → Set Removed

### Remove Exercise from Workout
Active Workout → Exercise Row → Delete → Exercise Removed

### Reorder Exercises During Workout
Active Workout → Edit Mode → Drag Exercise → Drop in New Position → Order Updated

### Add Exercise Notes
Active Workout → Select Exercise → Notes Field → Enter Notes → Notes Saved

### Add Workout Notes
Active Workout → Workout Notes Field → Enter Notes → Notes Saved

### Complete Workout
Active Workout → Complete Button → Confirm → Workout Saved → History Tab

### Save Completed Workout as Template
Active Workout → Complete Button → Save as Template (optional) → Enter Template Name → Template Created → History Tab

### Cancel Workout
Active Workout → Cancel Button → Confirm Discard → Workout Discarded → Home Tab

---

## Workout History

### View History
History Tab → Workout List (Chronological)

### View Workout Details
History Tab → Select Workout → Completed Workout Detail (Read-Only)

### Delete Completed Workout
Completed Workout Detail → Delete → Confirm → Workout Removed

### Clear All History
History Tab → Clear All → Confirm → All Workouts Removed

---

## Analytics

### View Dashboard
Analytics Tab → Insights Dashboard

### View Exercise Analytics
Analytics Tab → Select Exercise → Exercise Analytics (Volume, PRs, Trends)

### View Weekly Summary
Analytics Tab → Weekly Summary → Workouts This Week

### View Monthly Summary
Analytics Tab → Monthly Summary → Workouts This Month

### View Personal Records
Analytics Tab → Personal Records → PRs by Exercise

---

## Settings

### Open Settings
Any Tab → Settings Icon → Settings Modal

### Change Units
Settings Modal → Units → Select lbs/kg → Units Updated

### Change Appearance
Settings Modal → Appearance → Select Light/Dark/System → Appearance Updated

### Export Data
Settings Modal → Export Data → Generate JSON → Share/Save File

### Import Data
Settings Modal → Import Data → Select File → Confirm → Data Imported

### Reset Data
Settings Modal → Reset Data → Confirm → All Data Cleared

### View About
Settings Modal → About → Version Info
