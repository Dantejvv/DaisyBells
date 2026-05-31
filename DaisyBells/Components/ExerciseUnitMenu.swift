import SwiftUI

@MainActor
struct ExerciseUnitMenu: View {
    let exerciseType: ExerciseType
    let currentWeightUnit: Units
    let currentDistanceUnit: DistanceUnits
    let defaultWeightUnit: Units
    let defaultDistanceUnit: DistanceUnits
    let onWeightUnitChange: (Units?) -> Void
    let onDistanceUnitChange: (DistanceUnits?) -> Void

    var body: some View {
        switch exerciseType {
        case .weightAndReps, .bodyweightAndReps, .weightAndTime:
            Picker("Weight Unit", selection: Binding(
                get: { currentWeightUnit },
                set: { newUnit in
                    onWeightUnitChange(newUnit == defaultWeightUnit ? nil : newUnit)
                }
            )) {
                ForEach(Units.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            .pickerStyle(.inline)
        case .distanceAndTime:
            Picker("Distance Unit", selection: Binding(
                get: { currentDistanceUnit },
                set: { newUnit in
                    onDistanceUnitChange(newUnit == defaultDistanceUnit ? nil : newUnit)
                }
            )) {
                ForEach(DistanceUnits.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            .pickerStyle(.inline)
        case .reps, .time:
            EmptyView()
        }
    }
}
