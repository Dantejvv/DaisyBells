import Foundation

enum ExerciseType: String, Codable, CaseIterable {
    case weightAndReps
    case bodyweightAndReps
    case reps
    case time
    case distanceAndTime
    case weightAndTime
}

enum WorkoutStatus: String, Codable {
    case active
    case completed
    case cancelled
}

enum Units: String, Codable, CaseIterable {
    case lbs
    case kg
}

enum Appearance: String, Codable, CaseIterable {
    case light
    case dark
    case system
}
