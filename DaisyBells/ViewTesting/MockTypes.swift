import SwiftUI

// MARK: - Enums

enum MockExerciseType: String, CaseIterable {
    case weightAndReps
    case bodyweightAndReps
    case reps
    case time
    case distanceAndTime
    case weightAndTime

    var displayName: String {
        switch self {
        case .weightAndReps: "Weight & Reps"
        case .bodyweightAndReps: "Bodyweight & Reps"
        case .reps: "Reps Only"
        case .time: "Time"
        case .distanceAndTime: "Distance & Time"
        case .weightAndTime: "Weight & Time"
        }
    }
}

enum MockUnits: String, CaseIterable {
    case lbs
    case kg

    var displayName: String {
        switch self {
        case .lbs: "Pounds (lbs)"
        case .kg: "Kilograms (kg)"
        }
    }
}

enum MockAppearance: String, CaseIterable {
    case light
    case dark
    case system

    var displayName: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .system: "System"
        }
    }
}

// MARK: - Library Models

struct MockCategory: Identifiable {
    let id = UUID()
    var name: String
    var isDefault: Bool
    var exerciseCount: Int

    init(name: String, isDefault: Bool = false, exerciseCount: Int = 0) {
        self.name = name
        self.isDefault = isDefault
        self.exerciseCount = exerciseCount
    }
}

struct MockExercise: Identifiable {
    let id = UUID()
    var name: String
    var type: MockExerciseType
    var notes: String?
    var isFavorite: Bool
    var isArchived: Bool
    var categoryNames: [String]

    init(
        name: String,
        type: MockExerciseType,
        notes: String? = nil,
        isFavorite: Bool = false,
        isArchived: Bool = false,
        categoryNames: [String] = []
    ) {
        self.name = name
        self.type = type
        self.notes = notes
        self.isFavorite = isFavorite
        self.isArchived = isArchived
        self.categoryNames = categoryNames
    }
}

// MARK: - Template Models

struct MockTemplate: Identifiable {
    let id = UUID()
    var name: String
    var notes: String?
    var exerciseCount: Int
    var exercises: [MockTemplateExercise]

    init(name: String, notes: String? = nil, exercises: [MockTemplateExercise] = []) {
        self.name = name
        self.notes = notes
        self.exercises = exercises
        self.exerciseCount = exercises.count
    }
}

struct MockTemplateExercise: Identifiable {
    let id = UUID()
    var exerciseName: String
    var exerciseType: MockExerciseType
    var order: Int
    var targetSets: Int?
    var targetReps: Int?
}

// MARK: - Workout Logging Models

struct MockLoggedExercise: Identifiable {
    let id = UUID()
    var exerciseName: String
    var exerciseType: MockExerciseType
    var order: Int
    var notes: String = ""
    var sets: [MockLoggedSet]
}

struct MockLoggedSet: Identifiable {
    let id = UUID()
    var order: Int
    var weight: Double?
    var reps: Int?
    var bodyweightModifier: Double?
    var time: TimeInterval?
    var distance: Double?
}

// MARK: - History Models

struct MockCompletedWorkout: Identifiable {
    let id = UUID()
    var name: String
    var completedAt: Date
    var duration: TimeInterval
    var notes: String?
    var exerciseCount: Int
    var totalSets: Int
    var exercises: [MockCompletedExercise]
}

struct MockCompletedExercise: Identifiable {
    let id = UUID()
    var exerciseName: String
    var exerciseType: MockExerciseType
    var sets: [MockCompletedSet]
}

struct MockCompletedSet: Identifiable {
    let id = UUID()
    var order: Int
    var weight: Double?
    var reps: Int?
    var bodyweightModifier: Double?
    var time: TimeInterval?
    var distance: Double?
}

// MARK: - Analytics Models

struct MockPersonalRecord: Identifiable {
    let id = UUID()
    var exerciseName: String
    var value: String
    var date: Date
}

