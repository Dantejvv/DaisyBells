import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            ExerciseCategory.self,
            Exercise.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            TemplateSet.self,
            Split.self,
            SplitDay.self,
            Workout.self,
            LoggedExercise.self,
            LoggedSet.self
        ]
    }

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

        // Cached statistics (updated on workout completion)
        var lastPerformedAt: Date?
        var hasCompletedWorkout: Bool
        var totalVolume: Double

        // Personal record cache
        var prWeight: Double?
        var prReps: Int?
        var prTime: TimeInterval?
        var prDistance: Double?
        var prBodyweightModifier: Double?
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
            self.prWeight = nil
            self.prReps = nil
            self.prTime = nil
            self.prDistance = nil
            self.prEstimated1RM = nil
            self.prAchievedAt = nil
            self.totalVolumeUnit = nil
            self.prWeightUnit = nil
            self.prDistanceUnit = nil
            self.categories = []
        }
    }

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

    @Model
    final class Workout {
        @Attribute(.unique) var id: UUID
        var startedAt: Date
        var completedAt: Date?

        // Store as raw string for predicate support (internal for predicate access)
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
        var bodyweightModifier: Double?
        var time: TimeInterval?
        var distance: Double?
        var notes: String?
        var isCompleted: Bool = false

        // Unit tracking (stamped at creation time)
        var weightUnit: String?    // Units.rawValue ("lbs"/"kg")
        var distanceUnit: String?  // DistanceUnits.rawValue ("mi"/"km")

        var resolvedWeightUnit: Units? { weightUnit.flatMap { Units(rawValue: $0) } }
        var resolvedDistanceUnit: DistanceUnits? { distanceUnit.flatMap { DistanceUnits(rawValue: $0) } }

        // Denormalized for direct queries (set on workout completion)
        var exerciseId: UUID?
        var completedAt: Date?

        @Relationship
        var loggedExercise: LoggedExercise?

        init(order: Int) {
            self.id = UUID()
            self.order = order
            self.exerciseId = nil
            self.completedAt = nil
        }
    }
}
