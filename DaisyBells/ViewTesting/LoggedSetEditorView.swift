import SwiftUI

/// Dynamic input fields for logging a set based on exercise type
struct LoggedSetEditorView: View {
    let exerciseType: MockExerciseType
    let setNumber: Int

    @Binding var weight: Double?
    @Binding var reps: Int?
    @Binding var bodyweightModifier: Double?
    @Binding var time: TimeInterval?
    @Binding var distance: Double?

    var body: some View {
        HStack(spacing: 12) {
            // Set number indicator
            Text("\(setNumber)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            // Dynamic inputs based on exercise type
            switch exerciseType {
            case .weightAndReps:
                weightInput
                repsInput

            case .bodyweightAndReps:
                bodyweightModifierInput
                repsInput

            case .reps:
                repsInput
                Spacer()

            case .time:
                timeInput
                Spacer()

            case .distanceAndTime:
                distanceInput
                timeInput

            case .weightAndTime:
                weightInput
                timeInput
            }
        }
        .padding(.vertical, 8)
    }

    private var weightInput: some View {
        HStack(spacing: 4) {
            TextField("0", value: $weight, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
            Text("lbs")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var repsInput: some View {
        HStack(spacing: 4) {
            TextField("0", value: $reps, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 50)
            Text("reps")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var bodyweightModifierInput: some View {
        HStack(spacing: 4) {
            TextField("0", value: $bodyweightModifier, format: .number)
                .keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
            Text("%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var timeInput: some View {
        HStack(spacing: 4) {
            TextField("0", value: Binding(
                get: { (time ?? 0) / 60 },
                set: { time = $0 * 60 }
            ), format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 50)
            Text("min")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var distanceInput: some View {
        HStack(spacing: 4) {
            TextField("0", value: $distance, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
            Text("mi")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview Helper

private struct LoggedSetEditorPreview: View {
    @State private var weight: Double? = 135
    @State private var reps: Int? = 10
    @State private var bodyweightModifier: Double? = nil
    @State private var time: TimeInterval? = nil
    @State private var distance: Double? = nil

    let exerciseType: MockExerciseType

    var body: some View {
        LoggedSetEditorView(
            exerciseType: exerciseType,
            setNumber: 1,
            weight: $weight,
            reps: $reps,
            bodyweightModifier: $bodyweightModifier,
            time: $time,
            distance: $distance
        )
    }
}

#Preview("Weight & Reps") {
    VStack {
        LoggedSetEditorPreview(exerciseType: .weightAndReps)
        LoggedSetEditorPreview(exerciseType: .weightAndReps)
        LoggedSetEditorPreview(exerciseType: .weightAndReps)
    }
    .padding()
}

#Preview("Bodyweight & Reps") {
    VStack {
        LoggedSetEditorPreview(exerciseType: .bodyweightAndReps)
    }
    .padding()
}

#Preview("Reps Only") {
    VStack {
        LoggedSetEditorPreview(exerciseType: .reps)
    }
    .padding()
}

#Preview("Time") {
    VStack {
        LoggedSetEditorPreview(exerciseType: .time)
    }
    .padding()
}

#Preview("Distance & Time") {
    VStack {
        LoggedSetEditorPreview(exerciseType: .distanceAndTime)
    }
    .padding()
}

#Preview("Weight & Time") {
    VStack {
        LoggedSetEditorPreview(exerciseType: .weightAndTime)
    }
    .padding()
}