struct MockRecentExercise: Identifiable {
    let id = UUID()
    var name: String
    var type: MockExerciseType
    var lastPerformed: Date
    var lastPerformance: String
    var timesPerformed: Int
    var totalVolume: Double?
    var personalBest: String?
}

// MARK: - Mock Data

enum MockData {
    static var categories: [MockCategory] = [
        MockCategory(name: "Upper Body", isDefault: true, exerciseCount: 12),
        MockCategory(name: "Lower Body", isDefault: true, exerciseCount: 8),
        MockCategory(name: "Core", isDefault: true, exerciseCount: 6),
        MockCategory(name: "Cardio", isDefault: false, exerciseCount: 4),
        MockCategory(name: "Olympic Lifts", isDefault: false, exerciseCount: 3),
    ]
}

enum MockExerciseData {
    static var exercises: [MockExercise] = [
        MockExercise(name: "Bench Press", type: .weightAndReps, notes: "Keep shoulders back and down. Arch back slightly.", isFavorite: true, categoryNames: ["Upper Body"]),
        MockExercise(name: "Squat", type: .weightAndReps, notes: "Break at hips first. Keep knees tracking over toes.", isFavorite: true, categoryNames: ["Lower Body"]),
        MockExercise(name: "Deadlift", type: .weightAndReps, notes: "Keep bar close to body. Neutral spine throughout.", isFavorite: true, categoryNames: ["Lower Body"]),
        MockExercise(name: "Pull-ups", type: .bodyweightAndReps, notes: "Full extension at bottom. Chin over bar at top.", categoryNames: ["Upper Body"]),
        MockExercise(name: "Dips", type: .bodyweightAndReps, categoryNames: ["Upper Body"]),
        MockExercise(name: "Box Jumps", type: .reps, categoryNames: ["Lower Body"]),
        MockExercise(name: "Plank", type: .time, notes: "Keep body in straight line. Don't let hips sag.", categoryNames: ["Core"]),
        MockExercise(name: "Running", type: .distanceAndTime, categoryNames: ["Cardio"]),
        MockExercise(name: "Farmer's Carry", type: .weightAndTime, categoryNames: ["Core", "Upper Body"]),
        MockExercise(name: "Overhead Press", type: .weightAndReps, categoryNames: ["Upper Body"]),
        MockExercise(name: "Barbell Row", type: .weightAndReps, isFavorite: true, categoryNames: ["Upper Body"]),
        MockExercise(name: "Leg Press", type: .weightAndReps, isArchived: true, categoryNames: ["Lower Body"]),
    ]
}

enum MockTemplateData {
    static var templates: [MockTemplate] = [
        MockTemplate(
            name: "Push Day",
            notes: "Chest, shoulders, triceps",
            exercises: [
                MockTemplateExercise(exerciseName: "Bench Press", exerciseType: .weightAndReps, order: 0, targetSets: 4, targetReps: 8),
                MockTemplateExercise(exerciseName: "Overhead Press", exerciseType: .weightAndReps, order: 1, targetSets: 3, targetReps: 10),
                MockTemplateExercise(exerciseName: "Dips", exerciseType: .bodyweightAndReps, order: 2, targetSets: 3, targetReps: 12),
            ]
        ),
        MockTemplate(
            name: "Pull Day",
            notes: "Back, biceps",
            exercises: [
                MockTemplateExercise(exerciseName: "Deadlift", exerciseType: .weightAndReps, order: 0, targetSets: 3, targetReps: 5),
                MockTemplateExercise(exerciseName: "Pull-ups", exerciseType: .bodyweightAndReps, order: 1, targetSets: 4, targetReps: 8),
                MockTemplateExercise(exerciseName: "Barbell Row", exerciseType: .weightAndReps, order: 2, targetSets: 3, targetReps: 10),
            ]
        ),
        MockTemplate(
            name: "Leg Day",
            exercises: [
                MockTemplateExercise(exerciseName: "Squat", exerciseType: .weightAndReps, order: 0, targetSets: 4, targetReps: 6),
                MockTemplateExercise(exerciseName: "Box Jumps", exerciseType: .reps, order: 1, targetSets: 3, targetReps: 10),
            ]
        ),
        MockTemplate(
            name: "Core & Cardio",
            notes: "Light day",
            exercises: [
                MockTemplateExercise(exerciseName: "Plank", exerciseType: .time, order: 0, targetSets: 3),
                MockTemplateExercise(exerciseName: "Running", exerciseType: .distanceAndTime, order: 1, targetSets: 1),
            ]
        ),
    ]
}

