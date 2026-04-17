import Foundation

extension SchemaV1.Exercise {
    static func estimated1RM(weight: Double?, reps: Int?) -> Double? {
        guard let weight, let reps, reps > 0 else { return nil }
        return weight * (1 + Double(reps) / 30.0)
    }

    func shouldUpdatePR(with set: SchemaV1.LoggedSet) -> Bool {
        switch type {
        case .weightAndReps:
            guard let newEstimate = Self.estimated1RM(weight: set.weight, reps: set.reps) else { return false }
            let existing = normalizedExistingPR1RM(setUnit: set.resolvedWeightUnit)
            return newEstimate > existing

        case .bodyweightAndReps, .reps:
            guard let newReps = set.reps else { return false }
            return newReps > (prReps ?? 0)

        case .time, .weightAndTime:
            guard let newTime = set.time else { return false }
            return newTime > (prTime ?? 0)

        case .distanceAndTime:
            guard let newDistance = set.distance else { return false }
            if let setUnit = set.resolvedDistanceUnit,
               let prUnit = resolvedPrDistanceUnit,
               let prDistance = prDistance,
               setUnit != prUnit {
                return newDistance > prDistance.convertDistance(from: prUnit, to: setUnit)
            }
            return newDistance > (prDistance ?? 0)
        }
    }

    func applyPR(from set: SchemaV1.LoggedSet, completedAt: Date) {
        prWeight = set.weight
        prReps = set.reps
        prTime = set.time
        prDistance = set.distance
        prBodyweightModifier = set.bodyweightModifier
        prAchievedAt = completedAt
        prEstimated1RM = Self.estimated1RM(weight: set.weight, reps: set.reps)
        prWeightUnit = set.weightUnit
        prDistanceUnit = set.distanceUnit
    }

    func resetPRCache() {
        prWeight = nil
        prReps = nil
        prTime = nil
        prDistance = nil
        prBodyweightModifier = nil
        prEstimated1RM = nil
        prAchievedAt = nil
        prWeightUnit = nil
        prDistanceUnit = nil
    }

    private func normalizedExistingPR1RM(setUnit: Units?) -> Double {
        guard let existing = prEstimated1RM else { return 0 }
        guard let setUnit, let prUnit = resolvedPrWeightUnit, setUnit != prUnit else {
            return existing
        }
        return existing.convert(from: prUnit, to: setUnit)
    }
}
