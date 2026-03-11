import SwiftUI

struct EditableSetRow: View {
    let exerciseType: ExerciseType
    let setNumber: Int
    let badgeStyle: SetNumberBadge.Style
    var weightUnit: Units = .lbs
    var distanceUnit: DistanceUnits = .mi

    let weight: Double?
    let reps: Int?
    let bodyweightModifier: Double?
    let time: TimeInterval?
    let distance: Double?
    let notes: String?

    var previousWeight: Double?
    var previousReps: Int?
    var previousBodyweightModifier: Double?
    var previousTime: TimeInterval?
    var previousDistance: Double?
    var previousNotes: String?

    let onWeightChange: (Double?) -> Void
    let onRepsChange: (Int?) -> Void
    let onBodyweightModifierChange: (Double?) -> Void
    let onTimeChange: (Double?) -> Void
    let onDistanceChange: (Double?) -> Void
    let onNotesChange: (String?) -> Void

    var body: some View {
        HStack(spacing: 6) {
            SetNumberBadge(number: setNumber, style: badgeStyle)

            switch exerciseType {
            case .weightAndReps:
                EditableDualPill(
                    leftValue: weight,
                    rightValue: reps.map { Double($0) },
                    leftPlaceholder: previousWeight.map { String(format: "%g", $0) } ?? weightUnit.shortLabel.lowercased(),
                    rightPlaceholder: previousReps.map { "\($0)" } ?? "reps",
                    onLeftCommit: { onWeightChange($0) },
                    onRightCommit: { onRepsChange($0.map { Int($0) }) }
                )
            case .bodyweightAndReps:
                EditableDualPill(
                    leftValue: bodyweightModifier,
                    rightValue: reps.map { Double($0) },
                    leftPlaceholder: previousBodyweightModifier.map { String(format: "%+g", $0) } ?? "+/-",
                    rightPlaceholder: previousReps.map { "\($0)" } ?? "reps",
                    onLeftCommit: { onBodyweightModifierChange($0) },
                    onRightCommit: { onRepsChange($0.map { Int($0) }) }
                )
            case .distanceAndTime:
                EditableDualPill(
                    leftValue: distance,
                    rightValue: time,
                    leftPlaceholder: previousDistance.map { String(format: "%.1f", $0) } ?? distanceUnit.shortLabel.lowercased(),
                    rightPlaceholder: previousTime.map { $0.setDurationString } ?? "m:ss",
                    onLeftCommit: { onDistanceChange($0) },
                    onRightCommit: { onTimeChange($0) }
                )
            case .weightAndTime:
                EditableDualPill(
                    leftValue: weight,
                    rightValue: time,
                    leftPlaceholder: previousWeight.map { String(format: "%g", $0) } ?? weightUnit.shortLabel.lowercased(),
                    rightPlaceholder: previousTime.map { $0.setDurationString } ?? "m:ss",
                    onLeftCommit: { onWeightChange($0) },
                    onRightCommit: { onTimeChange($0) }
                )
            case .reps:
                EditableSinglePill(
                    value: reps.map { Double($0) },
                    placeholder: previousReps.map { "\($0)" } ?? "reps",
                    onCommit: { onRepsChange($0.map { Int($0) }) }
                )
            case .time:
                EditableSinglePill(
                    value: time,
                    placeholder: previousTime.map { $0.setDurationString } ?? "m:ss",
                    onCommit: { onTimeChange($0) }
                )
            }

            EditableNotesField(
                currentNotes: notes,
                previousNotes: previousNotes,
                onChange: onNotesChange
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }
}
