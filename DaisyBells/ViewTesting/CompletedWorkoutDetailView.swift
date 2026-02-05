import SwiftUI

/// Read-only view of a completed workout, matching ActiveWorkoutView layout
struct CompletedWorkoutDetailView: View {
    let workout: MockCompletedWorkout

    @Environment(\.dismiss) private var dismiss
    @State private var deleteConfig: ConfirmationDialogConfig?

    var body: some View {
        List {
            // MARK: - Header Section
            Section {
                // Title
                Text(workout.name)
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)

                // Date and Duration
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.completedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formattedDuration)
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.medium)
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Notes
                if let notes = workout.notes, !notes.isEmpty {
                    Text(notes)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No notes")
                        .foregroundStyle(.tertiary)
                        .italic()
                }
            }

            // MARK: - Exercise Sections
            ForEach(workout.exercises) { exercise in
                Section {
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        LoggedSetDisplayView(
                            exerciseType: exercise.exerciseType,
                            setNumber: index + 1,
                            weight: set.weight,
                            reps: set.reps,
                            bodyweightModifier: set.bodyweightModifier,
                            time: set.time,
                            distance: set.distance,
                            notes: set.notes ?? ""
                        )
                    }
                } header: {
                    exerciseHeader(for: exercise)
                }
            }

            // MARK: - Delete Section
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
                        Spacer()
                        Image(systemName: "trash")
                        Text("Delete Workout")
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(0)
        .contentMargins(.top, 0, for: .scrollContent)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog($deleteConfig)
    }

    // MARK: - Helpers

    private var formattedDuration: String {
        let hours = Int(workout.duration) / 3600
        let minutes = (Int(workout.duration) % 3600) / 60
        let seconds = Int(workout.duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    @ViewBuilder
    private func exerciseHeader(for exercise: MockCompletedExercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exerciseName)
                    .font(.headline)
                    .textCase(nil)
                    .foregroundStyle(Color(.label))
                Text(exercise.exerciseType.displayName)
                    .font(.caption)
                    .textCase(nil)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

/// Read-only display of a logged set, matching LoggedSetEditorView layout
private struct LoggedSetDisplayView: View {
    let exerciseType: MockExerciseType
    let setNumber: Int
    let weight: Double?
    let reps: Int?
    let bodyweightModifier: Double?
    let time: TimeInterval?
    let distance: Double?
    let notes: String

    var body: some View {
        HStack(spacing: 16) {
            // Set number indicator
            Text("\(setNumber)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            // Dynamic display based on exercise type
            switch exerciseType {
            case .weightAndReps:
                valueDisplay(value: formatWeight(weight), label: "lbs")
                valueDisplay(value: formatReps(reps), label: "reps")

            case .bodyweightAndReps:
                valueDisplay(value: formatBodyweightModifier(bodyweightModifier), label: "+/- lbs")
                valueDisplay(value: formatReps(reps), label: "reps")

            case .reps:
                valueDisplay(value: formatReps(reps), label: "reps")

            case .time:
                valueDisplay(value: formatTime(time), label: "min")

            case .distanceAndTime:
                valueDisplay(value: formatDistance(distance), label: "mi")
                valueDisplay(value: formatTime(time), label: "min")

            case .weightAndTime:
                valueDisplay(value: formatWeight(weight), label: "lbs")
                valueDisplay(value: formatTime(time), label: "min")
            }

            Spacer()

            // Notes display
            if !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private func valueDisplay(value: String, label: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .frame(width: label == "+/- lbs" ? 50 : 40)
                .padding(6)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: - Formatters

    private func formatWeight(_ weight: Double?) -> String {
        guard let weight else { return "—" }
        return "\(Int(weight))"
    }

    private func formatReps(_ reps: Int?) -> String {
        guard let reps else { return "—" }
        return "\(reps)"
    }

    private func formatBodyweightModifier(_ modifier: Double?) -> String {
        guard let modifier else { return "BW" }
        if modifier > 0 {
            return "+\(Int(modifier))"
        } else if modifier < 0 {
            return "\(Int(modifier))"
        } else {
            return "BW"
        }
    }

    private func formatTime(_ time: TimeInterval?) -> String {
        guard let time else { return "—" }
        let minutes = time / 60
        if minutes < 1 {
            return String(format: "%.1f", minutes)
        }
        return String(format: "%.1f", minutes)
    }

    private func formatDistance(_ distance: Double?) -> String {
        guard let distance else { return "—" }
        return String(format: "%.2f", distance)
    }
}

// MARK: - Previews

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
                            MockCompletedSet(order: 1, reps: 10),
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

#Preview("No Notes") {
    NavigationStack {
        CompletedWorkoutDetailView(
            workout: MockCompletedWorkout(
                name: "Quick Workout",
                completedAt: Date(),
                duration: 1800,
                exerciseCount: 1,
                totalSets: 3,
                exercises: [
                    MockCompletedExercise(
                        exerciseName: "Pull-ups",
                        exerciseType: .bodyweightAndReps,
                        sets: [
                            MockCompletedSet(order: 0, reps: 10),
                            MockCompletedSet(order: 1, reps: 8),
                            MockCompletedSet(order: 2, reps: 6),
                        ]
                    )
                ]
            )
        )
    }
}

#Preview("Cardio Workout") {
    NavigationStack {
        CompletedWorkoutDetailView(
            workout: MockCompletedWorkout(
                name: "Morning Run",
                completedAt: Date(),
                duration: 2700,
                notes: "Easy pace, felt good.",
                exerciseCount: 1,
                totalSets: 1,
                exercises: [
                    MockCompletedExercise(
                        exerciseName: "Running",
                        exerciseType: .distanceAndTime,
                        sets: [
                            MockCompletedSet(order: 0, time: 2700, distance: 3.5)
                        ]
                    )
                ]
            )
        )
    }
}
