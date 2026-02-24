import SwiftUI

struct ReadOnlySetRow: View {
    let exerciseType: ExerciseType
    let setNumber: Int
    let badgeStyle: SetNumberBadge.Style
    var weight: Double?
    var reps: Int?
    var bodyweightModifier: Double?
    var time: TimeInterval?
    var distance: Double?
    var notes: String?

    var body: some View {
        HStack(spacing: 6) {
            SetNumberBadge(number: setNumber, style: badgeStyle)

            switch exerciseType {
            case .weightAndReps:
                ReadOnlyDualPill(
                    left: weight.map { String(format: "%g", $0) } ?? "-",
                    right: reps.map { "\($0)" } ?? "-"
                )
            case .bodyweightAndReps:
                ReadOnlyDualPill(
                    left: bodyweightModifier.map { String(format: "%+g", $0) } ?? "-",
                    right: reps.map { "\($0)" } ?? "-"
                )
            case .distanceAndTime:
                ReadOnlyDualPill(
                    left: distance.map { String(format: "%.1f", $0) } ?? "-",
                    right: time.map { $0.setDurationString } ?? "-"
                )
            case .weightAndTime:
                ReadOnlyDualPill(
                    left: weight.map { String(format: "%g", $0) } ?? "-",
                    right: time.map { $0.setDurationString } ?? "-"
                )
            case .reps:
                ReadOnlySinglePill(value: reps.map { "\($0)" } ?? "-")
            case .time:
                ReadOnlySinglePill(value: time.map { $0.setDurationString } ?? "-")
            }

            if let notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Color.clear
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }
}