enum MockWorkoutHistory {
    static var workouts: [MockCompletedWorkout] = [
        MockCompletedWorkout(
            name: "Push Day",
            completedAt: Date(),
            duration: 3600,
            notes: "Felt strong today. Increased bench by 5 lbs.",
            exerciseCount: 4,
            totalSets: 14,
            exercises: [
                MockCompletedExercise(
                    exerciseName: "Bench Press",
                    exerciseType: .weightAndReps,
                    sets: [
                        MockCompletedSet(order: 0, weight: 185, reps: 8),
                        MockCompletedSet(order: 1, weight: 185, reps: 8),
                        MockCompletedSet(order: 2, weight: 185, reps: 7),
                        MockCompletedSet(order: 3, weight: 185, reps: 6),
                    ]
                ),
                MockCompletedExercise(
                    exerciseName: "Overhead Press",
                    exerciseType: .weightAndReps,
                    sets: [
                        MockCompletedSet(order: 0, weight: 95, reps: 10),
                        MockCompletedSet(order: 1, weight: 95, reps: 10),
                        MockCompletedSet(order: 2, weight: 95, reps: 8),
                    ]
                ),
            ]
        ),
        MockCompletedWorkout(
            name: "Pull Day",
            completedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            duration: 4200,
            exerciseCount: 5,
            totalSets: 16,
            exercises: []
        ),
        MockCompletedWorkout(
            name: "Leg Day",
            completedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            duration: 3900,
            exerciseCount: 4,
            totalSets: 12,
            exercises: []
        ),
        MockCompletedWorkout(
            name: "Push Day",
            completedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            duration: 3300,
            exerciseCount: 4,
            totalSets: 14,
            exercises: []
        ),
        MockCompletedWorkout(
            name: "Full Body",
            completedAt: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            duration: 4500,
            exerciseCount: 6,
            totalSets: 18,
            exercises: []
        ),
    ]
}

enum MockAnalyticsData {
    static var personalRecords: [MockPersonalRecord] = [
        MockPersonalRecord(exerciseName: "Bench Press", value: "225 lbs × 5", date: Date()),
        MockPersonalRecord(exerciseName: "Squat", value: "315 lbs × 3", date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
        MockPersonalRecord(exerciseName: "Deadlift", value: "405 lbs × 1", date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!),
        MockPersonalRecord(exerciseName: "Pull-ups", value: "15 reps", date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!),
    ]

    static var recentExercises: [MockRecentExercise] = [
        MockRecentExercise(name: "Bench Press", type: .weightAndReps, lastPerformed: Date(), lastPerformance: "185 × 8", timesPerformed: 24, totalVolume: 45000, personalBest: "225 × 5"),
        MockRecentExercise(name: "Squat", type: .weightAndReps, lastPerformed: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, lastPerformance: "275 × 6", timesPerformed: 18, totalVolume: 62000, personalBest: "315 × 3"),
        MockRecentExercise(name: "Pull-ups", type: .bodyweightAndReps, lastPerformed: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, lastPerformance: "12 reps", timesPerformed: 30, personalBest: "15 reps"),
        MockRecentExercise(name: "Plank", type: .time, lastPerformed: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, lastPerformance: "1:30", timesPerformed: 15, personalBest: "2:00"),
        MockRecentExercise(name: "Running", type: .distanceAndTime, lastPerformed: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, lastPerformance: "3.1 mi", timesPerformed: 8, personalBest: "5K in 24:30"),
    ]
}
