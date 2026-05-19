import Foundation

extension Double {

    /// Rounds to a specified number of decimal places
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }

    /// Rounds to the nearest increment (e.g., 0.5 for gym plate weights)
    func roundedToNearest(_ increment: Double) -> Double {
        (self / increment).rounded() * increment
    }

    // MARK: - Weight Formatting

    /// Formats weight with unit suffix (e.g., "135 lbs" or "61.2 kg")
    func weightString(units: Units) -> String {
        switch units {
        case .lbs:
            return self.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f lbs", self)
                : String(format: "%.1f lbs", self)
        case .kg:
            return String(format: "%.1f kg", self)
        }
    }

    // MARK: - Weight Conversion

    /// Converts from lbs to kg, rounded to nearest 0.5 kg
    var lbsToKg: Double {
        (self * 0.45359237).roundedToNearest(0.5)
    }

    /// Converts from kg to lbs, rounded to nearest 0.5 lbs
    var kgToLbs: Double {
        (self / 0.45359237).roundedToNearest(0.5)
    }

    /// Converts weight between unit systems
    func convert(from: Units, to: Units) -> Double {
        guard from != to else { return self }
        switch (from, to) {
        case (.lbs, .kg):
            return self.lbsToKg
        case (.kg, .lbs):
            return self.kgToLbs
        default:
            return self
        }
    }

    // MARK: - Distance Formatting

    /// Formats distance with unit suffix based on user preference (e.g., "3.2 mi" or "5.1 km")
    func distanceString(units: DistanceUnits) -> String {
        switch units {
        case .mi: String(format: "%.1f mi", self)
        case .km: String(format: "%.1f km", self)
        }
    }

    // MARK: - Distance Conversion

    /// Converts from miles to kilometers
    var milesToKm: Double {
        (self * 1.609344).rounded(toPlaces: 1)
    }

    /// Converts from kilometers to miles
    var kmToMiles: Double {
        (self / 1.609344).rounded(toPlaces: 1)
    }

    /// Converts distance between unit systems
    func convertDistance(from: DistanceUnits, to: DistanceUnits) -> Double {
        guard from != to else { return self }
        switch (from, to) {
        case (.mi, .km): return self.milesToKm
        case (.km, .mi): return self.kmToMiles
        default: return self
        }
    }

    // MARK: - Volume Formatting

    /// Formats total volume (weight * reps) with unit suffix
    func volumeString(units: Units) -> String {
        let formatted: String
        if self >= 1_000_000 {
            formatted = String(format: "%.1fM", self / 1_000_000)
        } else if self >= 1_000 {
            formatted = String(format: "%.1fK", self / 1_000)
        } else {
            formatted = String(format: "%.0f", self)
        }

        switch units {
        case .lbs:
            return "\(formatted) lbs"
        case .kg:
            return "\(formatted) kg"
        }
    }

    // MARK: - Bodyweight Modifier Formatting

    /// Formats bodyweight modifier with +/- prefix (e.g., "+45 lbs" or "-30 lbs")
    func bodyweightModifierString(units: Units) -> String {
        let prefix = self >= 0 ? "+" : ""
        switch units {
        case .lbs:
            return self.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%@%.0f lbs", prefix, self)
                : String(format: "%@%.1f lbs", prefix, self)
        case .kg:
            return String(format: "%@%.1f kg", prefix, self)
        }
    }
}

// MARK: - TimeInterval Extension

extension TimeInterval {

    /// Formats duration as "1h 30m" or "45m" or "30s"
    var durationString: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }

    /// Formats duration as "1:30:00" or "45:00" (HH:MM:SS or MM:SS)
    var timerString: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Formats duration for workout display (e.g., "1 hr 30 min")
    var workoutDurationString: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours) hr \(minutes) min"
        } else if hours > 0 {
            return "\(hours) hr"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "< 1 min"
        }
    }

    /// Formats duration compactly for set display (e.g., "1:30" for 90 seconds)
    var setDurationString: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Int Extension for Reps/Sets

extension Int {

    /// Formats reps compactly (e.g., "12")
    var repsCompactString: String {
        "\(self)"
    }
}
