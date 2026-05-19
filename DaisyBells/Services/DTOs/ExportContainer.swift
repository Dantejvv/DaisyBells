import Foundation

// MARK: - Top-Level Container

struct ExportContainer: Codable {
    let metadata: ExportMetadata
    let settings: SettingsExportDTO
    let categories: [CategoryExportDTO]
    let exercises: [ExerciseExportDTO]
    let templates: [TemplateExportDTO]
    let splits: [SplitExportDTO]
    let workouts: [WorkoutExportDTO]
}

// MARK: - Metadata

struct ExportMetadata: Codable {
    let exportDate: Date
    let appVersion: String
    let schemaVersion: String
}

// MARK: - Settings

struct SettingsExportDTO: Codable {
    let units: Units
    let distanceUnits: DistanceUnits
    let appearance: Appearance
}

// MARK: - Categories

struct CategoryExportDTO: Codable {
    let id: UUID
    let name: String
    let isDefault: Bool
    let order: Int
}

// MARK: - Exercises

struct ExerciseExportDTO: Codable {
    let id: UUID
    let name: String
    let type: ExerciseType
    let notes: String?
    let isFavorite: Bool
    let isArchived: Bool
    let createdAt: Date
    let preferredWeightUnit: Units?
    let preferredDistanceUnit: DistanceUnits?
    let categoryIds: [UUID]
}

// MARK: - Templates

struct TemplateExportDTO: Codable {
    let id: UUID
    let name: String
    let notes: String?
    let exercises: [TemplateExerciseExportDTO]
}

struct TemplateExerciseExportDTO: Codable {
    let id: UUID
    let order: Int
    let notes: String?
    let exerciseId: UUID?
    let sets: [TemplateSetExportDTO]
}

struct TemplateSetExportDTO: Codable {
    let id: UUID
    let order: Int
    let weight: Double?
    let reps: Int?
    let bodyweightModifier: Double?
    let time: TimeInterval?
    let distance: Double?
    let notes: String?
}

// MARK: - Splits

struct SplitExportDTO: Codable {
    let id: UUID
    let name: String
    let notes: String?
    let createdAt: Date
    let days: [SplitDayExportDTO]
}

struct SplitDayExportDTO: Codable {
    let id: UUID
    let name: String
    let order: Int
    let isCompletedInCycle: Bool
    let assignedWorkoutIds: [UUID]
}

// MARK: - Workouts

struct WorkoutExportDTO: Codable {
    let id: UUID
    let startedAt: Date
    let completedAt: Date?
    let statusValue: String
    let notes: String?
    let templateId: UUID?
    let exercises: [LoggedExerciseExportDTO]
}

struct LoggedExerciseExportDTO: Codable {
    let id: UUID
    let order: Int
    let notes: String?
    let exerciseId: UUID?
    let sets: [LoggedSetExportDTO]
}

struct LoggedSetExportDTO: Codable {
    let id: UUID
    let order: Int
    let weight: Double?
    let reps: Int?
    let bodyweightModifier: Double?
    let time: TimeInterval?
    let distance: Double?
    let notes: String?
    let isCompleted: Bool
    let weightUnit: String?
    let distanceUnit: String?
    let exerciseId: UUID?
    let completedAt: Date?
}
