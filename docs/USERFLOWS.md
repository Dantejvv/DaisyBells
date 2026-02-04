# User Flows

## Model to User Flow Mapping

This section maps data models to the user flows that create, read, update, or delete them.

### ExerciseCategory
- **Create:** Create Category
- **Read:** Browse Categories, Browse Exercises
- **Update:** Edit Category
- **Delete:** Delete Category

### Exercise
- **Create:** Create Exercise
- **Read:** Browse Exercises, Search Exercises, Exercise Detail, Exercise Picker
- **Update:** Edit Exercise, Favorite Exercise
- **Delete:** Delete Exercise (no history) or Archive Exercise (has history)

### WorkoutTemplate
- **Create:** Create Template
- **Read:** Browse Templates, Template Detail
- **Update:** Edit Template, Reorder Exercises
- **Delete:** Delete Template

### TemplateExercise
- **Create:** Add Exercise to Template
- **Read:** Template Detail
- **Update:** Reorder Exercises, Edit Template
- **Delete:** Remove Exercise from Template

### Workout
- **Create:** Start Workout from Template, Start Empty Workout
- **Read:** View History, View Workout Details, Active Workout
- **Update:** Complete Workout, Add Workout Notes, Edit Workout Notes
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

**Template to Workout Flow**
```
Create Template → Add Exercises → Start Workout from Template
                                          │
                                          ▼
                                  Workout created (status: active)
                                  LoggedExercises created from TemplateExercises
                                          │
                        ┌─────────────────┴─────────────────┐
                        ▼                                   ▼
                Complete Workout                     Cancel Workout
                (status: completed)                  (status: cancelled)
                Saved to History                     Discarded
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

## Exercise Library

### Browse Exercises
Library Tab → Categories List → Select Category → Exercise List → Exercise Detail

### Search Exercises
Library Tab → Search Bar → Type Query → Filtered Results → Exercise Detail

### Create Exercise
Library Tab → Categories List → "+" Button → Exercise Form → Fill Details → Select Categories → Save → Exercise List

### Edit Exercise
Library Tab → Exercise Detail → Edit Button → Exercise Form → Modify Details → Save → Exercise Detail

### Delete Exercise (No History)
Library Tab → Exercise Detail → Delete → Confirm → Exercise Removed

### Archive Exercise (Has History)
Library Tab → Exercise Detail → Delete → Confirm → Exercise Archived (hidden from library, preserved in history)

### Favorite Exercise
Library Tab → Exercise Detail → Tap Favorite → Exercise Marked as Favorite

### Filter by Favorites
Library Tab → Favorites Filter → Favorite Exercises List

---

## Exercise Categories

### Browse Categories
Library Tab → Categories List → View All Categories

### Create Category
Library Tab → Categories List → "+" Button → Enter Name → Save → Categories List

### Edit Category
Library Tab → Categories List → Category → Edit → Modify Name → Save

### Delete Category
Library Tab → Categories List → Category → Delete → Confirm → Category Removed

---

## Workout Templates

### Browse Templates
Library Tab → Templates Section → Template List

### Create Template
Library Tab → Templates Section → "+" Button → Template Form → Add Name → Add Exercises → Set Order → Save → Template List

### Edit Template
Library Tab → Template List → Select Template → Template Detail → Edit → Modify Template → Save → Template Detail

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

---

## Active Workout

### Start Workout from Template
Library Tab → Templates Section → Select Template → Template Detail → Start Workout → Active Workout Screen

### Start Empty Workout
Library Tab → Start Empty Workout → Active Workout Screen

### Add Exercise During Workout
Active Workout → Add Exercise → Exercise Picker → Select Exercise → Exercise Added to Workout

### Log a Set
Active Workout → Select Exercise → Add Set → Enter Weight/Reps/Time → Set Logged

### Edit a Set
Active Workout → Select Exercise → Tap Set → Modify Values → Set Updated

### Delete a Set
Active Workout → Select Exercise → Set Row → Delete → Set Removed

### Remove Exercise from Workout
Active Workout → Exercise Row → Delete → Exercise Removed

### Add Exercise Notes
Active Workout → Select Exercise → Notes Field → Enter Notes → Notes Saved

### Add Workout Notes
Active Workout → Workout Notes Field → Enter Notes → Notes Saved

### Complete Workout
Active Workout → Complete Button → Confirm → Workout Saved → History Tab

### Cancel Workout
Active Workout → Cancel Button → Confirm Discard → Workout Discarded → Library Tab

---

## Workout History

### View History
History Tab → Workout List (Chronological)

### View Workout Details
History Tab → Select Workout → Completed Workout Detail (Read-Only)

### Edit Workout Notes
Completed Workout Detail → Notes Field → Edit Notes → Save → Notes Updated

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
