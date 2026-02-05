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
    @Binding var notes: String

    var body: some View {
        HStack(spacing: 16) {
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

            case .time:
                timeInput

            case .distanceAndTime:
                distanceInput
                timeInput

            case .weightAndTime:
                weightInput
                timeInput
            }

            // Notes input - expands vertically
            notesInput
        }
        .padding(.vertical, 4)
    }

    private var notesInput: some View {
        VStack(alignment: .center, spacing: 2) {
            Text("note")
                .font(.caption2)
                .foregroundStyle(.secondary)
            TextField("", text: $notes, axis: .vertical)
                .lineLimit(1...3)
                .padding(6)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var weightInput: some View {
        VStack(alignment: .center, spacing: 2) {
            Text("lbs")
                .font(.caption2)
                .foregroundStyle(.secondary)
            TextField("0", value: $weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 40)
                .padding(6)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var repsInput: some View {
        VStack(alignment: .center, spacing: 2) {
            Text("reps")
                .font(.caption2)
                .foregroundStyle(.secondary)
            TextField("0", value: $reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 40)
                .padding(6)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var bodyweightModifierInput: some View {
        VStack(alignment: .center, spacing: 2) {
            Text("+/- lbs")
                .font(.caption2)
                .foregroundStyle(.secondary)
            TextField("0", text: Binding(
                get: {
                    guard let value = bodyweightModifier else { return "" }
                    if value > 0 {
                        return "+\(Int(value))"
                    } else if value < 0 {
                        return "\(Int(value))"
                    } else {
                        return "0"
                    }
                },
                set: { newValue in
                    let cleaned = newValue.trimmingCharacters(in: .whitespaces)
                    if cleaned.isEmpty {
                        bodyweightModifier = nil
                    } else if let parsed = Double(cleaned) {
                        bodyweightModifier = parsed
                    }
                }
            ))
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.center)
                .frame(width: 50)
                .padding(6)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var timeInput: some View {
        VStack(alignment: .center, spacing: 2) {
            Text("min")
                .font(.caption2)
                .foregroundStyle(.secondary)
            TextField("0", value: Binding(
                get: { (time ?? 0) / 60 },
                set: { time = $0 * 60 }
            ), format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 40)
                .padding(6)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var distanceInput: some View {
        VStack(alignment: .center, spacing: 2) {
            Text("mi")
                .font(.caption2)
                .foregroundStyle(.secondary)
            TextField("0", value: $distance, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 40)
                .padding(6)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 6))
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
    @State private var notes: String = ""

    let exerciseType: MockExerciseType

    var body: some View {
        LoggedSetEditorView(
            exerciseType: exerciseType,
            setNumber: 1,
            weight: $weight,
            reps: $reps,
            bodyweightModifier: $bodyweightModifier,
            time: $time,
            distance: $distance,
            notes: $notes
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
