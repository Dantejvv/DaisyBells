import Foundation

struct DraftTemplateExercise: Identifiable {
    let id: UUID
    let exerciseId: UUID
    let exerciseName: String
    let exerciseType: ExerciseType
    var exerciseNotes: String?
    var notes: String?
    var order: Int
    var sets: [DraftTemplateSet]

    init(id: UUID = UUID(), exerciseId: UUID, exerciseName: String, exerciseType: ExerciseType, exerciseNotes: String? = nil, notes: String? = nil, order: Int, sets: [DraftTemplateSet] = []) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.exerciseType = exerciseType
        self.exerciseNotes = exerciseNotes
        self.notes = notes
        self.order = order
        self.sets = sets
    }
}

struct DraftTemplateSet: Identifiable {
    let id: UUID
    var order: Int
    var weight: Double?
    var reps: Int?
    var bodyweightModifier: Double?
    var time: TimeInterval?
    var distance: Double?
    var notes: String?

    init(id: UUID = UUID(), order: Int, weight: Double? = nil, reps: Int? = nil, bodyweightModifier: Double? = nil, time: TimeInterval? = nil, distance: Double? = nil, notes: String? = nil) {
        self.id = id
        self.order = order
        self.weight = weight
        self.reps = reps
        self.bodyweightModifier = bodyweightModifier
        self.time = time
        self.distance = distance
        self.notes = notes
    }
}
