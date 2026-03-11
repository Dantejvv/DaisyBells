import SwiftUI

struct SetColumnHeaders: View {
    let exerciseType: ExerciseType
    var showCheckColumn: Bool = false
    var weightUnit: Units = .lbs
    var distanceUnit: DistanceUnits = .mi

    var body: some View {
        HStack(spacing: 6) {
            Text("Set")
                .frame(width: 22)

            switch exerciseType {
            case .weightAndReps:
                dualColumnLabel(weightUnit.shortLabel, "Reps")
            case .bodyweightAndReps:
                dualColumnLabel("+/- \(weightUnit.shortLabel)", "Reps")
            case .distanceAndTime:
                dualColumnLabel(distanceUnit.shortLabel, "Time")
            case .weightAndTime:
                dualColumnLabel(weightUnit.shortLabel, "Time")
            case .reps:
                Text("Reps")
                    .frame(width: 46)
            case .time:
                Text("Time")
                    .frame(width: 46)
            }

            Text("Notes")
                .frame(maxWidth: .infinity)

            if showCheckColumn {
                Color.clear
                    .frame(width: 22)
            }
        }
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(Color.textTertiary)
        .textCase(.uppercase)
        .padding(.horizontal, 14)
        .padding(.vertical, .spacingXs)
    }

    private func dualColumnLabel(_ left: String, _ right: String) -> some View {
        HStack(spacing: 0) {
            Text(left)
                .frame(maxWidth: .infinity)
            Text(right)
                .frame(maxWidth: .infinity)
        }
        .frame(width: 94)
    }
}
