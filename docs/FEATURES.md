# Feature & Component Specification

## 1. Exercise Categories
**Purpose:** Organization and discovery

### Categories
- System-defined categories:
  - Legs
  - Chest
  - Back
  - Shoulders
  - Arms
  - Core
  - Cardio
- User-defined categories:
  - Create
  - Rename
  - Reorder
  - Delete (only if unused)
- Exercises may belong to **zero or more** categories

---

## 2. Exercise
**Purpose:** A reusable movement definition

### Core Properties
- Name
- Exercise type
- Categories (zero or more)
- Exercise-level notes / form cues

### Exercise Types
- Reps
- Weight + Reps
- Bodyweight (+/- external load)
- Time
- Distance + Time
- Weight + Time

### Lifecycle Rules
- Exercises referenced by workout history:
  - Are **archived**, not deleted
- Archived exercises:
  - Hidden from the exercise library by default
  - Preserved in workout history
  - Can be shown via optional toggle filter
- Exercises with no history:
  - Permanently deletable

### Quality of Life
- Favorite / pinned exercises
- Exercise detail view (metadata + read-only stats)

---

## 3. Workout (Template)
**Purpose:** A reusable workout definition

- Name
- Ordered list of exercises
- Workout-level notes
- Supported actions:
  - Add / remove exercises
  - Reorder exercises
  - Duplicate
  - Rename
  - Delete

**Important Distinction**
- **Workout** = template
- **Completed Workout** = historical instance

---

## 4. Exercise Library
**Purpose:** Central exercise management

- List of exercises
- Browse by category
- Search by name
- Filters:
  - Favorites
  - Archived (optional toggle)
- Create, edit, archive exercises
- Exercise detail view shows:
  - Name, type, categories
  - Exercise-level notes / form cues
  - Read-only performance stats

---

## 5. Workout Library
**Purpose:** Workout template management

- List of workouts
- Create, edit, duplicate, delete workouts
- Quick-start workout from template
- Assign workouts to Splits

---

## 6. Active Workout Session
**Purpose:** Real-time workout execution

### Session Lifecycle
- Start workout:
  - From template
  - Or empty
- Auto-record start time
- Complete workout:
  - Records end time
  - Creates a Completed Workout
- Cancel workout:
  - No persistence

### During Workout
- Add / remove exercises
- Reorder exercises
- Add / remove sets

#### Set Fields (Dynamic by Exercise Type)
- Weight
- Reps
- Time
- Distance
- Notes (per-set)

### Smart Assistance
- Previous performance shown as placeholder:
  - Last weight / reps / time / distance
  - Last set notes
- Exercise-level notes visible
- Workout-level notes editable

### Completion Options
- Complete workout
- Save completed workout as a new template
- Discard workout

---

## 7. Workout History
**Purpose:** Immutable record of past training

- Chronological list of completed workouts
- View completed workout details (read-only structure)
- Displays:
  - Exercises performed
  - Sets with all recorded data
  - Notes (workout-level and set-level)
  - Start and end timestamps
- Delete individual workouts
- Clear all workout history

**Read-Only Rules:**
- Completed workouts are immutable historical records
- No editing of sets, exercises, or notes after completion
- Only action available: Delete

---

## 8. Splits
**Purpose:** Planning and organization

- Named split (e.g., Push / Pull / Legs)
- Days:
  - User-defined names (e.g., Day 1, Upper)
  - Ordered
- Assign workouts to days
- Split dashboard:
  - Day list
  - Associated workouts per day
- Actions:
  - Create, edit, delete splits
  - Add / remove days
  - Reorder days
  - Assign / unassign workouts to days

---

## 9. Analytics
**Purpose:** Insight and reflection

### Global Metrics
- Workouts per week / month
- Total training volume
- Consistency metrics

### Exercise Metrics
- Personal bests:
  - Max weight
  - Max reps
  - Longest time
- Last performed date
- Volume over time
- Simple performance trends

---

## 10. App Management (Settings)

- Units:
  - lbs / kg
- Appearance:
  - Light
  - Dark
  - System
- Data import / export (JSON)
- Reset all local data
- About / version information

---

# Tab Structure

## Home
- Split dashboard
- Start workout from template
- Start empty workout
- Recent or pinned workouts
- Quick access to active workout (if in progress)

---

## Library
- Exercise Library
  - Browse, search, filter exercises
  - Create, edit, archive exercises
  - Exercise detail view
- Workout Library
  - Browse, search workout templates
  - Create, edit, duplicate, delete workouts
  - Assign workouts to splits

---

## History
- Past workouts (chronological)
- Completed workout detail view (read-only)
- Delete workouts
- Clear all history

---

## Analytics
- Read-only insight dashboards
- Global metrics
- Exercise-specific analytics
