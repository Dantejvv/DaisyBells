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

enum DistanceUnits: String, Codable, CaseIterable {
    case mi
    case km
}

enum Appearance: String, Codable {
    case light
    case dark
    case system
}

enum ExerciseSortOption: String, Codable, CaseIterable {
    case alphabetical
    case creationDate
    case favoritesFirst
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
final class ExerciseCategory {
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
        self.exercises = []
    }
}

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: ExerciseType
    var notes: String?
    var isFavorite: Bool
    var isArchived: Bool
    var createdAt: Date
    var preferredWeightUnit: Units?
    var preferredDistanceUnit: DistanceUnits?

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

    // Unit tracking for cached stats
    var totalVolumeUnit: String?
    var prWeightUnit: String?
    var prDistanceUnit: String?

    var resolvedTotalVolumeUnit: Units? { totalVolumeUnit.flatMap { Units(rawValue: $0) } }
    var resolvedPrWeightUnit: Units? { prWeightUnit.flatMap { Units(rawValue: $0) } }
    var resolvedPrDistanceUnit: DistanceUnits? { prDistanceUnit.flatMap { DistanceUnits(rawValue: $0) } }

    @Relationship
    var categories: [ExerciseCategory]

    init(name: String, type: ExerciseType, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.notes = notes
        self.isFavorite = false
        self.isArchived = false
        self.createdAt = Date()
        self.preferredWeightUnit = nil
        self.preferredDistanceUnit = nil
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
final class WorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var templateExercises: [TemplateExercise]

    @Relationship
    var splitDays: [SplitDay]

    init(name: String, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.templateExercises = []
        self.splitDays = []
    }
}

@Model
final class TemplateExercise {
    @Attribute(.unique) var id: UUID
    var order: Int
    var notes: String?

    @Relationship
    var exercise: Exercise?

    @Relationship
    var template: WorkoutTemplate?

    @Relationship(deleteRule: .cascade, inverse: \TemplateSet.templateExercise)
    var sets: [TemplateSet]

    init(exercise: Exercise, order: Int) {
        self.id = UUID()
        self.exercise = exercise
        self.order = order
        self.sets = []
    }
}

@Model
final class TemplateSet {
    @Attribute(.unique) var id: UUID
    var order: Int
    var weight: Double?
    var reps: Int?
    var bodyweightModifier: Double?
    var time: TimeInterval?
    var distance: Double?
    var notes: String?

    @Relationship
    var templateExercise: TemplateExercise?

    init(order: Int) {
        self.id = UUID()
        self.order = order
    }
}
```

---

## Splits

```swift
@Model
final class Split {
    @Attribute(.unique) var id: UUID
    var name: String
    var notes: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \SplitDay.split)
    var days: [SplitDay]

    init(name: String, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.createdAt = Date()
        self.days = []
    }
}

@Model
final class SplitDay {
    @Attribute(.unique) var id: UUID
    var name: String
    var order: Int
    var isCompletedInCycle: Bool

    @Relationship
    var split: Split?

    @Relationship(inverse: \WorkoutTemplate.splitDays)
    var assignedWorkouts: [WorkoutTemplate]

    init(name: String, order: Int) {
        self.id = UUID()
        self.name = name
        self.order = order
        self.isCompletedInCycle = false
        self.assignedWorkouts = []
    }
}
```

---

## Workouts (Active + Completed)

```swift
@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var completedAt: Date?

    // Store as raw string for predicate support
    var statusValue: String

    var status: WorkoutStatus {
        get { WorkoutStatus(rawValue: statusValue) ?? .active }
        set { statusValue = newValue.rawValue }
    }

    @Relationship
    var fromTemplate: WorkoutTemplate?

    @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.workout)
    var loggedExercises: [LoggedExercise]

    init(fromTemplate: WorkoutTemplate? = nil) {
        self.id = UUID()
        self.statusValue = WorkoutStatus.active.rawValue
        self.startedAt = Date()
        self.fromTemplate = fromTemplate
        self.loggedExercises = []
    }
}

@Model
final class LoggedExercise {
    @Attribute(.unique) var id: UUID
    var order: Int
    var notes: String?

    @Relationship
    var exercise: Exercise?

    @Relationship
    var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \LoggedSet.loggedExercise)
    var sets: [LoggedSet]

    init(exercise: Exercise, order: Int) {
        self.id = UUID()
        self.exercise = exercise
        self.order = order
        self.sets = []
    }
}

@Model
final class LoggedSet {
    @Attribute(.unique) var id: UUID
    var order: Int
    var weight: Double?
    var reps: Int?
    var bodyweightModifier: Double?  // +/- lbs: -30 for assisted, +45 for weighted
    var time: TimeInterval?
    var distance: Double?
    var notes: String?
    var isCompleted: Bool = false

    // Unit tracking (stamped at creation time)
    var weightUnit: String?    // Units.rawValue ("lbs"/"kg")
    var distanceUnit: String?  // DistanceUnits.rawValue ("mi"/"km")

    var resolvedWeightUnit: Units? { weightUnit.flatMap { Units(rawValue: $0) } }
    var resolvedDistanceUnit: DistanceUnits? { distanceUnit.flatMap { DistanceUnits(rawValue: $0) } }

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

@MainActor
protocol SettingsServiceProtocol: AnyObject {
    var units: Units { get set }
    var distanceUnits: DistanceUnits { get set }
    var appearance: Appearance { get set }
    var activeSplitId: UUID? { get set }
}

@MainActor
final class SettingsService: SettingsServiceProtocol {
    private let userDefaults: UserDefaults

