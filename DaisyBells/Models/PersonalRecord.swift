import Foundation

struct PersonalRecord: Identifiable, Sendable {
    let id: UUID
    let exerciseId: UUID
    let exerciseName: String
    let exerciseType: ExerciseType
    let achievedAt: Date
    let weight: Double?
    let reps: Int?
    let time: TimeInterval?
    let distance: Double?
    let bodyweightModifier: Double?
    let weightUnit: Units?
    let distanceUnit: DistanceUnits?

    func displayValue(displayWeightUnit: Units, displayDistanceUnit: DistanceUnits) -> String {
        let wUnit = weightUnit ?? displayWeightUnit
        let dUnit = distanceUnit ?? displayDistanceUnit

        switch exerciseType {
        case .weightAndReps:
            if let weight, let reps {
                let converted = weight.convert(from: wUnit, to: displayWeightUnit)
                return converted.weightString(units: displayWeightUnit) + " x \(reps)"
            }
            return "—"

        case .bodyweightAndReps:
            if let reps {
                if let modifier = bodyweightModifier, modifier != 0 {
                    let converted = modifier.convert(from: wUnit, to: displayWeightUnit)
                    return "\(reps) reps (\(converted.bodyweightModifierString(units: displayWeightUnit)))"
                }
                return "\(reps) reps"
            }
            return "—"

        case .reps:
            if let reps {
                return "\(reps) reps"
            }
            return "—"

        case .time:
            if let time {
                return formatTime(time)
            }
            return "—"

        case .distanceAndTime:
            var parts: [String] = []
            if let distance {
                let fromUnit = dUnit
                let converted = distance.convertDistance(from: fromUnit, to: displayDistanceUnit)
                parts.append(converted.distanceString(units: displayDistanceUnit))
            }
            if let time {
                parts.append(formatTime(time))
            }
            return parts.isEmpty ? "—" : parts.joined(separator: " in ")

        case .weightAndTime:
            var parts: [String] = []
            if let weight {
                let converted = weight.convert(from: wUnit, to: displayWeightUnit)
                parts.append(converted.weightString(units: displayWeightUnit))
            }
            if let time {
                parts.append(formatTime(time))
            }
            return parts.isEmpty ? "—" : parts.joined(separator: " for ")
        }
    }

    var estimated1RM: Double? {
        guard exerciseType == .weightAndReps,
              let weight,
              let reps,
              reps > 0 else {
            return nil
        }
        return weight * (1 + Double(reps) / 30.0)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}
