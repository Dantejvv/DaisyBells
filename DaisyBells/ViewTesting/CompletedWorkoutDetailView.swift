import SwiftUI

/// Read-only view of a completed workout
struct CompletedWorkoutDetailView: View {
    let workout: MockCompletedWorkout

    @Environment(\.dismiss) private var dismiss
    @State private var notes: String
    @State private var deleteConfig: ConfirmationDialogConfig?

    init(workout: MockCompletedWorkout) {
        self.workout = workout
        _notes = State(initialValue: workout.notes ?? "")
    }

    var body: some View {
        List {
            // Summary section
            Section {
                SummaryRow(label: "Date", value: formattedDate)
                SummaryRow(label: "Duration", value: formattedDuration)
                SummaryRow(label: "Exercises", value: "\(workout.exerciseCount)")
                SummaryRow(label: "Total Sets", value: "\(workout.totalSets)")
            }

            // Exercises section
            if !workout.exercises.isEmpty {
                ForEach(workout.exercises) { exercise in
                    Section(exercise.exerciseName) {
                        // Column headers
                        columnHeaders(for: exercise.exerciseType)
                            .listRowBackground(Color.clear)

                        ForEach(exercise.sets) { set in
                            setRow(set: set, exerciseType: exercise.exerciseType)
                        }
                    }
                }
            }

            // Notes section
            Section("Notes") {
                if notes.isEmpty {
                    Text("No notes")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    Text(notes)
                }
            }

            // Delete section
            Section {
                Button(role: .destructive) {
                    deleteConfig = ConfirmationDialogConfig(
                        title: "Delete Workout?",
                        message: "This workout will be permanently deleted from your history.",
                        confirmTitle: "Delete"
                    ) {
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Workout")
                    }
                }
            }
        }
        .navigationTitle(workout.name)
        .confirmationDialog($deleteConfig)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: workout.completedAt)
    }

    private var formattedDuration: String {
        let hours = Int(workout.duration) / 3600
        let minutes = (Int(workout.duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }

    @ViewBuilder
    private func columnHeaders(for type: MockExerciseType) -> some View {
        HStack {
            Text("SET")
                .frame(width: 40, alignment: .leading)

            switch type {
            case .weightAndReps:
                Text("WEIGHT")
                Spacer()
                Text("REPS")
                    .frame(width: 50, alignment: .trailing)

            case .bodyweightAndReps:
                Text("MOD")
                Spacer()
                Text("REPS")
                    .frame(width: 50, alignment: .trailing)

            case .reps:
                Spacer()
                Text("REPS")
                    .frame(width: 50, alignment: .trailing)

            case .time:
                Spacer()
                Text("TIME")
                    .frame(width: 80, alignment: .trailing)

            case .distanceAndTime:
                Text("DIST")
                Spacer()
                Text("TIME")
                    .frame(width: 80, alignment: .trailing)

            case .weightAndTime:
                Text("WEIGHT")
                Spacer()
                Text("TIME")
                    .frame(width: 80, alignment: .trailing)
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func setRow(set: MockCompletedSet, exerciseType: MockExerciseType) -> some View {
        HStack {
            Text("\(set.order + 1)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)

            switch exerciseType {
            case .weightAndReps:
                Text("\(Int(set.weight ?? 0)) lbs")
                Spacer()
                Text("\(set.reps ?? 0)")
                    .fontWeight(.medium)
                    .frame(width: 50, alignment: .trailing)

            case .bodyweightAndReps:
                if let mod = set.bodyweightModifier {
                    Text(mod >= 0 ? "+\(Int(mod))%" : "\(Int(mod))%")
                } else {
                    Text("BW")
                }
                Spacer()
                Text("\(set.reps ?? 0)")
                    .fontWeight(.medium)
                    .frame(width: 50, alignment: .trailing)

            case .reps:
                Spacer()
                Text("\(set.reps ?? 0)")
                    .fontWeight(.medium)
                    .frame(width: 50, alignment: .trailing)

            case .time:
                Spacer()
                Text(formatTime(set.time ?? 0))
                    .fontWeight(.medium)
                    .frame(width: 80, alignment: .trailing)

            case .distanceAndTime:
                Text(String(format: "%.2f mi", set.distance ?? 0))
                Spacer()
                Text(formatTime(set.time ?? 0))
                    .fontWeight(.medium)
                    .frame(width: 80, alignment: .trailing)

            case .weightAndTime:
                Text("\(Int(set.weight ?? 0)) lbs")
                Spacer()
                Text(formatTime(set.time ?? 0))
                    .fontWeight(.medium)
                    .frame(width: 80, alignment: .trailing)
            }
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}

#Preview("Full Workout") {
    NavigationStack {
        CompletedWorkoutDetailView(
            workout: MockCompletedWorkout(
                name: "Push Day",
                completedAt: Date(),
                duration: 3600,
                notes: "Felt strong today. Increased bench by 5 lbs. Good pump on triceps.",
                exerciseCount: 3,
                totalSets: 10,
                exercises: [
                    MockCompletedExercise(
                        exerciseName: "Bench Press",
                        exerciseType: .weightAndReps,
                        sets: [
                            MockCompletedSet(order: 0, weight: 185, reps: 8),
                            MockCompletedSet(order: 1, weight: 185, reps: 8),
                            MockCompletedSet(order: 2, weight: 185, reps: 7),
                            MockCompletedSet(order: 3, weight: 185, reps: 6),
                        ]
                    ),
                    MockCompletedExercise(
                        exerciseName: "Dips",
                        exerciseType: .bodyweightAndReps,
                        sets: [
                            MockCompletedSet(order: 0, reps: 15),
                            MockCompletedSet(order: 1, reps: 10, bodyweightModifier: 25),
                            MockCompletedSet(order: 2, reps: 8, bodyweightModifier: 25),
                        ]
                    ),
                    MockCompletedExercise(
                        exerciseName: "Plank",
                        exerciseType: .time,
                        sets: [
                            MockCompletedSet(order: 0, time: 60),
                            MockCompletedSet(order: 1, time: 45),
                            MockCompletedSet(order: 2, time: 30),
                        ]
                    ),
                ]
            )
        )
    }
}

#Preview("Minimal") {
    NavigationStack {
        CompletedWorkoutDetailView(
            workout: MockCompletedWorkout(
                name: "Quick Workout",
                completedAt: Date(),
                duration: 1800,
                exerciseCount: 2,
                totalSets: 6,
                exercises: []
            )
        )
    }
}