    var units: Units { get set }
    var distanceUnits: DistanceUnits { get set }
    var appearance: Appearance { get set }
    var activeSplitId: UUID? { get set }
}
```

---

## Export DTOs (Services/DTOs/)

The export/import system uses Codable DTOs separate from SwiftData models to avoid serialization issues with `@Model` types and relationship cycles.

**ExportContainer** — top-level wrapper:
- `metadata: ExportMetadata` — exportDate, appVersion, schemaVersion
- `settings: SettingsExportDTO` — units, distanceUnits, appearance
- `categories: [CategoryExportDTO]`
- `exercises: [ExerciseExportDTO]` — includes `categoryIds: [UUID]` for relationship reconstruction
- `templates: [TemplateExportDTO]` — nested exercises and sets
- `splits: [SplitExportDTO]` — nested days with `assignedWorkoutIds`
- `workouts: [WorkoutExportDTO]` — nested logged exercises and sets

**JSONDocument** — SwiftUI `FileDocument` wrapper for file picker integration.

**Relationship strategy:** DTOs use UUID arrays (e.g., `categoryIds`, `exerciseId`) instead of nested objects. On import, DataService rebuilds relationships via UUID lookups after inserting in dependency order (categories → exercises → templates → splits → workouts).

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
│                                                    │ createdAt: Date  │    │
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
│  │ notes: String?   │     optional      │    │  │ statusValue: Str │       │
│  │ splitDays: []    │     reference     │    │  │ startedAt: Date  │       │
│  └────────┬─────────┘                   │    │  │ completedAt?     │       │
│           │                             │    │  │ notes: String?   │       │
│           │ one-to-many                 │    │  └────────┬─────────┘       │
│           │ (cascade delete)            │    │           │                 │
│           ▼                             │    │           │ one-to-many     │
│  ┌──────────────────┐                   │    │           │ (cascade delete)│
│  │TemplateExercise  │                   │    │           ▼                 │
│  ├──────────────────┤                   │    │  ┌──────────────────┐       │
│  │ id: UUID         │                   │    │  │  LoggedExercise  │       │
│  │ order: Int       │                   │    │  ├──────────────────┤       │
│  │ notes: String?   │                   │    │  │ id: UUID         │       │
│  │ exercise ────────┼───────────────────┼────┼─▶│ exercise ────────┼───┐   │
│  └────────┬─────────┘   references      │    │  │ order: Int       │   │   │
│           │              Exercise       │    │  │ notes: String?   │   │   │
│           │                             │    │  └────────┬─────────┘   │   │
│           │ one-to-many                 │    │           │             │   │
│           │ (cascade delete)            │    │           │ one-to-many │   │
│           ▼                             │    │           │ (cascade)   │   │
│  ┌──────────────────┐                   │    │           ▼             │   │
│  │   TemplateSet    │                   │    │  ┌──────────────────┐   │   │
│  ├──────────────────┤                   │    │  │    LoggedSet     │   │   │
│  │ id: UUID         │                   │    │  ├──────────────────┤   │   │
│  │ order: Int       │                   │    │  │ id: UUID         │   │   │
│  │ weight: Double?  │                   │    │  │ order: Int       │   │   │
│  │ reps: Int?       │                   │    │  │ weight: Double?  │   │   │
│  │ time: Interval?  │                   │    │  │ reps: Int?       │   │   │
│  │ distance: Double?│                   │    │  │ isCompleted: Bool│   │   │
│  │ notes: String?   │                   │    │  │ time: Interval?  │   │   │
│  └──────────────────┘                   │    │  │ distance: Double?│   │   │
│                                         │    │  │ notes: String?   │   │   │
│                 │  many-to-many         │    │  └──────────────────┘   │   │
│                 ▼                       │    │                         │   │
│  ┌────────────────────────┐             │    └─────────────────────────┼───┘
│  │      SplitDay          │             │                              │
│  ├────────────────────────┤             │                   references Exercise
│  │ id: UUID               │             │                   (why we archive,
│  │ name: String           │             │                    not delete)
│  │ order: Int             │
│  │ isCompletedInCycle:Bool│
│  │ assignedWorkouts ◄─────┼─────────────┘
│  └──────────┬─────────────┘
│             │
│             │ many-to-one
│             ▼
│  ┌────────────────────────┐
│  │        Split           │
│  ├────────────────────────┤
│  │ id: UUID               │
│  │ name: String           │
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
- **Inverse:** `TemplateExercise.template`

### TemplateExercise → Exercise
- **Type:** Many-to-One
- **Delete Rule:** Nullify

### TemplateExercise → TemplateSet
- **Type:** One-to-Many
- **Delete Rule:** Cascade
- **Inverse:** `TemplateSet.templateExercise`

### Split → SplitDay
- **Type:** One-to-Many
- **Delete Rule:** Cascade
- **Inverse:** `SplitDay.split`

### SplitDay ↔ WorkoutTemplate
- **Type:** Many-to-Many
- **Delete Rule:** Nullify
- **Inverse:** `WorkoutTemplate.splitDays`
- **Note:** A workout can be assigned to multiple split days, and a split day can have multiple workouts

### Workout → WorkoutTemplate
- **Type:** Many-to-One (optional)
- **Delete Rule:** Nullify

### Workout → LoggedExercise
- **Type:** One-to-Many
- **Delete Rule:** Cascade
- **Inverse:** `LoggedExercise.workout`

### LoggedExercise → Exercise
- **Type:** Many-to-One
- **Delete Rule:** Nullify

### LoggedExercise → LoggedSet
- **Type:** One-to-Many
- **Delete Rule:** Cascade
- **Inverse:** `LoggedSet.loggedExercise`
