# Data Models

## Enums

```swift
enum ExerciseType: String, Codable {
    case weightAndReps      // bench press
    case bodyweightAndReps  // pull-ups
    case reps               // box jumps
    case time               // plank
    case distanceAndTime    // running
    case weightAndTime      // farmer's carry
}

enum WorkoutStatus: String, Codable {
    case active
    case completed
    case cancelled
}

enum Units: String, Codable {
    case lbs
    case kg
}

enum Appearance: String, Codable {
    case light
    case dark
    case system
}
```

---

## ExerciseType

**ExerciseType** — *How you measure/log the exercise*
- Determines what input fields appear when logging a set
- Each exercise has exactly one type

### weightAndReps
- **Input Fields:** weight, reps
- **Example:** Bench Press

### bodyweightAndReps
- **Input Fields:** reps, bodyweightModifier (+/- lbs)
- **Example:** Pull-ups (-30 lbs assisted, +45 lbs weighted)

### reps
- **Input Fields:** reps only
- **Example:** Box Jumps

### time
- **Input Fields:** duration
- **Example:** Plank

### distanceAndTime
- **Input Fields:** distance, duration
- **Example:** Running

### weightAndTime
- **Input Fields:** weight, duration
- **Example:** Farmer's Carry

---

## Exercise Library

```swift
@Model
class ExerciseCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var isDefault: Bool
    var order: Int

    @Relationship(inverse: \Exercise.categories)
    var exercises: [Exercise]

    init(name: String, isDefault: Bool = false, order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.isDefault = isDefault
        self.order = order
    }
}

@Model
class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: ExerciseType
    var notes: String?
    var isFavorite: Bool
    var isArchived: Bool

    // Performance cache fields (updated on workout completion)
    var lastPerformedAt: Date?
    var hasCompletedWorkout: Bool
    var totalVolume: Double
    var prWeight: Double?
    var prReps: Int?
    var prTime: TimeInterval?
    var prDistance: Double?
    var prEstimated1RM: Double?
    var prAchievedAt: Date?

    @Relationship
    var categories: [ExerciseCategory]

    init(name: String, type: ExerciseType, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.notes = notes
        self.isFavorite = false
        self.isArchived = false
        self.lastPerformedAt = nil
        self.hasCompletedWorkout = false
        self.totalVolume = 0
        self.categories = []
    }
}
```

---

## Workout Templates

```swift
@Model
class WorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var notes: String?

    @Relationship(deleteRule: .cascade)
    var templateExercises: [TemplateExercise]

    init(name: String, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.templateExercises = []
    }
}

@Model
class TemplateExercise {
    @Attribute(.unique) var id: UUID
    var order: Int
    var targetSets: Int?
    var targetReps: Int?

    @Relationship
    var exercise: Exercise

    @Relationship
    var template: WorkoutTemplate?

    init(exercise: Exercise, order: Int, targetSets: Int? = nil, targetReps: Int? = nil) {
        self.id = UUID()
        self.exercise = exercise
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
    }
}
```

---

## Splits

```swift
@Model
class Split {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var days: [SplitDay]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.days = []
    }
}

@Model
class SplitDay {
    @Attribute(.unique) var id: UUID
    var name: String
    var order: Int

    @Relationship
    var split: Split?

    @Relationship
    var assignedWorkouts: [WorkoutTemplate]

    init(name: String, order: Int) {
        self.id = UUID()
        self.name = name
        self.order = order
        self.assignedWorkouts = []
    }
}
```

---

## Workouts (Active + Completed)

```swift
@Model
class Workout {
    @Attribute(.unique) var id: UUID
    var status: WorkoutStatus
    var startedAt: Date
    var completedAt: Date?
    var notes: String?

    @Relationship
    var fromTemplate: WorkoutTemplate?

    @Relationship(deleteRule: .cascade)
    var loggedExercises: [LoggedExercise]

    init(fromTemplate: WorkoutTemplate? = nil) {
        self.id = UUID()
        self.status = .active
        self.startedAt = Date()
        self.fromTemplate = fromTemplate
        self.loggedExercises = []
    }
}

@Model
class LoggedExercise {
    @Attribute(.unique) var id: UUID
    var order: Int
    var notes: String?

    @Relationship
    var exercise: Exercise

    @Relationship
    var workout: Workout?

    @Relationship(deleteRule: .cascade)
    var sets: [LoggedSet]

    init(exercise: Exercise, order: Int) {
        self.id = UUID()
        self.exercise = exercise
        self.order = order
        self.sets = []
    }
}

@Model
class LoggedSet {
    @Attribute(.unique) var id: UUID
    var order: Int
    var weight: Double?
    var reps: Int?
    var bodyweightModifier: Double?  // +/- lbs: -30 for assisted, +45 for weighted
    var time: TimeInterval?
    var distance: Double?
    var notes: String?

    // Denormalization for query performance
    var exerciseId: UUID?
    var completedAt: Date?

    @Relationship
    var loggedExercise: LoggedExercise?

    init(order: Int) {
        self.id = UUID()
        self.order = order
    }
}
```

---

## Settings (UserDefaults via SettingsService)

Settings are stored in UserDefaults but accessed exclusively through `SettingsService`. Views and ViewModels must not use `@AppStorage` directly—all settings flow through the service to maintain the architectural pattern.

```swift
// SettingsService owns all UserDefaults access
// Keys: "units" (String), "appearance" (String)

protocol SettingsServiceProtocol {
    var units: Units { get set }
    var appearance: Appearance { get set }
}

@Observable
class SettingsService: SettingsServiceProtocol {
    var units: Units {
        get { Units(rawValue: UserDefaults.standard.string(forKey: "units") ?? "") ?? .lbs }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "units") }
    }

    var appearance: Appearance {
        get { Appearance(rawValue: UserDefaults.standard.string(forKey: "appearance") ?? "") ?? .system }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "appearance") }
    }
}
```

