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

    var displayValue: String {
        switch exerciseType {
        case .weightAndReps:
            if let weight, let reps {
                return "\(Int(weight)) lbs x \(reps)"
            }
            return "—"

        case .bodyweightAndReps:
            if let reps {
                if let modifier = bodyweightModifier, modifier != 0 {
                    let sign = modifier > 0 ? "+" : ""
                    return "\(reps) reps (\(sign)\(Int(modifier)) lbs)"
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
                parts.append(String(format: "%.2f mi", distance))
            }
            if let time {
                parts.append(formatTime(time))
            }
            return parts.isEmpty ? "—" : parts.joined(separator: " in ")

        case .weightAndTime:
            var parts: [String] = []
            if let weight {
                parts.append("\(Int(weight)) lbs")
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
