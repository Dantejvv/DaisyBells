import Foundation

extension SchemaV1.Exercise {
    func resolvedWeightUnit(default fallback: Units) -> Units {
        preferredWeightUnit ?? fallback
    }

    func resolvedDistanceUnit(default fallback: DistanceUnits) -> DistanceUnits {
        preferredDistanceUnit ?? fallback
    }
}