---

# Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              EXERCISE LIBRARY                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────────────┐         many-to-many        ┌──────────────────┐    │
│   │ ExerciseCategory │◆────────────────────────────│     Exercise     │    │
│   ├──────────────────┤                             ├──────────────────┤    │
│   │ id: UUID         │                             │ id: UUID         │    │
│   │ name: String     │                             │ name: String     │    │
│   │ isDefault: Bool  │                             │ type: ExerciseType│   │
│   │ order: Int       │                             │ notes: String?   │    │
│   └──────────────────┘                             │ isFavorite: Bool │    │
│                                                    │ isArchived: Bool │    │
│                                                    └────────┬─────────┘    │
│                                                             │              │
└─────────────────────────────────────────────────────────────┼──────────────┘
                                                              │
                         ┌────────────────────────────────────┼─────────┐
                         │                                    │         │
                         ▼                                    ▼         │
┌─────────────────────────────────────────┐    ┌─────────────────────────────┐
│           WORKOUT TEMPLATES             │    │     WORKOUTS (LOGGING)      │
├─────────────────────────────────────────┤    ├─────────────────────────────┤
│                                         │    │                             │
│  ┌──────────────────┐                   │    │  ┌──────────────────┐       │
│  │ WorkoutTemplate  │                   │    │  │     Workout      │       │
│  ├──────────────────┤                   │    │  ├──────────────────┤       │
│  │ id: UUID         │                   │    │  │ id: UUID         │       │
│  │ name: String     │◄──────────────────┼────┼──│ fromTemplate?    │       │
│  │ notes: String?   │     optional      │    │  │ status: Status   │       │
│  └────────┬─────────┘     reference     │    │  │ startedAt: Date  │       │
│           │                             │    │  │ completedAt?     │       │
│           │ one-to-many                 │    │  │ notes: String?   │       │
│           │ (cascade delete)            │    │  └────────┬─────────┘       │
│           ▼                             │    │           │                 │
│  ┌──────────────────┐                   │    │           │ one-to-many     │
│  │TemplateExercise  │                   │    │           │ (cascade delete)│
│  ├──────────────────┤                   │    │           ▼                 │
│  │ id: UUID         │                   │    │  ┌──────────────────┐       │
│  │ order: Int       │                   │    │  │  LoggedExercise  │       │
│  │ targetSets: Int? │                   │    │  ├──────────────────┤       │
│  │ targetReps: Int? │                   │    │  │ id: UUID         │       │
│  │ exercise ────────┼───────────────────┼────┼─▶│ exercise ────────┼───┐   │
│  └──────────────────┘   references      │    │  │ order: Int       │   │   │
│                         Exercise        │    │  │ notes: String?   │   │   │
│                 │                       │    │  └────────┬─────────┘   │   │
│                 │                       │    │           │             │   │
│                 │                       │    │           │ one-to-many │   │
│                 │  many-to-many         │    │           │ (cascade)   │   │
│                 │                       │    │           ▼             │   │
│                 ▼                       │    │  ┌──────────────────┐   │   │
│  ┌────────────────────────┐             │    │  │    LoggedSet     │   │   │
│  │      SplitDay          │             │    │  ├──────────────────┤   │   │
│  ├────────────────────────┤             │    │  │ id: UUID         │   │   │
│  │ id: UUID               │             │    │  │ order: Int       │   │   │
│  │ name: String           │             │    │  │ weight: Double?  │   │   │
│  │ order: Int             │             │    │  │ reps: Int?       │   │   │
│  │ assignedWorkouts ◄─────┼─────────────┘    │  │ time: Interval?  │   │   │
│  └──────────┬─────────────┘                  │  │ distance: Double?│   │   │
│             │                                │  │ notes: String?   │   │   │
│             │ many-to-one                    │  └──────────────────┘   │   │
│             ▼                                │                         │   │
│  ┌────────────────────────┐                  └─────────────────────────┼───┘
│  │        Split           │                                            │
│  ├────────────────────────┤                               references Exercise
│  │ id: UUID               │                               (why we archive,
│  │ name: String           │                                not delete)
│  │ createdAt: Date        │
│  └────────────────────────┘
│
│              SPLITS
└─────────────────────────────────────────┘
```

---

## Key Relationships Summary

### ExerciseCategory ↔ Exercise
- **Type:** Many-to-Many
- **Delete Rule:** Nullify

### WorkoutTemplate → TemplateExercise
- **Type:** One-to-Many
- **Delete Rule:** Cascade

### TemplateExercise → Exercise
- **Type:** Many-to-One
- **Delete Rule:** Nullify

### Split → SplitDay
- **Type:** One-to-Many
- **Delete Rule:** Cascade

### SplitDay ↔ WorkoutTemplate
- **Type:** Many-to-Many
- **Delete Rule:** Nullify
- **Note:** A workout can be assigned to multiple split days, and a split day can have multiple workouts

### Workout → WorkoutTemplate
- **Type:** Many-to-One (optional)
- **Delete Rule:** Nullify

### Workout → LoggedExercise
- **Type:** One-to-Many
- **Delete Rule:** Cascade

### LoggedExercise → Exercise
- **Type:** Many-to-One
- **Delete Rule:** Nullify

### LoggedExercise → LoggedSet
- **Type:** One-to-Many
- **Delete Rule:** Cascade
