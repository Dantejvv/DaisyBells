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

        @Relationship(inverse: \Exercise.categories)
        var exercises: [Exercise]

        init(name: String, isDefault: Bool = false) {
            self.id = UUID()
            self.name = name
            self.isDefault = isDefault
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

        // Cached statistics (updated on workout completion)
        var lastPerformedAt: Date?
        var hasCompletedWorkout: Bool
        var totalVolume: Double

        // Personal record cache
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
            self.prWeight = nil
            self.prReps = nil
            self.prTime = nil
            self.prDistance = nil
            self.prEstimated1RM = nil
            self.prAchievedAt = nil
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

        init(name: String, notes: String? = nil) {
            self.id = UUID()
            self.name = name
            self.notes = notes
            self.templateExercises = []
        }
    }

    @Model
    final class TemplateExercise {
        @Attribute(.unique) var id: UUID
        var order: Int
        var targetSets: Int?
        var targetReps: Int?

        @Relationship
        var exercise: Exercise?

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

    @Model
    final class Workout {
        @Attribute(.unique) var id: UUID
        var startedAt: Date
        var completedAt: Date?
        var notes: String?

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
