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

        @Relationship
        var categories: [ExerciseCategory]

        init(name: String, type: ExerciseType, notes: String? = nil) {
            self.id = UUID()
            self.name = name
            self.type = type
            self.notes = notes
            self.isFavorite = false
            self.isArchived = false
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
        var status: WorkoutStatus
        var startedAt: Date
        var completedAt: Date?
        var notes: String?

        @Relationship
        var fromTemplate: WorkoutTemplate?

        @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.workout)
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

        @Relationship
        var loggedExercise: LoggedExercise?

        init(order: Int) {
            self.id = UUID()
            self.order = order
        }
    }
}
