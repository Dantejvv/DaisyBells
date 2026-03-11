import Foundation
import SwiftUI

enum ExerciseType: String, Codable, CaseIterable {
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

enum WorkoutStatus: String, Codable {
    case active
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .active: "Active"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        }
    }
}

enum Units: String, Codable, CaseIterable {
    case lbs
    case kg

    var displayName: String {
        switch self {
        case .lbs: "Pounds (lbs)"
        case .kg: "Kilograms (kg)"
        }
    }

    var shortLabel: String {
        switch self {
        case .lbs: "Lb"
        case .kg: "Kg"
        }
    }
}

enum DistanceUnits: String, Codable, CaseIterable {
    case mi
    case km

    var displayName: String {
        switch self {
        case .mi: "Miles (mi)"
        case .km: "Kilometers (km)"
        }
    }

    var shortLabel: String {
        switch self {
        case .mi: "Mi"
        case .km: "Km"
        }
    }
}

enum Appearance: String, Codable, CaseIterable {
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

    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}

enum ExerciseSortOption: String, Codable, CaseIterable {
    case alphabetical
    case creationDate
    case favoritesFirst

    var displayName: String {
        switch self {
        case .alphabetical: "Alphabetical"
        case .creationDate: "Creation Date"
        case .favoritesFirst: "Favorites First"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .alphabetical: "Abc"
        case .creationDate: "Date"
        case .favoritesFirst: "Fav"
        }
    }

    var iconName: String {
        switch self {
        case .alphabetical: "textformat.abc"
        case .creationDate: "calendar.badge.plus"
        case .favoritesFirst: "star"
        }
    }
}
